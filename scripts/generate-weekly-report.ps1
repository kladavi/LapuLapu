<#
.SYNOPSIS
  V4.0 Sprint 14 (Phase 8c): Structural weekly-report draft generator.

.DESCRIPTION
  Consumes the canonical Matryoshka JSON outputs and produces a structured
  weekly-report draft at 03-reporting/weekly/YYYY-WNN.md.

  Reads:
    00-context/generated/current-focus.json    (workstream categories + health)
    00-context/generated/decision-registry.json (decisions with priority scores)
    00-context/generated/risk-register.json    (risks with priority scores)
    00-context/generated/david-inbox.json      (ranked action items)
    00-context/generated/snapshots/INDEX.json  (delta baseline)

  Emits:
    03-reporting/weekly/YYYY-WNN.md   (status='DRAFT' unless -Final)

  Filtering rules:
    - Confidence gate: only items with unifiedConfidence >= 0.7 are surfaced.
    - Workstream sections: P1 workstreams get a dedicated section; P2 / Watch /
      ParkingLot roll into "Additional related work".
    - [ISSUE] blocks: red-status items with High severity or breached deadlines.
    - [NEW] tags: items added within the report week (delta.daysSinceLastTouched
      <= 7 AND delta.changeSummary == 'first appearance').
    - Watchlist: top 6 attentionRequired items excluding items already flagged
      [ISSUE].

  This produces a *structural draft*. David still edits for tone, framing,
  and any editorial context before publishing.

.PARAMETER WeekOf
  Any date within the target week (defaults to today). ISO week is computed
  from this.

.PARAMETER OutputPath
  Optional override for the emitted markdown path. Defaults to
  03-reporting/weekly/YYYY-WNN.md.

.PARAMETER Final
  When set, emits status='FINAL' in the frontmatter (still a draft though;
  reviewer just marks it as reviewed).

.EXAMPLE
  pwsh -File scripts/generate-weekly-report.ps1
  # Emits 03-reporting/weekly/2026-W29.md as a draft.

.EXAMPLE
  pwsh -File scripts/generate-weekly-report.ps1 -WeekOf '2026-07-24'
  # Emits the W30 report.
#>

[CmdletBinding()]
param(
    [datetime] $WeekOf = (Get-Date),
    [string]   $OutputPath = '',
    [switch]   $Final,
    [double]   $ConfidenceGate = 0.7
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent $PSScriptRoot
$GEN  = Join-Path $ROOT '00-context\generated'
$OUT_DIR = Join-Path $ROOT '03-reporting\weekly'

# --- Helpers ----------------------------------------------------------------

function Get-IsoWeek {
    <#
        Returns @{ year = <int>; week = <int>; label = 'YYYY-WNN'; monday = <datetime>; friday = <datetime> }.
        ISO 8601 week: week 1 is the one containing the first Thursday of the year.
    #>
    param([datetime] $Date)

    $cal = [System.Globalization.CultureInfo]::InvariantCulture.Calendar
    $week = $cal.GetWeekOfYear($Date, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [System.DayOfWeek]::Monday)
    # ISO year drifts around Jan/Dec boundaries; pin it by walking to the week's Thursday.
    $dow = [int]$Date.DayOfWeek; if ($dow -eq 0) { $dow = 7 }   # Sun=7 in ISO
    $thursday = $Date.AddDays(4 - $dow)
    $isoYear  = $thursday.Year

    $monday = $Date.AddDays(1 - $dow)
    $friday = $monday.AddDays(4)

    return @{
        year   = $isoYear
        week   = $week
        label  = ("{0:D4}-W{1:D2}" -f $isoYear, $week)
        monday = $monday.Date
        friday = $friday.Date
    }
}

function Read-Json {
    param([string] $Path)
    if (-not (Test-Path $Path)) { throw "Required input not found: $Path" }
    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "Empty JSON at $Path" }
    return $raw | ConvertFrom-Json -Depth 20
}

function Format-Period {
    param([datetime] $Monday, [datetime] $Friday)
    $m = $Monday.ToString('MMM d')
    $f = $Friday.ToString('MMM d, yyyy')
    return "$m – $f"
}

