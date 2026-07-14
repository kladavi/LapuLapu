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
| `scoring-model.yaml` | Human | Signal weights, category thresholds, and V1.2 attention formula. |
| `source-weights.yaml` | Human | **V1.2** — per-folder weight; controls whether files feed activity score vs context only. |
| `activity-windows.yaml` | Human | **V1.3** — current/previous windows (default 14 days), recency decay, and trend thresholds. |
| `generated/current-focus.md` | Generated | Attention-ranked focus dashboard (markdown). |
| `generated/current-focus.json` | Generated | Attention-ranked focus dashboard (JSON contract for UI). |
| `generated/current-focus-trends.md` | Generated | **V1.3** — per-workstream trend table (↑ / ↓ / →). |
| `generated/current-focus-trends.json` | Generated | **V1.3** — trend data for the UI. |
| `generated/morning-briefing.md` | Generated | **V1.4** — executive morning briefing. |
| `generated/morning-briefing.json` | Generated | **V1.4** — structured briefing for the UI. |

## Agent rules

Before regenerating any artifact under `generated/`, agents **must read**:

1. `workstreams.yaml`
2. `priority-overrides.yaml`
3. `scoring-model.yaml`
4. `source-weights.yaml`
5. `activity-windows.yaml`

Then run [scripts/generate-current-focus.ps1](../scripts/generate-current-focus.ps1)
to produce every file under `generated/` in one pass. The script writes the
`<!-- GENERATED FILE -->` marker naming itself.

- Never edit files under `generated/` by hand — regenerate instead.
- Generated files must not feed back into scoring. The script excludes them explicitly.
- Never renumber or rename workstream IDs — downstream files depend on them.
- Expired overrides (past `expires` date) must be ignored, not deleted.
- Stable context files (`00-context/`, `docs/`) are used for **meaning only**
  (purpose, dependencies, aliases). They contribute weight `0.15` / `0.3` in
  `source-weights.yaml` and are excluded from the activity score to prevent
  registry files from dominating the ranking.
