# Project Matryoshka - V2.5 Complete (Sprints 4-8)

**Status**: V2.5 Execution Intelligence shipped. `main` at `c236f07` (superseded by V3.0 at `3ea16e0`).
**Repo**: `kladavi/LapuLapu`. Generator: `scripts/generate-current-focus.ps1`. Dashboard: `ui/src/components/DashboardTab.tsx`.

> Historical snapshot as of the end of Sprint 8. For the current-state V3.0 view see `matryoshka-v3-adaptive-intelligence.md`.

## Sprint summary (V1.6 -> V2.5)

| Sprint | Version | PR | Theme | Key deliverables |
|---|---|---|---|---|
| 4 | V1.6 | #8  | Decision Intelligence   | `Get-DecisionRegistry`, decision-registry.md/json, dedup by workstream+title+file, aging + escalation candidates |
| 5 | V1.7 | #9  | Risk Intelligence       | `Get-RiskRegister`, risk-register.md/json, severity + trend + aging, structured `recommendedAction` |
| 6 | V1.8 | #10 | Ownership Intelligence  | `00-context/ownership-map.yaml`, `ownerConfidence` (workstream-map / name-proximity / unknown), escalationPath, stakeholders, structured `Get-Structured*Action` |
| 7 | V2.0 | #11 | David Brain             | `Get-EntryConfidence`, `impact`, `decisionRequired`/`decisionPrompt`/`decisionDeadline`, `Get-WorkstreamHealth` (R/A/G), `Get-DavidInbox`, priority-inbox card + workstream stripes |
| 8 | V2.5 | #12 | Execution Intelligence  | `decisionStatus` (Pending/Decided/Expired), `decisionOutcome`, `linkedActions`, `completionSignal`, `timeToEscalationRisk` (decisions+risks), tiered inbox (P1:5/P2:10/P3:10), `Get-DecisionClusters` (workstream x theme) |

Every sprint used the same recipe: isolated `sprint/matryoshka-*` branch -> commit -> `gh pr create --body-file` -> `gh pr merge --merge --delete-branch` -> `git pull --ff-only`.

## Capabilities achieved (V2.5)

- Auto-extracts and dedups decisions + risks from context-eligible corpus files (`source-weights.yaml` gate).
- Owner resolution with confidence tier (`workstream-map` > `name-proximity` > `unknown`).
- Lifecycle for every decision: **Pending** (awaiting), **Decided** (outcome/signal captured, incl. `**Decision:** Approved` fallback), **Expired** (past deadline +3d or aged 30+ without outcome).
- Escalation prediction (`timeToEscalationRisk` in days) on decisions AND risks, rolled up as `imminentEscalation` totals.
- Tiered priority inbox (P1 cap 5, P2 cap 10, P3 cap 10) that filters out Decided items and includes any entry with `timeToEscalationRisk <= 3` regardless of static priority.
- Decision/risk clustering by `workstream` first, then greedy bag-of-words `theme` with ~90-term stopword list.
- Workstream health R/A/G with stripe + reason on Current Focus cards.
- Confidence score `[0,1]` per entry combining ownerConfidence weight + log10 source count + recency window.
- Blacklist (`$script:GENERATED_ARTIFACTS`) prevents generated files from feeding scoring feedback.

## System architecture snapshot

```
00-context/
  workstreams.yaml            scoring-model.yaml       priority-overrides.yaml
  source-weights.yaml         activity-windows.yaml    ownership-map.yaml
  generated/                  <- all outputs written here (UTF-8 no BOM)
    current-focus.md/.json
    current-focus-trends.md/.json
    morning-briefing.md/.json
    decision-registry.md/.json
    risk-register.md/.json
    david-inbox.md/.json
  automation-state.json       pipeline-health.json

scripts/
  generate-current-focus.ps1  <- monolithic generator (~3200 lines, PS 7.6+)
  run-matryoshka-pipeline.ps1 <- orchestrator (idempotent, writes pipeline-health.json)

ui/                           <- Next.js 16 / React 19 / Tailwind, port 3000
  src/components/DashboardTab.tsx  <- reads all generated JSONs at build time
```