function Test-ConfidenceGate {
    param($Item, [double] $Gate)
    # Always let High-severity items through regardless of confidence:
    # severity itself is a strong signal that trumps a low confidence score.
    if ($Item.PSObject.Properties['severity'] -and $Item.severity -eq 'High') { return $true }
    # Always let red-status items through: they are the [ISSUE] blocks the
    # weekly report is built around.
    if ($Item.PSObject.Properties['matryoshkaStatus'] -and $Item.matryoshkaStatus -eq 'red') { return $true }
    # V4.0 Sprint 16: priorityScore >= 60 is a stronger corroborated signal
    # than raw confidence (it already accounts for status, ownership, deadline,
    # engagement). Let those items through even when raw confidence is low.
    if ($Item.PSObject.Properties['priorityScore'] -and [int]$Item.priorityScore -ge 60) { return $true }

    $c = 0.0
    if ($Item.PSObject.Properties['unifiedConfidence'] -and $null -ne $Item.unifiedConfidence) {
        $c = [double]$Item.unifiedConfidence
    } elseif ($Item.PSObject.Properties['decisionConfidence'] -and $null -ne $Item.decisionConfidence) {
        $c = [double]$Item.decisionConfidence
    } elseif ($Item.PSObject.Properties['riskConfidence'] -and $null -ne $Item.riskConfidence) {
        $c = [double]$Item.riskConfidence
    }
    return ($c -ge $Gate)
}

function Test-NewThisWeek {
    param($Item)
    if ($null -eq $Item.delta) { return $false }
    $days = if ($Item.delta.daysSinceLastTouched) { [int]$Item.delta.daysSinceLastTouched } else { 999 }
    $summary = if ($Item.delta.changeSummary) { [string]$Item.delta.changeSummary } else { '' }
    return ($days -le 7 -and $summary -eq 'first appearance')
}

function Test-Issue {
    param($Item, [string] $Kind)
    if ($Item.matryoshkaStatus -ne 'red') { return $false }
    if ($Kind -eq 'risk' -and $Item.severity -eq 'High') { return $true }
    if ($Kind -eq 'decision' -and $Item.decisionDeadline) {
        $today = (Get-Date).ToString('yyyy-MM-dd')
        if ([string]$Item.decisionDeadline -lt $today) { return $true }
    }
    # BLOCKED action_class always counts as an [ISSUE]
    $act = if ($Kind -eq 'decision') { $Item.recommendedFollowUp } else { $Item.recommendedAction }
    if ($act -and $act.actionClass -eq 'BLOCKED') { return $true }
    return $false
}

function Get-OwnerText {
    param($Item)
    $owner = if ($Item.owner) { [string]$Item.owner } else { 'Unassigned' }
    if ($owner -match '(?i)^unassigned$' -and $Item.suggestedOwner) {
        return "Unassigned (suggested: $($Item.suggestedOwner))"
    }
    return $owner
}

function Get-BestNextAction {
    param($Item, [string] $Kind)
    $act = if ($Kind -eq 'decision') { $Item.recommendedFollowUp } else { $Item.recommendedAction }
    if ($act -and $act.nextAction) { return [string]$act.nextAction }
    if ($act -and $act.verb) { return [string]$act.verb }
    return ''
}

function Get-ShortContext {
    param($Item, [int] $MaxChars = 220)
    $ctx = if ($Item.contextSummary) { [string]$Item.contextSummary } else { '' }
    if (-not $ctx) {
        if ($Item.decisionSummary) { $ctx = [string]$Item.decisionSummary }
        elseif ($Item.impact) { $ctx = [string]$Item.impact }
    }
    $ctx = ($ctx -replace '\s+', ' ').Trim()
    if ($ctx.Length -gt $MaxChars) { $ctx = $ctx.Substring(0, $MaxChars - 1) + '…' }
    return $ctx
}

# --- Load inputs ------------------------------------------------------------

$iso = Get-IsoWeek -Date $WeekOf
Write-Host ("Generating weekly report draft: {0} ({1})" -f $iso.label, (Format-Period $iso.monday $iso.friday)) -ForegroundColor Cyan

$focus = Read-Json (Join-Path $GEN 'current-focus.json')
$inbox = Read-Json (Join-Path $GEN 'david-inbox.json')

# V4.0 Sprint 16: prefer the canonical matryoshka-items.json as the primary
# source of decision + risk records. Falls back to the V3 registries when the
# canonical file is missing (older generator versions).
$canonicalPath = Join-Path $GEN 'matryoshka-items.json'
$useCanonical  = Test-Path $canonicalPath

