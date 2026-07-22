<#
.SYNOPSIS
  V4.0 Sprint 24: prepare Quartz-consumable markdown from canonical model.

.DESCRIPTION
  Reads 00-context/generated/matryoshka-items.json + matryoshka-index.json
  and emits Quartz-ready markdown under quartz-content/.

  Emitted structure:
    quartz-content/
      index.md                     home page
      workstreams/{id}.md          per-workstream landing pages
      decisions/{id}.md            per-decision detail pages
      risks/{id}.md                per-risk detail pages
      reports/{week-id}.md         copies of weekly reports

  Every page carries YAML frontmatter mapped from canonical fields per
  docs/quartz-deployment-decision.md Section D. Wiki-links (`[[...]]`) are
  emitted so Quartz's native backlink + graph features work out of the box.

  Canonical model is NOT modified - this script is a pure consumer.

.EXAMPLE
  pwsh -File scripts/prepare-quartz-content.ps1
#>

[CmdletBinding()]
param(
    [switch] $Clean
)

$ErrorActionPreference = 'Stop'
$ROOT       = Split-Path -Parent $PSScriptRoot
$GEN        = Join-Path $ROOT '00-context\generated'
$OUT_DIR    = Join-Path $ROOT 'quartz-content'
$ITEMS_JSON = Join-Path $GEN  'matryoshka-items.json'
$INDEX_JSON = Join-Path $GEN  'matryoshka-index.json'
$FOCUS_JSON = Join-Path $GEN  'current-focus.json'

# --- Helpers ----------------------------------------------------------------

function Read-JsonSafe {
    param([string] $Path)
    if (-not (Test-Path $Path)) { throw "Required file not found: $Path" }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    return $raw | ConvertFrom-Json -Depth 20
}

function ConvertTo-WorkstreamSlug {
    param([string] $Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return 'unassigned' }
    $s = $Name.ToLowerInvariant()
    $s = $s -replace '[^a-z0-9]+', '-'
    $s = $s.Trim('-')
    if (-not $s) { return 'unassigned' }
    return $s
}

function Escape-Yaml {
    param([string] $Value)
    if ($null -eq $Value) { return '' }
    return $Value -replace '"', '\"'
}

