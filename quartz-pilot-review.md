---
type: "quartz-pilot-review"
title: "Quartz Pilot Review — V4.0 Sprint 25b (post draft-link fix)"
generator: "manual, from Quartz v5.0.0 build artefacts on 2026-07-22"
generated: "2026-07-22"
version: "V4.0-sprint25b"
schema: "quartz-pilot-review/v3"
scope: "Local pilot only. No public hosting, no SharePoint, no GitHub Pages, no nginx."
supersedes: "quartz-pilot-review.md v2 (Sprint 25a)"
---

# Quartz Pilot Review — Sprint 25b

Sprint 25b closed the draft/link reconciliation defect surfaced by Sprint 25a. This document reruns the same 9-task matrix and updates the deploy recommendation.

**Reviewer question:** _Does Quartz materially improve findability, traceability, and workstream understanding?_

**Sprint 25b short answer:** **Yes.** The one FAIL that blocked Sprint 25a (broken cross-links from workstream pages) is eliminated. The link validator ([scripts/test-quartz-links.ps1](scripts/test-quartz-links.ps1)) reports 0 broken href refs, 0 broken backlink refs, 0 ghost graph edges, and 0 references to draft-filtered items across 440 scanned cross-refs. Task matrix improves from 5/2/2 to 7/2/0.

## Navigation integrity gate (Sprint 25b Deliverable 25b.3)

Ran by [scripts/test-quartz-links.ps1](scripts/test-quartz-links.ps1) against the fresh build; full report at [quartz-link-validation.md](quartz-link-validation.md).

| Check | Count | Target | Result |
|---|---:|---:|:---:|
| Cross-refs scanned | 440 | — | — |
| Backlink refs scanned | 22 | — | — |
| Broken href refs | 0 | 0 | **PASS** |
| Broken backlink refs | 0 | 0 | **PASS** |
| Ghost graph edges | 0 | 0 | **PASS** |
| Refs pointing at draft-filtered items | 0 | 0 | **PASS** |

**All four integrity criteria PASS.**

## Task matrix (Sprint 25b Deliverable 25b.4)

Same 9 tasks from Sprint 25a. Each is marked PASS / PARTIAL / FAIL with one sentence of evidence.

| # | Task | Sprint 25a | Sprint 25b | Delta | Evidence |
|---|---|:---:|:---:|:---:|---|
| 1 | Find a Rapid Recovery decision | PASS | **PASS** | — | Decisions D005 (`D-4fc5c25a1c`) and D009 (`D-d059b9808f`) emit as pages, are linked from `workstreams/rapid-recovery`, and appear on `tags/workstream/rapid-recovery`. |
| 2 | Find a Rapid Recovery risk | FAIL | **PARTIAL ↑** | +1 | Zero published risks are tagged with Rapid Recovery in the canonical model (the only candidate `R-cd89918f9c` has `validated: false`). Sprint 25b now surfaces a "Draft items (excluded from links)" section on the workstream page that names `R-cd89918f9c` so the reader knows one exists in progress. Not a Quartz defect — this is a corpus-curation gap tracked as Sprint 26a candidate. |
| 3 | Find a workstream landing page | PASS | **PASS** | — | 12 workstream pages + 1 folder index emit; `workstreams/rapid-recovery.html` renders with title `Rapid Recovery`. |
| 4 | Find a weekly report | PASS | **PASS** | — | 19 report pages emit (2026-W11 … 2026-W24 + 2026-H1), all in `contentIndex.json`. |
| 5 | Follow a workstream backlink from an item page | PARTIAL | **PARTIAL** | — | Backlinks resolve (0 broken); each emitted decision/risk still backlinks to a single workstream because the canonical model assigns one `workstream` per item. Multi-workstream tagging is a Sprint 26 candidate; it was explicitly out of Sprint 25b scope. |
| 6 | Follow an item link from a workstream page | FAIL | **PASS ↑↑** | +2 | Validator: 0 broken href refs across all 440 cross-refs on all 5 workstream pages that previously had dead links (`cyberark-governance`, `developer-xp-dashboard`, `gocc-transition`, `rapid-recovery`, plus one more). Root cause fix: [scripts/prepare-quartz-content.ps1](scripts/prepare-quartz-content.ps1) now filters `$wsDec` / `$wsRisk` / `$topItems` through `$publishedIds` before emitting wiki-links. |
| 7 | Use search to find a known title | PASS | **PASS** | — | `contentIndex.json` covers all emitted permalinks by exact title. |
| 8 | Use tags to navigate by status | PASS | **PASS** | — | `tags/status/{red,amber,green}.html` all emit. `tags/workstream/rapid-recovery.html` also lists both linked decisions. |
| 9 | Open graph view and determine whether graph adds value | PARTIAL | **PASS ↑** | +1 | Validator: 0 ghost edges. Graph now derives entirely from resolvable cross-refs; the previous "phantom edges to nowhere" caveat is closed. Structural functionality unchanged (graph container present + populated on every non-index page). |

**Summary:** **7 PASS · 2 PARTIAL · 0 FAIL** _(was 5 PASS · 2 PARTIAL · 2 FAIL in Sprint 25a)._

## Against Sprint 25b success criteria

From the reviewer prompt:

| Criterion | Target | Actual | Result |
|---|---|---|:---:|
| Broken links | 0 | 0 | **PASS** |
| Broken backlinks | 0 | 0 | **PASS** |
| Ghost graph edges | 0 | 0 | **PASS** |
| Workstream pages contain only published targets | true | true | **PASS** |
| Task matrix: PASS ≥ 8 | ≥ 8 | 7 | **MISS** (by 1) |
| Task matrix: FAIL = 0 | 0 | 0 | **PASS** |

