# Project Matryoshka - V3.0 Adaptive Intelligence (Sprints 4-9)

**Status**: V3.0 Adaptive Intelligence shipped. `main` at `3ea16e0`.
**Repo**: `kladavi/LapuLapu`. Generator: `scripts/generate-current-focus.ps1`. Dashboard: `ui/src/components/DashboardTab.tsx`.

## Sprint summary (V1.6 -> V3.0)

| Sprint | Version | PR | Theme | Key deliverables |
|---|---|---|---|---|
| 4 | V1.6 | #8  | Decision Intelligence   | `Get-DecisionRegistry`, decision-registry.md/json, dedup by workstream+title+file, aging + escalation candidates |
| 5 | V1.7 | #9  | Risk Intelligence       | `Get-RiskRegister`, risk-register.md/json, severity + trend + aging, structured `recommendedAction` |
| 6 | V1.8 | #10 | Ownership Intelligence  | `00-context/ownership-map.yaml`, `ownerConfidence` (workstream-map / name-proximity / unknown), escalationPath, stakeholders, structured `Get-Structured*Action` |
| 7 | V2.0 | #11 | David Brain             | `Get-EntryConfidence`, `impact`, `decisionRequired`/`decisionPrompt`/`decisionDeadline`, `Get-WorkstreamHealth` (R/A/G), `Get-DavidInbox`, priority-inbox card + workstream stripes |
| 8 | V2.5 | #12 | Execution Intelligence  | `decisionStatus` (Pending/Decided/Expired), `decisionOutcome`, `linkedActions`, `completionSignal`, `timeToEscalationRisk` (decisions+risks), tiered inbox (P1:5/P2:10/P3:10), `Get-DecisionClusters` (workstream x theme) |
| 9 | V3.0 | #13 | Adaptive Intelligence   | `Get-InferredActions` (activation layer), `actionSource='marker'\|'inferred'`, `Get-ExecutionInsights` + new `execution-insights.md/json`, `outcomeQuality` (High/Medium/Low/Unknown), `recurrenceCount` via `Get-NormalizedTitle`, `00-context/david-preferences.yaml` + `Read-DavidPreferences`, personalized `rankingScore` + `personalizationSignals` in inbox, learning loop (delayed-workstream / overloaded-owner feedback) |

Every sprint used the same recipe: isolated `sprint/matryoshka-*` branch -> commit -> `gh pr create --body-file` -> `gh pr merge --merge --delete-branch` -> `git pull --ff-only`.

## Capabilities achieved (V3.0)

**Data extraction + resolution**
- Auto-extracts and dedups decisions + risks from context-eligible corpus files (`source-weights.yaml` gate).
- Owner resolution with confidence tier (`workstream-map` > `name-proximity` > `unknown`).
- Confidence score `[0,1]` per entry combining ownerConfidence weight + log10 source count + recency window.

**Lifecycle + execution**
- Lifecycle for every decision: **Pending** (awaiting), **Decided** (outcome/signal captured, incl. `**Decision:** Approved` fallback), **Expired** (past deadline +3d or aged 30+ without outcome).
- `outcomeQuality` diagnostic: **High** (outcome + completed action), **Medium** (outcome only), **Low** (fallback-derived only), **Unknown** (not Decided).
- Recurrence detection via normalized-title second-pass count.
- Escalation prediction (`timeToEscalationRisk` in days) on decisions AND risks, rolled up as `imminentEscalation` totals.

**Action layer (V3.0)**
- Marker path: `**Action:** X (owner: Y, due: Z)` captured verbatim, status inferred (`pending`/`in-progress`/`completed`/`blocked`), tagged `actionSource='marker'`.
- Activation layer: when a Pending decision has zero markers, `Get-InferredActions` synthesizes 1-3 rule-based follow-ups tagged `actionSource='inferred'`. Rules cover P1 escalate / P2 confirm / 30+d archive / fresh monitor.

