<!-- HUMAN -->
# 02-work — Active Work Content

This folder holds **active work content**: workstream notes, task files, and
operational working documents. It is the truth layer for what is currently
being worked on.

## Contents

| Path | Type | Purpose |
|---|---|---|
| `tasks.md` | Human | Canonical task list with stable `T###` IDs, objective mapping, team, tags. |
| `decisions/` or `decisions.md` | Human | Decision log. Unaligned work recorded with a reason. |
| `risks/` | Human | Active risk register entries. |
| workstream notes | Human | Per-workstream running notes and context. |

## Agent rules

- Agents **can and should scan this folder** for workstream references
  (`#workstream-id`, front-matter) and task signals — these feed the activity
  signal in the focus dashboard.
- **Never renumber** `T###` or objective IDs. New tasks append with the next
  unused ID.
- Every task must carry tags for objective, system, team, and tier.
- Unaligned work goes to the decision log, not silently into `tasks.md`.
