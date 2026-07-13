<!-- HUMAN -->
# 01-inbox/copilot-activity — Copilot / M365 Activity Recaps

This folder stores **Copilot-generated 14-day activity recaps** for the Lapu-Lapu program.

## How recaps are created

1. Run the prompt `04-prompts/copilot-14-day-activity-assessment.md` in M365 Copilot.
2. Save the output as `YYYY-MM-DD-14-day-activity.md` in this folder.
3. Run `scripts/generate-current-focus.ps1` to incorporate the new evidence.

## What the generator does with these files

The generator treats each file here as **activity evidence**. It reads:
- YAML front-matter (`type`, `window_days`, `generated_on`, `source`)
- Workstream section headers (e.g. `### MMM L2`)
- Signal keyword counts (meeting mentions, tasks, decisions, risks, escalations)

Recency decay in the scoring model handles the fading relevance of older recaps.

## File naming

```
YYYY-MM-DD-14-day-activity.md
```

## Confidentiality

- Do **not** store raw email bodies, chat transcripts, or confidential personal data here.
- Store only **summarized, classified activity artifacts** produced by Copilot.
- If verbatim content is required for audit purposes, confirm approval before committing.