function Write-Utf8 {
    param([string] $Path, [string] $Content)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function New-Frontmatter {
    <#
        Emits a YAML frontmatter block from an ordered hashtable. Handles
        strings, ints, doubles, bools, and arrays deterministically.
    #>
    param([System.Collections.Specialized.OrderedDictionary] $Fields)
    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add('---')
    foreach ($k in $Fields.Keys) {
        $v = $Fields[$k]
        if ($null -eq $v) { continue }
        if ($v -is [array]) {
            if (@($v).Count -eq 0) { continue }
            $items = @($v) | ForEach-Object {
                if ($null -eq $_) { $null }
                else { '"' + (Escape-Yaml -Value ([string]$_)) + '"' }
            } | Where-Object { $_ }
            if (@($items).Count -eq 0) { continue }
            [void]$lines.Add(('{0}: [{1}]' -f $k, ($items -join ', ')))
        } elseif ($v -is [bool]) {
            [void]$lines.Add(('{0}: {1}' -f $k, ($v.ToString().ToLower())))
        } elseif ($v -is [int] -or $v -is [double] -or $v -is [long]) {
            [void]$lines.Add(('{0}: {1}' -f $k, $v))
        } else {
            $s = [string]$v
            if ([string]::IsNullOrWhiteSpace($s)) { continue }
            [void]$lines.Add(('{0}: "{1}"' -f $k, (Escape-Yaml -Value $s)))
        }
    }
    [void]$lines.Add('---')
    [void]$lines.Add('')
    return ($lines -join "`n")
}

# --- Load canonical model ---------------------------------------------------

Write-Host 'Loading canonical model (matryoshka-items.json + focus + index)...' -ForegroundColor Cyan
$items = Read-JsonSafe -Path $ITEMS_JSON
$index = Read-JsonSafe -Path $INDEX_JSON
$focus = Read-JsonSafe -Path $FOCUS_JSON

$allItems  = @($items.items)
$decisions = @($allItems | Where-Object { $_.type -eq 'decision' })
$risks     = @($allItems | Where-Object { $_.type -eq 'risk' })
$workstreams = @($focus.workstreams | Where-Object { $_ -and $_.name })

# V4.0 Sprint 25b: draft-aware navigation. An item is eligible for cross-link
# generation only if it is validated. Draft items are still emitted as pages
# (with draft:true frontmatter) but every workstream/home/backlink surface
# filters them out so that Quartz's remove-draft plugin does not create dead
# links. See quartz-pilot-review.md task 6 for the pre-fix failure mode.
$publishedIds = @{}
foreach ($it in $allItems) {
    if ($it.validated) { $publishedIds[[string]$it.id] = $true }
}
$publishedItems     = @($allItems  | Where-Object { $publishedIds.ContainsKey([string]$_.id) })
$publishedDecisions = @($decisions | Where-Object { $publishedIds.ContainsKey([string]$_.id) })
$publishedRisks     = @($risks     | Where-Object { $publishedIds.ContainsKey([string]$_.id) })
$draftCount         = $allItems.Count - $publishedItems.Count

Write-Host ("  items: {0} ({1} decisions, {2} risks)" -f $allItems.Count, $decisions.Count, $risks.Count) -ForegroundColor Cyan
Write-Host ("  published (link-eligible): {0} · draft (link-excluded): {1}" -f $publishedItems.Count, $draftCount) -ForegroundColor Cyan
Write-Host ("  workstreams: {0}" -f $workstreams.Count) -ForegroundColor Cyan

# --- Clean previous output --------------------------------------------------

if ($Clean -and (Test-Path $OUT_DIR)) {
    Write-Host "Cleaning previous quartz-content/ output..." -ForegroundColor Yellow
    Remove-Item -Path $OUT_DIR -Recurse -Force
}
if (-not (Test-Path $OUT_DIR)) { New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null }

# --- Build workstream slug map ----------------------------------------------

$wsSlugMap = @{}
foreach ($ws in $workstreams) {
    $wsSlugMap[[string]$ws.name] = ConvertTo-WorkstreamSlug -Name $ws.name
}

function Get-WorkstreamSlug {
    param([string] $Name)
    if ($wsSlugMap.ContainsKey($Name)) { return $wsSlugMap[$Name] }
    return (ConvertTo-WorkstreamSlug -Name $Name)
}

# --- Emit: per-item pages (decisions + risks) -------------------------------

$emittedItems     = 0
$emittedByType    = @{ decision = 0; risk = 0 }

function Build-ItemPage {
    param($It)
    $wsName = if ($It.workstream) { [string]$It.workstream } else { '' }
    $wsSlug = if ($wsName) { Get-WorkstreamSlug -Name $wsName } else { 'unassigned' }
    $ownerText = if ($It.owner) { [string]$It.owner } else { 'Unassigned' }
    $suggestedOwner = if ($It.suggested_owner) { [string]$It.suggested_owner } else { '' }

    $tags = [System.Collections.Generic.List[string]]::new()
    [void]$tags.Add(('type/' + [string]$It.type))
    if ($wsName) { [void]$tags.Add(('workstream/' + $wsSlug)) }
    if ($It.status)     { [void]$tags.Add(('status/'  + [string]$It.status)) }
    if ($It.action_class) { [void]$tags.Add(('action/' + ([string]$It.action_class).ToLower())) }
    if ($It.focus_signals -and $It.focus_signals.engaged)           { [void]$tags.Add('engaged') }
    if ($It.focus_signals -and $It.focus_signals.attentionRequired) { [void]$tags.Add('attention-required') }
    if ($It.focus_signals -and $It.focus_signals.awaitingOthers)    { [void]$tags.Add('awaiting-others') }

    $aliases = @()
    if ($It.merged_from -and @($It.merged_from).Count -gt 0) { $aliases = @($It.merged_from) }

    $actors = @()
    if ($It.context_metadata -and $It.context_metadata.actors) { $actors = @($It.context_metadata.actors) }

    $fm = [ordered]@{
        type       = [string]$It.type
        id         = [string]$It.id
        title      = [string]$It.title
        workstream = $wsName
        owner      = $ownerText
        status     = [string]$It.status
        weight     = [int]$It.priority_score
        aging_days = [int]$It.aging_days
        updated    = [string]$It.last_updated
        created    = [string]$It.first_seen
        tags       = @($tags)
    }
    if ($actors.Count -gt 0)  { $fm['people']  = @($actors) }
    if ($aliases.Count -gt 0) { $fm['aliases'] = @($aliases) }
    if (-not $It.validated)   { $fm['draft']   = $true }
    if ([string]$It.type -eq 'risk' -and $It.severity) { $fm['severity'] = [string]$It.severity }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append((New-Frontmatter -Fields $fm))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('# ' + [string]$It.title))
    [void]$sb.AppendLine('')

    # Status pill line
    $statusEmoji = switch ([string]$It.status) {
        'red'   { 'RED' }
        'amber' { 'AMBER' }
        'green' { 'GREEN' }
        default { 'UNKNOWN' }
    }
    [void]$sb.AppendLine(('**Status:** ' + $statusEmoji + '  ·  **Score:** ' + [int]$It.priority_score + '  ·  **Owner:** ' + $ownerText))
    if ($suggestedOwner -and $ownerText -match '(?i)^unassigned$') {
        [void]$sb.AppendLine(('_Suggested owner: ' + $suggestedOwner + '_'))
    }
    if ($wsName) {
        [void]$sb.AppendLine(('**Workstream:** [[workstreams/' + $wsSlug + '|' + $wsName + ']]'))
    }
    [void]$sb.AppendLine('')

    # Why it matters callout
    if ($It.why_it_matters) {
        [void]$sb.AppendLine('> [!info] Why it matters')
        [void]$sb.AppendLine(('> ' + ($It.why_it_matters -replace "`r?`n", ' ')))
        if ($It.why_it_matters_source -and $It.why_it_matters_source -ne 'none') {
            [void]$sb.AppendLine(('> _source: ' + [string]$It.why_it_matters_source + '  ·  confidence: ' + [Math]::Round([double]$It.why_it_matters_confidence, 2) + '_'))
        }
        [void]$sb.AppendLine('')
    }

    # Next action callout
    if ($It.next_action) {
        [void]$sb.AppendLine('> [!todo] Next action')
        [void]$sb.AppendLine(('> ' + [string]$It.next_action))
        if ($It.action_class) {
            [void]$sb.AppendLine(('> _class: **' + [string]$It.action_class + '**_'))
        }
        [void]$sb.AppendLine('')
    }

    # Priority reason bullets
    if ($It.priority_reason_bullets -and @($It.priority_reason_bullets).Count -gt 0) {
        [void]$sb.AppendLine('## Why this scored ' + [int]$It.priority_score)
        [void]$sb.AppendLine('')
        foreach ($b in @($It.priority_reason_bullets)) {
            [void]$sb.AppendLine('- ' + [string]$b)
        }
        [void]$sb.AppendLine('')
    }

    # Timeline
    [void]$sb.AppendLine('## Timeline')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('- First seen: ' + [string]$It.first_seen))
    [void]$sb.AppendLine(('- Last updated: ' + [string]$It.last_updated))
    [void]$sb.AppendLine(('- Aging: ' + [int]$It.aging_days + ' day(s)'))
    if ($It.delta -and $It.delta.changeSummary) {
        [void]$sb.AppendLine(('- Latest change: ' + [string]$It.delta.changeSummary))
    }
    [void]$sb.AppendLine('')

    # Context (from Phase 5 linking)
    if ($It.context_summary -and $It.context_summary -ne $It.why_it_matters) {
        [void]$sb.AppendLine('## Context')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine([string]$It.context_summary)
        [void]$sb.AppendLine('')
    }

    # Actors
    if ($actors.Count -gt 0) {
        [void]$sb.AppendLine('## Actors')
        [void]$sb.AppendLine('')
        foreach ($a in $actors) { [void]$sb.AppendLine('- ' + [string]$a) }
        [void]$sb.AppendLine('')
    }

    # Source
    if ($It.source) {
        [void]$sb.AppendLine('## Source')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('- `' + [string]$It.source + '`')
        [void]$sb.AppendLine('')
    }

    # Validation gaps (only shown for non-validated items)
    if (-not $It.validated -and $It.validation_errors -and @($It.validation_errors).Count -gt 0) {
        [void]$sb.AppendLine('## Validation gaps')
        [void]$sb.AppendLine('')
        foreach ($e in @($It.validation_errors)) {
            [void]$sb.AppendLine('- `' + [string]$e.field + '`: ' + [string]$e.reason)
        }
        [void]$sb.AppendLine('')
    }

    return $sb.ToString()
}