function ConvertFrom-CanonicalItem {
    <#
        Translates a canonical MatryoshkaItem (snake_case schema) back into a
        V3-registry-shaped object (camelCase) so the rest of this report
        generator can render both source types uniformly.
    #>
    param($Item, [string] $Kind)

    $out = [ordered]@{
        title             = [string]$Item.title
        workstream        = [string]$Item.workstream
        owner             = [string]$Item.owner
        suggestedOwner    = if ($Item.PSObject.Properties['suggested_owner']) { [string]$Item.suggested_owner } else { '' }
        ownerConfidence   = [string]$Item.owner_confidence
        status            = [string]$Item.status
        contextSummary    = [string]$Item.context_summary
        whyItMatters           = [string]$Item.why_it_matters
        whyItMattersConfidence = if ($Item.PSObject.Properties['why_it_matters_confidence']) { [double]$Item.why_it_matters_confidence } else { 0.0 }
        whyItMattersSource     = if ($Item.PSObject.Properties['why_it_matters_source'])     { [string]$Item.why_it_matters_source }     else { 'none' }
        matryoshkaStatus       = [string]$Item.status
        matryoshkaStatusReason = [string]$Item.status_reason
        focusSignals      = $Item.focus_signals
        priorityScore     = [int]$Item.priority_score
        priorityReason    = [string]$Item.priority_reason
        priorityFactors   = $Item.priority_factors
        delta             = $Item.delta
        stale             = [bool]$Item.stale
        unifiedConfidence = [double]$Item.confidence_score
        # Synthesize an action shape so Get-BestNextAction still works
        recommendedFollowUp = if ($Kind -eq 'decision') { [ordered]@{ nextAction=[string]$Item.next_action; actionClass=[string]$Item.action_class } } else { $null }
        recommendedAction   = if ($Kind -eq 'risk')     { [ordered]@{ nextAction=[string]$Item.next_action; actionClass=[string]$Item.action_class } } else { $null }
    }
    if ($Kind -eq 'decision') {
        $out.decisionId       = [string]$Item.id
        $out.decisionAgeDays  = [int]$Item.aging_days
        $out.decisionSummary  = [string]$Item.context_summary
        # V4.0 Sprint 16: canonical items preserve deadline + lifecycle status.
        $out.decisionDeadline = if ($Item.PSObject.Properties['decision_deadline'] -and $Item.decision_deadline) { [string]$Item.decision_deadline } else { '' }
        $out.decisionStatus   = if ($Item.PSObject.Properties['decision_status']   -and $Item.decision_status)   { [string]$Item.decision_status }   else { '' }
    } else {
        $out.riskId    = [string]$Item.id
        $out.agingDays = [int]$Item.aging_days
        $out.impact    = [string]$Item.context_summary
        # V4.0 Sprint 16: canonical items preserve type-specific fields (severity, trend).
        $out.severity  = if ($Item.PSObject.Properties['severity'] -and $Item.severity) { [string]$Item.severity } else { '' }
        $out.trend     = if ($Item.PSObject.Properties['trend']    -and $Item.trend)    { [string]$Item.trend }    else { '' }
        # Only synthesize severity from status when not carried through.
        if (-not $out.severity -and $Item.status -eq 'red') { $out.severity = 'High' }
    }
    return [PSCustomObject]$out
}

$allDecisions = @()
$allRisks     = @()

if ($useCanonical) {
    $items = Read-Json $canonicalPath
    $allDecisions = @(@($items.items) | Where-Object { $_ -and $_.type -eq 'decision' } | ForEach-Object { ConvertFrom-CanonicalItem -Item $_ -Kind 'decision' })
    $allRisks     = @(@($items.items) | Where-Object { $_ -and $_.type -eq 'risk'     } | ForEach-Object { ConvertFrom-CanonicalItem -Item $_ -Kind 'risk' })
    Write-Host ("  Source: matryoshka-items.json (canonical) - {0} decisions, {1} risks" -f $allDecisions.Count, $allRisks.Count) -ForegroundColor Cyan
} else {
    $decReg  = Read-Json (Join-Path $GEN 'decision-registry.json')
    $riskReg = Read-Json (Join-Path $GEN 'risk-register.json')
    $allDecisions = @($decReg.decisions) | Where-Object { $_ -and $_.status -ne 'closed' }
    $allRisks     = @($riskReg.risks)    | Where-Object { $_ -and $_.status -ne 'closed' }
    Write-Host ("  Source: V3 registries (fallback) - {0} decisions, {1} risks" -f $allDecisions.Count, $allRisks.Count) -ForegroundColor Yellow
}

