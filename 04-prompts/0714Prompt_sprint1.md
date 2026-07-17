````markdown
---
title: "VS Code Agent Prompt — Project Matryoshka V1.2-V1.4 Next Sprint"
project: "Project Matryoshka"
version: "V1.2-V1.4"
purpose: "Improve Current Focus scoring quality, add trend detection, and generate a morning briefing artifact."
target_folder: "04-prompts"
status: "ready-to-use"
---

# VS Code Agent Task — Project Matryoshka V1.2 / V1.3 / V1.4 Next Sprint

Repository root:

```text
C:\Users\kladavi\OneDrive - Manulife\Projects\LapuLapu
````

## Mission

Project Matryoshka V1.1 is complete.

The Lapu-Lapu repository has been migrated to OneDrive, the Current Focus generation pipeline is working, and the dev server dashboard/homepage now displays the automatically generated Current Focus output.

The next sprint improves the quality and usefulness of the generated focus model.

Implement the following:

* **V1.2 — Signal Quality**
* **V1.3 — Trend Detection**
* **V1.4 — Daily / Weekly Briefing Artifact**

Do not redesign the repository.  
Do not replace the existing dashboard.  
Do not remove working functionality.  
Extend the existing system safely.

***

# Current Situation

The V1.1 Current Focus Dashboard works, but scoring appears to be dominated by stable corpus files.

Current evidence examples include files such as:

```text
00-context\objectives.md
00-context\objective_skill.md
00-context\pack-config.md
00-context\settings.json
```

These files are valuable for strategic context, but they should not be counted the same way as recent activity signals.

The next sprint must separate:

1. Strategic importance
2. Recent activity
3. Human override
4. Trend
5. Recommended action

The goal is to move from a mention-count dashboard toward an operational command dashboard.

***

# Target Architecture

Current Focus should use a layered scoring model:

```text
Attention Score
=
Strategic Score
+
Recent Activity Score
+
Human Override
+
Trend Signal
```

Stable context files should inform meaning, objectives, dependency mapping, and descriptions.

Stable context files should not dominate current activity scoring.

***

# Required Generated Outputs

Create or update the following generated artifacts:

```text
00-context/generated/current-focus.md
00-context/generated/current-focus.json
00-context/generated/current-focus-trends.md
00-context/generated/current-focus-trends.json
00-context/generated/morning-briefing.md
00-context/generated/morning-briefing.json
```

All generated files must be Git-trackable.

Generated files must include a clear warning:

```markdown
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->
```

***

# Required Human-Maintained Control Files

Create or update:

```text
00-context/scoring-model.yaml
00-context/source-weights.yaml
00-context/activity-windows.yaml
00-context/priority-overrides.yaml
```

If these files already exist, update them carefully instead of replacing them.

Preserve existing values unless the update is necessary for V1.2-V1.4.

***

# V1.2 — Signal Quality

## Objective

Improve Current Focus scoring so recent operational activity is separated from stable strategic context.

## Create Source Weighting Control File

Create:

```text
00-context/source-weights.yaml
```

Suggested content:

```yaml
# Human-maintained
# Purpose: controls how strongly each folder contributes to Current Focus scoring.
# Stable context files should inform meaning but should not dominate recent activity scoring.

