---
type: phase10-verification
title: "Phase 10 Verification Report"
generator: scripts/verify-phase10.ps1
generated: 2026-07-21T16:02:10
version: V4.0-sprint23a
schema: ui/src/lib/matryoshka-item.ts
checks_passed: 8
checks_failed: 0
overall_status: PASS
---

# Phase 10 Verification

Generated at 2026-07-21T16:02:10 against canonical artifacts:
- `00-context/generated/matryoshka-items.json`
- `00-context/generated/matryoshka-index.json`

**Overall status: PASS** (8 checks passed, 0 failed)

## Canonical Item Counts

- Total items: **20**
- Validated: 11 (55%)
- Rejected:  9
- By type: decisions=7 / risks=13
- By status: red=9 / amber=6 / green=5

## Title Quality

- Titles matching any known-bad pattern (meeting-leak / numeric / empty-ws / truncated): **0**
  - ✅ No bad titles in canonical model

## Source Classification

Sprint 20 gates: REPORT / GENERATED / RECAP / GOVERNANCE / DOCS folders never produce decisions.
Sprint 23a title validator rejects meeting-transcript titles at extraction time even from allowed folders.

Top 8 source files feeding canonical items:
- 8x `01-inbox/archive/20260714 Lapu-Lapu ETS, GOCC and Obs.md`
- 7x `02-work/decisions.md`
- 2x `01-inbox/archive/W25_copilot.md`
- 1x `01-inbox/archive/RE Japan Team - Global Incident Management w Rohina (Placeholder).txt`
- 1x `01-inbox/copilot-activity/2026-07-13-14-day-activity.md`
- 1x `01-inbox/copilot-activity/2026-07-17-14-day-activity.md`

## Why-It-Matters Distribution

- T1 explicit-rationale (conf 0.90): 1
- T2 risk-consequence  (conf 0.75): 5
- T3 decision-impact   (conf 0.60-0.85): 2
- T4 context-fallback  (conf 0.15-0.30): 11
- none: 1
- **High-confidence (>= 0.6): 8 of 20**

## Markdown Frontmatter Compliance

- Generated MD artifacts indexed: 10
- With parseable YAML frontmatter: 10
- Missing / malformed: 0

Document type breakdown from index:
- copilot-activity-recap: 3
- dashboard: 1
- david-inbox: 1
- decision-registry: 1
- execution-insights: 1
- morning-briefing: 1
- no-frontmatter: 6
- phase10-verification: 1
- rejected-items: 1
- risk-register: 1
- trends: 1
- unknown: 18
- weekly-report: 1

## Index Validation

- Documents indexed: 37
- Items indexed: 20
- Canonical items: 20
- Missing paths (indexed but not on disk): 0
- Missing from index (canonical but not indexed): 0

## Check Results

### ✅ Passes

- every indexed document path exists on disk
- every generated markdown has valid YAML frontmatter
- every canonical item is discoverable via matryoshka-index.json
- no canonical item has empty workstream
- no title contains "meeting transcript/summary"
- no canonical item title appears truncated
- no title is entirely numeric
- index totals are internally consistent

