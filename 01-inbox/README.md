<!-- HUMAN -->
# 01-inbox — Intake Layer

This is the **intake layer**. It captures raw and semi-processed inputs before
they become authoritative work.

Typical contents:
- Raw Copilot summaries
- Meeting recap imports
- Email / chat summaries
- Unprocessed notes and quick captures

## Contents

| Path | Type | Purpose |
|---|---|---|
| `inbox.md` | Human | Free-form daily capture. |
| `copilot-activity/` | Imported | **Copilot/M365 14-day activity recaps** live here. One file per import. |

> Copilot/M365 14-day activity recaps **must** be stored in
> `01-inbox/copilot-activity/`. This is the canonical location the focus
> generator scans for M365 signal.

## Agent rules

- Do **not** treat raw inbox content as final truth. It becomes authoritative
  only after it is processed into `02-work/` or referenced by a generated
  output in `00-context/generated/` or `03-reporting/`.
- Do **not** delete items from `inbox.md`; move them via the intake prompt
  (`04-prompts/intake.md`).
- Preserve YAML front-matter (`date`, `source`, `workstreams`) on recap files —
  the focus generator reads it.
- Recency decay handles fading relevance; keep old recaps in place.