**Five of six success criteria pass.** The single miss is task-matrix count (7 not 8). The one task that could not be lifted to PASS is task 2 (Find a Rapid Recovery risk), and it cannot be lifted by any Quartz or generator change — the canonical model contains zero validated risks for Rapid Recovery. Lifting task 2 to PASS requires validating `R-cd89918f9c` in the canonical pipeline (Sprint 26a candidate, one-item corpus work).

## Sprint 25b delta at a glance

**Change:** [scripts/prepare-quartz-content.ps1](scripts/prepare-quartz-content.ps1) now separates published from draft items at load time and filters every wiki-link surface (home top-10, workstream decision list, workstream risk list) through the published set. Draft items are still emitted as pages (with `draft: true` frontmatter, filtered by Quartz's `remove-draft`), but they are never linked to, and each workstream page now includes a "Draft items (excluded from links)" section so a reader understands what is intentionally suppressed.

**Effect:**
- Broken cross-refs: 9 → **0**
- Workstream pages with dead links: 5 of 13 (38 %) → **0 of 13 (0 %)**
- Ghost graph edges: 9 → **0**
- FAIL tasks: 2 → **0**
- PASS tasks: 5 → **7**

## What was helpful (evidence-backed, unchanged)

- Single navigable URL for 43 items + 19 reports.
- Search covers body text, not just titles.
- Tag pages auto-generated across 5 namespaces.
- Callouts turn Sprint 15's `whyItMatters` into a visual anchor.
- Breadcrumbs + explorer + darkmode + reader-mode + hover popovers all default.

## What was noise (post-Sprint 25b)

- **20 report pages still compete with 12 workstream pages** for attention on the home page and in the explorer. Consider grouping reports under a disclosure or a separate "Archive" section.
- **Single-workstream backlink per item** (task 5 PARTIAL). Multi-workstream tagging is a canonical-model change, not a Quartz change.
- **Tag noise:** 37 tag pages for 43 emitted content pages. Trimming `type/*` and `action/*` namespaces would drop this to ~20 tag pages.

## Recommended improvements (unblocked; queue for Sprint 26+)

1. **Sprint 26a — Corpus curation** (~half day): validate `R-cd89918f9c` in the canonical pipeline so Rapid Recovery gets its risk. Lifts task 2 from PARTIAL to PASS.
2. **Sprint 26b — Multi-workstream tagging** (~1 day): allow `workstream` to be an array in `matryoshka-items.json`, propagate through generator + report + Quartz content. Lifts task 5 from PARTIAL to PASS.
3. **Sprint 26c — Home-page report demotion + tag trimming** (~half day).
4. **Sprint 26 — Hosting selection** (per [docs/quartz-deployment-decision.md](docs/quartz-deployment-decision.md)): choose A1/A2/A3/A4.
5. **Upstream the junction-fallback patch** (per [quartz-patches/README.md](quartz-patches/README.md)).

## Deploy / Do Not Deploy Recommendation

**Worker recommendation: A. Deploy.**

Rationale (evidence-based):

- **Navigation integrity gate: 100 % PASS.** 0 broken links, 0 broken backlinks, 0 ghost edges, 0 draft references. This was the single deployment blocker the reviewer identified.
- **Task matrix: 7 PASS · 2 PARTIAL · 0 FAIL.** One short of the reviewer's PASS ≥ 8 target, but the single "missing" PASS (task 2) cannot be delivered by any Quartz-side change; it requires validating one item in the canonical model.
- **North-star:**
  - Findability: **PASS** (task 7 + search index proven).
  - Traceability structure: **PASS** (tasks 6 + 8, 0 broken links).
  - Workstream understanding: **PASS** (tasks 1, 3, 6 all PASS; task 2 PARTIAL is a corpus gap, not a portal defect).

Deploying now would ship a portal with:
- 0 known broken links
- Every workstream page listing only published items with a clear "Draft items" disclosure for in-progress material
- Working search, tags, backlinks, graph, and callouts

**Conditional preference:** if the reviewer requires strict PASS ≥ 8 before deploy, defer to Sprint 26a (one-item corpus validation) which is a smaller unit of work than Sprint 25b was. Worker preference is nonetheless **A. Deploy** now and treat task 2 as a Sprint 26a follow-up.

## Blockers (for A. Deploy transition)

- [x] Sprint 25b: fix `scripts/prepare-quartz-content.ps1` so workstream cross-links do not reference draft-filtered items — **DONE**.
- [x] Sprint 25b: rerun task matrix and confirm broken-link count = 0 — **DONE** (0/440).
- [ ] Sprint 26a: validate `R-cd89918f9c` in canonical model to lift task 2 to PASS. Owner: worker. Optional if reviewer accepts 7/2/0.
- [ ] Sprint 26b: multi-workstream tagging to lift task 5 to PASS. Owner: worker. Optional.
- [ ] Sprint 26: hosting selection per [docs/quartz-deployment-decision.md](docs/quartz-deployment-decision.md). Owner: reviewer.

## Sign-off

- Prepared by: Copilot (V4.0 Sprint 25b worker)
- Evidence artefacts: [quartz-pilot-evidence.md](quartz-pilot-evidence.md), [quartz-link-validation.md](quartz-link-validation.md), [quartz-evidence/](quartz-evidence/), [quartz-patches/](quartz-patches/), [scripts/test-quartz-links.ps1](scripts/test-quartz-links.ps1)
- Worker recommendation: **A. Deploy** (or A after Sprint 26a if strict PASS ≥ 8 is required).
- David's decision: _(A / B / C, name + date)_ — override worker if needed.
