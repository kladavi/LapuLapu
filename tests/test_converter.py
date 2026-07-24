"""Unit tests for :mod:`confluence_integration.converter`."""

from __future__ import annotations

from confluence_integration.config import ConverterSettings
from confluence_integration.converter import HtmlToMarkdownConverter


def _mk() -> HtmlToMarkdownConverter:
    return HtmlToMarkdownConverter(ConverterSettings())


def test_convert_plain_html():
    md = _mk().convert("<h1>Hello</h1><p>World</p>")
    assert "# Hello" in md
    assert "World" in md


def test_convert_code_macro_preserves_language():
    html = (
        '<ac:structured-macro ac:name="code">'
        '<ac:parameter ac:name="language">python</ac:parameter>'
        "<ac:plain-text-body><![CDATA[print('hi')]]></ac:plain-text-body>"
        "</ac:structured-macro>"
    )
    md = _mk().convert(html)
    assert "print('hi')" in md
    assert "python" in md.lower()


def test_convert_info_macro_becomes_blockquote():
    html = (
        '<ac:structured-macro ac:name="info">'
        "<ac:rich-text-body><p>Heads up.</p></ac:rich-text-body>"
        "</ac:structured-macro>"
    )
    md = _mk().convert(html)
    assert md.strip().startswith(">")
    assert "INFO" in md
    assert "Heads up." in md


def test_convert_page_link_rewrites_to_anchor():
    html = (
        '<ac:link><ri:page ri:content-title="Rapid Recovery"/>'
        "<ac:plain-text-link-body><![CDATA[recovery]]></ac:plain-text-link-body>"
        "</ac:link>"
    )
    md = _mk().convert(html)
    assert "recovery" in md
    assert "confluence-page:Rapid%20Recovery" in md


def test_convert_layout_macros_are_stripped():
    html = "<ac:layout><ac:layout-section><ac:layout-cell><p>x</p></ac:layout-cell></ac:layout-section></ac:layout>"
    md = _mk().convert(html)
    assert "x" in md
    assert "ac:layout" not in md


def test_convert_empty_input_returns_empty_string():
    assert _mk().convert("") == ""


def test_convert_unknown_macros_are_dropped():
    html = '<p>keep</p><ac:structured-macro ac:name="unknown-plugin"><ac:parameter>x</ac:parameter></ac:structured-macro><p>after</p>'
    md = _mk().convert(html)
    assert "keep" in md
    assert "after" in md
    assert "unknown-plugin" not in md
