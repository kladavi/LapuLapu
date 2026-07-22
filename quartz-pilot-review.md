---
type: "quartz-pilot-review"
title: "Quartz Pilot Review — V4.0 Sprint 25a (evidence-backed)"
generator: "manual, from Quartz v5.0.0 build artefacts on 2026-07-22"
generated: "2026-07-22"
version: "V4.0-sprint25a"
schema: "quartz-pilot-review/v2"
scope: "Local pilot only. No public hosting, no SharePoint, no GitHub Pages, no nginx."
supersedes: "quartz-pilot-review.md (Sprint 25 v1)"
---

# Quartz Pilot Review — Sprint 25a

Sprint 25a converts the Sprint 25 pilot from "it builds" into "we know whether it is useful." The mechanical build evidence lives in [quartz-pilot-evidence.md](quartz-pilot-evidence.md); this document performs the UX task validation and produces the worker recommendation.

**Reviewer question:** _Does Quartz materially improve findability, traceability, and workstream understanding?_

**Short answer (this sprint):** Yes for findability. Yes for traceability structure. **No** for workstream understanding as currently built, because 9 workstream cross-links point at draft-filtered items — the Sprint 24 content generator does not reconcile with Quartz's `remove-draft` plugin. Fix that mismatch and the pilot moves from PARTIAL to PASS.

## Sprint 25a task matrix

Nine required tasks from the reviewer prompt. Each is marked PASS / PARTIAL / FAIL with one sentence of evidence keyed to [quartz-pilot-evidence.md](quartz-pilot-evidence.md).

| # | Task | Result | Evidence |
|---|---|:---:|---|
| 1 | Find a Rapid Recovery decision | **PASS** | `contentIndex.json` indexes decisions D005 (`d-4fc5c25a1c`) and D009 (`d-d059b9808f`) with "rapid recovery" in body; both HTML pages emit and return HTTP 200. |
| 2 | Find a Rapid Recovery risk | **FAIL** | The Rapid Recovery workstream page links to `risks/r-cd89918f9c` (the top-scored escalation-format risk) but that file was filtered by `remove-draft` and does not emit. No other emitted risk carries the Rapid Recovery workstream tag; there is no risk to click through to. |
| 3 | Find a workstream landing page | **PASS** | All 13 workstream pages (12 named + folder index) emit; each has a unique `<h1>` and populated body. Verified: `workstreams/rapid-recovery.html` renders with title `Rapid Recovery`. |
| 4 | Find a weekly report | **PASS** | 20 report pages emit (2026-W11 … 2026-W24 + 2026-H1). Every one is in `contentIndex.json` under its week id, so search on "W17" or "H1" surfaces them. |
| 5 | Follow a workstream backlink from an item page | **PARTIAL** | Backlinks plumbing works — decision D002 (`d-40250bb7d6`) shows a working backlink `<a href="../workstreams/cyberark-governance">CyberArk Governance</a>`. But each emitted decision backlinks to a **single** workstream (Sprint 24 sets one `workstream:` tag per item), so the panel misses secondary workstream relationships that a curated portal would show. |
| 6 | Follow an item link from a workstream page | **FAIL** | Site-wide scan (evidence doc §"Broken cross-link scan"): 9 of 371 item cross-refs (2.4 %) are broken, all on workstream pages, all pointing at draft-filtered items. 5 of 13 workstream pages (38 %) contain at least one dead link. Rapid Recovery alone has 2 (1 decision, 1 risk). |
| 7 | Use search to find a known title | **PASS** | Search index covers all 85 emitted permalinks by exact title. Direct probe: `D002 — Agreed: GOCC Delivery Model for Japan Monitoring` is in `contentIndex.json` and its HTML returns HTTP 200. |
| 8 | Use tags to navigate by status | **PASS** | `tags/status/red.html`, `tags/status/amber.html`, `tags/status/green.html` all emit and list every item carrying that status tag. Same coverage confirmed for the other 4 tag namespaces (`action`, `category`, `type`, `workstream`) — 37 tag pages in total. |
| 9 | Open graph view and determine whether graph adds value | **PARTIAL** | Structurally functional: `<div class="graph-container" data-cfg="…">` renders on every non-index page, and the global graph is reachable from the toolbar with valid node/edge data derived from the same 371 cross-refs. Value is **not proven** for two reasons: (a) the 9 broken cross-refs create ghost edges to nonexistent nodes, (b) with 45 real content nodes the local-graph view is likely readable but the global-graph view has not been assessed against an actual navigation task. Needs a re-run after the broken-link fix. |

**Summary:** 5 PASS · 2 PARTIAL · 2 FAIL. Every FAIL and both PARTIALs trace back to the same root cause — Sprint 24's content generator writes cross-links to items that Quartz then filters as drafts.

## What was helpful (evidence-backed)

