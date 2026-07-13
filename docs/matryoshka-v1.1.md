# Project Matryoshka — V1.1B

## Purpose
Generate a **Current Focus Dashboard** that fuses the Lapu-Lapu corpus with imported
M365/Copilot activity, human overrides, a workstream registry, and a scoring model.

## Inputs
| Source | Path | Maintained by |
|---|---|---|
| Lapu-Lapu corpus | `00-context/`, `02-work/` | Mixed |
| Workstream registry | `00-context/workstreams.yaml` | Human |
| Priority overrides | `00-context/priority-overrides.yaml` | Human |
| Scoring model | `00-context/scoring-model.yaml` | Human |
| Copilot/M365 recaps | `01-inbox/copilot-recaps/*.md` | Imported |
| Inbox | `01-inbox/inbox.md` | Human |
| Weekly reports | `03-reporting/weekly/*.md` | Mixed |
| Decisions | `02-work/decisions/*.md` | Human |
| Risks | `02-work/risks/*.md` | Human |

## Output
- `03-reporting/current-focus.md` — **generated**, Git-tracked.

## Scoring (default)
`score = w_recency * recency + w_priority * priority + w_signal * activity_signal + override_boost`

Recency uses exponential decay with `half_life_days` from the scoring model.

## Regeneration
```powershell
python scripts/generate_current_focus.py
```

## Conventions
- Files starting with `<!-- GENERATED -->` are overwritten by scripts. Do not hand-edit.
- Files starting with `<!-- HUMAN -->` are authoritative human input.