**Inbox + personalization (V3.0)**
- Tiered priority inbox (P1 cap 5, P2 cap 10, P3 cap 10) that filters out Decided items and includes any entry with `timeToEscalationRisk <= 3` regardless of static priority.
- Static boosts: `priority_boosts.workstream / owner / kind` (from `david-preferences.yaml`).
- Dynamic penalties: `overloaded_owner_penalty` on non-P1 items, `low_confidence_penalty` when confidence < 0.4.
- Dynamic bonuses: `recurring_decision_bonus`, `missed_deadline_bonus`, `imminent_escalation_bonus`, `inferred_action_bonus`.
- Each item carries a `rankingScore` (float, secondary sort key within tier) + a `personalizationSignals` array `[{source, delta, reason}, ...]` rendered as a tooltip - every ranking decision is auditable.

**Insights + learning loop (V3.0)**
- New artifact `execution-insights.md/json` publishes six signal streams: `delayedDecisions`, `missedDeadlines`, `overloadedOwners`, `recurringDecisions`, `stalePendingByWorkstream`, `highSeverityAgedRisks`.
- Learning loop wires insights back into the inbox ranker:
  - Item's workstream in `delayedDecisions` AND verb is `Escalate` -> `learning:delayed-workstream` bonus (+0.10).
  - Item's owner in `overloadedOwners` -> `learning:overloaded-owner` penalty (-0.05) + the direct `overloaded-owner` -0.20 penalty on non-P1 items (P1 never dampened).

**Clustering + health (V2.0/V2.5)**
- Decision/risk clustering by `workstream` first, then greedy bag-of-words `theme` with ~90-term stopword list.
- Workstream health R/A/G with stripe + reason on Current Focus cards.

**Hygiene**
- Blacklist (`$script:GENERATED_ARTIFACTS`) prevents generated files from feeding scoring feedback.

## System architecture snapshot

```
00-context/
  workstreams.yaml            scoring-model.yaml         priority-overrides.yaml
  source-weights.yaml         activity-windows.yaml      ownership-map.yaml
  david-preferences.yaml      <- V3.0: personalization + learning-loop weights
  generated/                  <- all outputs written here (UTF-8 no BOM)
    current-focus.md/.json
    current-focus-trends.md/.json
    morning-briefing.md/.json
    decision-registry.md/.json
    risk-register.md/.json
    david-inbox.md/.json
    execution-insights.md/.json  <- V3.0
  automation-state.json       pipeline-health.json

scripts/
  generate-current-focus.ps1  <- monolithic generator (~3600 lines, PS 7.6+)
  run-matryoshka-pipeline.ps1 <- orchestrator (idempotent, writes pipeline-health.json)

ui/                           <- Next.js 16 / React 19 / Tailwind, port 3000
  src/components/DashboardTab.tsx  <- reads all generated JSONs at build time
```

Generator pipeline order (matters):
1. Read control YAMLs -> `Read-Workstreams`, `Read-Overrides`, `Read-ScoringModel`, `Read-SourceWeights`, `Read-ActivityWindows`, `Read-OwnershipMap`, `Read-DavidPreferences` (V3.0).
2. Scan corpus -> `Get-SourceFileRecords` + `Get-ActivityWindowBuckets` (current/previous/older).
3. Score -> `Measure-WorkstreamSignals` -> `Get-NormalizedScores` -> `Measure-WorkstreamActivityV2` -> `Get-AttentionScores` -> `Merge-AttentionIntoResults` -> `Invoke-Overrides`.
4. Write current-focus + trends (v1).
5. `Get-DecisionRegistry` -> in the finalize loop: lifecycle -> escalation risk -> **inferred actions** (V3.0) -> outcomeQuality -> second-pass recurrence -> decision-registry files.
6. `Get-RiskRegister` -> risk-register files.
7. `Get-WorkstreamHealth` -> mutate `finalResults[wsId].health` -> **rewrite current-focus files (v2 with health)**.
8. **V3.0**: `Get-ExecutionInsights` -> execution-insights files.
9. `Get-DavidInbox -Preferences $preferences -Insights $insights` -> david-inbox files (tiered + clustered + **personalized**).
10. `Build-MorningBriefing*` (consumes decisions + risks).

All artifacts carry `version: V3.0` and `generator: 'scripts/generate-current-focus.ps1'`.

