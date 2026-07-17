<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Execution Insights

Generated: 2026-07-17 09:37

Cross-cutting patterns detected across the decision registry and risk register.
These signals feed the priority-inbox re-ranking and the confidence-tuning learning loop.

## Delayed Decisions (Pending 14+ days)

- **D015 — Agreed: Mandatory Server Restart Authorization Decision Matrix in Every RRP** - Rapid Recovery - owner Balaji Ravi - aged **14d** (D-6f81d99006)
- **D019 — Agreed: Adopt CAP-48585 Capacity Management Delivery Plan (WP1–WP6, GOCC/ETS Split, Ingenium/NDM/ServerF Pilot, September 2026 Tar...** - Capacity Management - owner Rasheersh - aged **14d** (D-0ac2a0c612)
- **D013 — Agreed: Trim Developer Experience Dashboard Alerting to Actionable Signals Only** - Developer XP Dashboard - owner Deb - aged **14d** (D-3ced6cbb47)
- **D018 — Agreed: Lock GBO Japan Batch Transition Execution Plan, Operating Principles, and September Pilot Timeline** - GBO Batch Transition - owner Rowena - aged **14d** (D-f91314563c)
- **D017 — Agreed: GOCC Transitions to Unified Operating Model Without L1/L2 Silos in September** - GBO Batch Transition - owner Rowena - aged **14d** (D-30ae77972e)
- **D014 — Agreed: Include Shared-Folder ACL Compliance Monitoring in Lapu-Lapu Scope** - GOCC Transition - owner Balaji Ravi - aged **14d** (D-e275b159e5)
- **D016 — Agreed: Park R2R-Scope ADX Onboarding Push Until App-Driven Demand Materializes** - ADX Registration - owner Kelvin - aged **14d** (D-fadd968d28)

## Missed Deadlines (past decisionDeadline, still Pending)

_None._

## Overloaded Owners (>= 3 open items)

- **Balaji Ravi** - 10 open items (2 decisions / 8 risks, 8 P1), avg confidence 0.72
- **Rasheersh** - 10 open items (1 decisions / 9 risks, 4 P1), avg confidence 0.74
- **Manish** - 7 open items (0 decisions / 7 risks, 5 P1), avg confidence 0.79
- **Rowena** - 6 open items (2 decisions / 4 risks, 3 P1), avg confidence 0.69
- **unassigned** - 6 open items (2 decisions / 4 risks, 2 P1), avg confidence 0.22

## Recurring Decisions (same normalized title 2+ times)

_None._

## Stale Pending by Workstream (>= 3 Pending)

_None._

## High-Severity Aged Risks (14+ days)

- **Vendor Escalation** - GBO Batch Transition - owner Rowena - aged **87d** (R-52c6e63cae)
- **Standardization of templates, CI identification, and escalation procedures to reduce** -  - owner  - aged **87d** (R-f386376f94)
- **Review and operationalize the vendor escalation format** - Rapid Recovery - owner Balaji Ravi - aged **87d** (R-cd89918f9c)

## Notes

- **delayedDecisions** and **stalePendingByWorkstream** boost the confidence of any Escalate action on their workstream.
- **overloadedOwners** trigger a down-rank on non-P1 items assigned to that owner in David's inbox.
- **missedDeadlines** always jump to P1 with escalate-today priority regardless of static priority.
- **recurringDecisions** get a small ranking boost - the same question resurfacing means the prior decision didn't stick.