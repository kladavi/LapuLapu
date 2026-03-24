# LapuLapu — Personal Project Management System

A Markdown-based, objective-driven project management system designed for individual use, LLM-assisted reasoning, and executive-ready reporting.

## How It Works

All work flows through three stages:

```
Inbox → Tasks → Weekly Summary
```

### Daily Workflow

1. Capture raw inputs into `01-inbox/inbox.md` (meetings, requests, file drops, Slack threads).
2. Run the intake prompt (`04-prompts/intake.md`) to extract work items.
3. Each item is matched to a Tier-3 objective, assigned a team, scored for relevance, and appended to `02-work/tasks.md`.
4. Unaligned work is flagged in `02-work/decisions.md` with a reason.

### Weekly Workflow

1. Run the weekly summary prompt (`04-prompts/weekly-summary.md`) against `02-work/tasks.md`.
2. Output is placed in `03-reporting/weekly/YYYY-WNN.md`.
3. Copy-paste into executive email or slide deck.

## Folder Map

| Folder | Purpose |
|---|---|
| `00-context/` | Objectives, teams, systems — the stable reference layer |
| `01-inbox/` | Raw, unprocessed inputs |
| `02-work/` | Structured tasks and decision log |
| `03-reporting/` | Weekly summaries and templates |
| `04-prompts/` | LLM prompts for intake, reporting, and queries |
| `99-archive/` | Completed or obsolete items |

## Golden Rules

1. **All work must map to an objective.** No task exists without a Tier-3 → Tier-1 chain.
2. **Unaligned work is flagged or rejected.** It goes to `decisions.md` with a reason.
3. **Markdown is the source of truth.** No databases, no SaaS dashboards. Files are the system.
4. **IDs are stable.** Objective IDs (`O1`, `O2`…) and Task IDs (`T001`, `T002`…) never change once assigned.
5. **Tags are mandatory.** Every item carries tags for objective, system, team, and tier.