## Known constraints

- **`**Action:**` markers not yet populated in corpus.** In V3.0 this no longer produces empty `linkedActions` - the activation layer synthesizes rule-based follow-ups tagged `actionSource='inferred'` (7 in current corpus, one per Pending decision). Once markers appear, the marker path takes over (dedupe by lowercased text; markers displace inferred entries).
- **`**Impact:**` markers not yet populated in corpus.** `impact` field is empty for every decision + risk today. Extractor recognizes `**Impact:**` on a bulleted line; populates automatically once used.
- **`**Outcome:**`/`**Resolution:**`/`**Result:**` markers rarely used**; the V2.5 fallback that reads `**Decision:** Approved|Deferred|Rejected|Superseded|Reversed|Deprecated|Locked|Confirmed` produced 12 Decided items in the current corpus, but ALL 12 land at `outcomeQuality: Low` because the fallback is a single-token resolution. Explicit `**Outcome:** X` markers upgrade them to Medium / High.
- **Clustering stopwords are English-only**; if Japanese theme tokens become desirable, add a JA stopword file + switch flag (deferred).
- **`timeToEscalationRisk` uses hardcoded 3-day deadline buffer**; externalize to `scoring-model.yaml` in a future sprint if the buffer becomes tunable.
- **Personalization weights are static YAML** in `david-preferences.yaml`. A future sprint could add automatic tuning based on which items David actually opens (requires click telemetry). Learning-loop bonuses are additive-only today; a future sprint could add decay so a workstream stays "hot" for N days after clearing its delayed decisions.
- **Recurrence detection uses greedy title normalization**; identical-topic decisions with different phrasings won't collide. Fuzzy matching (Jaccard on token sets) would catch more.
- **StrictMode discipline**: any hashtable-count / property-count call must be wrapped `@(...)` and cast `[int]` because generators return `$null` on empty and `[hashtable].Count` throws under strict mode.
- **UTF-8 BOM**: writes MUST use `[System.IO.File]::WriteAllText(..., New-Object System.Text.UTF8Encoding($false))` or Unicode arrows/badges corrupt. Never use `Set-Content` for generated artifacts.
- **PowerShell scope-prefix bite**: `"text $var: more"` fails to parse because `$var:` looks like a scope reference. Always use `${var}` when a colon follows.
- **`-replace` with scriptblock callback**: use `[regex]::Replace($input, $pattern, { param($m) ... $m.Groups[1].Value ... })` - the `-replace 'x', { $args[0]... }` pattern does NOT work reliably in PS 7 under StrictMode.

## Definition of "Adaptive Intelligence" (V3.0)

The V3.0 layer answers three additional operational questions the V2.5 dashboard could not:

1. **Even if we don't have explicit actions, what should be next?** -> `Get-InferredActions` synthesizes rule-based follow-ups tagged `actionSource='inferred'`, so every Pending decision has at least one concrete next step.
2. **Which owner is over-capacity right now, and how should that affect what I ask them today?** -> `overloadedOwners` insight + `overloaded-owner` and `learning:overloaded-owner` ranker penalties push non-P1 items on capacity-constrained owners DOWN within their tier (P1 escalate-today items are never dampened).
3. **Why did the system rank THIS item above THAT one?** -> Every inbox item carries a `rankingScore` pill + `personalizationSignals` tooltip listing every boost/penalty applied. Fully auditable, no black box.

Plus the wire behind the answers:
- Marker path vs activation path: `linkedActions[].actionSource` distinguishes captured-from-source vs synthesized, so David can see at a glance which are ready to act on vs which are hints.
- Outcome quality diagnostic: `outcomeQuality: Low` across 12 Decided items today is the system telling David his team is not writing outcome text - a coaching signal, not a bug.
- Recurrence pill (`recurring Nx`) flags decisions that resurface - the prior decision didn't stick and needs a stronger fix.

Together V3.0 turns the dashboard from "executable inbox" (V2.5) into "executable inbox that learns" - the same corpus produces different rankings today than yesterday depending on who is overloaded, what has been delayed, and what David has told the system he cares about.