foreach ($it in $allItems) {
    $body = Build-ItemPage -It $it
    $sub  = if ($it.type -eq 'decision') { 'decisions' } else { 'risks' }
    $path = Join-Path $OUT_DIR (Join-Path $sub ([string]$it.id + '.md'))
    Write-Utf8 -Path $path -Content $body
    $emittedItems += 1
    $emittedByType[[string]$it.type] += 1
}
Write-Host ("Emitted {0} item pages ({1} decisions, {2} risks) under quartz-content/decisions|risks/" -f `
    $emittedItems, $emittedByType.decision, $emittedByType.risk) -ForegroundColor Green

# --- Emit: workstream landing pages -----------------------------------------

$emittedWs = 0
foreach ($ws in $workstreams) {
    $wsName = [string]$ws.name
    $wsSlug = Get-WorkstreamSlug -Name $wsName
    # V4.0 Sprint 25b: only published items are eligible for cross-links.
    $wsDec  = @($publishedDecisions | Where-Object { [string]$_.workstream -eq $wsName } | Sort-Object { -[int]$_.priority_score })
    $wsRisk = @($publishedRisks     | Where-Object { [string]$_.workstream -eq $wsName } | Sort-Object { -[int]$_.priority_score })
    $wsDecDraft  = @($decisions | Where-Object { [string]$_.workstream -eq $wsName -and -not $publishedIds.ContainsKey([string]$_.id) })
    $wsRiskDraft = @($risks     | Where-Object { [string]$_.workstream -eq $wsName -and -not $publishedIds.ContainsKey([string]$_.id) })

    $tags = [System.Collections.Generic.List[string]]::new()
    [void]$tags.Add('type/workstream')
    [void]$tags.Add(('workstream/' + $wsSlug))
    if ($ws.category) { [void]$tags.Add(('category/' + ([string]$ws.category).ToLower())) }

    $fm = [ordered]@{
        type       = 'workstream'
        id         = [string]$ws.id
        title      = $wsName
        category   = [string]$ws.category
        weight     = [int]$ws.score
        updated    = [string]$focus.generated
        tags       = @($tags)
    }
    if ($ws.health -and $ws.health.status) { $fm['health'] = [string]$ws.health.status }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append((New-Frontmatter -Fields $fm))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# ' + $wsName)
    [void]$sb.AppendLine('')

    $healthLine = 'Category: **' + [string]$ws.category + '**  ·  Score: **' + [double]$ws.score + '**'
    if ($ws.health -and $ws.health.status) { $healthLine += '  ·  Health: **' + [string]$ws.health.status + '**' }
    [void]$sb.AppendLine($healthLine)
    [void]$sb.AppendLine('')
    if ($ws.health -and $ws.health.reason) {
        [void]$sb.AppendLine('> ' + [string]$ws.health.reason)
        [void]$sb.AppendLine('')
    }

    if ($wsDec.Count -gt 0) {
        [void]$sb.AppendLine('## Open decisions (' + $wsDec.Count + ')')
        [void]$sb.AppendLine('')
        foreach ($d in $wsDec) {
            $line = ('- [[decisions/' + [string]$d.id + '|' + [string]$d.title + ']] · score ' + [int]$d.priority_score + ' · ' + [string]$d.status)
            [void]$sb.AppendLine($line)
        }
        [void]$sb.AppendLine('')
    }
    if ($wsRisk.Count -gt 0) {
        [void]$sb.AppendLine('## Open risks (' + $wsRisk.Count + ')')
        [void]$sb.AppendLine('')
        foreach ($r in $wsRisk) {
            $sev = if ($r.severity) { ' · ' + [string]$r.severity } else { '' }
            $line = ('- [[risks/' + [string]$r.id + '|' + [string]$r.title + ']] · score ' + [int]$r.priority_score + $sev)
            [void]$sb.AppendLine($line)
        }
        [void]$sb.AppendLine('')
    }
    if ($wsDec.Count -eq 0 -and $wsRisk.Count -eq 0) {
        [void]$sb.AppendLine('_No open decisions or risks._')
        [void]$sb.AppendLine('')
    }
    # V4.0 Sprint 25b: surface (but do not link to) draft items so a reader
    # knows the workstream has more in-flight material without seeing dead links.
    if ($wsDecDraft.Count -gt 0 -or $wsRiskDraft.Count -gt 0) {
        [void]$sb.AppendLine('## Draft items (excluded from links)')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('_The following items exist in the canonical model but have `validated: false` and are excluded from published navigation. They will surface once they pass validation._')
        [void]$sb.AppendLine('')
        foreach ($d in $wsDecDraft) {
            [void]$sb.AppendLine(('- **decision** `' + [string]$d.id + '` — ' + [string]$d.title))
        }
        foreach ($r in $wsRiskDraft) {
            [void]$sb.AppendLine(('- **risk** `' + [string]$r.id + '` — ' + [string]$r.title))
        }
        [void]$sb.AppendLine('')
    }

    $path = Join-Path $OUT_DIR (Join-Path 'workstreams' ($wsSlug + '.md'))
    Write-Utf8 -Path $path -Content $sb.ToString()
    $emittedWs += 1
}
Write-Host ("Emitted {0} workstream landing pages under quartz-content/workstreams/" -f $emittedWs) -ForegroundColor Green

# --- Emit: weekly report copies ---------------------------------------------

$reportSrc = Join-Path $ROOT '03-reporting\weekly'
$reportDstDir = Join-Path $OUT_DIR 'reports'
if (-not (Test-Path $reportDstDir)) { New-Item -ItemType Directory -Path $reportDstDir -Force | Out-Null }
$emittedReports = 0
if (Test-Path $reportSrc) {
    $reportFiles = @(Get-ChildItem -LiteralPath $reportSrc -File -Filter '*.md' -ErrorAction SilentlyContinue)
    foreach ($rf in $reportFiles) {
        $dest = Join-Path $reportDstDir $rf.Name
        Copy-Item -LiteralPath $rf.FullName -Destination $dest -Force
        $emittedReports += 1
    }
}
Write-Host ("Copied {0} weekly reports into quartz-content/reports/" -f $emittedReports) -ForegroundColor Green

# --- Emit: home page --------------------------------------------------------

# V4.0 Sprint 25b: top-10 draws from published items only. Draft items are
# not linkable and must not appear on the home page.
$topItems = @($publishedItems | Sort-Object { -[int]$_.priority_score } | Select-Object -First 10)
$p1Ws = @($workstreams | Where-Object { $_.category -eq 'P1' } | Sort-Object { -[double]$_.score })
$p2Ws = @($workstreams | Where-Object { $_.category -eq 'P2' } | Sort-Object { -[double]$_.score })
$watchWs = @($workstreams | Where-Object { $_.category -eq 'Watch' } | Sort-Object { -[double]$_.score })

$deltaLine = ''
try {
    $inbox = Read-JsonSafe -Path (Join-Path $GEN 'david-inbox.json')
    if ($inbox.dailyDelta) {
        $deltaLine = ('Added {0} · Changed {1} · Removed {2} · Stale {3} (baseline: {4})' -f `
            $inbox.dailyDelta.addedCount, $inbox.dailyDelta.changedCount, `
            $inbox.dailyDelta.removedCount, $inbox.dailyDelta.staleCount, `
            $inbox.dailyDelta.comparedAgainst)
    }
} catch { }

