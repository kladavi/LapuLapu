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

- `generate_current_focus.py` — builds the Current Focus Dashboard from the
  workstream registry, scoring model, overrides, Copilot recaps
  (`01-inbox/copilot-activity/`), and `02-work/`.

## Agent rules

- New scripts follow the rules above.
- Generated outputs must carry a `<!-- GENERATED -->` marker naming the
  producing script.
- Do not add dependencies casually; list required packages in the script
  docstring.