source_weights:
  01-inbox/copilot-activity:
    type: recent_activity
    weight: 1.0
    include_for_activity_score: true
    include_for_context: true
    description: Copilot-generated 14-day activity recaps based on M365 activity.

  01-inbox:
    type: intake
    weight: 0.8
    include_for_activity_score: true
    include_for_context: true
    description: Raw or semi-processed intake, including imported summaries and operational notes.

  02-work:
    type: active_work
    weight: 0.7
    include_for_activity_score: true
    include_for_context: true
    description: Active workstream notes, tasks, and operational working files.

  03-reporting/weekly:
    type: weekly_reporting
    weight: 0.6
    include_for_activity_score: true
    include_for_context: true
    description: Weekly reporting artifacts and recent status summaries.

  docs/key-results:
    type: key_results
    weight: 0.5
    include_for_activity_score: true
    include_for_context: true
    description: Key result evidence and measurable delivery artifacts.

  00-context:
    type: stable_context
    weight: 0.15
    include_for_activity_score: false
    include_for_context: true
    description: Strategic context, objectives, registries, settings, and operating model.

  docs:
    type: durable_docs
    weight: 0.3
    include_for_activity_score: false
    include_for_context: true
    description: Durable reference documentation and milestone material.

  99-archive:
    type: archive
    weight: 0.0
    include_for_activity_score: false
    include_for_context: false
    description: Historical or retired material.

  90-assets:
    type: assets
    weight: 0.0
    include_for_activity_score: false
    include_for_context: false
    description: Images, screenshots, and non-text assets.
```

***

## Create Activity Windows Control File

Create:

```text
00-context/activity-windows.yaml
```

Suggested content:

```yaml
# Human-maintained
# Purpose: defines recency windows for activity scoring and trend detection.

windows:
  current:
    days: 14
    description: Primary activity window for Current Focus.

  previous:
    days: 14
    offset_days: 14
    description: Prior comparison window for trend detection.

  reference:
    days: 60
    description: Secondary context window for historical reference.

recency_decay:
  enabled: true
  half_life_days: 7
  description: Newer activity should contribute more than older activity.

trend_rules:
  increasing:
    minimum_delta_percent: 20
    symbol: "↑"
  decreasing:
    maximum_delta_percent: -20
    symbol: "↓"
  stable:
    symbol: "→"
```

***

## Update Scoring Model

Update:

```text
00-context/scoring-model.yaml
```

Ensure the model supports these score components:

```yaml
score_components:
  strategic_score:
    description: Stable workstream importance based on workstream registry.
    source: 00-context/workstreams.yaml

  activity_score:
    description: Recent operational activity based on weighted recent sources.
    source: recent activity folders

  override_score:
    description: Human steering from priority-overrides.yaml.
    source: 00-context/priority-overrides.yaml

  trend_score:
    description: Change in activity compared to the previous activity window.
    source: current vs previous activity windows

  attention_score:
    description: Final normalized score used for dashboard ranking.
```

Suggested formula:

```yaml
attention_formula:
  strategic_weight_percent: 20
  activity_weight_percent: 60
  override_weight_percent: 15
  trend_weight_percent: 5
```

Use the existing signal weights where possible:

```yaml
signals:
  meeting_mention: 2
  email_mention: 1
  chat_mention: 1
  task_created: 5
  decision_logged: 6
  risk_logged: 8
  manager_mention: 8
  birger_mention: 10
  escalation: 10
```

***

## Update Current Focus Generator

Update:

```text
scripts/generate-current-focus.ps1
```

Required behavior:

1. Continue reading:
   * `00-context/workstreams.yaml`
   * `00-context/priority-overrides.yaml`
   * `00-context/scoring-model.yaml`

2. Also read:
   * `00-context/source-weights.yaml`
   * `00-context/activity-windows.yaml`

3. Separate score components:
   * `strategic_score`
   * `activity_score`
   * `override_score`
   * `trend_score`
   * `attention_score`

4. Use stable context files only for:
   * purpose
   * description
   * dependency context
   * objective alignment
   * alias resolution
   * background context

5. Do not allow stable context files to dominate activity score.

6. Prefer recent activity evidence from:
   * `01-inbox/copilot-activity`
   * `01-inbox`
   * `02-work`
   * `03-reporting/weekly`
   * `docs/key-results`

7. Exclude generated outputs from all scoring input:
   * `00-context/generated/current-focus.md`
   * `00-context/generated/current-focus.json`
   * `00-context/generated/current-focus-trends.md`
   * `00-context/generated/current-focus-trends.json`
   * `00-context/generated/morning-briefing.md`
   * `00-context/generated/morning-briefing.json`

8. Prevent generated outputs from feeding future scores.

9. Preserve the existing generated Current Focus output contract where possible so the UI does not break.

10. Add new fields to JSON rather than removing existing fields.

***

# V1.3 — Trend Detection

## Objective

Show whether each workstream is increasing, decreasing, or stable compared to the previous activity window.

## Trend Model

Compare:

```text
Current 14 days
vs
Previous 14 days
```

For each workstream calculate:

```text
current_activity_score
previous_activity_score
delta
delta_percent
trend_direction
trend_symbol
trend_reason
```

Trend direction rules:

```yaml
increasing:
  minimum_delta_percent: 20
  symbol: "↑"

