---
type: execution-insights
title: "Execution Insights"
generator: scripts/generate-current-focus.ps1
generated: 2026-07-22T07:34:04
version: V4.0-sprint23a
schema: ui/src/lib/matryoshka-item.ts
---
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Execution Insights

Generated: 2026-07-22 07:33

Cross-cutting patterns detected across the decision registry and risk register.
These signals feed the priority-inbox re-ranking and the confidence-tuning learning loop.

## Delayed Decisions (Pending 14+ days)

- **D013 — Agreed: Trim Developer Experience Dashboard Alerting to Actionable Signals Only** - Developer XP Dashboard - owner Unassigned - aged **19d** (D-3ced6cbb47)
- **D017 — Agreed: GOCC Transitions to Unified Operating Model Without L1/L2 Silos in September** - GBO Batch Transition - owner Birger Fjaellman - aged **19d** (D-30ae77972e)
- **D014 — Agreed: Include Shared-Folder ACL Compliance Monitoring in Lapu-Lapu Scope** - GOCC Transition - owner Birger Fjaellman - aged **19d** (D-e275b159e5)
- **D015 — Agreed: Mandatory Server Restart Authorization Decision Matrix in Every RRP** - Rapid Recovery - owner Unassigned - aged **19d** (D-6f81d99006)
- **D016 — Agreed: Park R2R-Scope ADX Onboarding Push Until App-Driven Demand Materializes** - ADX Registration - owner Balaji Ravi - aged **19d** (D-fadd968d28)

## Missed Deadlines (past decisionDeadline, still Pending)

_None._

## Overloaded Owners (>= 3 open items)

_None._

## Recurring Decisions (same normalized title 2+ times)

_None._

## Stale Pending by Workstream (>= 3 Pending)

_None._

## High-Severity Aged Risks (14+ days)

- **Review and operationalize the vendor escalation format** - Rapid Recovery - owner Unassigned - aged **92d** (R-cd89918f9c)
- **Standardization of templates, CI identification, and escalation procedures to reduce** -  - owner Unassigned - aged **92d** (R-f386376f94)

## Notes

- **delayedDecisions** and **stalePendingByWorkstream** boost the confidence of any Escalate action on their workstream.
- **overloadedOwners** trigger a down-rank on non-P1 items assigned to that owner in David's inbox.
- **missedDeadlines** always jump to P1 with escalate-today priority regardless of static priority.
- **recurringDecisions** get a small ranking boost - the same question resurfacing means the prior decision didn't stick.