# Apply confidence gate uniformly
$decisions = @($allDecisions | Where-Object { Test-ConfidenceGate -Item $_ -Gate $ConfidenceGate })
$risks     = @($allRisks     | Where-Object { Test-ConfidenceGate -Item $_ -Gate $ConfidenceGate })

Write-Host ("  Confidence gate ({0:P0}): decisions {1}/{2}, risks {3}/{4}" -f `
    $ConfidenceGate, $decisions.Count, $allDecisions.Count, $risks.Count, $allRisks.Count) -ForegroundColor Yellow

# --- Group by workstream ---------------------------------------------------

$wsIndex = @{}
foreach ($ws in @($focus.workstreams)) {
    $wsIndex[[string]$ws.name] = $ws
}

function Group-ByWorkstream {
    param([object[]] $Items)
    $groups = @{}
    foreach ($it in $Items) {
        $ws = if ($it.workstream) { [string]$it.workstream } else { '(unassigned)' }
        if (-not $groups.ContainsKey($ws)) { $groups[$ws] = [System.Collections.Generic.List[object]]::new() }
        $groups[$ws].Add($it)
    }
    return $groups
}

$decByWs  = Group-ByWorkstream -Items $decisions
$riskByWs = Group-ByWorkstream -Items $risks

# --- Render sections --------------------------------------------------------

$distribution = @('Birger','Hari','Kelvin','Jonan','Deb','Balaji','Joan','Harish')
$distJson     = ($distribution | ForEach-Object { '"' + $_ + '"' }) -join ','
$statusText   = if ($Final) { 'FINAL' } else { 'DRAFT' }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('project: "lapu-lapu"')
[void]$sb.AppendLine(('weekId: "{0}"' -f $iso.label))
[void]$sb.AppendLine(('period: "{0}"' -f (Format-Period $iso.monday $iso.friday)))
[void]$sb.AppendLine(('distribution: [{0}]' -f $distJson))
[void]$sb.AppendLine(('status: "{0}"' -f $statusText))
[void]$sb.AppendLine(('generatedBy: "scripts/generate-weekly-report.ps1"'))
[void]$sb.AppendLine(('generatedAt: "{0}"' -f (Get-Date).ToString('yyyy-MM-dd HH:mm')))
[void]$sb.AppendLine('---')
[void]$sb.AppendLine()
[void]$sb.AppendLine('# Weekly Project Status Report — Lapu-Lapu')
[void]$sb.AppendLine()
[void]$sb.AppendLine('**Project:** Lapu-Lapu')
[void]$sb.AppendLine(('**Week Ending:** {0} {1}' -f $iso.label, $iso.friday.ToString('MMMM d, yyyy')))
[void]$sb.AppendLine()
[void]$sb.AppendLine('---')

# --- Executive Summary skeleton --------------------------------------------
[void]$sb.AppendLine()
[void]$sb.AppendLine('**Executive Summary**')
[void]$sb.AppendLine()
[void]$sb.AppendLine('> _This section is a structural placeholder. Fill in with 2-3 sentence narrative per objective._')
[void]$sb.AppendLine()
foreach ($obj in @(
    'Frictionless Customer Experience',
    'Robust Technical Core',
    'Outstanding Colleague Experience',
    'Technology Transformation through AI & Automation'
)) {
    [void]$sb.AppendLine(('**{0}:** _(narrative)_' -f $obj))
    [void]$sb.AppendLine()
}
[void]$sb.AppendLine('---')

# --- Monitoring Status: per P1 workstream ----------------------------------
[void]$sb.AppendLine()
[void]$sb.AppendLine('**Monitoring Status** — Apps and transition activities')
[void]$sb.AppendLine()

$p1Workstreams = @($focus.workstreams | Where-Object { $_.category -eq 'P1' } | Sort-Object { -[double]$_.score })

foreach ($ws in $p1Workstreams) {
    $wsName = [string]$ws.name
    $wsDecisions = if ($decByWs.ContainsKey($wsName)) { @($decByWs[$wsName]) } else { @() }
    $wsRisks     = if ($riskByWs.ContainsKey($wsName)) { @($riskByWs[$wsName]) } else { @() }

    # Sort within workstream by priorityScore desc
    $wsDecisions = @($wsDecisions | Sort-Object { -[int]$_.priorityScore })
    $wsRisks     = @($wsRisks     | Sort-Object { -[int]$_.priorityScore })

    $healthBadge = ''
    if ($ws.health -and $ws.health.status) {
        $healthBadge = " [health: $($ws.health.status)]"
    }

    [void]$sb.AppendLine(('**{0}:**{1}' -f $wsName, $healthBadge))

    if ($wsDecisions.Count -eq 0 -and $wsRisks.Count -eq 0) {
        [void]$sb.AppendLine('_No high-confidence signals surfaced this week._')
        [void]$sb.AppendLine()
        continue
    }

    foreach ($d in ($wsDecisions | Select-Object -First 3)) {
        $tag = ''
        if (Test-Issue -Item $d -Kind 'decision') { $tag = '[ISSUE] ' }
        elseif (Test-NewThisWeek -Item $d)        { $tag = '[NEW] ' }
        $line = ('- {0}(decision) {1} — owner: {2}; score {3}' -f `
            $tag, ([string]$d.title), (Get-OwnerText $d), [int]$d.priorityScore)
        [void]$sb.AppendLine($line)
        $na = Get-BestNextAction -Item $d -Kind 'decision'
        if ($na) { [void]$sb.AppendLine(('  - Next: {0}' -f $na)) }
    }
    foreach ($r in ($wsRisks | Select-Object -First 3)) {
        $tag = ''
        if (Test-Issue -Item $r -Kind 'risk') { $tag = '[ISSUE] ' }
        elseif (Test-NewThisWeek -Item $r)   { $tag = '[NEW] ' }
        $line = ('- {0}(risk/{1}) {2} — owner: {3}; score {4}' -f `
            $tag, ([string]$r.severity), ([string]$r.title), (Get-OwnerText $r), [int]$r.priorityScore)
        [void]$sb.AppendLine($line)
        $na = Get-BestNextAction -Item $r -Kind 'risk'
        if ($na) { [void]$sb.AppendLine(('  - Next: {0}' -f $na)) }
    }
    [void]$sb.AppendLine()
}

[void]$sb.AppendLine('---')

# --- Additional related work: P2 / Watch, plus all [ISSUE] blocks ---------
[void]$sb.AppendLine()
[void]$sb.AppendLine('**Additional related work**')
[void]$sb.AppendLine()

$otherWs = @($focus.workstreams | Where-Object { $_.category -in @('P2','Watch') } | Sort-Object { -[double]$_.score })

foreach ($ws in $otherWs) {
    $wsName = [string]$ws.name
    $wsDecisions = if ($decByWs.ContainsKey($wsName)) { @($decByWs[$wsName]) } else { @() }
    $wsRisks     = if ($riskByWs.ContainsKey($wsName)) { @($riskByWs[$wsName]) } else { @() }
    if ($wsDecisions.Count -eq 0 -and $wsRisks.Count -eq 0) { continue }

    $wsDecisions = @($wsDecisions | Sort-Object { -[int]$_.priorityScore })
    $wsRisks     = @($wsRisks     | Sort-Object { -[int]$_.priorityScore })

    [void]$sb.AppendLine(('**{0}** _({1})_:' -f $wsName, $ws.category))
    foreach ($d in ($wsDecisions | Select-Object -First 2)) {
        $tag = ''
        if (Test-Issue -Item $d -Kind 'decision') { $tag = '[ISSUE] ' }
        elseif (Test-NewThisWeek -Item $d)        { $tag = '[NEW] ' }
        [void]$sb.AppendLine(('- {0}(decision) {1} — score {2}' -f $tag, ([string]$d.title), [int]$d.priorityScore))
    }
    foreach ($r in ($wsRisks | Select-Object -First 2)) {
        $tag = ''
        if (Test-Issue -Item $r -Kind 'risk') { $tag = '[ISSUE] ' }
        elseif (Test-NewThisWeek -Item $r)   { $tag = '[NEW] ' }
        [void]$sb.AppendLine(('- {0}(risk/{1}) {2} — score {3}' -f $tag, ([string]$r.severity), ([string]$r.title), [int]$r.priorityScore))
    }
    [void]$sb.AppendLine()
}

[void]$sb.AppendLine('---')

# --- Watchlist: top attention items for next week --------------------------
[void]$sb.AppendLine()
[void]$sb.AppendLine(('**Watchlist for W{0:D2}**' -f ($iso.week + 1)))
[void]$sb.AppendLine()

$attentionPool = @(
    @($decisions | ForEach-Object {
        [PSCustomObject]@{
            kind = 'decision'
            item = $_
            score = [int]$_.priorityScore
        }
    })
    @($risks | ForEach-Object {
        [PSCustomObject]@{
            kind = 'risk'
            item = $_
            score = [int]$_.priorityScore
        }
    })
) | Where-Object {
    $_.item.focusSignals -and $_.item.focusSignals.attentionRequired -and -not (Test-Issue -Item $_.item -Kind $_.kind)
}
$attentionPool = @($attentionPool | Sort-Object { -$_.score } | Select-Object -First 6)

if ($attentionPool.Count -eq 0) {
    [void]$sb.AppendLine('_No attentionRequired items above confidence gate._')
} else {
    foreach ($row in $attentionPool) {
        $it = $row.item
        $wsLabel = if ($it.workstream) { "[$($it.workstream)] " } else { '' }
        [void]$sb.AppendLine(('- {0}{1} ({2}, score {3})' -f $wsLabel, [string]$it.title, $row.kind, $row.score))
    }
}

[void]$sb.AppendLine()
[void]$sb.AppendLine('---')

# --- Delta ribbon (this week's added / changed) ----------------------------
if ($inbox.dailyDelta) {
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('**This week — Delta ribbon**')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine(('- Added: {0}' -f $inbox.dailyDelta.addedCount))
    [void]$sb.AppendLine(('- Changed: {0}' -f $inbox.dailyDelta.changedCount))
    [void]$sb.AppendLine(('- Removed: {0}' -f $inbox.dailyDelta.removedCount))
    [void]$sb.AppendLine(('- Stale: {0}' -f $inbox.dailyDelta.staleCount))
    if ($inbox.dailyDelta.comparedAgainst) {
        [void]$sb.AppendLine(('- Baseline: {0}' -f $inbox.dailyDelta.comparedAgainst))
    }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('---')
}

# --- Project Resources (static) --------------------------------------------
[void]$sb.AppendLine()
[void]$sb.AppendLine('Project Resources')
[void]$sb.AppendLine()
[void]$sb.AppendLine('🔗 [Confluence — GOCC Japan (Lapu-Lapu)](https://manulife-ets.atlassian.net/wiki/x/XoCRtgM)')
[void]$sb.AppendLine('🧩 [Jira — LPLP Project Board](https://manulife-ets.atlassian.net/jira/software/c/projects/LPLP/issues?jql=project+%3D+LPLP+ORDER+BY+created+DESC)')
[void]$sb.AppendLine('📊 [Ops Dashboard — Power BI](https://app.powerbi.com/links/-UO6N0K4_L?ctid=5d3e2773-e07f-4432-a630-1a0f68a28a05&pbi_source=linkShare)')
[void]$sb.AppendLine('📁 [SharePoint — ETS Japan Program Delivery](https://mfc.sharepoint.com/:f:/r/sites/ets-japan/Program%20Delivery/Lapu-Lapu?csf=1&web=1&e=OldAiG)')
[void]$sb.AppendLine()
[void]$sb.AppendLine('---')
[void]$sb.AppendLine()
[void]$sb.AppendLine('Prepared by: David Klan · Manulife Enterprise Technology Services')

# --- Write --------------------------------------------------------------------

if (-not $OutputPath) {
    $OutputPath = Join-Path $OUT_DIR ("{0}.md" -f $iso.label)
}
$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# Do NOT clobber a FINAL report - only overwrite drafts.
if ((Test-Path $OutputPath) -and -not $Final) {
    $existing = Get-Content -Path $OutputPath -Raw -Encoding UTF8
    if ($existing -match '(?im)^status:\s*"?FINAL"?') {
        $backup = "$OutputPath.draft-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        [System.IO.File]::WriteAllText($backup, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
        Write-Host ("Existing FINAL report preserved; draft written to {0}" -f $backup) -ForegroundColor Yellow
        return
    }
}

[System.IO.File]::WriteAllText($OutputPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
$rel = $OutputPath.Replace($ROOT, '').TrimStart('\','/')
Write-Host ("Written: {0}" -f $rel) -ForegroundColor Green
