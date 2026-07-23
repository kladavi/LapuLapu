---
type: "quartz-link-validation"
title: "Quartz Link Validation Report"
generator: "scripts/test-quartz-links.ps1"
generated: "2026-07-22 13:45"
version: "V4.0-sprint25b"
schema: "quartz-link-validation/v1"
verdict: "PASS"
---

# Quartz Link Validation Report

Sprint 25b Deliverable 25b.1 + 25b.3. Emitted by [scripts/test-quartz-links.ps1](scripts/test-quartz-links.ps1) against the built Quartz site.

## Summary

| Check | Count | Target | Result |
|---|---:|---:|:---:|
| Emitted HTML files | 86 | - | - |
| Cross-refs scanned | 440 | - | - |
| Backlink refs scanned | 22 | - | - |
| Broken href refs | 0 | 0 | **PASS** |
| Broken backlink refs | 0 | 0 | **PASS** |
| Ghost graph edges | 0 | 0 | **PASS** |
| Refs pointing at draft-filtered items | 0 | 0 | **PASS** |

**Overall verdict: PASS**

## Canonical model context

- Published (link-eligible) items: **11**
- Draft (link-excluded) items: **9**
- Source: `00-context/generated/matryoshka-items.json`

## Notes

All navigation surfaces (href, backlinks, graph) resolve to emitted pages. The Sprint 25b draft-aware navigation logic in `scripts/prepare-quartz-content.ps1` (Sprint 25b) is validated: no page references a draft-filtered target.


