---
type: "quartz-pilot-review"
title: "Quartz Pilot Review — V4.0 Sprint 25"
generator: "manual + build-log evidence from Quartz v5.0.0"
generated: "2026-07-22"
version: "V4.0-sprint25"
schema: "quartz-pilot-review/v1"
scope: "Local pilot only. No public hosting, no SharePoint, no GitHub Pages, no nginx."
---

# Quartz Pilot Review — Sprint 25

## Purpose

The reviewer flipped Sprint 24 back on with an explicit constraint: **validate whether Quartz is actually useful before spending any sprint on hosting**. Sprint 25 installs Quartz locally, points it at the `quartz-content/` pilot corpus produced in Sprint 24, and asks: does the resulting site make the Lapu-Lapu knowledge base easier to navigate, search, and trust?

This document records objective build evidence + a subjective UX assessment against six navigation surfaces (home, workstreams, decisions, risks, reports, tags), and ends with a Deploy / Do Not Deploy recommendation.

**Out of scope (per reviewer):** hosting decisions, public deploy, SharePoint publish, GitHub Pages publish, nginx.

## Build Evidence

**Runtime:**
- Quartz v5.0.0 (cloned from `https://github.com/jackyzha0/quartz.git` on 2026-07-22)
- Node v24.9.0, npm v11.6.0 (satisfies engine requirement `node>=22, npm>=10.9.2`)
- Install location: [quartz-site/](quartz-site/) (gitignored: `public/`, `.quartz-cache/`, `.git/`; `node_modules/` already covered by root rule)

**Install steps executed:**
1. `git clone --depth 1 https://github.com/jackyzha0/quartz.git quartz-site`
2. `npm install --no-audit --no-fund` — 378 packages, 2 min
3. `npx quartz plugin install --from-config` — resolved 44 plugins (all built or pre-built dist)
4. `npx quartz build -d ../quartz-content` — 52 input files → 139 emitted files in 22.4 s
5. `npx quartz build --serve -d ../quartz-content --port 8098` — server up, all HTTP smoke tests 200

**Two Quartz-side patches were required on this Manulife Windows machine:**

| # | File | Reason | Change |
|---|---|---|---|
| P1 | [quartz-site/quartz/plugins/loader/gitLoader.ts](quartz-site/quartz/plugins/loader/gitLoader.ts) | Windows without Developer Mode / admin lacks `SeCreateSymbolicLinkPrivilege`; plugin loader used `fs.symlinkSync(target, linkPath, "dir")` which failed with `EPERM` for every plugin. | Added NTFS-junction fallback in `trySymlink()` — junctions require no elevation for same-volume dirs. |
| P2 | [quartz-site/quartz.config.default.yaml](quartz-site/quartz.config.default.yaml) | `og-image` plugin fetches TTF fonts from a CDN; Manulife network blocked the fetch (`fetch failed` → `undici` assertion fatal). | Disabled `github:quartz-community/og-image`. |

Both patches are documented findings for the deploy recommendation below.

**Build result:**
```
Cleaned output directory `public` in 117ms
Found 52 input files from `../quartz-content` in 51ms
Parsed 52 Markdown files in 3s
Filtered out 9 files in 222μs           # draft: true items correctly hidden
Emitting files
Emitted 139 files to `public` in 3s
Done processing 52 files in 6s
```

**Emitted structure (`quartz-site/public/`):**

| Section | HTML files | Notes |
|---|---:|---|
| `decisions/` | 5 | 5 canonical decisions from Sprint 24 (1 filtered as draft) |
| `risks/` | 8 | risks with `draft: false` |
| `workstreams/` | 13 | one page per workstream |
| `reports/` | 20 | weekly reports copied from `03-reporting/weekly/` |
| `tags/` | (dir) | tag index pages auto-generated |
| root | index.html, 404.html, sitemap.xml, tags.html, index.xml (RSS) | |
| static | contentIndex.json (137 KB) — powers Flexsearch | |

**Plugins verified enabled** (from `quartz.config.default.yaml`, all in emitted HTML):

