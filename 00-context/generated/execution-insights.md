<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Execution Insights

Generated: 2026-07-21 10:53

Cross-cutting patterns detected across the decision registry and risk register.
These signals feed the priority-inbox re-ranking and the confidence-tuning learning loop.

## Delayed Decisions (Pending 14+ days)

- **D013 — Agreed: Trim Developer Experience Dashboard Alerting to Actionable Signals Only** - Developer XP Dashboard - owner Unassigned - aged **18d** (D-3ced6cbb47)
- **D014 — Agreed: Include Shared-Folder ACL Compliance Monitoring in Lapu-Lapu Scope** - GOCC Transition - owner Birger Fjaellman - aged **18d** (D-e275b159e5)
- **D019 — Agreed: Adopt CAP-48585 Capacity Management Delivery Plan (WP1–WP6, GOCC/ETS Split, Ingenium/NDM/ServerF Pilot, September 2026 Tar...** - Capacity Management - owner Debamalya Das (delivery), David Klan (Lapu-Lapu integration) - aged **18d** (D-0ac2a0c612)
- **D015 — Agreed: Mandatory Server Restart Authorization Decision Matrix in Every RRP** - Rapid Recovery - owner Unassigned - aged **18d** (D-6f81d99006)
- **D016 — Agreed: Park R2R-Scope ADX Onboarding Push Until App-Driven Demand Materializes** - ADX Registration - owner Balaji Ravi - aged **18d** (D-fadd968d28)
- **D018 — Agreed: Lock GBO Japan Batch Transition Execution Plan, Operating Principles, and September Pilot Timeline** - GBO Batch Transition - owner David Klan - aged **18d** (D-f91314563c)
- **D017 — Agreed: GOCC Transitions to Unified Operating Model Without L1/L2 Silos in September** - GBO Batch Transition - owner Balaji Ravi - aged **18d** (D-30ae77972e)

## Missed Deadlines (past decisionDeadline, still Pending)

_None._

## Overloaded Owners (>= 3 open items)

_None._

## Recurring Decisions (same normalized title 2+ times)

_None._

## Stale Pending by Workstream (>= 3 Pending)

_None._

## High-Severity Aged Risks (14+ days)

- **Vendor Escalation** - MMM L2 - owner Unassigned - aged **91d** (R-1c3d9c0e3b)
- **Review and operationalize the vendor escalation format** - Rapid Recovery - owner Unassigned - aged **91d** (R-cd89918f9c)
- **Standardization of templates, CI identification, and escalation procedures to reduce** -  - owner Unassigned - aged **91d** (R-f386376f94)
- **CMDB data quality** remains a named dependency for every downstream workstream and is now also a prerequisite for capacity management** - Capacity Management - owner Unassigned - aged **15d** (R-aa0c3f050b)

## Notes

- **delayedDecisions** and **stalePendingByWorkstream** boost the confidence of any Escalate action on their workstream.
- **overloadedOwners** trigger a down-rank on non-P1 items assigned to that owner in David's inbox.
- **missedDeadlines** always jump to P1 with escalate-today priority regardless of static priority.
- **recurringDecisions** get a small ranking boost - the same question resurfacing means the prior decision didn't stick.