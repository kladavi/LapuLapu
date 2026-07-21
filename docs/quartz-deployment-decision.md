---
type: deployment-decision
title: "Quartz Deployment Decision"
generator: hand-authored
generated: 2026-07-21
version: V4.0-sprint24
schema: ui/src/lib/matryoshka-item.ts
status: DRAFT
---

# Quartz Deployment Decision — Sprint 24

This document captures the architecture options + metadata mapping for adding
[Quartz](https://quartz.jzhao.xyz/) as a knowledge-navigation layer over the
Lapu-Lapu canonical corpus. Written as a decision-record so the tradeoffs are
visible; a final selection is required before Quartz can be built.

## Non-negotiable architectural rule

```
Sources
  ↓
Canonical Model  (matryoshka-items.json)
  ↓
Validator
  ↓
Priority Engine
  ↓
Generated Markdown  (00-context/generated/*.md, quartz-content/*.md)
  ↓
Quartz
```

**Quartz is a consumer, never the system of record.** Nothing in the Quartz
site editing surface writes back to the canonical model. The pilot build
(`scripts/prepare-quartz-content.ps1`) reads matryoshka-items.json and emits
static markdown files into `quartz-content/` — Quartz then consumes those
files. No coupling in the reverse direction.

## Deliverables covered by Sprint 24

- **Q1** Deployment architecture — this document
- **Q2** Navigation design — sections below
- **Q3** Metadata mapping — sections below
- **Q4** Pilot content generation — `scripts/prepare-quartz-content.ps1`
  produces `quartz-content/` with workstream / decision / risk / report pages

Actual Quartz installation + hosting is **not yet decided** and remains a
downstream decision (see Sections A + C below).

---

## A. Hosting options

Choose ONE. Each has different consequences for review workflow, secret
handling, and rebuild cadence.

### A1. GitHub Pages (from this repo)

- **Pros**: zero infra to run; standard `gh-pages` deploy pattern; rebuild
  triggers already in place via GitHub Actions.
- **Cons**: LapuLapu is a **private** Manulife repo. GitHub Pages on a private
  repo requires GitHub Enterprise Cloud or moves the content to a public repo.
  Not acceptable unless a public-facing subset is explicitly approved.

### A2. Manulife SharePoint site (static hosting)

- **Pros**: aligns with Manulife content-governance defaults; audit trail;
  no external surface; supports ADFS-gated distribution.
- **Cons**: SharePoint's static-html hosting is limited — Quartz's client-side
  routing and search may not work cleanly; may require a hybrid of "generate
  static HTML + upload via CLI".

### A3. Local file server / laptop-only

- **Pros**: fastest to pilot; no security review; David can iterate freely.
- **Cons**: no team access; loses the "knowledge portal" value proposition.
  Useful ONLY as a pilot / proof-of-concept phase.

### A4. Internal Manulife web hosting (nginx / IIS on ETS infrastructure)

- **Pros**: full Quartz feature support; team-accessible; controlled surface;
  fits ETS operational model.
- **Cons**: requires infrastructure request + approval; slower to iterate.

**Recommended path**: start on **A3** for the pilot, prove the value, then
move to **A4** or **A2** for team distribution once value is demonstrated.

---

## B. Repository structure

Quartz expects a specific folder layout. Chosen structure:

```
LapuLapu/
├── 00-context/generated/     (canonical model - unchanged by Quartz)
├── 02-work/                  (human-authored source - unchanged)
├── 03-reporting/weekly/      (generator output - unchanged)
├── quartz-content/           ← NEW: Quartz-consumable markdown
│   ├── index.md              (home page)
│   ├── workstreams/
│   │   ├── mmm-l2.md
│   │   ├── rapid-recovery.md
│   │   └── ...
│   ├── decisions/
│   │   ├── D-3ced6cbb47.md
│   │   └── ...
│   ├── risks/
│   │   ├── R-cd89918f9c.md
│   │   └── ...
│   └── reports/
│       └── 2026-W30.md       (copy of weekly report)
├── quartz-site/              ← DEFERRED: `git clone quartz` here when
│                                infra decision is made
└── scripts/
    └── prepare-quartz-content.ps1  ← NEW: staging script
```

**Rationale**: keep `quartz-content/` as generator output (like
`00-context/generated/`) — deterministically rebuildable, no manual edits.
Keep `quartz-site/` (the Quartz npm project) separate so the ~1000 npm
packages don't bloat the corpus workspace.

---

## C. Rebuild trigger

Options for keeping `quartz-content/` in sync with the canonical model:

### C1. Manual (invoke script on demand)

```powershell
pwsh -File scripts/prepare-quartz-content.ps1
```

Simplest. Fine for pilot / low-frequency updates.

### C2. Chained after the canonical pipeline

Extend `scripts/run-matryoshka-pipeline.ps1` (the orchestrator that runs
generate-current-focus.ps1) to call prepare-quartz-content.ps1 immediately
after. Then any pipeline run (Task Scheduler daily run + AtLogOn triggers)
rebuilds Quartz content automatically.

### C3. GitHub Action

On push to `main`, run the prep script + rebuild the Quartz site + deploy.
Requires GitHub Pages / gh-pages decision from Section A.

**Recommended path**: **C1** for the pilot, **C2** once Quartz is deployed to
some destination (A3 or A4), **C3** only if A1 is selected.

---

## D. Metadata mapping (Q3)

Every canonical field in `matryoshka-items.json` maps to specific Quartz
frontmatter / rendering concerns. The prep script implements this mapping
deterministically.

| Canonical field (matryoshka-items.json) | Quartz consumption |
|---|---|
| `id` | Page filename (`decisions/D-3ced6cbb47.md`), permalink anchor |
| `type` | Frontmatter `type:` → drives layout template |
| `title` | Frontmatter `title:` → H1 |
| `workstream` | Frontmatter `tags:` → `#workstream/rapid-recovery`; also becomes a wiki-link `[[workstreams/rapid-recovery]]` |
| `owner` / `suggested_owner` | Frontmatter `owner:`, rendered in the page header |
| `status` | Frontmatter `status:` → CSS class for coloured status pill |
| `priority_score` | Frontmatter `weight:` → controls listing sort order in workstream landing pages |
| `priority_reason_bullets` | Rendered as a `**Why now**` bullet block |
| `why_it_matters` | Rendered as a callout above the fold |
| `next_action` | Rendered as an "Action" callout |
| `focus_signals` | Frontmatter tags (`#engaged`, `#attention-required`, `#awaiting-others`) |
| `delta.days_since_last_touched` | Frontmatter `updated:` (ISO date) — enables Quartz's "recent updates" widget |
| `source` | Wiki-link back to the source markdown file |
| `context_metadata.actors` | Frontmatter `people:` → produces backlink pages |
| `merged_from` | Frontmatter `aliases:` → old IDs redirect to canonical |
| `validated` / `validation_errors` | Frontmatter `draft: true` when validation failed; hides from navigation until fixed |

**Backlinks** are automatic in Quartz once wiki-links exist. The prep script
emits `[[workstreams/rapid-recovery]]` wherever a canonical item references a
workstream, and `[[decisions/D-3ced6cbb47]]` wherever another item's
`related_items` array references it — Quartz then renders backlinks + a
knowledge graph without further code.

---

## E. Navigation design (Q2)

The pilot site provides five entry points:

### E1. Home page (`quartz-content/index.md`)

- Top 10 items across all workstreams by `priority_score`
- 4-objective banner (Frictionless CX / Robust Tech Core / Outstanding
  Colleague XP / Tech Transformation) with one-line status per objective
- Delta ribbon (added / changed / stale)

### E2. Workstream landing pages (`quartz-content/workstreams/{id}.md`)

Per P1/P2/Watch workstream:
- Health status + score
- All open decisions sorted by `priority_score` desc
- All open risks sorted by `priority_score` desc
- Wiki-links to per-item detail pages

### E3. Decision navigation (`quartz-content/decisions/{id}.md`)

Per decision:
- Title, status, owner, aging
- `why_it_matters` (semantic sentence when available)
- `priority_reason_bullets` (rationale)
- Cross-links: workstream, related risks, source file
- Timeline: first_seen, last_updated, delta.change_summary

### E4. Risk navigation (`quartz-content/risks/{id}.md`)

Same shape as E3, adapted for risks (severity, trend fields visible).

### E5. Weekly reports (`quartz-content/reports/{week-id}.md`)

Copies of the generator output from `03-reporting/weekly/`. Since those
already carry Sprint 22 frontmatter, they're valid Quartz pages as-is —
the prep script just copies them into the Quartz content tree.

### E6. Search entry points

Quartz has native full-text search over the content folder. No extra work
required beyond the prep script emitting clean markdown with useful
frontmatter — search will index title, headings, and body.

---

## F. Success criteria (Sprint 24 acceptance)

- [x] `quartz-content/` produced from canonical model by the prep script
- [x] Workstream landing pages exist for every active workstream
- [x] Decision + risk detail pages exist for every non-stale canonical item
- [x] Weekly reports are cross-linked
- [x] Frontmatter mapping documented (Section D)
- [x] Navigation design documented (Section E)
- [x] Canonical model unchanged — Quartz is a pure consumer
- [ ] Hosting decision made (Section A) — **deferred**
- [ ] Quartz npm project installed at `quartz-site/` — **deferred**
- [ ] Site build / deploy verified against a specific host — **deferred**

The first 7 items ship in Sprint 24. The last 3 are downstream decisions.

---

## G. Downstream decisions (out of scope for Sprint 24)

Before advancing beyond the pilot:

1. **Hosting selection** — pick one of A1/A2/A3/A4 above.
2. **Manulife content-governance review** if the site will be team-visible.
3. **Rebuild trigger selection** — C1/C2/C3.
4. **Quartz installation location** — `quartz-site/` folder in this repo, or
   sibling repo, or npm workspace.

These require human decisions and are not included in this sprint's automated
deliverables.
