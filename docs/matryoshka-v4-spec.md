# Matryoshka V4.0 Refactor Specification

**Response to** [`04-prompts/0717ReviewPrompt.md`](../04-prompts/0717ReviewPrompt.md)
**Feedback source**: [`05-memory/feedback/2026-07-live-test.md`](../05-memory/feedback/2026-07-live-test.md)
**Current baseline**: V3.1 (adaptive intelligence + corpus-signature trigger, live at `6cc43b3`)
**Author**: David Klan · Manulife ETS Japan
**Date**: 2026-07-17

---

## North Star

> Any workstream member should be able to understand what needs to be done, why it matters, what decisions have been made, who owns it, and what the next action is — without requiring David to explain it.

---

## Framing: mapping feedback to phases

| Live-test complaint | Phase |
|---|---|
| *"Balaji is listed as owner for most items but that doesn't seem right"* | 7 |
| *"3 items are effectively redundant"* (R-b493137b8f / R-bafab65c68 / R-d7f568105f re Ingenium) | 6 |
| *"Vendor escalation… should not be given further attention since they are over 1 month old"* (R-cd89918f9c 85d) | 3 |
| *"Most priority items are 'Escalate:' and we should rarely be escalating"* | 2 |
| *"Many items… same today with no updates that show yesterday's activity"* | 4 |
| *"Descriptions do not provide deterministic actions or context"* | 1, 5 |
| *"Ideally I want to click-thru any item to find more details"* | 5 |
| *"Copilot prompt scheduled at 11am... Manually created file… (10 min)"* + `2026-07-17-14-day-activity.md` stayed 0-bytes | 8 |

---

## 🔴 Phase 1 — Strict Item Contract

### 1a. Canonical schema (TypeScript — canonical, since the dashboard is the primary consumer)

```typescript
// ui/src/lib/matryoshka-item.ts (NEW)
export type MatryoshkaItemType = "task" | "decision" | "follow-up" | "risk";
export type MatryoshkaAction   = "DO" | "DECIDE" | "FOLLOW_UP" | "INVESTIGATE" | "BLOCKED";
export type MatryoshkaStatus   = "green" | "amber" | "red";
export type OwnerConfidence    = "high" | "medium" | "low";

export interface MatryoshkaActivityLogEntry {
  timestamp: string;      // ISO 8601
  event: string;          // "created" | "updated" | "merged" | "status-changed" | "owner-changed"
  from?: string;          // prior value where relevant
  to?: string;            // new value where relevant
  source?: string;        // path or ref that produced this update
}

export interface MatryoshkaItem {
  // --- IDENTITY ---
  id: string;                        // "MAT-{short-hash}" — deterministic from title+workstream+type
  type: MatryoshkaItemType;          // one of task/decision/follow-up/risk
  title: string;                     // human-readable, ≤140 chars, must NOT start with a verb like "Escalate:"

  // --- OWNERSHIP (Phase 7) ---
  owner: string;                     // MUST be present; use "Unassigned" if unknown
  suggested_owner?: string;          // inferred but not confirmed
  owner_confidence: OwnerConfidence; // low = only inferred; medium = name-proximity; high = ownership-map hit

  // --- CONTEXT (Phase 1 core) ---
  why_it_matters: string;            // 1 sentence, MANDATORY
  next_action: string;               // imperative verb sentence, MANDATORY
  action_class: MatryoshkaAction;    // one of DO/DECIDE/FOLLOW_UP/INVESTIGATE/BLOCKED
  workstream: string;                // canonical workstream name, or "" if none

  // --- LIFECYCLE ---
  status: MatryoshkaStatus;          // green/amber/red per rules below
  status_reason: string;             // human-readable justification
  aging_days: number;                // days since first_seen
  stale: boolean;                    // computed per Phase 3 rules

  // --- SOURCES + CONTEXT LINKING (Phase 5) ---
  source: string;                    // primary source (canonical repo-relative path)
  source_uri?: string;               // clickable if applicable (Teams URL etc)
  context_summary: string;           // 2-3 sentences from the source paragraph
  related_items: string[];           // IDs of related MatryoshkaItems

  // --- CONFIDENCE + DEDUPE (Phase 6) ---
  confidence_score: number;          // [0,1], based on frequency of mentions
  merged_from: string[];             // IDs of items merged into this one

  // --- HISTORY (Phase 4) ---
  first_seen: string;                // ISO
  last_updated: string;              // ISO
  activity_log: MatryoshkaActivityLogEntry[];

  // --- DELTA (Phase 4, computed at emit time) ---
  delta: {
    days_since_last_touched: number;
    updated_since_yesterday: boolean;
    change_summary?: string;
  };
}

export interface MatryoshkaValidationError {
  itemId: string;
  field: string;
  reason: string;
}
```