$homeFm = [ordered]@{
    type       = 'home'
    title      = 'Lapu-Lapu — Knowledge Portal'
    updated    = [string]$focus.generated
    tags       = @('type/home')
}
$homeSb = [System.Text.StringBuilder]::new()
[void]$homeSb.Append((New-Frontmatter -Fields $homeFm))
[void]$homeSb.AppendLine('')
[void]$homeSb.AppendLine('# Lapu-Lapu — Knowledge Portal')
[void]$homeSb.AppendLine('')
[void]$homeSb.AppendLine(('_Generated at ' + [string]$focus.generated + ' from `matryoshka-items.json`._'))
[void]$homeSb.AppendLine('')
if ($deltaLine) {
    [void]$homeSb.AppendLine('**Daily delta**: ' + $deltaLine)
    [void]$homeSb.AppendLine('')
}

[void]$homeSb.AppendLine('## Top 10 open items')
[void]$homeSb.AppendLine('')
foreach ($it in $topItems) {
    $sub = if ([string]$it.type -eq 'decision') { 'decisions' } else { 'risks' }
    [void]$homeSb.AppendLine(('- [[' + $sub + '/' + [string]$it.id + '|' + [string]$it.title + ']] · **' + [int]$it.priority_score + '** · ' + [string]$it.status + ' · ' + [string]$it.workstream))
}
[void]$homeSb.AppendLine('')

