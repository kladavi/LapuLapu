#Requires -Version 5.1
<#
.SYNOPSIS
    Project Matryoshka V1.1 — Current Focus Dashboard generator.
.DESCRIPTION
    Reads workstreams, overrides, and scoring model from 00-context/.
    Scans corpus text files for workstream activity signals.
    Writes 00-context/generated/current-focus.md and current-focus.json.
    Safe to run repeatedly. No external dependencies required.
.INPUTS
    00-context/workstreams.yaml
    00-context/priority-overrides.yaml
    00-context/scoring-model.yaml
    01-inbox/, 01-inbox/copilot-activity/, 02-work/, 03-reporting/weekly/, docs/
.OUTPUTS
    00-context/generated/current-focus.md
    00-context/generated/current-focus.json
.NOTES
    Pure PowerShell — no external modules required.
    YAML parsing is targeted to the known structure of these control files.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT     = Split-Path $PSScriptRoot -Parent
$CTX      = Join-Path $ROOT '00-context'
$GEN      = Join-Path $CTX  'generated'
$OUT_MD   = Join-Path $GEN  'current-focus.md'
$OUT_JSON = Join-Path $GEN  'current-focus.json'

$SCAN_FOLDERS = @(
    '00-context',
    '01-inbox',
    (Join-Path '01-inbox' 'copilot-activity'),
    '02-work',
    (Join-Path '03-reporting' 'weekly'),
    'docs'
)

$BINARY_EXTS = @('.png','.jpg','.jpeg','.gif','.bmp','.pdf',
                 '.docx','.xlsx','.pptx','.zip','.exe','.dll')

# ─── YAML Parsers ─────────────────────────────────────────────────────────────

function Read-FileLines($path) {
    if (-not (Test-Path $path)) { return @() }
    Get-Content $path -Encoding UTF8
}

function Read-Workstreams($path) {
    $lines   = Read-FileLines $path
    $result  = [System.Collections.Generic.List[hashtable]]::new()
    $cur     = $null
    $context = ''   # aliases | objectives | upstream | downstream | ''

    foreach ($raw in $lines) {
        $line = $raw
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }

        # New workstream block
        if ($line -match '^  - id:\s*(.+)$') {
            if ($cur) { $result.Add($cur) }
            $cur = @{
                id                = $Matches[1].Trim()
                name              = ''
                status            = 'active'
                strategic_weight  = 5
                aliases           = [System.Collections.Generic.List[string]]::new()
                primary_objectives= [System.Collections.Generic.List[string]]::new()
                notes             = ''
            }
            $context = ''
            continue
        }
        if (-not $cur) { continue }

        switch -Regex ($line) {
            '^    name:\s*(.+)$'             { $cur.name = $Matches[1].Trim(); $context=''; break }
            '^    status:\s*(.+)$'           { $cur.status = $Matches[1].Trim(); $context=''; break }
            '^    strategic_weight:\s*(\d+)' { $cur.strategic_weight = [int]$Matches[1]; $context=''; break }
            '^    notes:\s*(.*)$'            { $cur.notes = $Matches[1].Trim(); $context=''; break }
            '^    aliases:'                  { $context = 'aliases'; break }
            '^    primary_objectives:'       { $context = 'objectives'; break }
            '^    dependencies:'             { $context = 'deps'; break }
            '^      upstream:'               { $context = 'upstream'; break }
            '^      downstream:'             { $context = 'downstream'; break }
            '^      - (.+)$' {
                $val = $Matches[1].Trim()
                switch ($context) {
                    'aliases'     { $cur.aliases.Add($val) }
                    'objectives'  { $cur.primary_objectives.Add($val) }
                }
                break
            }
            # Any new 4-space field resets sub-context
            '^    [a-z]' { if ($context -notin @('aliases','objectives')) { $context = '' } }
        }
    }
    if ($cur) { $result.Add($cur) }
    return $result
}

function Read-Overrides($path) {
    $lines  = Read-FileLines $path
    $result = [System.Collections.Generic.List[hashtable]]::new()
    $cur    = $null

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#' -or [string]::IsNullOrWhiteSpace($raw)) { continue }
        if ($raw -match '^  - workstream_id:\s*(.+)$') {
            if ($cur) { $result.Add($cur) }
            $cur = @{ workstream_id=''; force_category=''; reason=''; expires=$null }
            $cur.workstream_id = $Matches[1].Trim()
            continue
        }
        if (-not $cur) { continue }
        switch -Regex ($raw) {
            '^    force_category:\s*(.+)$' { $cur.force_category = $Matches[1].Trim() }
            '^    reason:\s*"?(.+?)"?\s*$' { $cur.reason = $Matches[1].Trim('"') }
            '^    expires:\s*(.+)$'        {
                $v = $Matches[1].Trim()
                if ($v -ne 'null') { $cur.expires = $v }
            }
        }
    }
    if ($cur) { $result.Add($cur) }
    return $result
}