### 1b. Enforcement — hard rejection at emit time

Every function that currently emits a decision/risk/inbox item wraps its output through:

```typescript
// (mirrored in PowerShell as Test-MatryoshkaItem in generate-current-focus.ps1)
export function validateItem(candidate: Partial<MatryoshkaItem>):
  { ok: true; item: MatryoshkaItem } | { ok: false; errors: MatryoshkaValidationError[] } {

  const errors: MatryoshkaValidationError[] = [];
  const required: (keyof MatryoshkaItem)[] = [
    "id", "type", "title", "owner", "owner_confidence",
    "why_it_matters", "next_action", "action_class",
    "status", "status_reason", "aging_days",
    "source", "context_summary", "confidence_score",
    "first_seen", "last_updated"
  ];

  for (const f of required) {
    const v = (candidate as any)[f];
    if (v === undefined || v === null || v === "") {
      errors.push({ itemId: candidate.id ?? "(no-id)", field: f, reason: "missing required field" });
    }
  }
  if (candidate.title && candidate.title.length > 140) {
    errors.push({ itemId: candidate.id!, field: "title", reason: "exceeds 140 chars" });
  }
  if (candidate.why_it_matters && candidate.why_it_matters.split(/[.!?]/).filter(s=>s.trim()).length > 1) {
    errors.push({ itemId: candidate.id!, field: "why_it_matters", reason: "must be exactly 1 sentence" });
  }
  if (candidate.title && /^\s*(escalate|todo|fix)\s*:/i.test(candidate.title)) {
    errors.push({ itemId: candidate.id!, field: "title", reason: "title must not start with imperative verb — that's what action_class is for" });
  }

  return errors.length ? { ok: false, errors } : { ok: true, item: candidate as MatryoshkaItem };
}
```

**Rejection log**: `00-context/generated/rejected-items.md` and `.json`. Every rejected candidate lands here with the field(s) that failed. Fixable — creators see exactly what's missing.

**Where to plug in**: rewrite `New-InboxItem` in `scripts/generate-current-focus.ps1` as a builder that fails closed. Same for `Get-DecisionRegistry` and `Get-RiskRegister` finalizer loops. All three funnel through `Test-MatryoshkaItem`.

---

## 🟠 Phase 2 — Action Classification (kill the "Escalate" default)

### 2a. Taxonomy

| Action | Definition | Verb prefix in `next_action` |
|---|---|---|
| **DO** | David or the owner does something themselves this week | *"Do X"* / *"Send X"* / *"Write X"* / *"Deploy X"* |
| **DECIDE** | A concrete choice needs to be made — decision-log candidate | *"Decide whether…"* / *"Choose between…"* |
| **FOLLOW_UP** | Contact someone / check status / gather info | *"Ask X for…"* / *"Confirm…"* / *"Check…"* |
| **INVESTIGATE** | Root-cause analysis needed | *"Investigate why…"* / *"Analyse…"* |
| **BLOCKED** | External dependency — nothing to do until unblocked | *"Awaiting…"* / *"Blocked by…"* |