if ($p1Ws.Count -gt 0) {
    [void]$homeSb.AppendLine('## P1 workstreams')
    [void]$homeSb.AppendLine('')
    foreach ($ws in $p1Ws) {
        $wsSlug = Get-WorkstreamSlug -Name ([string]$ws.name)
        $healthTag = if ($ws.health -and $ws.health.status) { ' · ' + [string]$ws.health.status } else { '' }
        [void]$homeSb.AppendLine(('- [[workstreams/' + $wsSlug + '|' + [string]$ws.name + ']] · score ' + [double]$ws.score + $healthTag))
    }
    [void]$homeSb.AppendLine('')
}
if ($p2Ws.Count -gt 0) {
    [void]$homeSb.AppendLine('## P2 workstreams')
    [void]$homeSb.AppendLine('')
    foreach ($ws in $p2Ws) {
        $wsSlug = Get-WorkstreamSlug -Name ([string]$ws.name)
        [void]$homeSb.AppendLine(('- [[workstreams/' + $wsSlug + '|' + [string]$ws.name + ']] · score ' + [double]$ws.score))
    }
    [void]$homeSb.AppendLine('')
}
if ($watchWs.Count -gt 0) {
    [void]$homeSb.AppendLine('## Watch workstreams')
    [void]$homeSb.AppendLine('')
    foreach ($ws in $watchWs) {
        $wsSlug = Get-WorkstreamSlug -Name ([string]$ws.name)
        [void]$homeSb.AppendLine(('- [[workstreams/' + $wsSlug + '|' + [string]$ws.name + ']] · score ' + [double]$ws.score))
    }
    [void]$homeSb.AppendLine('')
}

