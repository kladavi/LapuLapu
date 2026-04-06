# OKR Key Results — Requirements Specification

**Version:** 1.0
**Date:** 2026-04-01
**Branch:** `feature/key-results`

---

## 1. Functional Requirements

### FR-001 — Key Result Lifecycle
A Key Result (KR) can be created, viewed, edited, and archived. Each KR has a unique auto-incrementing ID (`KR001`, `KR002`, …).

### FR-002 — Objective Linkage
Every KR must be linked to exactly one existing objective (Tier-1 or Tier-2). The link is stored as the objective ID in the `Objective` field.

### FR-003 — Minimum Coverage
Each objective should have at least one KR. The system displays a warning badge on objectives with zero KRs.

### FR-004 — Maximum Warning
When an objective accumulates more than 5 KRs, the system displays a warning indicator suggesting decomposition.

### FR-010 — Required Fields
Every KR record must include:
| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Auto-generated `KRnnn` |
| `title` | string | Human-readable name |
| `objectiveId` | string | Linked objective ID (e.g. `H-3`, `O1`) |
| `metricType` | enum | `numeric` or `boolean` |
| `startValue` | number | Baseline value (0 for boolean) |
| `targetValue` | number | Goal value (1 for boolean) |
| `currentValue` | number | Latest progress value |
| `targetDate` | string | ISO date `YYYY-MM-DD` |
| `status` | enum | `Not Started`, `On Track`, `At Risk`, `Behind`, `Complete` |
| `tags` | string[] | Hashtag array |
| `description` | string | Brief description |
| `created` | string | ISO date `YYYY-MM-DD` |

### FR-020 — Progress Entries
Progress is tracked via a log of entries, each with:
- `date` (ISO date)
- `value` (number)
- `comment` (string)

### FR-021 — Computed Progress
Progress percentage is computed as:
$$\text{progress} = \frac{\text{currentValue} - \text{startValue}}{\text{targetValue} - \text{startValue}} \times 100$$
Clamped to 0–100%. For boolean KRs: 0% or 100%.

### FR-022 — Progress History
All progress entries are displayed in reverse-chronological order within the KR detail view.

### FR-030 — Audit / Change History
Definition-level changes (title, target, dates, status) are logged in a Change Log section with timestamp and description.

---

## 2. UI Requirements

### UR-001 — Navigation Tab
A "Key Results" tab with 📈 icon appears in the main navigation between "Objectives" and "Tasks".

### UR-002 — KR List View
The KR list supports:
- Filter by objective (dropdown)
- Filter by status (multi-select)
- Search by title/tags
- Sort by target date, progress %, or status
- Colour-coded status badges

### UR-003 — Objective Detail Integration
The Objectives tab detail panel shows a "Key Results" section listing all KRs linked to the selected objective, with progress bars.

### UR-004 — Create/Edit Form
A form allows creating a new KR or editing an existing one:
- Objective selector (dropdown of all objectives)
- Metric type toggle (numeric/boolean)
- Start/target/current value inputs
- Target date picker
- Status selector
- Tags input
- Description textarea

### UR-005 — Progress Entry Form
From the KR detail view, users can add a progress entry:
- Date (defaults to today)
- Value (number input)
- Comment (text input)

### UR-006 — Dashboard Integration
The Dashboard tab shows a "Key Results" summary card with total count and status breakdown.

---

## 3. Data Model

### 3a — Markdown Format (`02-work/key-results.md`)
```markdown
# Key Results

## KR001 — Reduce P1 MTTR to <2.5 hours
- **Objective:** H-3 (AI Ops / Incident Troubleshooting)
- **Metric Type:** Numeric
- **Start Value:** 4.2
- **Target Value:** 2.5
- **Current Value:** 3.1
- **Target Date:** 2026-06-30
- **Status:** On Track
- **Created:** 2026-04-01
- **Tags:** #project:lapu-lapu #domain:observability
- **Description:** Track and reduce mean time to resolve P1 incidents.

### Progress Log
| Date | Value | Comment |
|------|-------|---------|
| 2026-04-01 | 4.2 | Baseline from Q1 |
| 2026-04-15 | 3.8 | Improved correlation rules |

### Change Log
| Date | Change |
|------|--------|
| 2026-04-01 | Created |
```

### 3b — TypeScript Interfaces
```typescript
interface KeyResultProgressEntry {
  date: string;
  value: number;
  comment: string;
}

interface KeyResultChangeEntry {
  date: string;
  change: string;
}

interface KeyResult {
  id: string;
  title: string;
  objectiveId: string;
  metricType: "numeric" | "boolean";
  startValue: number;
  targetValue: number;
  currentValue: number;
  targetDate: string;
  status: "Not Started" | "On Track" | "At Risk" | "Behind" | "Complete";
  created: string;
  tags: string[];
  description: string;
  progressLog: KeyResultProgressEntry[];
  changeLog: KeyResultChangeEntry[];
  raw: string;
}
```

---

## 4. Persistence

- **Storage:** `02-work/key-results.md` (same pattern as tasks.md, decisions.md)
- **Load:** Via existing `/api/load-local` route (already reads all `.md` files)
- **Save:** Via existing `/api/save-local` route with `filePath: "02-work/key-results.md"`
- **Serialization:** `serializeKeyResults(krs: KeyResult[]): string` renders full markdown file

---

## 5. Non-Functional Requirements

| NFR | Target |
|-----|--------|
| Parse time | <50ms for 200 KRs |
| Save latency | <200ms via save-local API |
| Bundle size | <10KB added (no new dependencies) |
| Test coverage | ≥90% for parser and serializer |
| Accessibility | Keyboard-navigable forms, ARIA labels |
