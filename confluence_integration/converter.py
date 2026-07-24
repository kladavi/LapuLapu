"""Confluence storage-format HTML → Markdown conversion.

Confluence returns page bodies as *storage-format* XHTML, which is largely
HTML plus a handful of ``<ac:...>`` / ``<ri:...>`` custom tags for macros,
mentions, links, and layouts. We do a light pre-processing pass to reduce
the most common noisy macros to sensible HTML, then hand off to
:mod:`html2text` for the actual Markdown emission.
"""

from __future__ import annotations

import base64
import logging
import re
from typing import Iterable
from urllib.parse import quote

import html2text

from .config import ConverterSettings

logger = logging.getLogger("confluence_integration.converter")

# Regex-based cleanup is intentional: an XML parser on storage-format
# content would need namespace declarations for every ``ac:`` / ``ri:``
# prefix that Confluence emits, which is more fragile in practice than
# targeted rewrites.

_LAYOUT_TAGS = ("ac:layout", "ac:layout-section", "ac:layout-cell")

_INFO_MACROS = {"info", "note", "warning", "tip", "success"}
_CODE_MACRO_LANGUAGE_PARAM = re.compile(
    r'<ac:parameter\s+ac:name="language">([^<]*)</ac:parameter>',
    re.IGNORECASE,
)

# Placeholder token used to smuggle fenced code blocks through html2text
# without them being reformatted. Chosen from characters html2text never
# touches, and re-substituted in the post-processing stage.
_CODE_PLACEHOLDER_RE = re.compile(r"§§CODEBLOCK:([^§]+)§§")



