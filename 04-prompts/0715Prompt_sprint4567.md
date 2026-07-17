---
title: "Project Matryoshka – Copilot Sprint 4-7"
project: "Lapu-Lapu / Project Matryoshka"
version: "V2 Roadmap"
status: "Ready for VS Code Agent"
updated: "2026-07-15"
---

# Project Matryoshka – Sprint 4-7

Current maturity:

```text
V1.5 Complete

✅ Current Focus
✅ Trends
✅ Morning Briefing
✅ Automated Intake Pipeline
✅ Scheduled Task
✅ Pipeline Health
✅ Dashboard Integration
✅ Git Automation
```

The objective of Sprint 4-7 is to evolve Matryoshka from:

```text
Knowledge System
```

into:

```text
Operational Intelligence System
```

---

# Sprint 4 — V1.6 Decision Intelligence

## Objective

Build a first-class Decision Intelligence capability.

Current state:

```text
Decisions appear inside:
- Activity Recaps
- Morning Briefings
- Weekly Reports
```

Desired state:

```text
Decision Registry
Decision Watch
Decision Aging
Decision Ownership
Decision Trends
```

---

## Deliverables

Create:

```text
00-context/generated/decision-registry.md
00-context/generated/decision-registry.json
```

---

## Extract Decision Signals From

```text
01-inbox/copilot-activity/
03-reporting/weekly/
02-work/
meeting recaps
meeting notes
```

Detect phrases such as:

```text
Decision:
Decided:
Approved:
Agreed:
Consensus:
Green Light:
Proceed with:
Selected:
Chosen:
```

---

## Data Model

Each decision should contain:

```json
{
  "decisionId": "",
  "title": "",
  "dateDetected": "",
  "status": "",
  "owner": "",
  "workstream": "",
  "sourceFiles": [],
  "decisionAgeDays": 0,
  "decisionSummary": "",
  "recommendedFollowUp": ""
}
```

---

## Dashboard Additions

Add:

```text
Decision Watch
```

Show:

```text
Open Decisions

Pending Decisions

Recently Closed Decisions

Oldest Unresolved Decisions
```

---

## Morning Briefing Enhancements

Add:

```text
Decision Pressure
```

Example:

```text
Decision Watch

GOCC Transition
Pending 11 days

Capacity Management
Pending 8 days
```

---

## Definition of Done

Dashboard displays:

```text
Decision Watch
```

Generated artifacts validate.

Decision registry auto-generated.

Decision aging calculated.

---

# Sprint 5 — V1.7 Risk Intelligence

## Objective

Make risks first-class citizens.

Current:

```text
Risks appear as text.
```

Desired:

```text
Risk Registry
Risk Score
Risk Trend
Risk Aging
Escalation Status
```

---

## Deliverables

Create:

```text
00-context/generated/risk-register.md
00-context/generated/risk-register.json
```

---

## Data Sources

Scan:

```text
Copilot activity recaps

Weekly reports

Workstream notes

Meeting notes

Morning briefings
```

---

## Detect Risk Indicators

Examples:

```text
Risk

At Risk

Blocked

Dependency

Awaiting

Escalation

Concern

Compliance Gap

Capacity Issue
```

---

## JSON Model

```json
{
  "riskId": "",
  "title": "",
  "workstream": "",
  "owner": "",
  "severity": "",
  "agingDays": 0,
  "status": "",
  "trend": "",
  "sourceFiles": [],
  "recommendedAction": ""
}
```

---

## Dashboard Additions

Add:

```text
Risk Watch
```

Display:

```text
Highest Risks

Fastest Growing Risks

Oldest Risks

Escalated Risks
```

---

## Morning Briefing Enhancements

Add:

```text
Top 5 Risks
```

and:

```text
Risks Trending Up
```

---

## Definition of Done

Dashboard contains:

```text
Risk Watch
```

Risk register generated.

Risk aging generated.

Risk trend generated.

---

# Sprint 6 — V1.8 Ownership Intelligence

## Objective

