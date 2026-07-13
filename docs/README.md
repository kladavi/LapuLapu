<!-- HUMAN -->
# docs — Durable Documentation

This folder stores **durable documentation**: design notes, milestones, key
results, and reference material.

It is **less volatile** than `01-inbox/` or `02-work/`. Content here changes
slowly and is expected to remain relevant across many operational cycles.

## Typical contents

- Design docs (e.g. `matryoshka-v1.1.md`)
- Key results and milestone summaries
- Architecture notes, onboarding guides, glossaries

## Conventions

- One topic per file. Kebab-case filenames.
- Start each doc with a `# Title` and a one-line purpose statement.
- Link back to operational files (`02-work/…`, `00-context/…`) rather than
  duplicating their content.
- Human-maintained unless explicitly marked `<!-- GENERATED -->`.
