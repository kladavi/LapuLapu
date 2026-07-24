"""Export orchestration for Confluence page trees."""

from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

from tqdm import tqdm

from .client import ConfluenceAPIError, ConfluenceClient
from .config import Settings
from .converter import HtmlToMarkdownConverter

logger = logging.getLogger("confluence_integration.exporter")


_FILENAME_SANITIZE = re.compile(r'[<>:"/\\|?*\x00-\x1f]+')
_WHITESPACE_SANITIZE = re.compile(r"\s+")


@dataclass
class ExportManifest:
    """In-memory + on-disk record of a previous export.

    Structure written to disk (``export-manifest.json``)::

        {
          "generated_at": "...",
          "root_page_id": "...",
          "pages": {
            "<page_id>": {
              "title": "...",
              "version": 12,
              "updated_at": "...",
              "path": "gocc/foo.md",
              "url": "https://..."
            }, ...
          }
        }
    """

    root_page_id: str
    pages: dict[str, dict[str, Any]] = field(default_factory=dict)
    generated_at: str = ""

    @classmethod
    def load(cls, path: Path, root_page_id: str) -> "ExportManifest":
        if not path.exists():
            return cls(root_page_id=root_page_id)
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            logger.warning("Existing manifest %s is malformed; starting fresh", path)
            return cls(root_page_id=root_page_id)
        return cls(
            root_page_id=payload.get("root_page_id", root_page_id),
            pages=payload.get("pages", {}) or {},
            generated_at=payload.get("generated_at", ""),
        )

    def save(self, path: Path) -> None:
        self.generated_at = datetime.now(timezone.utc).isoformat()
        payload = {
            "generated_at": self.generated_at,
            "root_page_id": self.root_page_id,
            "pages": self.pages,
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    def record(self, page_id: str, entry: dict[str, Any]) -> None:
        self.pages[str(page_id)] = entry

    def get_version(self, page_id: str) -> int | None:
        entry = self.pages.get(str(page_id))
        if not entry:
            return None
        version = entry.get("version")
        return int(version) if version is not None else None


@dataclass
class ExportPlan:
    """Result of a dry-run — pages that *would* be exported."""

    pages: list[dict[str, Any]] = field(default_factory=list)
    skipped_unchanged: list[str] = field(default_factory=list)

    def __len__(self) -> int:
        return len(self.pages)


class ConfluenceExporter:
    """Recursively export a Confluence page tree to Markdown."""

    def __init__(
        self,
        settings: Settings,
        client: ConfluenceClient | None = None,
        converter: HtmlToMarkdownConverter | None = None,
    ) -> None:
        self.settings = settings
        self.client = client or ConfluenceClient(settings)
        self.converter = converter or HtmlToMarkdownConverter(settings.converter)
        self.failures: list[dict[str, Any]] = []

    # ── Public API ─────────────────────────────────────────────────

    def export_page_tree(
        self,
        page_id: str | None = None,
        output_dir: str | Path | None = None,
        *,
        incremental: bool = True,
        dry_run: bool = False,
        progress: bool = True,
    ) -> ExportPlan | ExportManifest:
        """Export ``page_id`` and every descendant to Markdown.

        Parameters
        ----------
        page_id:
            Root page id. Defaults to ``settings.root_page_id``.
        output_dir:
            Where to write files. Defaults to ``settings.output_directory``.
        incremental:
            When ``True`` (default), pages whose ``version.number`` matches
            the manifest are skipped.
        dry_run:
            When ``True``, no files are written. Returns an
            :class:`ExportPlan` describing what *would* happen.
        progress:
            Show a ``tqdm`` progress bar (auto-disables in dry-run and
            when stderr is not a TTY).
        """
        root_id = str(page_id or self.settings.root_page_id)
        out_path = Path(output_dir) if output_dir else self.settings.output_directory
        out_path = out_path.resolve()

        manifest_path = out_path / self.settings.export.manifest_filename
        manifest = ExportManifest.load(manifest_path, root_id)

        pages = list(self._walk(root_id))
        logger.info(
            "Discovered %d page(s) rooted at %s", len(pages), root_id
        )

        plan = ExportPlan()
        iterable: Iterator[tuple[dict[str, Any], Path]] = iter(
            self._assign_paths(pages, out_path)
        )
        if progress and not dry_run:
            iterable = tqdm(list(iterable), desc="Exporting", unit="page")

        for page, target in iterable:
            page_id_str = str(page.get("id"))
            version = int(((page.get("version") or {}).get("number")) or 0)
            if incremental and manifest.get_version(page_id_str) == version:
                logger.debug(
                    "Skipping %s (version %d unchanged)", page_id_str, version
                )
                plan.skipped_unchanged.append(page_id_str)
                continue

            plan.pages.append(
                {
                    "id": page_id_str,
                    "title": page.get("title", ""),
                    "version": version,
                    "path": str(target.relative_to(out_path)),
                }
            )

            if dry_run:
                continue

            try:
                self.save_page_as_markdown(page, target)
                manifest.record(
                    page_id_str,
                    {
                        "title": page.get("title", ""),
                        "version": version,
                        "updated_at": ((page.get("version") or {}).get("when")) or "",
                        "path": str(target.relative_to(out_path)),
                        "url": self._page_url(page),
                    },
                )
            except Exception as exc:  # noqa: BLE001 — keep exporting other pages
                logger.exception("Failed to export page %s: %s", page_id_str, exc)
                self.failures.append(
                    {"id": page_id_str, "title": page.get("title", ""), "error": str(exc)}
                )

        if dry_run:
            logger.info(
                "Dry-run: %d page(s) would be exported, %d unchanged",
                len(plan.pages),
                len(plan.skipped_unchanged),
            )
            return plan

        manifest.save(manifest_path)
        logger.info(
            "Export complete: %d written, %d unchanged, %d failed",
            len(plan.pages),
            len(plan.skipped_unchanged),
            len(self.failures),
        )
        return manifest

    def save_page_as_markdown(
        self,
        page_data: dict[str, Any],
        target: Path,
    ) -> Path:
        """Write ``page_data`` to ``target`` as Markdown with frontmatter."""
        target.parent.mkdir(parents=True, exist_ok=True)

        storage = ((page_data.get("body") or {}).get("storage") or {}).get("value", "")
        body_md = self.converter.convert(storage)
        header = self._frontmatter(page_data)
        target.write_text(header + "\n" + body_md, encoding="utf-8")
        logger.debug("Wrote %s", target)
        return target

    # ── Helpers ────────────────────────────────────────────────────

    def _walk(self, page_id: str) -> Iterator[dict[str, Any]]:
        """Depth-first traversal yielding fully-expanded page dicts."""
        try:
            root = self.client.fetch_page_content(page_id)
        except ConfluenceAPIError as exc:
            logger.error("Cannot fetch root page %s: %s", page_id, exc)
            self.failures.append(
                {"id": page_id, "title": "(root)", "error": str(exc)}
            )
            return

        yield root

        try:
            children = list(self.client.iter_child_pages(page_id))
        except ConfluenceAPIError as exc:
            logger.error("Cannot list children of %s: %s", page_id, exc)
            self.failures.append(
                {"id": page_id, "title": root.get("title", ""), "error": str(exc)}
            )
            return

        for child in children:
            child_id = str(child.get("id"))
            yield from self._walk(child_id)

    def _assign_paths(
        self,
        pages: list[dict[str, Any]],
        root_dir: Path,
    ) -> list[tuple[dict[str, Any], Path]]:
        """Map each page to an on-disk path.

        Pages that have children get their own subdirectory (named
        ``{id}_{slug}/``) with the page body written to ``_index.md`` inside.
        Leaf pages become ``{id}_{slug}.md`` alongside their parent's index.
        """
        children_by_parent: dict[str, list[dict[str, Any]]] = {}
        pages_by_id: dict[str, dict[str, Any]] = {}
        for page in pages:
            pages_by_id[str(page.get("id"))] = page
            ancestors = page.get("ancestors") or []
            parent_id = str(ancestors[-1].get("id")) if ancestors else None
            if parent_id and parent_id in pages_by_id:
                children_by_parent.setdefault(parent_id, []).append(page)

        assignments: list[tuple[dict[str, Any], Path]] = []
        dir_for_page: dict[str, Path] = {}

        for page in pages:
            page_id = str(page.get("id"))
            title = page.get("title", "untitled")
            slug = self._sanitize_filename(
                title, max_length=self.settings.export.max_title_length
            )
            ancestors = page.get("ancestors") or []
            parent_dir = root_dir
            for ancestor in ancestors:
                ancestor_id = str(ancestor.get("id"))
                if ancestor_id in dir_for_page:
                    parent_dir = dir_for_page[ancestor_id]

            has_children = bool(children_by_parent.get(page_id))
            if has_children:
                page_dir = parent_dir / f"{page_id}_{slug}"
                dir_for_page[page_id] = page_dir
                target = page_dir / "_index.md"
            else:
                dir_for_page[page_id] = parent_dir
                target = parent_dir / f"{page_id}_{slug}.md"
            assignments.append((page, target))

        return assignments

    def _frontmatter(self, page: dict[str, Any]) -> str:
        title = page.get("title", "")
        page_id = page.get("id", "")
        version = (page.get("version") or {}).get("number", "")
        updated = (page.get("version") or {}).get("when", "")
        url = self._page_url(page)
        # YAML-safe: quote the title, everything else is scalar-safe.
        safe_title = title.replace('"', '\\"')
        return (
            "---\n"
            f'title: "{safe_title}"\n'
            f"page_id: {page_id}\n"
            f"version: {version}\n"
            f"updated_at: {updated}\n"
            f"source_url: {url}\n"
            "---\n"
        )

    def _page_url(self, page: dict[str, Any]) -> str:
        webui = ((page.get("_links") or {}).get("webui")) or ""
        if webui:
            base = self.settings.wiki_base
            if webui.startswith("/wiki"):
                return self.settings.confluence_url.rstrip("/") + webui
            return f"{base}{webui}"
        page_id = page.get("id", "")
        return f"{self.settings.wiki_base}/pages/{page_id}"

    @staticmethod
    def _sanitize_filename(value: str, *, max_length: int = 80) -> str:
        cleaned = _FILENAME_SANITIZE.sub(" ", value or "")
        cleaned = _WHITESPACE_SANITIZE.sub("-", cleaned).strip("-._ ")
        cleaned = cleaned or "untitled"
        if len(cleaned) > max_length:
            cleaned = cleaned[:max_length].rstrip("-._ ")
        return cleaned or "untitled"
