# confluence_integration — Confluence → Markdown exporter

Production-ready Python module that pulls Confluence pages (via the
Cloud REST API) and writes them into the vault as Markdown for
downstream AI/context processing.

## Quick start

```powershell
# 1. Install dependencies
python -m pip install -r requirements.txt

# 2. Create your credentials file
Copy-Item config/.env.example config/.env
# Edit config/.env — set API_EMAIL and API_TOKEN
# API tokens: https://id.atlassian.com/manage-profile/security/api-tokens

# 3. Verify credentials
python main.py check

# 4. Dry-run against the configured root page
python main.py export --dry-run

# 5. Real export (default root = GOCC Japan — Lapu-Lapu project, id 15947890782)
python main.py export
```

Output lands under the path set in `OUTPUT_DIRECTORY` (default
`./exports/gocc_japan`).

## Layout

| Path | Purpose |
|---|---|
| `confluence_integration/__init__.py` | Public API surface |
| `confluence_integration/config.py` | `.env` + YAML config loader (`Settings`, `load_settings`) |
| `confluence_integration/client.py` | `ConfluenceClient` — retry-aware REST client |
| `confluence_integration/converter.py` | `HtmlToMarkdownConverter` — storage-format → Markdown |
| `confluence_integration/exporter.py` | `ConfluenceExporter`, `ExportManifest`, `ExportPlan` |
| `config/.env.example` | Credential template (copy to `config/.env`) |
| `config/settings.yaml` | Non-secret runtime tuning |
| `main.py` | CLI (`export`, `search`, `check`) |
| `tests/` | Pytest suite with mocked API responses |

## Output structure

For a page tree, the exporter writes a directory for every non-leaf page and a
plain `.md` for every leaf, with the parent's own body in `_index.md`:

```
exports/gocc_japan/
├── export-manifest.json
└── 15947890782_GOCC-Japan-Lapu-Lapu-project/
    ├── _index.md                              # frontmatter + body of the root page
    ├── 15947890783_Charter.md                 # leaf child
    └── 15947890900_Workstreams/
        ├── _index.md
        └── 15947890901_Rapid-Recovery.md
```

Each Markdown file starts with YAML frontmatter:

```yaml
---
title: "GOCC Japan — Lapu-Lapu project"
page_id: 15947890782
version: 42
updated_at: 2026-07-24T04:12:33.000Z
source_url: https://manulife-ets.atlassian.net/wiki/spaces/GOCC/pages/15947890782/...
---
```

## Programmatic use

```python
from confluence_integration import ConfluenceExporter, load_settings

settings = load_settings()
exporter = ConfluenceExporter(settings)
manifest = exporter.export_page_tree(
    page_id="15947890782",
    output_dir="./exports/gocc_japan",
    incremental=True,
)
print(f"Exported {len(manifest.pages)} pages")
```

## Features

- **Recursive traversal** with pagination for pages with many children.
- **Incremental sync** — the `export-manifest.json` tracks `version.number`
  per page; unchanged pages are skipped on subsequent runs. Pass
  `--no-incremental` to force a full re-export.
- **Dry-run** (`--dry-run`) prints the plan without writing.
- **Progress bar** via `tqdm` (disable with `--no-progress`).
- **Rate-limit aware** — HTTP 429 and 5xx responses trigger exponential
  backoff (honouring `Retry-After` when present); tunable in
  `config/settings.yaml`.
- **Per-page failure isolation** — one bad page never aborts the export;
  failures are logged and summarised on exit (non-zero exit code).
- **CQL search** (`python main.py search "term"`) restricted to the
  configured root ancestor.
- **Confluence storage-format** cleanup: code macros keep their language,
  `info/note/warning/tip/success` panels become blockquotes, layout
  wrappers are stripped, unknown macros are dropped safely.

## Running the tests

```powershell
python -m pip install -r requirements.txt pytest
python -m pytest tests
```

All tests mock the HTTP layer — no live Confluence calls are made.
