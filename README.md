# LapuLapu — Operational Knowledge Vault & Project Matryoshka Source of Truth

This repository is the **Lapu-Lapu operational knowledge vault** and the
**Project Matryoshka "David Brain" source of truth**. It maintains strategic
context, operational memory, workstream state, reporting inputs, and generated
Copilot-ready outputs for the Lapu-Lapu program.

It is designed to be read and modified by both **humans** and **AI agents**
(Copilot, VS Code Agent, ChatITSM). Markdown is the source of truth.

## Repository Purpose

- Preserve stable strategic context (objectives, teams, systems).
- Capture raw intake and Copilot/M365 activity as durable evidence.
- Track workstream state, tasks, decisions, and risks.
- Produce deterministic, Git-tracked reporting and focus artifacts.
- Serve as a shared substrate for human + agent reasoning.

## Agent Instructions

Before modifying any file, agents **must**:

1. Read this root `README.md`.
2. Read the `README.md` in the target directory (if present).
3. Determine whether the target file is **human-maintained** or **generated**
   (see markers below).
4. Avoid editing generated files directly — regenerate them via their script.
5. Preserve frontmatter, tags, and stable IDs where present.
6. Prefer **adding context over deleting history**.
7. Keep generated outputs **deterministic and Git-trackable**.

File markers:
- `<!-- HUMAN -->` — authoritative human input; edit freely.
- `<!-- GENERATED -->` — produced by a script; do not hand-edit.

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

## Main Folders

| Folder | Purpose |
|---|---|
| `00-context/` | Stable context, registries, overrides, generated current state |
| `01-inbox/` | Raw or semi-processed intake, including Copilot/M365 activity recaps |
| `02-work/` | Work items, workstream notes, tasks, active operational content |
| `03-reporting/` | Weekly reports, templates, generated reporting artifacts |
| `04-prompts/` | Prompts used for Copilot, VS Code Agent, ChatITSM, and automation |
| `90-assets/` | Images, screenshots, attachments, non-text supporting assets |
| `99-archive/` | Historical or retired material |
| `docs/` | Longer-form documentation, key results, milestones, reference material |
| `scripts/` | Automation scripts |
| `ui/` | User interface / app layer if applicable |

## Generated Artifacts

Generated files (e.g. `00-context/generated/current-focus.md`) are **committed to Git for
traceability** so history is auditable and diffs show how focus/state evolves.
They must **not be hand-edited** — rerun the owning script instead. Each
generated file begins with a `<!-- GENERATED -->` marker naming its source
script.

## Golden Rules

1. **All work must map to an objective.** No task exists without a Tier-3 → Tier-1 chain.
2. **Unaligned work is flagged or rejected.** It goes to `decisions.md` with a reason.
3. **Markdown is the source of truth.** No databases, no SaaS dashboards. Files are the system.
4. **IDs are stable.** Objective IDs (`O1`, `O2`…) and Task IDs (`T001`, `T002`…) never change once assigned.
5. **Tags are mandatory.** Every item carries tags for objective, system, team, and tier.
6. **Respect the human/generated boundary.** See markers above.
