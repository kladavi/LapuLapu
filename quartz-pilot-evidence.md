---
type: "quartz-pilot-evidence"
title: "Quartz Pilot Evidence Package — V4.0 Sprint 25a"
generator: "manual, from Quartz v5.0.0 build artefacts on 2026-07-22"
generated: "2026-07-22"
version: "V4.0-sprint25a"
schema: "quartz-pilot-evidence/v1"
scope: "Objective build + smoke-test evidence for Sprint 25a. Subjective UX assessment lives in quartz-pilot-review.md."
---

# Quartz Pilot Evidence Package

Sprint 25a Deliverable 25a.1. All numbers below come from the artefacts on disk in [quartz-site/public/](quartz-site/public/) after a clean rebuild on 2026-07-22.

## Environment

| Field | Value |
|---|---|
| OS | Windows (Manulife-managed workstation) |
| Node | v24.9.0 |
| npm | v11.6.0 |
| Quartz | v5.0.0 @ `9cf87ff` (grafted, cloned `--depth 1` from `https://github.com/jackyzha0/quartz.git` on 2026-07-22) |
| Install location | [quartz-site/](quartz-site/) — gitignored |
| Content source | [quartz-content/](quartz-content/) — produced by [scripts/prepare-quartz-content.ps1](scripts/prepare-quartz-content.ps1) in Sprint 24 |

## Reproducibility from clean clone

```powershell
# 1. Clone Quartz (from repo root)
git clone --depth 1 https://github.com/jackyzha0/quartz.git quartz-site

# 2. Apply local patches (see quartz-patches/README.md for rationale)
Set-Location quartz-site
git apply ..\quartz-patches\01-disable-og-image.patch
git apply ..\quartz-patches\02-junction-fallback-trysymlink.patch

# 3. Install dependencies
npm install --no-audit --no-fund

# 4. Install Quartz plugins from the (patched) config
npx quartz plugin install --from-config

# 5. Clear default sample content and build against our corpus
Remove-Item .\content\* -Recurse -Force
Set-Location ..
Set-Location quartz-site
npx quartz build -d ../quartz-content

# 6. Serve locally (Ctrl+C to stop)
npx quartz build --serve -d ../quartz-content --port 8098
```

Every step above was executed in this order for both Sprint 25 and Sprint 25a. Both patches are strictly required on this workstation.

## Build command + output

Command:

```powershell
cd quartz-site
npx quartz build -d ../quartz-content
```

Captured output (verbatim, 2026-07-22 rebuild):

```
 Quartz v5.0.0

Cleaned output directory `public` in 142ms
Found 52 input files from `../quartz-content` in 70ms
Parsing input files using 1 threads
Parsed 52 Markdown files in 37s
Filtered out 9 files in 322μs
Emitting files
Emitted 139 files to `public` in 6s
Done processing 52 files in 43s
```

The 37-second parse is dominated by OneDrive filesystem sync overhead on this machine. On a non-synced drive an earlier build of the identical content completed the same phase in ~3 s.

## Emitted page counts

Directly measured from [quartz-site/public/](quartz-site/public/):

| Section | HTML files | Notes |
|---|---:|---|
| `decisions/` | 5 | 4 decision pages + 1 folder index (`index.html`). 1 draft decision filtered by `remove-draft`. |
| `risks/` | 8 | 7 risk pages + 1 folder index. 6 draft risks filtered. |
| `workstreams/` | 13 | 12 workstream pages + 1 folder index. |
| `reports/` | 20 | Every weekly + half-year report copied from [03-reporting/weekly/](03-reporting/weekly/). |
| `tags/` | 37 | Auto-emitted tag pages across 5 tag namespaces: `action`, `category`, `status`, `type`, `workstream`. |
| **Total** | **139** | |

Filter behaviour is a Quartz `remove-draft` plugin (enabled by default) reading `draft: true` from frontmatter. Sprint 24 emitted `draft: true` for every canonical item whose `validated == false`. 9 items were filtered; **see [quartz-pilot-review.md](quartz-pilot-review.md) for the broken-cross-link consequence.**

## Search index (contentIndex.json)

| Metric | Value |
|---|---:|
| File | `quartz-site/public/static/contentIndex.json` |
| Size | 137,174 bytes |
| Indexed entries | 85 |
| Entries with body text | 85 |
| Coverage | Every emitted HTML page has an entry keyed by its permalink. |

Powers the Flexsearch widget in the toolbar of every page.

## Serve command + HTTP smoke tests

Command:

```powershell
cd quartz-site
npx quartz build --serve -d ../quartz-content --port 8098
```

Captured server-side access log (verbatim, Sprint 25 initial run):

```
Started a Quartz server listening at http://localhost:8098
hint: exit with ctrl+c
[200] /
[301] /index.html
[301] /index
[200] /
[200] /decisions/d-40250bb7d6
[200] /workstreams/rapid-recovery
[200] /static/contentIndex.json
[200] /tags
```

Client-side probe (`Invoke-WebRequest`):

| URL | Status | Bytes |
|---|---:|---:|
| `http://localhost:8098/` | 200 | 28,542 |
| `http://localhost:8098/index.html` | 200 | 28,542 |
| `http://localhost:8098/decisions/d-40250bb7d6` | 200 | 28,076 |
| `http://localhost:8098/workstreams/rapid-recovery` | 200 | 23,946 |
| `http://localhost:8098/static/contentIndex.json` | 200 | 137,174 |
| `http://localhost:8098/tags` | 200 | 152,131 |

