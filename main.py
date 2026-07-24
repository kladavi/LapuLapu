"""CLI entry point for the Confluence exporter.

Usage examples::

    # Full export using config/.env + config/settings.yaml
    python main.py export

    # Dry-run to see what would be exported
    python main.py export --dry-run

    # Force re-export of everything (ignore manifest)
    python main.py export --no-incremental

    # Search inside the configured root page
    python main.py search "rapid recovery"

    # Validate credentials without exporting
    python main.py check
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from confluence_integration import (
    ConfluenceAPIError,
    ConfluenceClient,
    ConfluenceExporter,
    load_settings,
)
from confluence_integration.config import ConfigError, configure_logging


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="confluence-exporter",
        description="Export a Confluence page tree to Markdown.",
    )
    parser.add_argument(
        "--env-file",
        type=Path,
        default=None,
        help="Path to a .env file (defaults to config/.env).",
    )
    parser.add_argument(
        "--settings-file",
        type=Path,
        default=None,
        help="Path to settings YAML (defaults to config/settings.yaml).",
    )

    sub = parser.add_subparsers(dest="command", required=True)

    export = sub.add_parser("export", help="Export the configured page tree.")
    export.add_argument(
        "--page-id",
        default=None,
        help="Override ROOT_PAGE_ID for this run.",
    )
    export.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Override OUTPUT_DIRECTORY for this run.",
    )
    export.add_argument(
        "--dry-run",
        action="store_true",
        help="List pages that would be exported without writing files.",
    )
    export.add_argument(
        "--no-incremental",
        action="store_true",
        help="Re-export every page even if its version matches the manifest.",
    )
    export.add_argument(
        "--no-progress",
        action="store_true",
        help="Disable the tqdm progress bar.",
    )

    search = sub.add_parser("search", help="Search inside the configured root page.")
    search.add_argument("query", help="Free-text CQL query.")
    search.add_argument(
        "--ancestor-id",
        default=None,
        help="Scope the search under a specific ancestor id (defaults to ROOT_PAGE_ID).",
    )
    search.add_argument("--limit", type=int, default=25)

    sub.add_parser("check", help="Validate credentials and quit.")

    return parser


def _cmd_export(args: argparse.Namespace, settings) -> int:
    exporter = ConfluenceExporter(settings)
    try:
        exporter.export_page_tree(
            page_id=args.page_id,
            output_dir=args.output_dir,
            incremental=not args.no_incremental,
            dry_run=args.dry_run,
            progress=not args.no_progress,
        )
    except ConfluenceAPIError as exc:
        logging.error("Export aborted: %s", exc)
        return 2

    if exporter.failures:
        logging.warning("%d page(s) failed to export:", len(exporter.failures))
        for failure in exporter.failures:
            logging.warning("  - %s (%s): %s", failure["title"], failure["id"], failure["error"])
        return 1
    return 0


def _cmd_search(args: argparse.Namespace, settings) -> int:
    client = ConfluenceClient(settings)
    ancestor = args.ancestor_id or settings.root_page_id
    try:
        results = client.search_pages(args.query, ancestor_id=ancestor, limit=args.limit)
    except ConfluenceAPIError as exc:
        logging.error("Search failed: %s", exc)
        return 2

    if not results:
        print("No matches.")
        return 0

    for hit in results:
        page_id = hit.get("id", "?")
        title = hit.get("title", "(untitled)")
        version = (hit.get("version") or {}).get("number", "?")
        print(f"[{page_id}] v{version}  {title}")
    return 0


def _cmd_check(_args: argparse.Namespace, settings) -> int:
    client = ConfluenceClient(settings)
    try:
        user = client.validate_authentication()
    except ConfluenceAPIError as exc:
        logging.error("Authentication check failed: %s", exc)
        return 2
    display = user.get("displayName") or user.get("email") or "(unknown)"
    logging.info("Authenticated as %s", display)
    print(f"OK — authenticated as {display}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    try:
        settings = load_settings(args.env_file, args.settings_file)
    except ConfigError as exc:
        print(f"Configuration error: {exc}", file=sys.stderr)
        return 3
    configure_logging(settings)

    if args.command == "export":
        return _cmd_export(args, settings)
    if args.command == "search":
        return _cmd_search(args, settings)
    if args.command == "check":
        return _cmd_check(args, settings)

    parser.error(f"Unknown command: {args.command}")
    return 4


if __name__ == "__main__":
    sys.exit(main())
