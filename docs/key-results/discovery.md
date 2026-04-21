# Phase 0 — Discovery: OKR Key Results

**Date:** 2026-04-01
**Branch:** `feature/key-results`

---

## 1. Repo Structure Audit

### Data Layer
| Concern | File(s) | Notes |
|---------|---------|-------|
| Types | `ui/src/lib/types.ts` | All domain interfaces (Objective, Task, Decision, etc.) |
| Parsers | `ui/src/lib/parsers.ts` | `parseObjectives()`, `parseTasks()`, `parseDecisions()`, `parseWeeklySummaries()`, `parseProjects()` |
| Relationships | `ui/src/lib/relationships.ts` | `buildRelationshipMap()` — Tier-1↔Tier-2↔Task enforcement |
| Settings | `ui/src/lib/settings.ts` | `AppSettings`, `parseSettings()`, `DEFAULT_SETTINGS` |
| Linter | `ui/src/lib/linter.ts` | `lintRepo()` — data quality checks |

### State & API
| Concern | File(s) | Notes |
|---------|---------|-------|
| Context | `ui/src/context/PMContext.tsx` | `PMProvider` / `usePMData()` — loads files, parses, stores in React Context |
| Load API | `ui/src/app/api/load-local/route.ts` | Reads `.md`/`.json` from project root |
| Save API | `ui/src/app/api/save-local/route.ts` | Writes `.md`/`.json` within project root |

### UI Layer
| Component | Purpose |
|-----------|---------|
| `page.tsx` | Tab navigation (`TABS` array), landing screen, auto-load |
| `DashboardTab.tsx` | Summary cards, drill-down |
| `ObjectivesTab.tsx` | Tree/diagram view, detail panel, relationship drill-down |
| `TasksTab.tsx` | Filterable task list |
| `WeeklyTab.tsx` | Weekly summary browser |
| `IntakeTab.tsx` | 4-phase intake processor |
| `ExportTab.tsx` | Export/pack builder |

### Markdown Data Files
| File | Format |
|------|--------|
| `00-context/objectives.md` | `### ID — Title` + bullet fields |
| `02-work/tasks.md` | `## TID — Title` + bullet fields |
| `02-work/decisions.md` | `## DID — Title` + `**Field**` fields |

---

## 2. Patterns to Follow

### 2a — Markdown Record Format (task-style bullets)
```markdown
## KR001 — Key Result Title
- **Objective:** H-3 (AI Ops / Incident Troubleshooting)
- **Metric Type:** Numeric
- **Start Value:** 0
- **Target Value:** 100
- **Current Value:** 25
- **Target Date:** 2026-06-30
- **Status:** On Track
- **Tags:** #project:lapu-lapu #domain:observability
- **Description:** Brief description of the key result.

### Progress Log
| Date | Value | Comment |
|------|-------|---------|
| 2026-04-01 | 0 | Baseline |
| 2026-04-15 | 25 | Q2 sprint 1 complete |
```

### 2b — Parser Pattern
- Normalise line endings
- Split by heading regex `(?=^## KR\d)`
- Extract bullet fields with `extractBulletField(block, label)`
- Return typed array

### 2c — Context Integration
- Add `keyResultsPath` to `findFile()` calls
- Parse with `parseKeyResults()`
- Add `keyResults` to `PMData`

### 2d — Tab Registration
- Add entry to `TABS` array in `page.tsx`
- Create `KeyResultsTab` component
- Render conditionally

---

## 3. Key Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Store KRs in `02-work/key-results.md` | Follows existing `02-work/` pattern for actionable data |
| 2 | ID format: `KR001`, `KR002`, … | Consistent with T001, D001 patterns |
| 3 | Link to objectives via `Objective` bullet field | Mirrors Task's `Objective Chain` field |
| 4 | Progress log as markdown table within KR block | Self-contained, no extra files needed |
| 5 | Audit history as `### Change Log` section | Tracks definition changes separately from progress |
| 6 | Tab position: after "Objectives", before "Tasks" | Natural OKR flow: Objectives → Key Results → Tasks |

---

## 4. Risk Register

| Risk | Mitigation |
|------|------------|
| Parser complexity for embedded table | Table has strict format; regex sufficient |
| Large KR count bloats single file | Acceptable for <200 KRs; revisit if needed |
| Progress entry conflicts (concurrent edits) | Local-first single-user; not a concern |

---

## 5. Files to Create/Modify

### New Files
- `docs/key-results/discovery.md` ← this file
- `docs/key-results/requirements.md`
- `docs/key-results/acceptance.feature`
- `docs/key-results/evaluation.md`
- `02-work/key-results.md` — data file
- `ui/src/components/KeyResultsTab.tsx` — UI tab
- `ui/src/__tests__/keyResults.test.ts` — unit tests

### Modified Files
- `ui/src/lib/types.ts` — add `KeyResult`, `KeyResultProgressEntry` interfaces
- `ui/src/lib/parsers.ts` — add `parseKeyResults()`, `serializeKeyResult()`
- `ui/src/context/PMContext.tsx` — wire keyResults into context
- `ui/src/app/page.tsx` — add tab to TABS, render component
- `ui/src/components/DashboardTab.tsx` — add KR summary card