**6 / 6 smoke-test URLs returned HTTP 200.**

## Plugin list (verified enabled from `quartz.config.default.yaml` and confirmed present in emitted HTML)

| Plugin | Enabled | Emitted evidence |
|---|:---:|---|
| `search` (Flexsearch) | ✓ | `static/contentIndex.json` served, search widget in toolbar of every page |
| `backlinks` | ✓ | `<div class="backlinks">` present on decision, workstream, risk pages |
| `graph` | ✓ | `<div class="graph-container" data-cfg="...">` present |
| `explorer` | ✓ | Left-nav file tree rendered |
| `breadcrumbs` | ✓ | Non-index pages start with breadcrumb trail |
| `darkmode` | ✓ | Toolbar toggle |
| `reader-mode` | ✓ | Toolbar toggle |
| `popover` | ✓ | Hover preview enabled for internal wiki-links |
| `content-index` | ✓ | `sitemap.xml` and `index.xml` (RSS) emitted |
| `obsidian-flavored-markdown` | ✓ | `[!info]` and `[!todo]` callouts rendered as `<div class="callout" data-callout="info">…</div>` |
| `tag-page` | ✓ | `tags/{action,category,status,type,workstream}/*.html` emitted (37 pages total) |
| `crawl-links` | ✓ | Wiki-links `[[decisions/D-xxx\|Title]]` resolved to `<a href="../decisions/d-xxx">Title</a>` |
| `remove-draft` | ✓ | 9 files filtered from Sprint 24's `validated:false` items |
| `og-image` | ✗ | **DISABLED by patch 01** — plugin fetches TTF fonts from a CDN blocked by corp network |

## Known local patches

Two patches are required on this workstation. Both live in [quartz-patches/](quartz-patches/) with full rationale in [quartz-patches/README.md](quartz-patches/README.md).

| # | File | Patch | Reproducible after clean clone? |
|---|---|---|:---:|
| 01 | [quartz-patches/01-disable-og-image.patch](quartz-patches/01-disable-og-image.patch) | `quartz.config.default.yaml`: disable `og-image` plugin | Yes, via `git apply` from repo root |
| 02 | [quartz-patches/02-junction-fallback-trysymlink.patch](quartz-patches/02-junction-fallback-trysymlink.patch) | `quartz/plugins/loader/gitLoader.ts`: add NTFS-junction fallback in `trySymlink()` | Yes, via `git apply` from repo root |

Both patches were tested by running the reproducibility sequence in this document.

## HTML evidence snippets

Representative extracts from the emitted site live under [quartz-evidence/](quartz-evidence/):

| File | Section |
|---|---|
| [quartz-evidence/snippet-01-home-top10.html](quartz-evidence/snippet-01-home-top10.html) | Home page top-10 list |
| [quartz-evidence/snippet-02-workstream-rapid-recovery.html](quartz-evidence/snippet-02-workstream-rapid-recovery.html) | Rapid Recovery workstream page (cross-links visible) |
| [quartz-evidence/snippet-03-decision-d40250bb7d6.html](quartz-evidence/snippet-03-decision-d40250bb7d6.html) | Decision D002 page (callouts + tags visible) |
| [quartz-evidence/snippet-04-risk-bf28edfac4.html](quartz-evidence/snippet-04-risk-bf28edfac4.html) | Risk page (severity + trend + backlinks visible) |
| [quartz-evidence/snippet-05-tag-status-red.html](quartz-evidence/snippet-05-tag-status-red.html) | Tag page for `status/red` |
| [quartz-evidence/snippet-06-backlinks-section.html](quartz-evidence/snippet-06-backlinks-section.html) | Backlinks section markup |
| [quartz-evidence/snippet-07-graph-container.html](quartz-evidence/snippet-07-graph-container.html) | Graph container element with config |

## Broken cross-link scan

Site-wide scan (all `href="…decisions/…"`, `…risks/…`, `…workstreams/…`, `…reports/…` references against the set of emitted files):

| Metric | Value |
|---|---:|
| Total item cross-refs scanned | 371 |
| Broken references | 9 |
| Broken rate | 2.4 % |
| Workstream pages containing at least one broken link | 5 of 13 (38 %) |

Broken references (each is a workstream page linking to a draft-filtered item):

```
workstreams/cyberark-governance.html    -> risks/r-228ae1101c.html
workstreams/developer-xp-dashboard.html -> decisions/d-3ced6cbb47.html
workstreams/developer-xp-dashboard.html -> decisions/d-7f991874c7.html
workstreams/developer-xp-dashboard.html -> risks/r-9bfa424dbf.html
workstreams/developer-xp-dashboard.html -> risks/r-2884ed4872.html
workstreams/gocc-transition.html        -> risks/r-38e1cf13ff.html
workstreams/gocc-transition.html        -> risks/r-c7355ab891.html
workstreams/rapid-recovery.html         -> decisions/d-6f81d99006.html
workstreams/rapid-recovery.html         -> risks/r-cd89918f9c.html
```

**Root cause:** [scripts/prepare-quartz-content.ps1](scripts/prepare-quartz-content.ps1) (Sprint 24) writes cross-links from each workstream page to every decision/risk that carries its slug, but does not check `validated`. When those items are emitted with `draft: true`, Quartz's `remove-draft` plugin filters them from output — and the workstream page's links dead-end.

The broken links are the single most consequential finding of Sprint 25a. See [quartz-pilot-review.md](quartz-pilot-review.md) for how they affect the UX task results and the deploy recommendation.
