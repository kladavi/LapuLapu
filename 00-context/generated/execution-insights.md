<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Execution Insights

Generated: 2026-07-15 13:13

Cross-cutting patterns detected across the decision registry and risk register.
These signals feed the priority-inbox re-ranking and the confidence-tuning learning loop.

## Delayed Decisions (Pending 14+ days)

_None._

## Missed Deadlines (past decisionDeadline, still Pending)

_None._

## Overloaded Owners (>= 3 open items)

- **Balaji Ravi** - 8 open items (2 decisions / 6 risks, 4 P1), avg confidence 0.7
- **Rasheersh** - 8 open items (1 decisions / 7 risks, 2 P1), avg confidence 0.73
- **Rowena** - 5 open items (2 decisions / 3 risks, 1 P1), avg confidence 0.69

## Recurring Decisions (same normalized title 2+ times)

_None._

## Stale Pending by Workstream (>= 3 Pending)

_None._

## High-Severity Aged Risks (14+ days)

- **Vendor Escalation** - GBO Batch Transition - owner Rowena - aged **85d** (R-52c6e63cae)
- **Review and operationalize the vendor escalation format** - Rapid Recovery - owner Balaji Ravi - aged **85d** (R-cd89918f9c)
- **Standardization of templates, CI identification, and escalation procedures to reduce** -  - owner  - aged **85d** (R-f386376f94)

## Notes

- **delayedDecisions** and **stalePendingByWorkstream** boost the confidence of any Escalate action on their workstream.
- **overloadedOwners** trigger a down-rank on non-P1 items assigned to that owner in David's inbox.
- **missedDeadlines** always jump to P1 with escalate-today priority regardless of static priority.
- **recurringDecisions** get a small ranking boost - the same question resurfacing means the prior decision didn't stick.