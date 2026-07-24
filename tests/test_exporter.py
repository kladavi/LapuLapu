"""Unit tests for :mod:`confluence_integration.exporter`."""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import MagicMock

from confluence_integration.exporter import (
    ConfluenceExporter,
    ExportManifest,
    ExportPlan,
)


def _make_page(page_id: str, title: str, ancestors: list[str] | None = None, body: str = "<p>ok</p>", version: int = 1):
    return {
        "id": page_id,
        "title": title,
        "body": {"storage": {"value": body}},
        "version": {"number": version, "when": "2026-07-24T00:00:00Z"},
        "ancestors": [{"id": aid} for aid in (ancestors or [])],
        "_links": {"webui": f"/spaces/DEMO/pages/{page_id}"},
    }


def _mk_client(pages_by_id, children_by_id):
    client = MagicMock()

    def fetch(page_id):
        return pages_by_id[str(page_id)]

    def iter_children(page_id):
        return iter(children_by_id.get(str(page_id), []))

    client.fetch_page_content.side_effect = fetch
    client.iter_child_pages.side_effect = iter_children
    return client


def test_sanitize_filename_replaces_invalid_chars():
    slug = ConfluenceExporter._sanitize_filename('Weird / Title : "here"')
    assert "/" not in slug and ":" not in slug and '"' not in slug
    assert slug.startswith("Weird") and slug.endswith("here")


def test_sanitize_filename_truncates():
    slug = ConfluenceExporter._sanitize_filename("a" * 200, max_length=10)
    assert len(slug) <= 10


def test_dry_run_returns_plan_without_writing(tmp_path, settings):
    root = _make_page("100", "Root")
    child = _make_page("200", "Child", ancestors=["100"])
    pages = {"100": root, "200": child}
    children = {"100": [child], "200": []}
    client = _mk_client(pages, children)

    settings.output_directory = tmp_path
    exporter = ConfluenceExporter(settings, client=client)
    plan = exporter.export_page_tree(page_id="100", dry_run=True, progress=False)

    assert isinstance(plan, ExportPlan)
    assert len(plan.pages) == 2
    # No files or manifest written
    assert list(tmp_path.iterdir()) == []


def test_export_writes_files_and_manifest(tmp_path, settings):
    root = _make_page("100", "Root Page", body="<p>root body</p>")
    child = _make_page("200", "Child One", ancestors=["100"], body="<p>child body</p>")
    grand = _make_page("300", "Grand", ancestors=["100", "200"], body="<p>grand</p>")
    pages = {"100": root, "200": child, "300": grand}
    children = {"100": [child], "200": [grand], "300": []}
    client = _mk_client(pages, children)

    settings.output_directory = tmp_path
    exporter = ConfluenceExporter(settings, client=client)
    manifest = exporter.export_page_tree(page_id="100", progress=False)

    assert isinstance(manifest, ExportManifest)
    # Root is a container → root/_index.md
    root_dir = tmp_path / "100_Root-Page"
    assert (root_dir / "_index.md").exists()
    # Child has grandchild → child dir with _index.md
    child_dir = root_dir / "200_Child-One"
    assert (child_dir / "_index.md").exists()
    # Grandchild is a leaf → flat markdown file inside child dir
    assert (child_dir / "300_Grand.md").exists()

    manifest_path = tmp_path / settings.export.manifest_filename
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert set(payload["pages"].keys()) == {"100", "200", "300"}
    assert payload["root_page_id"] == "100"

    # Frontmatter is present
    body = (root_dir / "_index.md").read_text(encoding="utf-8")
    assert body.startswith("---\n")
    assert 'title: "Root Page"' in body
    assert "page_id: 100" in body


def test_incremental_skips_unchanged(tmp_path, settings):
    root = _make_page("100", "Root", version=3)
    pages = {"100": root}
    children = {"100": []}
    client = _mk_client(pages, children)

    settings.output_directory = tmp_path
    exporter = ConfluenceExporter(settings, client=client)
    exporter.export_page_tree(page_id="100", progress=False)  # first run writes

    # Second run should skip because manifest matches
    exporter2 = ConfluenceExporter(settings, client=_mk_client(pages, children))
    result = exporter2.export_page_tree(page_id="100", dry_run=True, progress=False)
    assert isinstance(result, ExportPlan)
    assert len(result.pages) == 0
    assert result.skipped_unchanged == ["100"]


def test_failure_recorded_but_export_continues(tmp_path, settings):
    root = _make_page("100", "Root")
    good = _make_page("200", "Good", ancestors=["100"])
    pages = {"100": root, "200": good}
    children = {"100": [good], "200": []}
    client = _mk_client(pages, children)

    settings.output_directory = tmp_path
    exporter = ConfluenceExporter(settings, client=client)

    # Force one page to fail during write
    original_save = exporter.save_page_as_markdown

    def flaky(page_data, target: Path):
        if page_data["id"] == "200":
            raise RuntimeError("disk full")
        return original_save(page_data, target)

    exporter.save_page_as_markdown = flaky  # type: ignore[assignment]

    exporter.export_page_tree(page_id="100", progress=False)

    assert any(f["id"] == "200" for f in exporter.failures)
    # Root still written
    root_dir = tmp_path / "100_Root"
    assert (root_dir / "_index.md").exists()