- `search` (Flexsearch) — search index present, search widget rendered
- `backlinks` — backlinks section present on decision + workstream pages
- `graph` — `graph-container` div present on decision + workstream pages
- `explorer` — left-nav file tree present
- `breadcrumbs` — present on non-index pages
- `darkmode` — toggle in toolbar
- `reader-mode` — toggle in toolbar
- `popover` — hover-preview enabled for wiki-links
- `content-index` (sitemap + RSS) — `sitemap.xml` and `index.xml` emitted
- `obsidian-flavored-markdown` — `[!info]` and `[!todo]` callouts rendered (`callout` class present)
- `tag-page` — `tags/` and `tags.html` emitted
- `crawl-links` (shortest resolution) — wiki-links `[[decisions/D-xxx|Title]]` correctly resolved to `<a href>`
- `remove-draft` — 9 files filtered from Sprint 24's `validated: false` items

## Screenshots

_TODO — capture 6 screenshots for the record after browsing `http://localhost:8098`:_

1. `01-home.png` — home page with top-10 list and delta ribbon
2. `02-decision.png` — a decision page showing callouts, backlinks, graph
3. `03-workstream.png` — Rapid Recovery workstream showing linked decisions + risks
4. `04-risk.png` — a risk page showing severity/trend + backlinks
5. `05-search.png` — search widget results for "cyberark"
6. `06-graph.png` — global graph view

Save under `quartz-content/screenshots/` (folder to be created).

## Search Experience

**Objective evidence:** `static/contentIndex.json` = 137,174 bytes. Flexsearch UI present in every page. HTTP GET returns 200.

**Task validation checklist** — perform in browser and mark:

- [ ] Search for a **decision** by short id (`D002`) — does it surface? Time to click:
- [ ] Search for a **decision** by keyword (`gocc delivery model`) — does it surface? Time to click:
- [ ] Search for a **risk** by keyword (`cyberark`) — how many hits? Do all 7 CyberArk-tagged risks appear?
- [ ] Search for a **workstream** by name (`rapid recovery`) — is the workstream page top hit or buried under decisions?
- [ ] Search for a **weekly report** by week number (`W17`, `W24`) — surfaced?
- [ ] Search inside body text (`escalation format`) — does it hit the intended risk?

_Findings (fill after task run):_

## Navigation Experience

**Objective evidence:** breadcrumbs, explorer (left nav), and toolbar (search + darkmode + reader-mode) render on every non-index page. Every page loads in <300 ms locally.

**Task validation:**

- [ ] From home → click top-item risk → land on risk page — path clear?
- [ ] From risk page → click linked workstream — path clear?
- [ ] From workstream → click linked decision — path clear?
- [ ] From decision → click linked workstream — round-trip works?
- [ ] Use explorer to walk `decisions/ → risks/ → workstreams/` — is the tree readable, or is it noisy with copilot artefacts?
- [ ] Weekly reports discoverable? From home? Via explorer? Via search?

_Findings (fill after task run):_

## Backlink Experience

**Objective evidence:**

- Decision page (`decisions/d-40250bb7d6`) HTML: `backlinks` section present, tag-links present, 2 outbound links to `workstreams/*`.
- Workstream page (`workstreams/rapid-recovery`) HTML: `backlinks` section present, 5 outbound `decisions/*` links, 1 outbound `risks/*` link.

Wiki-links written by [scripts/prepare-quartz-content.ps1](scripts/prepare-quartz-content.ps1) in the format `[[workstreams/rapid-recovery|Rapid Recovery]]` and `[[decisions/D-xxx|Title]]` were correctly resolved to `<a>` tags by Quartz's `crawl-links` plugin with `markdownLinkResolution: shortest`.

**Task validation:**

- [ ] Open a workstream → does the "Backlinks" panel list every decision + risk that references it? Or are some missing?
- [ ] Open a decision → does its Backlinks panel show the workstream that references it?
- [ ] Open a risk → same check.
- [ ] Do the backlinks give me a **useful reverse map** ("who else cares about this decision?") or is it just noise from the auto-generated index page?

_Findings (fill after task run):_

## Graph Experience

**Objective evidence:** `graph-container` div present on decision + workstream pages. Global graph accessible from toolbar.