- **Single navigable URL for 45 items + 20 reports.** Everything the weekly report and dashboard talk about is one link away from a top-10 list on the home page. Confirmed by task 1, 3, 4.
- **Search covers body text, not just titles.** 137 KB Flexsearch index indexes all 85 emitted pages including callout bodies. Confirmed by task 7.
- **Tag pages are auto-generated across all 5 namespaces.** `status/red` gives an instant "what is on fire" list without a bespoke view. Confirmed by task 8.
- **Callouts turn Sprint 15's `whyItMatters` into a visual anchor.** `[!info] Why it matters` and `[!todo] Next action` render as coloured blocks on every decision + risk page. Confirmed by [quartz-evidence/snippet-03-decision-d40250bb7d6.html](quartz-evidence/snippet-03-decision-d40250bb7d6.html).
- **Breadcrumbs + explorer + darkmode + reader-mode + hover popovers** are all default and add zero authoring cost.

## What was noise (evidence-backed)

- **Broken cross-links.** 9 dead references on 5 of 13 workstream pages. Discoverable simply by opening `workstreams/rapid-recovery` and clicking either of the two dead links. This is the single biggest UX defect the pilot exposed and it must be fixed before anyone else sees the site.
- **Single-workstream backlink from each decision/risk.** Sprint 24 emits `workstream:` as a single-value frontmatter tag, so Quartz's Backlinks panel only surfaces the primary workstream. Decisions that span workstreams (D002 GOCC delivery model backlinks to CyberArk Governance only) look misfiled.
- **20 report pages compete with 12 workstream pages for attention.** The tag namespace `type/weekly-report` groups them, but on the home page and in the explorer they mix with the smaller, higher-value workstream/decision set.
- **Tag noise.** 37 tag pages for a 45-item corpus is close to 1:1. Auto-generation is fine on a 500-item vault but here every additional workstream/decision creates ~3-4 tag pages that a user must ignore.

## Recommended improvements (before considering deploy)

Ordered by impact:

1. **Fix the draft/link reconciliation in [scripts/prepare-quartz-content.ps1](scripts/prepare-quartz-content.ps1)** _(Sprint 25b, ~half day)_. Options: (a) do not emit `[[…|…]]` links from workstream pages to items where `validated == false`, or (b) do not set `draft: true` for validated items whose only issue is a soft rule fail. Option (a) is safer.
2. **Emit multi-workstream backlinks.** If a decision/risk touches multiple workstreams, either (a) emit `workstream: [slug1, slug2]` as a list frontmatter tag, or (b) write an explicit `Related workstreams:` link section in the body so Quartz's Backlinks panel picks up every reverse edge.
3. **Home-page report demotion.** Move the reports list under a `<details>` disclosure or a separate section; keep the top-10 items above the fold.
4. **Trim tag namespaces.** Drop `type/*` (fully implicit from folder) and consider dropping `action/*` (only a handful of values, rarely used for browsing). Keep `workstream/*`, `status/*`, `category/*`.
5. **Upstream the junction-fallback patch.** See [quartz-patches/README.md](quartz-patches/README.md).

## Deploy / Do Not Deploy Recommendation

**Worker recommendation: C. Defer.**

Rationale (evidence-based):

- **Mechanical build, serve, search, tags, callouts, breadcrumbs, explorer, backlinks plumbing:** all working. Every objective quality gate passes.
- **Content correctness:** blocked. 9 broken cross-links on 38 % of workstream pages, all traceable to a single generator/plugin mismatch that a half-day sprint can fix. Deploying now would put those broken links in front of stakeholders on their first visit.
- **North-star ("Does Quartz materially improve findability, traceability, and workstream understanding?"):**
  - Findability: **improved** (search works, task 7 PASS).
  - Traceability structure: **improved** (backlinks + tags work, tasks 5 PARTIAL + 8 PASS).
  - Workstream understanding: **not yet improved** as long as the workstream pages have dead links (task 6 FAIL).

**Choosing A. Deploy would ship a portal with known broken navigation on 5 of 13 workstream pages.** Choosing B. Do Not Deploy would discard a build that already meets 5 of 9 tasks and only fails on a fixable content bug. **Defer to Sprint 25b** for the content fix, then re-run this task matrix; if 5-of-9 PASS becomes 8-of-9 PASS, upgrade the recommendation to A.

## Blockers (for C → A transition)

- [ ] Sprint 25b: fix `scripts/prepare-quartz-content.ps1` so workstream cross-links do not reference draft-filtered items. Owner: worker.
- [ ] Sprint 25b: rerun this task matrix and confirm broken-link count = 0. Owner: worker.
- [ ] Sprint 25b: decide multi-workstream backlink representation (task 5 PARTIAL → PASS). Owner: worker.
- [ ] Sprint 25b: hosting choice remains **out of scope** until 25b completes and recommendation flips to A. Owner: reviewer.

## Sign-off

- Prepared by: Copilot (V4.0 Sprint 25a worker)
- Evidence artefacts: [quartz-pilot-evidence.md](quartz-pilot-evidence.md), [quartz-evidence/](quartz-evidence/), [quartz-patches/](quartz-patches/)
- Worker recommendation: **C. Defer** — proceed with Sprint 25b (content fix + rerun) before any hosting decision.
- David's decision: _(A / B / C, name + date)_ — override worker if needed.