class HtmlToMarkdownConverter:
    """Convert Confluence storage HTML to Markdown."""

    def __init__(self, settings: ConverterSettings) -> None:
        self.settings = settings

    def convert(self, storage_html: str) -> str:
        """Return a Markdown string for the given storage-format HTML."""
        if not storage_html:
            return ""

        preprocessed = self._preprocess(storage_html)
        converter = self._build_html2text()
        markdown = converter.handle(preprocessed)
        return self._postprocess(markdown)

    # ── Pipeline stages ───────────────────────────────────────────

    def _preprocess(self, html: str) -> str:
        text = html

        if self.settings.strip_layout_macros:
            text = self._strip_tags(text, _LAYOUT_TAGS)

        text = self._rewrite_code_macros(text)
        text = self._rewrite_info_macros(text)
        text = self._rewrite_status_macros(text)
        text = self._rewrite_user_mentions(text)
        text = self._rewrite_page_links(text)
        text = self._rewrite_attachment_images(text)
        text = self._drop_unknown_macros(text)
        return text

    def _postprocess(self, markdown: str) -> str:
        # Reinstate fenced code blocks that we hid behind placeholders
        def _decode(match: re.Match[str]) -> str:
            payload = match.group(1)
            try:
                raw = base64.urlsafe_b64decode(payload.encode("ascii")).decode("utf-8")
            except (ValueError, UnicodeDecodeError):
                return match.group(0)
            return raw

        restored = _CODE_PLACEHOLDER_RE.sub(_decode, markdown)
        # Collapse runs of 3+ blank lines that html2text sometimes emits
        collapsed = re.sub(r"\n{3,}", "\n\n", restored)
        return collapsed.strip() + "\n"

    def _build_html2text(self) -> html2text.HTML2Text:
        h = html2text.HTML2Text()
        h.body_width = self.settings.body_width
        h.ignore_links = self.settings.ignore_links
        h.ignore_images = self.settings.ignore_images
        h.bypass_tables = self.settings.bypass_tables
        h.protect_links = True
        return h

    # ── Storage-format rewrites ───────────────────────────────────

    @staticmethod
    def _strip_tags(html: str, tags: Iterable[str]) -> str:
        for tag in tags:
            open_re = re.compile(rf"<{re.escape(tag)}\b[^>]*>", re.IGNORECASE)
            close_re = re.compile(rf"</{re.escape(tag)}\s*>", re.IGNORECASE)
            html = open_re.sub("", html)
            html = close_re.sub("", html)
        return html

    @staticmethod
    def _rewrite_code_macros(html: str) -> str:
        pattern = re.compile(
            r'<ac:structured-macro\s+ac:name="code"[^>]*>(?P<body>.*?)</ac:structured-macro>',
            re.IGNORECASE | re.DOTALL,
        )

        def repl(match: re.Match[str]) -> str:
            body = match.group("body")
            lang_match = _CODE_MACRO_LANGUAGE_PARAM.search(body)
            language = lang_match.group(1).strip() if lang_match else ""
            cdata = re.search(
                r"<ac:plain-text-body>\s*<!\[CDATA\[(?P<code>.*?)\]\]>\s*</ac:plain-text-body>",
                body,
                re.DOTALL | re.IGNORECASE,
            )
            code = cdata.group("code") if cdata else ""
            fenced = f"```{language}\n{code}\n```"
            payload = base64.urlsafe_b64encode(fenced.encode("utf-8")).decode("ascii")
            # Wrap in <p> so html2text keeps it on its own line
            return f"<p>§§CODEBLOCK:{payload}§§</p>"

        return pattern.sub(repl, html)


    @staticmethod
    def _rewrite_info_macros(html: str) -> str:
        pattern = re.compile(
            r'<ac:structured-macro\s+ac:name="(?P<name>[a-zA-Z]+)"[^>]*>'
            r"(?P<body>.*?)</ac:structured-macro>",
            re.IGNORECASE | re.DOTALL,
        )

        def repl(match: re.Match[str]) -> str:
            name = match.group("name").lower()
            if name not in _INFO_MACROS:
                return match.group(0)
            body = match.group("body")
            rich = re.search(
                r"<ac:rich-text-body>(?P<inner>.*?)</ac:rich-text-body>",
                body,
                re.DOTALL | re.IGNORECASE,
            )
            inner = rich.group("inner") if rich else body
            label = name.upper()
            return f"<blockquote><strong>{label}:</strong> {inner}</blockquote>"

        return pattern.sub(repl, html)

    @staticmethod
    def _rewrite_status_macros(html: str) -> str:
        pattern = re.compile(
            r'<ac:structured-macro\s+ac:name="status"[^>]*>(?P<body>.*?)</ac:structured-macro>',
            re.IGNORECASE | re.DOTALL,
        )

        def repl(match: re.Match[str]) -> str:
            body = match.group("body")
            title = re.search(
                r'<ac:parameter\s+ac:name="title">([^<]*)</ac:parameter>',
                body,
                re.IGNORECASE,
            )
            colour = re.search(
                r'<ac:parameter\s+ac:name="colour">([^<]*)</ac:parameter>',
                body,
                re.IGNORECASE,
            )
            label = title.group(1).strip() if title else ""
            hue = colour.group(1).strip().upper() if colour else ""
            if hue and label:
                return f"<code>[{hue}] {label}</code>"
            return f"<code>{label or hue}</code>"

        return pattern.sub(repl, html)

    @staticmethod
    def _rewrite_user_mentions(html: str) -> str:
        pattern = re.compile(
            r'<ac:link>\s*<ri:user\s+ri:userkey="(?P<key>[^"]+)"\s*/>\s*</ac:link>',
            re.IGNORECASE,
        )
        return pattern.sub(lambda m: f"@{m.group('key')}", html)

    @staticmethod
    def _rewrite_page_links(html: str) -> str:
        pattern = re.compile(
            r'<ac:link[^>]*>\s*'
            r'<ri:page\s+ri:content-title="(?P<title>[^"]+)"[^/]*/>'
            r'(?:\s*<ac:plain-text-link-body>\s*<!\[CDATA\[(?P<text>[^\]]*)\]\]>'
            r'\s*</ac:plain-text-link-body>)?'
            r'\s*</ac:link>',
            re.IGNORECASE | re.DOTALL,
        )

        def repl(match: re.Match[str]) -> str:
            title = match.group("title")
            text = match.group("text") or title
            href = f"confluence-page:{quote(title, safe='')}"
            return f'<a href="{href}">{text}</a>'

        return pattern.sub(repl, html)

    @staticmethod
    def _rewrite_attachment_images(html: str) -> str:
        pattern = re.compile(
            r'<ac:image[^>]*>\s*<ri:attachment\s+ri:filename="(?P<name>[^"]+)"[^/]*/>\s*</ac:image>',
            re.IGNORECASE,
        )
        return pattern.sub(
            lambda m: f'<img src="attachments/{m.group("name")}" alt="{m.group("name")}"/>',
            html,
        )

    @staticmethod
    def _drop_unknown_macros(html: str) -> str:
        pattern = re.compile(
            r'<ac:structured-macro[^>]*>.*?</ac:structured-macro>',
            re.IGNORECASE | re.DOTALL,
        )
        return pattern.sub("", html)
