<!-- HUMAN -->
# scripts — Automation

This folder contains **automation** that reads and writes the vault.

## Rules for scripts

Scripts **must** be:

1. **Deterministic** — same inputs → same outputs. No hidden randomness.
2. **Simple** — prefer clarity over cleverness; readable by humans and agents.
3. **Documented** — top-of-file docstring covering purpose, inputs, outputs,
   and how to run.
4. **Safe to run locally** — idempotent; no destructive operations without
   explicit flags.
5. **Offline by default** — scripts **should not require external network
   calls** unless explicitly documented in the docstring.

## Current scripts

- `generate-current-focus.ps1` — **primary generator** (pwsh 7). Reads the five
  control files under `00-context/` and produces six artifacts in a single pass:
  - `00-context/generated/current-focus.md` / `.json` — attention-ranked focus dashboard.
  - `00-context/generated/current-focus-trends.md` / `.json` — **V1.3** trend detection
    (current 14 days vs previous 14 days, ↑ / ↓ / →).
  - `00-context/generated/morning-briefing.md` / `.json` — **V1.4** executive briefing.
- `generate-current-focus.v1_1.ps1` — pinned V1.1 baseline kept for reference.
- `generate_current_focus.py` — legacy Python variant (superseded by the .ps1 pipeline).
- `generate-current-focus.ps1` computes per-workstream `strategic_score`,
  `activity_score`, `override_score`, `trend_score`, and a combined
  `attention_score` using the formula in
  [../00-context/scoring-model.yaml](../00-context/scoring-model.yaml).

### Run

```powershell
& "C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.3.0_x64__8wekyb3d8bbwe\pwsh.exe" -NoLogo -NoProfile -File .\scripts\generate-current-focus.ps1
```

The script is idempotent and safe to rerun. It excludes generated outputs from
its own scoring input so past runs never bias future runs.

## Agent rules

- New scripts follow the rules above.
- Generated outputs must carry a `<!-- GENERATED -->` marker naming the
  producing script.
- Do not add dependencies casually; list required packages in the script
  docstring.
- PS scripts target **PowerShell 7.6.3+** (`pwsh`); use `#Requires -Version 7.0`.