[void]$homeSb.AppendLine('## Reports')
[void]$homeSb.AppendLine('')
if ($emittedReports -gt 0) {
    $repList = @(Get-ChildItem -LiteralPath (Join-Path $OUT_DIR 'reports') -File -Filter '*.md' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    foreach ($rf in $repList) {
        [void]$homeSb.AppendLine('- [[reports/' + $rf.BaseName + '|' + $rf.BaseName + ']]')
    }
} else {
    [void]$homeSb.AppendLine('_No weekly reports yet._')
}
[void]$homeSb.AppendLine('')
[void]$homeSb.AppendLine('---')
[void]$homeSb.AppendLine('')
[void]$homeSb.AppendLine('_Home page auto-generated by `scripts/prepare-quartz-content.ps1`. Do not edit._')

Write-Utf8 -Path (Join-Path $OUT_DIR 'index.md') -Content $homeSb.ToString()
Write-Host 'Emitted quartz-content/index.md (home page).' -ForegroundColor Green

# --- Summary ----------------------------------------------------------------

Write-Host ''
Write-Host ('Quartz content preparation complete:') -ForegroundColor Cyan
Write-Host ('  {0} items · {1} workstreams · {2} reports · 1 home' -f `
    $emittedItems, $emittedWs, $emittedReports) -ForegroundColor Cyan
Write-Host ('  output: quartz-content/') -ForegroundColor Cyan
Write-Host ''
Write-Host 'Next steps (deferred per docs/quartz-deployment-decision.md):' -ForegroundColor Yellow
Write-Host '  1. Choose hosting (A1/A2/A3/A4)' -ForegroundColor Yellow
Write-Host '  2. git clone https://github.com/jackyzha0/quartz.git quartz-site' -ForegroundColor Yellow
Write-Host '  3. Point quartz-site/content/ at quartz-content/' -ForegroundColor Yellow
Write-Host '  4. cd quartz-site && npm install && npx quartz build --serve' -ForegroundColor Yellow