Build Team Brain foundations.

Current:

```text
Workstreams
```

Desired:

```text
Workstreams
+
Owners
+
Collaborators
+
Escalation Paths
+
Stakeholders
```

---

## Deliverables

Create:

```text
00-context/generated/ownership-map.md
00-context/generated/ownership-map.json
```

---

## Data Sources

Use:

```text
workstreams.yaml

activity recaps

meeting records

weekly reporting

manual overrides
```

---

## Data Model

```json
{
  "workstream": "",
  "owner": "",
  "contributors": [],
  "stakeholders": [],
  "escalationPath": [],
  "lastActivityDate": ""
}
```

---

## Dashboard Additions

Display:

```text
Owner

Top Contributors

Stakeholders

Last Activity
```

for each workstream.

---

## New Dashboard View

Create:

```text
Workstream Ownership View
```

Allows answering:

```text
Who owns this?

Who should act?

Who is involved?

Who should be informed?
```

---

## Morning Briefing Enhancements

Add:

```text
People Requiring Attention Today
```

Example:

```text
GOCC Transition

Owner:
Balaji Ravi

Recommended Contact:
Jonan Tan Pangan

Escalation Path:
Birger Fjaellman
```

---

## Definition of Done

Ownership map generated.

Dashboard displays ownership.

Morning briefing references ownership data.

---

# Sprint 7 — V2.0 David Brain

## Objective

Create operational executive intelligence.

Current:

```text
Current Focus
Trends
Morning Briefing
```

V2.0:

```text
Executive Intelligence
```

---

## Deliverables

Create:

```text
00-context/generated/executive-briefing.md
00-context/generated/executive-briefing.json
```

---

## Inputs

Combine:

```text
Current Focus

Trends

Risk Register

Decision Registry

Ownership Map

Activity Recaps
```

---

## Questions To Answer

Every morning:

```text
What changed?

What requires attention?

What decisions are waiting?

What risks increased?

Who should act?

What should David do next?
```

---

## Executive Briefing Format

```markdown
# Executive Briefing

## Executive Snapshot

## Attention Changes

## Decision Watch

## Risk Watch

## Ownership Watch

## Recommended Actions

## Escalation Candidates

## Blocked Items

## Rising Workstreams

## Falling Workstreams
```

---

## Dashboard Additions

Add:

```text
Executive Intelligence
```

Summary panel containing:

```text
Top Risks

Pending Decisions

Escalations

Recommended Actions

Major Changes
```

---

## Action Recommendation Engine

Produce:

```json
{
  "recommendedActions": [
    {
      "priority": 1,
      "workstream": "",
      "reason": "",
      "owner": "",
      "suggestedAction": ""
    }
  ]
}
```

---

## Definition of Done

Dashboard can answer:

```text
What changed?

What matters?

Who owns it?

What is blocked?

What should David do next?
```

without requiring manual review of source files.

---

# Success Criteria For V2.0

At completion, Project Matryoshka should function as:

```text
David Brain
```

Capabilities:

✅ Automated ingestion

✅ Focus scoring

✅ Trend detection

✅ Morning briefing

✅ Decision intelligence

✅ Risk intelligence

✅ Ownership awareness

✅ Executive recommendations

✅ Operational command dashboard

---

# Git Strategy

Complete each sprint in an isolated branch:

```text
sprint/matryoshka-decision-intelligence

sprint/matryoshka-risk-intelligence

sprint/matryoshka-ownership-intelligence

sprint/matryoshka-david-brain-v2
```

Require:

```text
PR
Review
Merge
```

for every sprint.

Do not commit directly to main.

---

# Final Deliverable

At completion of Sprint 7, create:

```text
docs/Matryoshka-V2-Architecture.md
```

Document:

```text
Data Sources

Generated Artifacts

Pipeline Flow

Workstream Model

Decision Model

Risk Model

Ownership Model

Executive Intelligence Model

Dashboard Architecture

Automation Architecture
```

This document becomes the authoritative specification for Project Matryoshka V2.