function Read-ScoringModel($path) {
    $lines   = Read-FileLines $path
    $model   = @{
        windows            = @{ primary_days=14; secondary_days=60 }
        signals            = @{}
        stakeholder_weights= @{}
        categories         = @{}
        rules              = @{}
    }
    $section = ''; $catName = ''

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#' -or [string]::IsNullOrWhiteSpace($raw)) { continue }
        switch -Regex ($raw) {
            '^windows:'            { $section='windows';   $catName=''; break }
            '^signals:'            { $section='signals';   $catName=''; break }
            '^stakeholder_weights:'{ $section='stake';     $catName=''; break }
            '^categories:'         { $section='cats';      $catName=''; break }
            '^rules:'              { $section='rules';     $catName=''; break }
            '^  (\w+):\s*$' {
                if ($section -eq 'cats') {
                    $catName = $Matches[1]
                    $model.categories[$catName] = @{ minimum_score=0; description='' }
                }
                break
            }
            '^\s+(\w+):\s*(\d+)$' {
                $k = $Matches[1]; $v = [int]$Matches[2]
                switch ($section) {
                    'windows' { $model.windows[$k] = $v }
                    'signals' { $model.signals[$k] = $v }
                    'cats'    { if ($catName -and $k -eq 'minimum_score') { $model.categories[$catName].minimum_score = $v } }
                }
                break
            }
            '^\s+(.+?):\s*(\d+)$' {
                if ($section -eq 'stake') { $model.stakeholder_weights[$Matches[1].Trim()] = [int]$Matches[2] }
                break
            }
            '^\s+(\w+):\s*(.+)$' {
                if ($section -eq 'rules') { $model.rules[$Matches[1]] = $Matches[2].Trim() }
            }
        }
    }
    return $model
}

# ─── File Collection ──────────────────────────────────────────────────────────

function Get-SourceFiles($root, $folders) {
    $files = [System.Collections.Generic.List[string]]::new()
    $genPath = (Join-Path $root '00-context' 'generated') -replace '\\','/'

    foreach ($folder in $folders) {
        $full = Join-Path $root $folder
        if (-not (Test-Path $full)) { continue }
        Get-ChildItem -Path $full -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $fp = $_.FullName
            # Skip generated folder (avoid self-reinforcement)
            if ($fp -replace '\\','/' -like "*$($genPath)*") { return }
            # Skip binary extensions
            if ($BINARY_EXTS -contains $_.Extension.ToLower()) { return }
            $files.Add($fp)
        }
    }
    return $files
}

# ─── Signal Detection ─────────────────────────────────────────────────────────

$SIGNAL_PATTERNS = @{
    meeting_mention  = '\b(meeting|call|sync|agenda|transcript|standup|stand-up|catchup|catch.up)\b'
    email_mention    = '\b(email|mail|inbox|message sent|replied)\b'
    chat_mention     = '\b(chat|teams|message|thread|channel)\b'
    task_created     = '\b(action|task|T\d{3,}|todo|to.do|assigned)\b'
    decision_logged  = '\b(decision|decided|D\d{3,}|agreed|approved)\b'
    risk_logged      = '\b(risk|issue|blocker|blocked|concern|impediment)\b'
    escalation       = '\b(escalat|leadership|exec|urgent|critical|P0|P1 issue)\b'
}