decreasing:
  maximum_delta_percent: -20
  symbol: "↓"

stable:
  symbol: "→"
```

## Generate Trend Artifacts

Generate:

```text
00-context/generated/current-focus-trends.md
00-context/generated/current-focus-trends.json
```

Markdown format:

```markdown
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Current Focus Trends

Generated: YYYY-MM-DD HH:mm

## Executive Summary

Briefly describe which workstreams are increasing, decreasing, or stable.

## Trend Table

| Workstream | Current Activity Score | Previous Activity Score | Delta | Delta % | Trend | Reason |
|---|---:|---:|---:|---:|---|---|

## Increasing Attention

## Decreasing Attention

## Stable Attention

## Notes

Trend is based on recent activity signals only. Strategic weight and human overrides are not sufficient by themselves to create an increasing trend.
```

## JSON Format

The JSON should include:

```json
{
  "generated": "YYYY-MM-DDTHH:mm:ss",
  "currentWindowDays": 14,
  "previousWindowDays": 14,
  "workstreams": [
    {
      "id": "mmm-l2",
      "name": "MMM L2",
      "currentActivityScore": 0,
      "previousActivityScore": 0,
      "delta": 0,
      "deltaPercent": 0,
      "trendDirection": "stable",
      "trendSymbol": "→",
      "trendReason": ""
    }
  ]
}
```

***

# V1.4 — Morning Briefing

## Objective

Generate a concise executive briefing from Current Focus and Trends.

Create:

```text
00-context/generated/morning-briefing.md
00-context/generated/morning-briefing.json
```

This briefing should answer:

1. What needs attention now?
2. What changed compared to the previous activity window?
3. What is blocked or at risk?
4. What decisions may be required?
5. What should David do next?

## Markdown Format

Use this format:

```markdown
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Lapu-Lapu Morning Briefing

Generated: YYYY-MM-DD HH:mm

## Executive Snapshot

One concise paragraph summarizing the current operational picture.

## Today’s Primary Focus

### Workstream Name

Why it matters:
- ...

What changed:
- ...

Recommended next action:
- ...

## Rising Risks

## Decision Watch

## Blocked / Escalation Candidates

## Recommended Actions for David

## Source Inputs

## Agent Notes