**No "ESCALATE"**. Escalation is a *severity flag* (per Phase 1's `status: red`), not an action.

### 2b. Classifier logic (deterministic pattern-matching, no LLM)

```powershell
# scripts/generate-current-focus.ps1 (NEW helper)
function Get-ActionClass {
    param([string] $NextAction, [string] $StatusReason)
    $t = ($NextAction + ' ' + $StatusReason).ToLowerInvariant()
    if ($t -match '\bblocked by\b|\bawaiting\b|\bwaiting on\b|\bwaiting for\b') { return 'BLOCKED' }
    if ($t -match '\bdecide\b|\bchoose\b|\bapprov(e|al)\b|\bsign[- ]off\b') { return 'DECIDE' }
    if ($t -match '\binvestigat(e|ion)\b|\bdiagnos\b|\banaly(s|z)\b|\broot[- ]cause\b') { return 'INVESTIGATE' }
    if ($t -match '\bask\b|\bconfirm\b|\bcheck\b|\breach out\b|\bfollow[- ]up\b|\bcontact\b') { return 'FOLLOW_UP' }
    if ($t -match '\bdo\b|\bsend\b|\bwrite\b|\bdeploy\b|\bcomplete\b|\bfinish\b|\bimplement\b|\bcreate\b|\bpublish\b') { return 'DO' }
    return $null   # invalid — item will be rejected by Test-MatryoshkaItem
}
```

### 2c. Migration from V3.1 taxonomy

| V3.1 verb (from `recommendedAction`) | V4.0 `action_class` | `next_action` template |
|---|---|---|
| `Escalate` (P1) | `DO` if owner is David; `FOLLOW_UP` otherwise | *"Send escalation to {escalationPath[0]} today"* |
| `Confirm` (P2) | `FOLLOW_UP` | *"Confirm with {owner} that…"* |
| `Investigate` (P2) | `INVESTIGATE` | *"Investigate why…"* |
| `Review` (P3) | `FOLLOW_UP` | *"Review with {owner}…"* |
| `Track` (P4) | `FOLLOW_UP` | *"Check in with {owner} in 7 days"* |
| `Archive` (P5) | *(removed — items go stale)* | n/a |
| `Monitor` (P4 risk) | `FOLLOW_UP` if aging < 7d, else `BLOCKED` | *"Monitor {workstream} — re-check in 7 days"* |

Every generator finalizer replaces the "Escalate everywhere" default with this classifier's output. Items where the classifier returns `null` are pushed to `rejected-items.md` with reason *"action_class unclassifiable — needs explicit next_action"*.

---

## 🟡 Phase 3 — Aging + Relevance

### 3a. Rules

```powershell
function Get-Stale {
    param([hashtable] $Entry, [datetime] $Now)
    $age = if ($Entry.aging_days) { [int]$Entry.aging_days } else { 0 }

    # Not stale if actively updated
    $lastUpd = [datetime]$Entry.last_updated
    $daysSinceUpdate = [int](($Now - $lastUpd).TotalDays)
    if ($daysSinceUpdate -le 7) { return $false }

    # Not stale if explicitly active
    if ($Entry.status -eq 'red') { return $false }        # Red items always fresh
    if ($Entry.action_class -eq 'DO' -or $Entry.action_class -eq 'DECIDE') { return $false }

    # Stale rules
    if ($age -gt 30) { return $true }
    if ($daysSinceUpdate -gt 14) { return $true }
    return $false
}
```

### 3b. Filter enforcement — hide vs. exclude

- Stale items are **excluded from the priority inbox** (never appear).
- Stale items are **collapsed on Decision Watch / Risk Register** under a `Stale (N)` disclosure — one click to expand for context, but not surfaced by default.
- Stale items retain their `activity_log` and are re-eligible for surfacing the moment they are `updated_since_last_snapshot = true` (Phase 4).

### 3c. Real-corpus example

`R-cd89918f9c` (85 days old, vendor escalation, no updates in 60+ days) → `stale = true` under new rules → dropped from dashboard by default. Currently it shows as P1 imminent-escalation and clogs the inbox.

---

## 🟢 Phase 4 — Daily Delta System

### 4a. Snapshot storage

```
00-context/generated/snapshots/
  2026-07-17.json          <- today's full artifact bundle
  2026-07-16.json          <- yesterday
  2026-07-15.json
  ...                       <- rolling 30-day retention
  INDEX.json               <- {date, itemCount, addedIds, removedIds, changedIds}
```

Snapshot content = concat of all validated MatryoshkaItems (post-Phase 1) as a stable sorted array. Retention: last 30 days trimmed nightly.

### 4b. Delta computation

```powershell
function Get-DailyDelta {
    param([object[]] $Today, [object[]] $Yesterday)
    $ymap = @{}; foreach ($y in $Yesterday) { $ymap[$y.id] = $y }
    $tmap = @{}; foreach ($t in $Today)     { $tmap[$t.id] = $t }

    $added   = @($Today  | Where-Object { -not $ymap.ContainsKey($_.id) })
    $removed = @($Yesterday | Where-Object { -not $tmap.ContainsKey($_.id) })
    $changed = @($Today | Where-Object {
        $ymap.ContainsKey($_.id) -and
        (Get-ItemFingerprint $_) -ne (Get-ItemFingerprint $ymap[$_.id])
    })
    $stale = @($Today | Where-Object { $_.stale })

    return @{
        added   = $added
        removed = $removed
        changed = $changed
        stale   = $stale
        unchanged = @($Today | Where-Object {
            $ymap.ContainsKey($_.id) -and
            (Get-ItemFingerprint $_) -eq (Get-ItemFingerprint $ymap[$_.id]) -and
            -not $_.stale
        })
    }
}
```

`Get-ItemFingerprint` = SHA of `title|owner|status|next_action|last_updated` — content-only, ignores `activity_log` and `confidence_score`.

### 4c. Per-item metadata added to each item at emit time

Every item's `delta` object is populated:

```
delta: {
  days_since_last_touched: number;       // "Last touched: X days ago"
  updated_since_yesterday: boolean;      // "Updated since yesterday: YES/NO"
  change_summary?: string;               // e.g. "owner changed unassigned → Balaji Ravi"
}
```

### 4d. Dashboard rendering

- Every item card gets a small pill: `Updated today` (green) / `Updated 2d ago` (grey) / `No change 8d` (amber).
- New "Today's Movement" ribbon at top of Priority Inbox: `+3 new · 5 changed · 12 stale`.

---

## 🔵 Phase 5 — Context Linking

### 5a. `context_summary` generation (deterministic, no LLM)

```powershell
function Get-ContextSummary {
    param([string] $SourceFilePath, [string] $MatchedLine)
    if (-not (Test-Path $SourceFilePath)) { return '' }
    $content = Get-Content $SourceFilePath -Raw -Encoding UTF8
    # Find the matched line, capture 2 lines before + the line + 2 lines after
    $lines = ($content -replace "`r`n", "`n") -split "`n"
    $idx = [Array]::IndexOf($lines, ($lines | Where-Object { $_ -like "*$MatchedLine*" } | Select-Object -First 1))
    if ($idx -lt 0) { return '' }
    $start = [Math]::Max(0, $idx - 2)
    $end   = [Math]::Min($lines.Count - 1, $idx + 2)
    $summary = ($lines[$start..$end] -join ' ') -replace '\s+', ' '
    $summary = $summary.Trim()
    if ($summary.Length -gt 300) { $summary = $summary.Substring(0, 297) + '...' }
    return $summary
}
```

### 5b. `related_items` matching

```powershell
function Get-RelatedItems {
    param([hashtable] $Item, [object[]] $AllItems)
    $mine = @{
        ws     = [string]$Item.workstream
        tokens = @(Get-TitleTokens $Item.title) # normalized, stopword-filtered
    }
    $related = @()
    foreach ($other in $AllItems) {
        if ($other.id -eq $Item.id) { continue }
        $overlap = 0
        if ($other.workstream -eq $mine.ws -and $mine.ws) { $overlap += 2 }
        $otherTokens = @(Get-TitleTokens $other.title)
        $shared = @($mine.tokens | Where-Object { $otherTokens -contains $_ }).Count
        if ($shared -ge 2) { $overlap += $shared }
        if ($overlap -ge 3) { $related += $other.id }
    }
    return @($related | Select-Object -First 5)  # cap 5 to keep JSON compact
}
```

### 5c. Dashboard drill-down

- Each item card gets a **"Context" button** that opens a slide-in panel showing:
  - `context_summary`
  - Link to `source` (opens `01-inbox/...` or `02-work/...` in VS Code via `vscode://file/{abs-path}`)
  - Chips for each `related_items` ID — click to jump
- Any Teams-chat URL in the source (like the Cost/setup-issues chat from live-test) becomes a `source_uri` on the corresponding item, rendered as a clickable link.

---

## 🟣 Phase 6 — De-duplication + Confidence

### 6a. Fuzzy match on titles

```powershell
function Get-DuplicateGroups {
    param([object[]] $Items)
    $groups = @{}  # normKey -> [item, item, ...]
    foreach ($it in $Items) {
        $norm = Get-NormalizedTitle -Title $it.title  # already exists as V3.0 helper
        $tokens = @(Get-TitleTokens $it.title) | Sort-Object
        # Use Jaccard against every existing group representative
        $matched = $false
        foreach ($k in @($groups.Keys)) {
            $rep = $groups[$k][0]
            $repTokens = @(Get-TitleTokens $rep.title) | Sort-Object
            $intersection = @($tokens | Where-Object { $repTokens -contains $_ }).Count
            $union = ($tokens + $repTokens | Sort-Object -Unique).Count
            $jaccard = if ($union -gt 0) { $intersection / $union } else { 0 }
            if ($jaccard -ge 0.6 -and $rep.workstream -eq $it.workstream -and $rep.type -eq $it.type) {
                $groups[$k] += $it
                $matched = $true
                break
            }
        }
        if (-not $matched) { $groups[$it.id] = @($it) }
    }
    return $groups.Values | Where-Object { $_.Count -gt 1 }
}
```

### 6b. Merge semantics

For each group:

- **Keep** the item with the most recent `last_updated`.
- **Merge**: `merged_from` array gets the other IDs; `activity_log` concatenated; `source` becomes the primary source (newest); `confidence_score` recomputed as below; `context_summary` from the newest source.
- All merged items are removed from the item set (they still exist historically in yesterday's snapshot for delta comparison).

### 6c. Confidence formula (V4.0 unified)

```
confidence_score = clamp01(
    0.4 * owner_confidence_weight        # high=1.0, medium=0.5, low=0.0
  + 0.3 * min(1, log10(mention_count+1)/log10(6))  # asymptotes at 5 mentions
  + 0.2 * recency_weight                 # 1.0 if <=7d, linearly decays to 0 at 30d
  + 0.1 * source_quality_weight          # tasks.md/decisions.md=1.0, meeting=0.7, inbox archive=0.4
)
```

### 6d. Real-corpus example

Three items `R-b493137b8f`, `R-bafab65c68`, `R-d7f568105f` — from live-test they're all *"Ingenium desktop rehearsal"*. After Phase 6 they merge into **one** MatryoshkaItem with:

- `title: "Convert Ingenium desktop rehearsal into tracked Rapid Recovery validation event"`
- `merged_from: ["R-bafab65c68","R-d7f568105f"]`
- `confidence_score: 0.87` (3 mentions boost it)
- `activity_log`: entries from all three source mentions

Priority Inbox goes from 3 redundant rows to 1 high-confidence row.

---

## ⚫ Phase 7 — Ownership Correction

### 7a. Removal of default-assignment behavior

Current V3.0 (from `scripts/generate-current-focus.ps1`):

```powershell
# CURRENT
if ($mapEntry -and $mapEntry.owner) {
    $e.owner = $mapEntry.owner              # Balaji auto-assigned from workstream-map
    $e.ownerConfidence = 'workstream-map'
}
```

V4.0 change — **workstream ownership becomes a *suggestion*, not an assignment**:

```powershell
# V4.0
if ($e.owner) {
    # explicit name in source context — trust it
    $e.owner_confidence = 'medium'  # name-proximity
} elseif ($mapEntry -and $mapEntry.owner) {
    $e.owner = 'Unassigned'
    $e.suggested_owner = $mapEntry.owner
    $e.owner_confidence = 'low'     # workstream-map is a suggestion, not truth
} else {
    $e.owner = 'Unassigned'
    $e.owner_confidence = 'low'
}
# High confidence only when confirmed by explicit **Owner:** marker in source
if ($outcomeContext -match '(?im)^\s*\*\*Owner:\*\*\s*(.+)$') {
    $e.owner = $Matches[1].Trim()
    $e.owner_confidence = 'high'
}
```

### 7b. Dashboard rendering change

- `Unassigned` shows in slate with a **"Suggested: Balaji Ravi"** subtitle when there's a workstream-map hit.
- `owner_confidence: low` items show a **"Confirm owner"** button that opens a small form to record `**Owner:** X` back into the source file.
- Old `workstream-map` badge (green) is retired — that confidence level was misleading.

### 7c. Real-corpus impact

The "Balaji is over-attributed" complaint from live-test feedback disappears. Balaji is now `suggested_owner` on Rapid Recovery items and `owner` only on items where his name literally appears in the source paragraph. Estimated corpus impact: 8 of Balaji's current 11 items downgrade from confirmed to suggested — matching David's intuition.

---

## ⚪ Phase 8 — Reporting Pipeline Fix

### 8a. Root-cause of the 0-byte recap issue

From live-test log: *"Manually created file in `01-inbox/copilot-activity/2026-07-17-14-day-activity.md` and copied the copilot md."* — the file was created but the copy step failed silently. The generator saw it (mtime new, hash new), marked it processed, then left a 0-byte "processed" file until manually fixed.

### 8b. Fixes

**Fix 1 — 0-byte guard in the orchestrator**:

```powershell
if ($latest.Length -eq 0) {
    Write-Log "WARNING: Latest recap is 0 bytes — skipping. Fill in file and retry."
    $Health.status = 'warn'
    $Health.message = "Latest recap '$($latest.Name)' is 0 bytes."
    return  # do NOT mark as processed, do NOT update state
}
```

So the recap stays "unprocessed" until it has real content. Next run then re-fires when the file is filled in.

**Fix 2 — Copilot recap fetch automation**:
Create `scripts/fetch-copilot-recap.ps1` that:

1. Opens a browser to the M365 Copilot prompt (URL to be captured from the workflow)
2. Waits for response, extracts markdown from the response DOM (via Playwright / Puppeteer or clipboard poll)
3. Writes to `01-inbox/copilot-activity/{today}-14-day-activity.md`

This is the ~10 min Step 1 in the live-test log. Requires capturing the M365 Copilot URL + the DOM selector for the response text. Deferred until confirmed.

**Fix 3 — Weekly report generator from structured data**:

```powershell
# scripts/generate-weekly-report.ps1 (NEW)
# Consumes 00-context/generated/matryoshka-items.json (Phase 1 output)
# Emits 03-reporting/weekly/2026-W{NN}.md
#
# Template + slot-fills per objective / workstream, using:
#   - This week's added/changed items (from Phase 4 delta)
#   - Status = red items surfaced as [ISSUE] blocks
#   - Confidence >= 0.7 items only (drops noise)
#   - Owner rendered per Phase 7 rules
```

Removes the ~45 min Step 2 in the live-test log. Requires chat-approval for tone/framing (like the W29 iteration), but the structural draft is generated automatically.

---

## 📋 Before / After — three real items

### Item A — the redundant Ingenium risks

**Before (V3.1 corpus, today)**:

```
Priority Inbox:
  P1 Escalate: Convert Ingenium desktop rehearsal into a tracked Rapid Recovery... [R-b493137b8f]
    owner: Balaji Ravi  (workstream-map)  confidence: 0.79  escalate: today
  P1 Escalate: The Ingenium rehearsal scope includes monitoring, team handover... [R-bafab65c68]
    owner: Balaji Ravi  (workstream-map)  confidence: 0.79  escalate: today
  P1 Escalate: Convert Ingenium desktop rehearsal into tracked event... [R-d7f568105f]
    owner: Balaji Ravi  (workstream-map)  confidence: 0.79  escalate: today
```

Three redundant rows, all attributed to Balaji by workstream-map default. From feedback: *"3 items are effectively redundant"*.

**After (V4.0)**:

```
Priority Inbox:
  [FOLLOW_UP] status:red  Convert Ingenium desktop rehearsal into a tracked event  [MAT-a1b2c3]
    owner: Unassigned   suggested: Balaji Ravi   confidence: 0.87  (3 mentions merged)
    why_it_matters: Ingenium is the Gold-app RRP pilot; unrehearsed RRPs default to unusable.
    next_action:    Confirm with Balaji whether Jonan/MIM are locked in for the rehearsal date.
    related_items:  [MAT-x8y9z0 T145]
    merged_from:    [R-b493137b8f, R-bafab65c68, R-d7f568105f]
    context: [Context ▸]   source: 01-inbox/archive/20260714-…md#L138
    delta: Updated today   Last touched: 0d
```

One row, higher confidence, honest owner, one-click drill-down.

### Item B — the 85-day vendor escalation

**Before (V3.1)**:

```
Priority Inbox:
  P1 Escalate: Standardization of templates, CI identification... [R-cd89918f9c]
    owner: Unassigned  confidence: 0.09  aging: 85d  escalate: today
```

Live-test comment: *"I don't remember what this vendor escalation thing refers to (85 day aging)"*. Yet it's in the P1 inbox forcing attention.

**After (V4.0)**:

```
(item removed from Priority Inbox — stale=true, aging 85d, no updates in 60d, action_class=BLOCKED)
Under "Stale (14)" disclosure on Risk Register:
  MAT-f386376   Standardization of templates, CI identification...   85d stale
```

Off the priority surface. Recoverable via disclosure if reviewed later, but not costing daily attention.

### Item C — a Balaji over-attribution

**Before (V3.1)**:

```
D-0ac2a0c612  Capacity Management CMDB scope
  owner: Balaji Ravi  ownerConfidence: workstream-map  (green pill — "high confidence")
```

Live-test comment: *"Balaji is listed as owner for most items but that doesn't seem right"*. The green pill implied confirmed ownership when the assignment came only from a workstream lookup.

**After (V4.0)**:

```
MAT-0ac2a06  Capacity Management CMDB scope
  owner: Unassigned   suggested: Balaji Ravi   confidence: low
  [Confirm owner ▸] button
  why_it_matters: Capacity Management milestones depend on which CIs are in scope.
  next_action: Decide the CI scope for CAP-48585 phase 1 (Balaji / Rasheersh conversation).
  action_class: DECIDE
```

Honest state, path to correct it (Confirm owner button), clear next action instead of Escalate.

---

## ⚙️ Assumptions

1. **Backward compat**: existing V3.x artifacts (decision-registry.json, risk-register.json, david-inbox.json) stay produced during the migration window (V4.0 emits `matryoshka-items.json` as the new canonical, and the V3.x builders wrap it). Dashboard tabs can migrate one at a time.
2. **No LLM at emit time** — everything above is deterministic pattern-matching so the pipeline stays reproducible and cheap (<10s to regenerate). LLM-authored `context_summary` is an optional Phase 5b upgrade.
3. **Ownership map keeps existing `00-context/ownership-map.yaml`** but its meaning changes: it produces `suggested_owner`, never `owner`. No file edits required.
4. **Rejected items don't fail the run**. `rejected-items.md` grows; David reviews it weekly and either fixes source content or accepts the exclusion.
5. **Snapshot storage** stays local (in `00-context/generated/snapshots/`) with 30-day retention. Git-tracked. Not enough volume to warrant separate storage.
6. **Delta detection is content-hash based** — activity_log churn doesn't count as a "change" (avoids false positives).

---

## 🚦 Recommended implementation order

Sequenced as smallest reversible increments first:

| Sprint | Phase | Est. size | Payoff |
|---|---|---|---|
| **10a** | **7 + 8a** | ~150 LOC | Balaji over-attribution stops immediately + 0-byte recap bug fixed. High signal-to-effort. |
| **10b** | **2** | ~200 LOC | Kills "Escalate everywhere". Requires classifier + verb-mapping table + migration of existing items. |
| **10c** | **3** | ~100 LOC | Old stale items disappear from inbox. |
| **11a** | **1 + validator** | ~400 LOC | The canonical schema + rejection log. Everything downstream benefits. |
| **11b** | **6** | ~250 LOC | De-dup the Ingenium-style clusters. |
| **12a** | **4** | ~350 LOC | Daily delta + snapshot infrastructure + dashboard "movement" ribbon. |
| **12b** | **5** | ~300 LOC + UI | Context linking + click-through drill-down. |
| **13** | **8b, 8c** | ~500 LOC + Playwright | Copilot recap fetch + structured weekly report generator. |

Total: ~7 packages across 4 sprints. Sprint 10a alone probably solves 40% of the live-test friction.

---

## 📎 Deliverable summary (against prompt's output requirements)

| Requirement | Where covered |
|---|---|
| 1. Updated schema definition | Phase 1a — TypeScript `MatryoshkaItem` |
| 2. Transformation logic | Phase 1b + Phase 2b + Phase 6b + Phase 7 |
| 3. Filtering rules implementation | Phase 3a-b (stale) + Phase 1 (validation reject) |
| 4. Delta tracking implementation approach | Phase 4a-d |
| 5. Example before/after for 3 items | Items A / B / C above (real IDs from live-test) |
| 6. Assumptions clearly stated | "Assumptions" section above |