**Task validation:** _(this is the make-or-break for graph — it's either a wow moment or throwaway visual noise)_

- [ ] Local graph on a decision — does it show its workstream + related risks in a way that reveals structure?
- [ ] Global graph — do the ~45 real nodes cluster meaningfully by workstream? Or is it a hairball?
- [ ] Would you actually **navigate** via the graph, or just glance at it once?

_Findings (fill after task run):_

## Workstream Drill-Down

**Objective evidence:** 13 workstream pages emitted. Each written by Sprint 24 with:
- YAML frontmatter (`type: workstream`, `workstream/{slug}`, `status/{health}`, `category/{p1|p2|watch}`)
- Score + health + category header
- Cross-linked decisions section
- Cross-linked risks section
- Owners + accountable BU + BU stakeholders

**Task validation:**

- [ ] Open **Rapid Recovery** — do I get the full picture (score, health, all its decisions, all its risks, owners) in one page?
- [ ] Open **MMM L2** — same check.
- [ ] Open **Watch-list** items (score < 50) — do they still deserve a page, or is it clutter?

_Findings (fill after task run):_

## Decision Traceability

**Objective evidence:** 5 decision pages emitted (1 filtered as draft). Each has `[!info] Why it matters` and `[!todo] Next action` callouts, priority reason bullets, timeline, source citation, actors.

**Task validation:**

- [ ] Open a decision → can I answer "why does this matter?" + "what happens next?" without reading source docs?
- [ ] Is the source citation (`Source: [file.md]`) present and correct?
- [ ] Are decisions grouped/filterable by workstream via tags?

_Findings (fill after task run):_

## Risk Traceability

**Objective evidence:** 8 risk pages emitted. Each has severity/trend frontmatter, callouts, priority bullets, backlinks.

**Task validation:**

- [ ] Open the top-scored risk (`R-cd89918f9c` — vendor escalation, score 98) — is the risk statement + severity + trend + mitigation clear?
- [ ] Are ⚠️ / 🚨 emoji-titled risks readable, or should Sprint 24 have stripped them?
- [ ] Are risks grouped/filterable by workstream via tags?

_Findings (fill after task run):_

## What Was Helpful

_(user to fill after Task Validation runs)_

Candidate strengths to confirm/deny:

- Single-URL navigation across all 45 items + 20 reports
- Backlinks turn the flat generator output into a graph without extra authoring
- Search over 137 KB index is fast and covers body text (not just titles)
- Callouts (`[!info]`, `[!todo]`) turn "Why it matters" into a visual anchor
- Explorer tree gives a familiar Obsidian-like navigation
- Reader mode + darkmode + popover = ergonomics for a stakeholder audience

## What Was Noise

_(user to fill after Task Validation runs)_

Candidate weaknesses to confirm/deny:

- Explorer tree may be noisy if it exposes internal artefacts (draft items, tag pages)
- Global graph may be a hairball on 45 nodes without curated categories
- Reports section has 20 pages — may swamp the more important workstream/decision hierarchy
- Tag pages auto-generated for every tag we set (workstream/*, status/*, action/*, type/*) — could be overwhelming
- 6 different tag namespaces per item may add UI clutter without payoff

## Recommended Improvements

_(user to fill after Task Validation runs)_

Candidate follow-ups if we do choose to keep Quartz:

- **CDN independence:** replace `og-image` plugin (needs CDN font fetch) with a self-hosted alternative, OR permanently disable and use a static OG image.
- **Windows compatibility:** upstream a PR for the junction fallback in `trySymlink()` so future clones on locked-down machines just work.
- **Content curation:** decide whether all 6 tag namespaces are useful, or trim to workstream + status.
- **Home page:** the Sprint 24 generator produced a good top-10 + workstream-tier layout, but the delta ribbon (`Added 2 · Changed 9 · Removed 34`) needs baseline management or it will always be stale.
- **Report weight:** reports/ section has 20 items and will grow. Consider surfacing only the latest N or grouping by quarter.

## Deploy / Do Not Deploy Recommendation

_(user to fill after Task Validation runs)_

Recommendation template (delete whichever does not apply):

**A. DEPLOY.** Quartz produced a materially better navigation surface than the raw markdown vault. Next sprint should choose hosting from the options in [docs/quartz-deployment-decision.md](docs/quartz-deployment-decision.md).

**B. DO NOT DEPLOY.** Quartz did not meet the north-star. The dashboard + weekly report already covers the same ground and Quartz added navigation without solving a real question. Keep the pilot in the repo for reference; do not sprint on hosting.

**C. DEFER.** Quartz is promising but the pilot exposed blockers (list below). Reassess after they are resolved.

Blockers (if C):

- [ ] Sync/Corp-network limitations (og-image, CDN fonts)
- [ ] Windows Developer Mode policy (junction patch is a workaround, not a solution)
- [ ] Content curation gaps surfaced by the pilot
- [ ] Other:

---

## Sign-off

- Prepared by: Copilot (V4.0 Sprint 25 automation)
- Reviewed by: _(name + date)_
- Decision: _(A / B / C)_
- Follow-up sprint scope: _(free text)_