function Measure-WorkstreamSignals($files, $workstreams, $model) {
    # Returns hashtable: wsId -> @{ score=n; files=@[]; signal_counts=@{} }
    $results = @{}
    foreach ($ws in $workstreams) {
        $results[$ws.id] = @{
            raw_score     = 0.0
            mention_count = 0
            signal_counts = @{}
            evidence_files= [System.Collections.Generic.List[string]]::new()
        }
        foreach ($sig in $model.signals.Keys) { $results[$ws.id].signal_counts[$sig] = 0 }
    }

    # Build alias lookup: wsId -> regex pattern
    $aliasPatterns = @{}
    foreach ($ws in $workstreams) {
        $terms = [System.Collections.Generic.List[string]]::new()
        $terms.Add([regex]::Escape($ws.name))
        $terms.Add([regex]::Escape($ws.id))
        foreach ($a in $ws.aliases) { $terms.Add([regex]::Escape($a)) }
        $aliasPatterns[$ws.id] = '(?i)\b(' + ($terms -join '|') + ')\b'
    }

    # Stakeholder pattern
    $stakeTerms = $model.stakeholder_weights.Keys | ForEach-Object { [regex]::Escape($_) }
    $stakePattern = if ($stakeTerms) { '(?i)(' + ($stakeTerms -join '|') + ')' } else { $null }

    foreach ($file in $files) {
        try { $content = Get-Content $file -Raw -Encoding UTF8 -ErrorAction Stop }
        catch { continue }
        if ([string]::IsNullOrWhiteSpace($content)) { continue }

        foreach ($ws in $workstreams) {
            $wsId = $ws.id
            if (-not ($content -match $aliasPatterns[$wsId])) { continue }

            # Count raw alias mentions
            $mentionCount = ([regex]::Matches($content, $aliasPatterns[$wsId])).Count
            $results[$wsId].mention_count += $mentionCount

            # Record evidence file (relative path)
            $rel = $file.Replace($ROOT, '').TrimStart('\').TrimStart('/')
            if (-not $results[$wsId].evidence_files.Contains($rel)) {
                $results[$wsId].evidence_files.Add($rel)
            }

            # Detect signal keywords in this file
            $sigPoints = 0.0
            foreach ($sig in $SIGNAL_PATTERNS.Keys) {
                if ($content -imatch $SIGNAL_PATTERNS[$sig]) {
                    $sigWeight = if ($model.signals.ContainsKey($sig)) { $model.signals[$sig] } else { 1 }
                    $results[$wsId].signal_counts[$sig] += 1
                    $sigPoints += $sigWeight
                }
            }

            # Stakeholder signal
            if ($stakePattern) {
                $stakeMatches = [regex]::Matches($content, $stakePattern)
                foreach ($m in $stakeMatches) {
                    $name = $m.Value
                    $weight = $model.stakeholder_weights[$model.stakeholder_weights.Keys | Where-Object { $_ -ieq $name } | Select-Object -First 1]
                    if ($weight) { $sigPoints += $weight }
                }
            }

            # Accumulate: mention_count * signal points (per-file contribution)
            $results[$wsId].raw_score += $sigPoints
        }
    }

    # Apply strategic_weight multiplier + base
    foreach ($ws in $workstreams) {
        $wsId = $ws.id
        $base = $ws.strategic_weight * 3   # base ensures high-weight items start visible
        $results[$wsId].raw_score = [Math]::Round($base + $results[$wsId].raw_score, 1)
    }

    return $results
}

# ─── Categorisation ───────────────────────────────────────────────────────────

function Get-Category($score, $categories) {
    # Sort categories by minimum_score descending, return first that score meets
    $sorted = $categories.GetEnumerator() |
              Sort-Object { $_.Value.minimum_score } -Descending
    foreach ($cat in $sorted) {
        if ($score -ge $cat.Value.minimum_score) { return $cat.Key }
    }
    return 'ParkingLot'
}

function Apply-Overrides($workstreams, $signals, $overrides, $categories) {
    $today = Get-Date
    $finalResults = @{}

    foreach ($ws in $workstreams) {
        $wsId    = $ws.id
        $score   = $signals[$wsId].raw_score
        $category = Get-Category $score $categories
        $overrideApplied = $false
        $overrideReason  = ''

        foreach ($ov in $overrides) {
            if ($ov.workstream_id -ne $wsId) { continue }
            if ($ov.expires) {
                try {
                    $expDate = [datetime]::Parse($ov.expires)
                    if ($today -gt $expDate) { continue }
                } catch { continue }
            }
            if ($ov.force_category) {
                $category        = $ov.force_category
                $overrideApplied = $true
                $overrideReason  = $ov.reason
            }
        }

        $finalResults[$wsId] = @{
            workstream       = $ws
            score            = $score
            category         = $category
            override_applied = $overrideApplied
            override_reason  = $overrideReason
            mention_count    = $signals[$wsId].mention_count
            signal_counts    = $signals[$wsId].signal_counts
            evidence_files   = $signals[$wsId].evidence_files
        }
    }
    return $finalResults
}

# ─── Markdown Generation ──────────────────────────────────────────────────────

function Format-WorkstreamSection($r) {
    $ws  = $r.workstream
    $ovr = if ($r.override_applied) { "Yes — $($r.override_reason)" } else { 'No' }
    $ev  = if ($r.evidence_files.Count -gt 0) {
        ($r.evidence_files | Select-Object -First 5 | ForEach-Object { "- ``$_``" }) -join "`n"
    } else { '- No mentions detected in scanned files.' }

    $sigs = ($r.signal_counts.GetEnumerator() |
             Where-Object { $_.Value -gt 0 } |
             ForEach-Object { "$($_.Key): $($_.Value)" }) -join ', '
    $sigLine = if ($sigs) { $sigs } else { 'none detected' }

    $action = switch ($r.category) {
        'P1'         { "Review progress this week. Ensure blockers are visible to stakeholders." }
        'P2'         { "Keep moving. Unblock dependencies where possible." }
        'Watch'      { "Monitor. Escalate to P1 if a blocker or deadline appears." }
        'ParkingLot' { "Parked. Revisit when capacity allows." }
        default      { "Review." }
    }

    return @"
### $($ws.name)

**Status:** $($r.category)  **Score:** $($r.score)  **Override:** $ovr
**Mentions:** $($r.mention_count)  **Signals:** $sigLine

$($ws.notes)

**Evidence:**
$ev

**Recommended next action:**
- $action

"@
}

function Build-Dashboard($workstreams, $finalResults, $model, $scannedFiles, $latestRecap) {
    $now = Get-Date -Format 'yyyy-MM-dd HH:mm'

    # Group by category
    $groups = @{ P1=@(); P2=@(); Watch=@(); ParkingLot=@() }
    foreach ($r in $finalResults.Values) {
        $cat = $r.category
        if (-not $groups.ContainsKey($cat)) { $groups[$cat] = @() }
        $groups[$cat] += $r
    }
    foreach ($cat in $groups.Keys) {
        $groups[$cat] = @($groups[$cat] | Sort-Object { $_.score } -Descending)
    }

    # Score table
    $tableRows = ($finalResults.Values |
        Sort-Object { $_.score } -Descending |
        ForEach-Object {
            $ovr  = if ($_.override_applied) { '✓' } else { '' }
            $top  = if ($_.evidence_files.Count -gt 0) { $_.evidence_files[0] } else { '—' }
            $act  = switch ($_.category) {
                'P1' { 'Review & report' }; 'P2' { 'Progress' }
                'Watch' { 'Monitor' }; default { 'Park' }
            }
            "| $($_.workstream.name) | $($_.category) | $($_.score) | $ovr | ``$top`` | $act |"
        }) -join "`n"

    # Overrides applied section
    $overrideLines = ($finalResults.Values |
        Where-Object { $_.override_applied } |
        ForEach-Object { "- **$($_.workstream.name)** → $($_.category): $($_.override_reason)" }) -join "`n"
    if (-not $overrideLines) { $overrideLines = '_None active._' }

    # Source coverage
    $folderList = ($SCAN_FOLDERS | ForEach-Object { "- ``$_``" }) -join "`n"
    $recapLine  = if ($latestRecap) { "- ``$latestRecap``" } else { '- No recap files found in `01-inbox/copilot-activity/`.' }

    # Build blocked/escalation candidates
    $escalated = @($finalResults.Values |
        Where-Object { $_.signal_counts.ContainsKey('escalation') -and $_.signal_counts['escalation'] -gt 0 } |
        ForEach-Object { "- **$($_.workstream.name)** — escalation signal detected." })
    $escalatedSection = if ($escalated) { $escalated -join "`n" } else { '_None detected._' }

    # Section builder
    function Build-CategorySection($label, $items) {
        if (-not $items -or $items.Count -eq 0) { return "## $label`n`n_None._`n" }
        $body = ($items | ForEach-Object { Format-WorkstreamSection $_ }) -join ''
        return "## $label`n`n$body"
    }

    # Executive summary
    $p1Names  = ($groups['P1']  | ForEach-Object { $_.workstream.name }) -join ', '
    $watchNames = ($groups['Watch'] | ForEach-Object { $_.workstream.name }) -join ', '
    $execSummary = "Primary focus: **$p1Names**. Watch items: **$watchNames**. " +
                   "Human overrides are active — see Human Overrides section for details."

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->
# Current Focus Dashboard

Project: **Project Matryoshka V1.1 — David Brain**  
Scope: **Lapu-Lapu**  
Generated: **$now**  
Primary activity window: **$($model.windows.primary_days) days**  
Secondary reference window: **$($model.windows.secondary_days) days**  

---

## Executive Summary

$execSummary

---

$(Build-CategorySection 'P1 Focus' $groups['P1'])
$(Build-CategorySection 'P2 Focus' $groups['P2'])
$(Build-CategorySection 'Watch List' $groups['Watch'])
$(Build-CategorySection 'Parking Lot' $groups['ParkingLot'])

## Blocked / Escalation Candidates

$escalatedSection

---

## Workstream Score Table

| Workstream | Category | Score | Override | Top Evidence | Recommended Action |
|---|---:|---:|:---:|---|---|
$tableRows

---

## Human Overrides Applied

$overrideLines

---

## Source Coverage

Scanned folders:
$folderList

Latest Copilot activity recap:
$recapLine

Total files scanned: **$($scannedFiles.Count)**

---

## Agent Notes

- This file is generated by `scripts/generate-current-focus.ps1`.
- Do not edit this file directly.
- To change workstream priorities: edit `00-context/priority-overrides.yaml`.
- To change scoring behaviour: edit `00-context/scoring-model.yaml`.
- To add workstreams: edit `00-context/workstreams.yaml`.
- To provide new activity evidence: drop a recap into `01-inbox/copilot-activity/` and regenerate.
"@
}

function Build-Json($finalResults, $meta) {
    $items = $finalResults.Values | Sort-Object { $_.score } -Descending | ForEach-Object {
        [ordered]@{
            id               = $_.workstream.id
            name             = $_.workstream.name
            category         = $_.category
            score            = $_.score
            strategic_weight = $_.workstream.strategic_weight
            override_applied = $_.override_applied
            override_reason  = $_.override_reason
            mention_count    = $_.mention_count
            evidence_files   = @($_.evidence_files | Select-Object -First 5)
        }
    }
    $output = [ordered]@{
        generated    = $meta.generated
        generator    = 'scripts/generate-current-focus.ps1'
        version      = 'V1.1'
        workstreams  = @($items)
    }
    return $output | ConvertTo-Json -Depth 6
}

# ─── Main ─────────────────────────────────────────────────────────────────────

Write-Host "`nProject Matryoshka V1.1 — Current Focus Generator" -ForegroundColor Cyan
Write-Host "Root: $ROOT`n"

# Load control files
$workstreams = Read-Workstreams (Join-Path $CTX 'workstreams.yaml')
$overrides   = Read-Overrides  (Join-Path $CTX 'priority-overrides.yaml')
$model       = Read-ScoringModel (Join-Path $CTX 'scoring-model.yaml')

Write-Host "Loaded $($workstreams.Count) workstreams, $($overrides.Count) overrides."

# Collect source files
$allFiles = Get-SourceFiles $ROOT $SCAN_FOLDERS
Write-Host "Scanning $($allFiles.Count) files..."

# Detect latest recap
$recapDir    = Join-Path $ROOT '01-inbox' 'copilot-activity'
$latestRecap = $null
if (Test-Path $recapDir) {
    $latest = Get-ChildItem $recapDir -Filter '*.md' -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -ne 'README.md' } |
              Sort-Object Name -Descending | Select-Object -First 1
    if ($latest) { $latestRecap = $latest.FullName.Replace($ROOT,'').TrimStart('\').TrimStart('/') }
}

# Score
$signals      = Measure-WorkstreamSignals $allFiles $workstreams $model
$finalResults = Apply-Overrides $workstreams $signals $overrides $model.categories

# Ensure output directory exists
if (-not (Test-Path $GEN)) { New-Item -ItemType Directory -Path $GEN -Force | Out-Null }

$meta = @{ generated = (Get-Date -Format 'yyyy-MM-dd HH:mm') }

# Write markdown
$md = Build-Dashboard $workstreams $finalResults $model $allFiles $latestRecap
[System.IO.File]::WriteAllText($OUT_MD, $md, [System.Text.Encoding]::UTF8)
Write-Host "Written: $($OUT_MD.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# Write JSON
$json = Build-Json $finalResults $meta
[System.IO.File]::WriteAllText($OUT_JSON, $json, [System.Text.Encoding]::UTF8)
Write-Host "Written: $($OUT_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# Summary to console
Write-Host "`nCategory summary:" -ForegroundColor Yellow
$finalResults.Values | Sort-Object { $_.score } -Descending | ForEach-Object {
    $flag = if ($_.override_applied) { ' [override]' } else { '' }
    Write-Host "  [$($_.category.PadRight(10))] $($_.workstream.name)$flag  (score: $($_.score))"
}
Write-Host "`nDone.`n" -ForegroundColor Cyan
