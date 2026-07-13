<!-- HUMAN -->
# Project Matryoshka V1 Milestones

## V1.1 — Current Focus Dashboard

**Status:** Implementing

### Objective

Create a generated dashboard that identifies David's current focus using the
Lapu-Lapu corpus, Copilot/M365 activity recaps, workstream metadata, scoring
rules, and human overrides.

### Definition of Done

- [ ] `workstreams.yaml` exists and is populated
- [ ] `priority-overrides.yaml` exists and is populated
- [ ] `scoring-model.yaml` exists and is populated
- [ ] `current-focus.md` is generated at `00-context/generated/current-focus.md`
- [ ] `current-focus.json` is generated at `00-context/generated/current-focus.json`
- [ ] Generated files are checked into Git
- [ ] `README.md` files exist in all major folders explaining purpose and agent behaviour
- [ ] Copilot 14-day activity prompt exists at `04-prompts/copilot-14-day-activity-assessment.md`
- [ ] Copilot activity recap template exists at `03-reporting/templates/copilot-14-day-activity-recap-template.md`
- [ ] Script can regenerate the dashboard repeatedly and safely
- [ ] Weekly reporting can consume `current-focus.md` as input

### Success Criteria

- David can open one file and understand current priorities.
- Copilot and VS Code agents can locate the current focus via `00-context/generated/current-focus.md`.
- Weekly reporting can use `current-focus.md` as an input.
- New activity can be incorporated through Copilot recap imports into `01-inbox/copilot-activity/`.
- Human overrides in `priority-overrides.yaml` can steer priorities without rewriting generated files.

### Recommended Weekly Loop

1. Ask Copilot for the 14-day Lapu-Lapu activity assessment using `04-prompts/copilot-14-day-activity-assessment.md`.
2. Save output to `01-inbox/copilot-activity/YYYY-MM-DD-14-day-activity.md`.
3. Run `.\scripts\generate-current-focus.ps1`.
4. Review `00-context/generated/current-focus.md`.
5. If priorities are directionally wrong, update `00-context/priority-overrides.yaml` only — do not edit the generated file.
6. Commit the updated generated files.
