<!-- HUMAN -->
# 00-context — Strategic Context Layer

This is the **strategic context layer** of the vault. It contains
human-maintained registries and generated current-state outputs. Everything
downstream (focus, reporting, agent reasoning) is anchored here.

## Contents

| Path | Type | Purpose |
|---|---|---|
| `workstreams.yaml` | Human | Registry of active workstreams (stable IDs, priority, tags). |
| `priority-overrides.yaml` | Human | Manual boosts/suppressions applied to scoring. |
| `scoring-model.yaml` | Human | Weights and decay parameters for the focus score. |
| `generated/` | Generated | Current-state outputs derived from the corpus (e.g. `current-focus.md`). |

## Agent rules

Before generating `current-focus.md` (or any current-state artifact), agents
**must read**:

1. `workstreams.yaml`
2. `priority-overrides.yaml`
3. `scoring-model.yaml`

Then scan `01-inbox/` and `02-work/` for activity signals, apply the model, and
write the result under `00-context/generated/` with a `<!-- GENERATED -->`
marker naming the source script.

- Never edit generated files by hand.
- Never renumber or rename workstream IDs — downstream files depend on them.
- Expired overrides (past `expires` date) must be ignored, not deleted.
