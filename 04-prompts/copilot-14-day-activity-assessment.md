<!-- HUMAN -->
# Copilot Prompt — 14-Day Lapu-Lapu Activity Assessment

**Purpose:** Generate a structured activity recap across M365 signals for the Lapu-Lapu program.
**Inputs:** M365 email, Teams chats, meetings, meeting transcripts, and files from the last 14 days.
**Outputs:** Completed recap saved to `01-inbox/copilot-activity/YYYY-MM-DD-14-day-activity.md`.
**Version:** v1.1 (2026-07-13)

---

Assess my Microsoft 365 activity over the last 14 days for the Lapu-Lapu program.

Include emails, Teams chats, meetings, meeting transcripts, and files where available.

Classify activity into these workstreams:

- ADX Registration
- CMDB Mapping
- Employee XP Dashboard
- Developer XP Dashboard
- GOCC Transition
- MMM L2
- Rapid Recovery
- GBO Batch Transition
- CyberArk Governance
- Capacity Management

For each workstream, provide:

1. Meeting mentions
2. Email mentions
3. Chat mentions
4. Tasks or action items
5. Decisions
6. Risks or blockers
7. Escalations
8. Important stakeholders involved
9. Evidence summary
10. Recommended priority category: P1, P2, Watch, or Parking Lot

Do not fabricate counts. If exact counts are unavailable, say "referenced" instead of giving a number.

Return the output in markdown using the template:

```
03-reporting/templates/copilot-14-day-activity-recap-template.md
```

The result will be saved into:

```
01-inbox/copilot-activity/YYYY-MM-DD-14-day-activity.md
```
