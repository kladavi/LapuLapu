# 0721Phase10_prompt.md

# Phase 10 – Corpus Quality, Source Hygiene, and Knowledge Navigation

## Context

V4.0 architecture is now substantially complete.

Completed foundations:

- Phase 1a: Canonical Schema
- Phase 1b: Validator
- Phase 1c: Deterministic Status Ladder
- Phase 2: Action Classification
- Phase 3: Aging + Stale Detection
- Phase 4: Daily Delta + Snapshots
- Phase 5: Context Linking + Metadata
- Phase 6: Deduplication + Unified Confidence
- Phase 7: Ownership Correction
- Phase 8: Reporting Automation
- Phase 9: Focus Model + Priority Engine

The canonical system-of-record is now:

```text
matryoshka-items.json
```

The primary bottleneck is no longer reporting, prioritization, ownership, status, or dashboarding.

The primary bottleneck is now:

```text
Corpus Quality
```

Current symptoms include:

- Numeric titles appearing as decisions (example: `0.05`)
- Meeting titles being promoted into decisions or risks
- Weak semantic extraction causing heavy T4 fallback usage
- Report narratives constrained by source quality rather than generator quality
- Duplicate or malformed issue descriptions
- Low Decision Impact extraction (T3)

Goal:

Improve source quality so that semantic understanding improves automatically across:

- why_it_matters
- executive summaries
- weekly reports
- risk narratives
- decision narratives
- future Quartz knowledge navigation

---

# Sprint 19 – Decision Title Normalization

## Objective

Eliminate malformed, numeric, placeholder, and noisy titles before they enter the canonical model.

## Deliverables

Create:

```text
Normalize-DecisionTitle
```

Apply before canonical emit.

### Normalize

Remove:

- `[Project X]`
- `[ISSUE]`
- `[NEW]`
- confidence fragments
- score fragments
- source boilerplate
- meeting transcript prefixes

### Validation Rules

Decision titles must:

- contain at least 5 meaningful words
- contain at least one noun
- not be entirely numeric
- not be a confidence score
- not be a person name only

### Auto-Reject Examples

Reject:

```text
0.05
0.08
70
Balaji Ravi
```

### Success Criteria

Weekly report no longer surfaces:

```text
0.05
```

or similarly malformed decision entries.

---

# Sprint 20 – Source Classification and Recap Cleanup

## Objective

Ensure source material is classified correctly before extraction.

## New Source Classes

```text
DECISION
RISK
ACTION
CONTEXT
COMMENTARY
```

## Deliverables

Create classification stage before item extraction.

Meeting transcript content should not automatically become:

- Risk
- Decision
- Action

unless it passes classification rules.

## Additional Scope

Clean Copilot recap ingestion.

Reduce:

- transcript noise
- duplicated issue markers
- repeated owner text
- malformed fragments

### Success Criteria

Reduction of:

- false-positive risks
- false-positive decisions
- duplicate issues

---

# Sprint 21 – Decision Impact Extraction (T3)

## Objective

Improve semantic understanding of decisions.

Current extraction distribution is heavily concentrated in T4 fallback.

Increase T3 coverage through explicit decision-impact detection.

## Deliverables

Create:

```text
Get-DecisionImpact
```

Extraction examples:

Input:

```text
Decision required before rollout planning.
```

Output:

```text
Rollout planning cannot proceed until this decision is made.
```

Input:

```text
Approval needed before migration cutover.
```

Output:

```text
Migration cutover is blocked pending approval.
```

### Success Criteria

Increase:

```text
T3 Decision Impact
```

while reducing:

```text
T4 Context Fallback
```

---

# Sprint 22 – Markdown Metadata Standard

## Objective

Prepare the corpus for deterministic indexing and future knowledge navigation.

## Deliverables

Standardize frontmatter on all durable markdown artifacts.

Example:

```yaml
---
id: MAT-123
type: decision
workstream: Rapid Recovery
owner: David Klan
status: amber
priorityScore: 82
source: meeting-transcript
generatedAt: 2026-07-21
---
```

## Scope

Apply to:

- decisions
- risks
- reports
- recaps
- workstream summaries

### Success Criteria

Every durable markdown artifact contains standardized metadata.

---

# Sprint 23 – Canonical Markdown Index

## Objective

Create a deterministic navigation layer.

## Deliverables

Generate:

```text
00-context/generated/matryoshka-index.json
```

## Index Contents

```json
{
  "id": "MAT-123",
  "type": "decision",
  "workstream": "Rapid Recovery",
  "path": "02-decisions/d015.md",
  "status": "amber"
}
```

## Source Coverage

Index:

- Decisions
- Risks
- Weekly Reports
- Recaps
- Workstreams

### Success Criteria

Consumers can discover content without scanning the full markdown corpus.

---

# Sprint 24 – Quartz Knowledge Portal

## Objective

Introduce Quartz as a knowledge-navigation layer.

## Architectural Rule

Quartz is:

```text
A consumer
```

not:

```text
The system of record
```

Canonical architecture:

```text
Source Data
    ↓
Canonical Model
    ↓
matryoshka-items.json
    ↓
Generated Markdown
    ↓
Quartz
```

## Deliverables

Deploy Quartz against generated markdown.

Enable:

- Full-text search
- Backlinks
- Tag navigation
- Workstream browsing
- Decision-to-risk traceability
- Knowledge graph navigation

## Future Enhancements

Potential additions:

- Risk timeline views
- Decision timeline views
- Workstream landing pages
- Priority dashboards
- Related-item graph visualization

### Success Criteria

Users can navigate the corpus without relying on folder structure or manual searching.

---

# Phase 10 Success Criteria

The phase is complete when:

- malformed decision titles are eliminated
- source classification prevents noisy extraction
- T3 decision-impact extraction is operational
- markdown metadata is standardized
- canonical markdown indexing exists
- Quartz is deployed as a navigation layer
- executive summaries improve due to better source quality rather than generator changes

## North Star

Any workstream member should be able to understand:

- what needs to be done
- why it matters
- what decisions have been made
- who owns it
- what the next action is

without requiring David to explain it.