- This file is generated.
- Edit workstreams.yaml, priority-overrides.yaml, scoring-model.yaml, source-weights.yaml, or activity-windows.yaml to change behavior.
```

## JSON Format

The JSON should include:

```json
{
  "generated": "YYYY-MM-DDTHH:mm:ss",
  "executiveSnapshot": "",
  "primaryFocus": [],
  "risingRisks": [],
  "decisionWatch": [],
  "blockedOrEscalationCandidates": [],
  "recommendedActionsForDavid": [],
  "sourceInputs": []
}
```

***

# UI Updates

Update the dev server UI to show:

1. Current Focus
2. Trends
3. Morning Briefing

Do not remove the existing Current Focus page.

Add clear sections or cards for:

```text
Strategic Score
Activity Score
Override
Trend
Attention Score
```

For each workstream card, display:

```text
Workstream Name
Category
Attention Score
Activity Score
Strategic Score
Strategic Weight
Trend Symbol
Override Status
Top Evidence
Recommended Next Action
```

The UI should make it clear whether a workstream is ranked highly because of:

* Strategic importance
* Recent activity
* Human override
* Rising trend
* Actual blocker or escalation

Avoid showing only raw mention counts as the main signal.

***

# README Updates

Update relevant README files:

```text
README.md
00-context/README.md
scripts/README.md
ui/README.md
04-prompts/README.md
```

Document:

* V1.2 Signal Quality
* V1.3 Trend Detection
* V1.4 Morning Briefing
* Which files are human-maintained
* Which files are generated
* How agents should regenerate outputs
* Why generated files must not be edited manually
* Why stable context and recent activity are scored differently
* How source weighting works
* How trend detection works

***

# Validation Requirements

After implementation, run:

```powershell
.\scripts\generate-current-focus.ps1
```

Confirm these files exist:

```powershell
Test-Path .\00-context\generated\current-focus.md
Test-Path .\00-context\generated\current-focus.json
Test-Path .\00-context\generated\current-focus-trends.md
Test-Path .\00-context\generated\current-focus-trends.json
Test-Path .\00-context\generated\morning-briefing.md
Test-Path .\00-context\generated\morning-briefing.json
```

Validate JSON:

```powershell
Get-Content .\00-context\generated\current-focus.json | ConvertFrom-Json | Out-Null
Get-Content .\00-context\generated\current-focus-trends.json | ConvertFrom-Json | Out-Null
Get-Content .\00-context\generated\morning-briefing.json | ConvertFrom-Json | Out-Null
```

Preview generated markdown:

```powershell
Get-Content .\00-context\generated\current-focus.md -TotalCount 80
Get-Content .\00-context\generated\current-focus-trends.md -TotalCount 80
Get-Content .\00-context\generated\morning-briefing.md -TotalCount 80
```

***

# UI Validation

Run the dev server.

```powershell
npm run dev
```

If that fails, inspect package scripts:

```powershell
Get-Content .\package.json
Get-Content .\ui\package.json
```

Use the correct dev script from the applicable package file.

Confirm the dashboard renders:

* Current Focus
* Trends
* Morning Briefing
* P1 Focus
* Watch Items
* Human Overrides
* Evidence
* Recommended next actions

Confirm the UI does not break if trend files or morning briefing files are missing. It should show a useful placeholder or warning.

***

# Expected Priority Behavior

The dashboard should still recognize these as high priority unless activity and overrides indicate otherwise:

```text
GOCC Transition
Rapid Recovery
MMM L2
GBO Batch Transition
```

Expected Watch items:

```text
Capacity Management
CyberArk Governance
```

unless activity or human overrides elevate them.

The difference after this sprint is that evidence and scoring should increasingly come from recent activity files, not only stable context files.

***

# Expected Improved Output

The dashboard should move away from this style:

```text
GOCC Transition
Mentions: 1073
```

Toward this style:

```text
GOCC Transition

Attention Score: 91
Strategic Score: 9
Activity Score: High
Override: P1
Trend: ↑ Increasing

Reason:
Ingenium desktop rehearsal and incident handoff validation are active execution items.

Recommended Next Action:
Confirm rehearsal scope, participants, escalation path, and evidence expectations.
```

This is the desired shift from search-count dashboard to operational command dashboard.

***

# Git Hygiene

Run:

```powershell
git status
```

If only Project Matryoshka sprint files changed, commit:

```powershell
git add README.md 00-context scripts ui docs 01-inbox 02-work 03-reporting 04-prompts
git commit -m "Improve Project Matryoshka current focus scoring and trends"
```

Do not push.

If unrelated changes are present, do not commit them. Report them separately.

***

# Final Response to David

Return a concise completion report with:

1. Files created.
2. Files modified.
3. Whether generation succeeded.
4. Whether JSON validated.
5. Whether UI rendered.
6. Whether source weighting works.
7. Whether stable context no longer dominates activity score.
8. Whether trends were generated.
9. Whether morning briefing was generated.
10. Whether Git commit was created.
11. Commit hash if available.
12. Any remaining follow-up items.

Do not ask questions unless blocked.

```
```