Generator pipeline order (matters):
1. Read control YAMLs -> `Read-Workstreams`, `Read-Overrides`, `Read-ScoringModel`, `Read-SourceWeights`, `Read-ActivityWindows`, `Read-OwnershipMap`.
2. Scan corpus -> `Get-SourceFileRecords` + `Get-ActivityWindowBuckets` (current/previous/older).
3. Score -> `Measure-WorkstreamSignals` -> `Get-NormalizedScores` -> `Measure-WorkstreamActivityV2` -> `Get-AttentionScores` -> `Merge-AttentionIntoResults` -> `Invoke-Overrides`.
4. Write current-focus + trends (v1).
5. `Get-DecisionRegistry` -> decision-registry files.
6. `Get-RiskRegister` -> risk-register files.
7. `Get-WorkstreamHealth` -> mutate `finalResults[wsId].health` -> **rewrite current-focus files (v2 with health)**.
8. `Get-DavidInbox` -> david-inbox files (tiered + clustered).
9. `Build-MorningBriefing*` (consumes decisions + risks).

All artifacts carry `version: V2.5` and `generator: 'scripts/generate-current-focus.ps1'`.

## Known constraints (as of V2.5)

- **`**Action:**` markers not yet populated in corpus.** `linkedActions` array is empty for every decision today. Wire-up is complete: any decision with `**Action:** ... (owner: X, due: Y)` in nearby context is captured with status inference (`pending`/`in-progress`/`completed`/`blocked`), capped at 5 per decision. No code change needed once David starts writing them. _(Resolved in V3.0 via the activation layer - Sprint 9 adds inferred actions when markers are absent.)_
- **`**Impact:**` markers not yet populated in corpus.** `impact` field is empty for every decision + risk today. Extractor recognizes `**Impact:**` on a bulleted line; populates automatically once used.
- **`**Outcome:**`/`**Resolution:**`/`**Result:**` markers rarely used**; the V2.5 fallback that reads `**Decision:** Approved|Deferred|Rejected|Superseded|Reversed|Deprecated|Locked|Confirmed` is what produced 12 Decided items in the current corpus. Explicit `**Outcome:** X` markers would surface richer per-decision text.
- **Clustering stopwords are English-only**; if Japanese theme tokens become desirable, add a JA stopword file + switch flag (deferred).
- **`timeToEscalationRisk` uses hardcoded 3-day deadline buffer**; externalize to `scoring-model.yaml` in a future sprint if the buffer becomes tunable.
- **StrictMode discipline**: any hashtable-count / property-count call must be wrapped `@(...)` and cast `[int]` because generators return `$null` on empty and `[hashtable].Count` throws under strict mode.
- **UTF-8 BOM**: writes MUST use `[System.IO.File]::WriteAllText(..., New-Object System.Text.UTF8Encoding($false))` or Unicode arrows/badges corrupt. Never use `Set-Content` for generated artifacts.

## Definition of "Execution Intelligence"

The V2.5 layer answers four operational questions the pre-V2.5 dashboard could not:

1. **Did we already decide this?** -> `decisionStatus` (Pending / Decided / Expired). Decided items no longer clog David's inbox.
2. **What did we decide?** -> `decisionOutcome` (surfaced inline on Decision Watch).
3. **How close are we to needing to escalate?** -> `timeToEscalationRisk` in days, colour-graded (red = today, amber <= 3d, blue <= 7d).
4. **Which items can we handle in one conversation with one owner?** -> `clusters` (workstream + theme) collapse multi-item calls into batched escalations.

Plus the mechanical wire:
- Decision -> Action -> Completion signal (`linkedActions[].status`).
- Cap discipline: David sees at most 25 items across three tiers, not a wall.
- Escalation-first sort key overrides pure priority when a P2 item is imminent.

Together this turns the dashboard from "what's happening" (attention scoring) into "what David must action before end of day" (executable inbox).
