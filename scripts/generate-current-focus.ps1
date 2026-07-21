#Requires -Version 7.0
<#
.SYNOPSIS
    Project Matryoshka V1.1 baseline - Current Focus Dashboard generator.
.DESCRIPTION
    Reads workstreams, overrides, and scoring model from 00-context/.
    Scans corpus text files for workstream activity signals.
    Writes 00-context/generated/current-focus.md and current-focus.json.
    Safe to run repeatedly. No external dependencies required.
.NOTES
    Target shell: PowerShell 7.6.3+ (pwsh).
    Path: C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.3.0_x64__8wekyb3d8bbwe\pwsh.exe
    V1.2/V1.3/V1.4 (source weighting, trends, morning briefing) extend this
    baseline via companion helper scripts to keep changes reviewable.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT     = Split-Path $PSScriptRoot -Parent
$CTX      = Join-Path $ROOT '00-context'
$GEN      = Join-Path $CTX  'generated'
$OUT_MD          = Join-Path $GEN 'current-focus.md'
$OUT_JSON        = Join-Path $GEN 'current-focus.json'
$OUT_TRENDS_MD   = Join-Path $GEN 'current-focus-trends.md'
$OUT_TRENDS_JSON = Join-Path $GEN 'current-focus-trends.json'
$OUT_BRIEF_MD    = Join-Path $GEN 'morning-briefing.md'
$OUT_BRIEF_JSON  = Join-Path $GEN 'morning-briefing.json'
$OUT_DECREG_MD   = Join-Path $GEN 'decision-registry.md'
$OUT_DECREG_JSON = Join-Path $GEN 'decision-registry.json'
$OUT_RISKREG_MD  = Join-Path $GEN 'risk-register.md'
$OUT_RISKREG_JSON = Join-Path $GEN 'risk-register.json'
$OUT_INBOX_MD    = Join-Path $GEN 'david-inbox.md'
$OUT_INBOX_JSON  = Join-Path $GEN 'david-inbox.json'
$OUT_INSIGHTS_MD   = Join-Path $GEN 'execution-insights.md'
$OUT_INSIGHTS_JSON = Join-Path $GEN 'execution-insights.json'
# V4.0 Phase 1: quality-gate rejection log
$OUT_REJECTED_MD   = Join-Path $GEN 'rejected-items.md'
$OUT_REJECTED_JSON = Join-Path $GEN 'rejected-items.json'
# V4.0 Sprint 16: canonical MatryoshkaItem system-of-record
$OUT_ITEMS_JSON    = Join-Path $GEN 'matryoshka-items.json'

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

# Control files are inputs to the generator, not evidence  Eexclude to prevent
# workstream self-amplification via aliases in workstreams.yaml.
$EXCLUDED_FILES = @(
    'workstreams.yaml',
    'priority-overrides.yaml',
    'scoring-model.yaml'
)

$script:SIGNAL_PATTERNS = @{
    meeting_mention  = '\b(meeting|call|sync|agenda|transcript|standup|stand-up|catchup)\b'
    email_mention    = '\b(email|mail|inbox|replied)\b'
    chat_mention     = '\b(chat|teams|message|thread|channel)\b'
    task_created     = '\b(action|task|T\d{3,}|todo|to-do|assigned)\b'
    decision_logged  = '\b(decision|decided|D\d{3,}|agreed|approved)\b'
    risk_logged      = '\b(risk|issue|blocker|blocked|concern|impediment)\b'
    escalation       = '\b(escalat|leadership|exec|urgent|critical)\b'
}

# --- YAML Parsers -----------------------------------------------------------

function Read-FileLines($path) {
    if (-not (Test-Path $path)) { return @() }
    Get-Content $path -Encoding UTF8
}

function Read-Workstreams($path) {
    $lines   = Read-FileLines $path
    $result  = [System.Collections.Generic.List[hashtable]]::new()
    $cur     = $null
    $context = ''

    foreach ($raw in $lines) {
        $line = $raw
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }

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
                    'aliases'    { $cur.aliases.Add($val) }
                    'objectives' { $cur.primary_objectives.Add($val) }
                }
                break
            }
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
    $lines = Read-FileLines $path
    $model = @{
        windows             = @{ primary_days=14; secondary_days=60 }
        signals             = @{
            meeting_mention  = '\b(meeting|call|sync|agenda|transcript|standup|stand-up|catchup)\b'
            email_mention    = '\b(email|mail|inbox|replied)\b'
            chat_mention     = '\b(chat|teams|message|thread|channel)\b'
            task_created     = '\b(action|task|T\d{3,}|todo|to-do|assigned)\b'
            decision_logged  = '\b(decision|decided|D\d{3,}|agreed|approved)\b'
            risk_logged      = '\b(risk|issue|blocker|blocked|concern|impediment)\b'
            escalation       = '\b(escalat|leadership|exec|urgent|critical)\b'
        }
        stakeholder_weights = @{}
        categories          = @{
            ParkingLot = @{ minimum_score=0; description='No immediate action' }
            P1        = @{ minimum_score=8; description='High priority' }
            P2        = @{ minimum_score=5; description='Medium priority' }
            Watch     = @{ minimum_score=3; description='Monitor for changes' }
        }
        rules               = @{
            'default' = 'P2'
        }
    }
    $section = ''; $catName = ''

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#' -or [string]::IsNullOrWhiteSpace($raw)) { continue }
        switch -Regex ($raw) {
            '^windows:'             { $section='windows'; $catName=''; break }
            '^signals:'             { $section='signals'; $catName=''; break }
            '^stakeholder_weights:' { $section='stake';   $catName=''; break }
            '^categories:'          { $section='cats';    $catName=''; break }
            '^rules:'               { $section='rules';   $catName=''; break }
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

# --- V1.8 Ownership Intelligence: ownership-map parser ----------------------
# Reads 00-context/ownership-map.yaml into id -> { owner, escalationPath, stakeholders }.
# Used as the PRIMARY source for owner resolution in registries.

function Read-OwnershipMap($path) {
    $result = @{}
    if (-not (Test-Path -LiteralPath $path)) { return $result }
    $lines       = Read-FileLines $path
    $currentId   = $null
    $listContext = ''
    $inOwnership = $false

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#' -or [string]::IsNullOrWhiteSpace($raw)) { continue }
        if ($raw -match '^ownership:\s*$')  { $inOwnership = $true; continue }
        if (-not $inOwnership) { continue }

        # Workstream id at 2-space indent
        if ($raw -match '^  ([a-z0-9\-]+):\s*$') {
            $currentId = $Matches[1]
            $result[$currentId] = @{
                owner          = ''
                escalationPath = [System.Collections.Generic.List[string]]::new()
                stakeholders   = [System.Collections.Generic.List[string]]::new()
            }
            $listContext = ''
            continue
        }
        if (-not $currentId) { continue }

        switch -Regex ($raw) {
            '^    owner:\s*(.+)$'                 { $result[$currentId].owner = $Matches[1].Trim(); $listContext = ''; break }
            '^    escalationPath:\s*(\[\])?\s*$'  { $listContext = 'escalation'; break }
            '^    stakeholders:\s*(\[\])?\s*$'    { $listContext = 'stakeholders'; break }
            '^      - (.+)$' {
                $val = $Matches[1].Trim()
                switch ($listContext) {
                    'escalation'   { $result[$currentId].escalationPath.Add($val) }
                    'stakeholders' { $result[$currentId].stakeholders.Add($val) }
                }
                break
            }
            '^    [a-z]' { $listContext = '' }
        }
    }
    return $result
}

# --- V3.0 Adaptive Intelligence: David preference profile parser -----------
#
# Minimal YAML slice for david-preferences.yaml. Reads the specific keys used
# by the inbox re-ranker and returns a nested hashtable. Missing file returns
# a zero-weight default so the ranker still works.

function Read-DavidPreferences($path) {
    $default = @{
        priorityBoosts = @{ workstream = @{}; owner = @{}; kind = @{} }
        penalties      = @{
            overloadedOwnerThreshold = 5
            overloadedOwnerPenalty   = 0.20
            lowConfidencePenalty     = 0.10
            lowConfidenceThreshold   = 0.4
        }
        bonuses        = @{
            recurringDecisionBonus   = 0.10
            missedDeadlineBonus      = 0.30
            imminentEscalationBonus  = 0.15
            inferredActionBonus      = 0.05
        }
        learning       = @{
            delayedWorkstreamConfidenceBonus = 0.10
            missedDeadlineConfidenceBonus    = 0.15
            overloadedOwnerConfidencePenalty = 0.05
        }
        version        = ''
    }
    if (-not (Test-Path -LiteralPath $path)) { return $default }
    $lines = Read-FileLines $path

    $section    = ''
    $subSection = ''
    foreach ($raw in $lines) {
        if ($raw -match '^\s*#' -or [string]::IsNullOrWhiteSpace($raw)) { continue }

        if ($raw -match '^version:\s*(.+)$') { $default.version = $Matches[1].Trim(); continue }

        # Top-level section keys (unindented + trailing colon).
        if ($raw -match '^([a-z_]+):\s*$') {
            $section = $Matches[1]
            $subSection = ''
            continue
        }

        # Second-level: 2-space indent + trailing colon (only inside priority_boosts).
        if ($section -eq 'priority_boosts' -and $raw -match '^  ([a-z_]+):\s*$') {
            $subSection = $Matches[1]
            continue
        }

        # Third-level (priority_boosts nested map) or second-level scalar.
        if ($raw -match '^    "?([^":]+)"?\s*:\s*([0-9.\-]+)\s*$' -and $section -eq 'priority_boosts') {
            $key = $Matches[1].Trim().Trim('"')
            $val = [double]$Matches[2]
            switch ($subSection) {
                'workstream' { $default.priorityBoosts.workstream[$key] = $val }
                'owner'      { $default.priorityBoosts.owner[$key] = $val }
                'kind'       { $default.priorityBoosts.kind[$key] = $val }
            }
            continue
        }

        # Second-level scalar under penalties / bonuses / learning.
        if ($raw -match '^  ([a-z_]+):\s*([0-9.\-]+)\s*$') {
            $key = $Matches[1]
            $val = [double]$Matches[2]
            # snake -> camel for consumption
            $camel = [regex]::Replace($key, '_([a-z])', { param($m) $m.Groups[1].Value.ToUpperInvariant() })
            switch ($section) {
                'penalties' { $default.penalties[$camel] = $val }
                'bonuses'   { $default.bonuses[$camel]   = $val }
                'learning'  { $default.learning[$camel]  = $val }
            }
            continue
        }
    }

    return $default
}

# --- V1.2 additions: source weighting + activity windows --------------------
# These are additive helpers. Existing scoring paths (Get-SourceFiles /
# Measure-WorkstreamSignals) are untouched so V1.1 output remains identical
# until V1.2 scoring is enabled in a later package.

function Read-SourceWeights($path) {
    $lines   = Read-FileLines $path
    $entries = [System.Collections.Generic.List[hashtable]]::new()
    $section = ''
    $cur     = $null

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#' -or [string]::IsNullOrWhiteSpace($raw)) { continue }
        if ($raw -match '^source_weights:\s*$') { $section = 'sw'; continue }
        if ($section -ne 'sw') { continue }

        if ($raw -match '^  ([^\s:][^:]*):\s*$') {
            if ($cur) { $entries.Add($cur) }
            $cur = @{
                path                       = $Matches[1].Trim()
                type                       = 'unknown'
                weight                     = 0.0
                include_for_activity_score = $false
                include_for_context        = $true
                description                = ''
            }
            continue
        }
        if (-not $cur) { continue }

        switch -Regex ($raw) {
            '^    type:\s*(.+)$'                       { $cur.type = $Matches[1].Trim() }
            '^    weight:\s*([0-9.]+)\s*$'             { $cur.weight = [double]$Matches[1] }
            '^    include_for_activity_score:\s*(.+)$' { $cur.include_for_activity_score = ($Matches[1].Trim() -ieq 'true') }
            '^    include_for_context:\s*(.+)$'        { $cur.include_for_context = ($Matches[1].Trim() -ieq 'true') }
            '^    description:\s*(.+)$'                { $cur.description = $Matches[1].Trim() }
        }
    }
    if ($cur) { $entries.Add($cur) }

    # Sort by path length descending so the most specific match wins.
    return @($entries | Sort-Object { -($_.path.Length) })
}

function Read-ActivityWindows($path) {
    $lines = Read-FileLines $path
    $out = @{
        current   = @{ days = 14; description = '' }
        previous  = @{ days = 14; offset_days = 14; description = '' }
        reference = @{ days = 60; description = '' }
        decay     = @{ enabled = $true; half_life_days = 7 }
        trends    = @{
            increasing_delta_percent =  20
            decreasing_delta_percent = -20
            increasing_symbol        = ([char]0x2191).ToString()  # up arrow
            decreasing_symbol        = ([char]0x2193).ToString()  # down arrow
            stable_symbol            = ([char]0x2192).ToString()  # right arrow
        }
    }

    $section = ''
    $sub     = ''

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#' -or [string]::IsNullOrWhiteSpace($raw)) { continue }

        if ($raw -match '^windows:\s*$')        { $section = 'windows'; $sub = ''; continue }
        if ($raw -match '^recency_decay:\s*$')  { $section = 'decay';   $sub = ''; continue }
        if ($raw -match '^trend_rules:\s*$')    { $section = 'trends';  $sub = ''; continue }

        switch ($section) {
            'windows' {
                if ($raw -match '^  (current|previous|reference):\s*$') { $sub = $Matches[1]; break }
                if ($sub) {
                    switch -Regex ($raw) {
                        '^    days:\s*(\d+)\s*$'         { $out[$sub].days        = [int]$Matches[1] }
                        '^    offset_days:\s*(\d+)\s*$'  { $out[$sub].offset_days = [int]$Matches[1] }
                        '^    description:\s*(.+)$'      { $out[$sub].description = $Matches[1].Trim() }
                    }
                }
            }
            'decay' {
                switch -Regex ($raw) {
                    '^  enabled:\s*(.+)$'          { $out.decay.enabled        = ($Matches[1].Trim() -ieq 'true') }
                    '^  half_life_days:\s*(\d+)$'  { $out.decay.half_life_days = [int]$Matches[1] }
                }
            }
            'trends' {
                if ($raw -match '^  (increasing|decreasing|stable):\s*$') { $sub = $Matches[1]; break }
                if ($sub) {
                    switch -Regex ($raw) {
                        '^    minimum_delta_percent:\s*(-?\d+)' { $out.trends.increasing_delta_percent = [int]$Matches[1] }
                        '^    maximum_delta_percent:\s*(-?\d+)' { $out.trends.decreasing_delta_percent = [int]$Matches[1] }
                        '^    symbol:\s*"?([^"\r\n]+)"?\s*$' {
                            $sym = $Matches[1].Trim().Trim('"')
                            switch ($sub) {
                                'increasing' { $out.trends.increasing_symbol = $sym }
                                'decreasing' { $out.trends.decreasing_symbol = $sym }
                                'stable'     { $out.trends.stable_symbol     = $sym }
                            }
                        }
                    }
                }
            }
        }
    }
    return $out
}

# Explicit list of generated artifacts to exclude from every scoring input.
$script:GENERATED_ARTIFACTS = @(
    'current-focus.md',
    'current-focus.json',
    'current-focus-trends.md',
    'current-focus-trends.json',
    'morning-briefing.md',
    'morning-briefing.json',
    'decision-registry.md',
    'decision-registry.json',
    'risk-register.md',
    'risk-register.json',
    'david-inbox.md',
    'david-inbox.json',
    'rejected-items.md',
    'rejected-items.json',
    'matryoshka-items.json',
    'pipeline-health.json'
)

function Get-SourceWeightForPath {
    param(
        [string]   $RelPath,
        [object[]] $WeightEntries
    )
    $norm = ($RelPath -replace '\\','/')
    foreach ($entry in $WeightEntries) {
        $key = $entry.path
        if ($norm -eq $key -or $norm.StartsWith($key + '/')) {
            return $entry
        }
    }
    return $null
}

function Get-SourceFileRecords {
    <#
        Returns rich file records for V1.2 scoring:
            @{ FullPath; RelPath; LastWriteTime; SourceWeight; IncludeForActivity;
               IncludeForContext; FolderType }
        Filters:
            - excludes binary extensions
            - excludes generator control files
            - excludes generated artifacts
            - excludes folders whose weight entry has both include flags false
    #>
    param(
        [string]   $Root,
        [string[]] $Folders,
        [object[]] $WeightEntries
    )

    $records = [System.Collections.Generic.List[hashtable]]::new()
    $genPath = (Join-Path (Join-Path $Root '00-context') 'generated') -replace '\\','/'

    foreach ($folder in $Folders) {
        $full = Join-Path $Root $folder
        if (-not (Test-Path $full)) { continue }

        Get-ChildItem -Path $full -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $fp = $_.FullName
            $normFp = $fp -replace '\\','/'

            if ($normFp -like "*$genPath*") { return }
            if ($BINARY_EXTS -contains $_.Extension.ToLower()) { return }
            if ($EXCLUDED_FILES -contains $_.Name) { return }
            if ($script:GENERATED_ARTIFACTS -contains $_.Name) { return }

            $rel = $fp.Replace($Root, '').TrimStart('\').TrimStart('/') -replace '\\','/'
            $weight = Get-SourceWeightForPath -RelPath $rel -WeightEntries $WeightEntries

            $sourceWeight       = if ($weight) { [double]$weight.weight } else { 0.5 }
            $includeForActivity = if ($weight) { [bool]$weight.include_for_activity_score } else { $true }
            $includeForContext  = if ($weight) { [bool]$weight.include_for_context } else { $true }
            $folderType         = if ($weight) { $weight.type } else { 'unclassified' }

            if (-not $includeForActivity -and -not $includeForContext) { return }

            $records.Add(@{
                FullPath           = $fp
                RelPath            = $rel
                LastWriteTime      = $_.LastWriteTime
                SourceWeight       = $sourceWeight
                IncludeForActivity = $includeForActivity
                IncludeForContext  = $includeForContext
                FolderType         = $folderType
            })
        }
    }
    return $records
}

function Get-ActivityWindowBuckets {
    <#
        Assigns each file record to a window bucket:
            'current'  -> LastWriteTime within last <current.days>
            'previous' -> LastWriteTime within [now - previous.offset_days - previous.days,
                                                now - previous.offset_days)
            'older'    -> outside both windows
        Adds .Window to each record.
    #>
    param(
        [System.Collections.Generic.List[hashtable]] $Records,
        [hashtable] $Windows
    )

    $now         = Get-Date
    $currentCut  = $now.AddDays(-1 * [int]$Windows.current.days)
    $prevEnd     = $now.AddDays(-1 * [int]$Windows.previous.offset_days)
    $prevStart   = $prevEnd.AddDays(-1 * [int]$Windows.previous.days)

    foreach ($rec in $Records) {
        $ts = [datetime]$rec.LastWriteTime
        if ($ts -ge $currentCut) {
            $rec.Window = 'current'
        } elseif ($ts -ge $prevStart -and $ts -lt $prevEnd) {
            $rec.Window = 'previous'
        } else {
            $rec.Window = 'older'
        }
    }
    return $Records
}

# --- File Collection --------------------------------------------------------

function Get-SourceFiles($root, $folders) {
    $files = [System.Collections.Generic.List[string]]::new()
    $genPath = (Join-Path (Join-Path $root '00-context') 'generated') -replace '\\','/'

    foreach ($folder in $folders) {
        $full = Join-Path $root $folder
        if (-not (Test-Path $full)) { continue }
        Get-ChildItem -Path $full -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $fp = $_.FullName
            if (($fp -replace '\\','/') -like "*$genPath*") { return }
            if ($BINARY_EXTS -contains $_.Extension.ToLower()) { return }
            if ($EXCLUDED_FILES -contains $_.Name) { return }
            $files.Add($fp)
        }
    }
    return $files
}

# --- Signal Detection -------------------------------------------------------

function Measure-WorkstreamSignals($files, $workstreams, $model) {
    # Returns hashtable: wsId -> @{ score=n; files=@[]; signal_counts=@{} }
    $results = @{}
    foreach ($ws in $workstreams) {
        $results[$ws.id] = @{
            raw_score      = 0.0
            mention_count  = 0
            signal_counts  = @{
            }
            evidence_files = [System.Collections.Generic.List[string]]::new()
        }
        foreach ($sig in $script:SIGNAL_PATTERNS.Keys) { $results[$ws.id].signal_counts[$sig] = 0 }
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
    $stakeKeys = @($model.stakeholder_weights.Keys)
    $stakePattern = $null
    if ($stakeKeys.Count -gt 0) {
        $escaped = $stakeKeys | ForEach-Object { [regex]::Escape($_) }
        $stakePattern = '(?i)(' + ($escaped -join '|') + ')'
    }

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
            foreach ($sig in $script:SIGNAL_PATTERNS.Keys) {
                if ($content -imatch $script:SIGNAL_PATTERNS[$sig]) {
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
                    # Find canonical key (case-insensitive)
                    $canonKey = $stakeKeys | Where-Object { $_ -ieq $name } | Select-Object -First 1
                    if ($canonKey) {
                        $sigPoints += $model.stakeholder_weights[$canonKey]
                    }
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

# --- Categorisation ---------------------------------------------------------

function Get-NormalizedScores($signals) {
    # Normalize raw_score to 0-100 based on the max across all workstreams.
    # Preserves raw_score; adds `score` (normalized) to each entry.
    $max = 0.0
    foreach ($v in $signals.Values) {
        if ($v.raw_score -gt $max) { $max = $v.raw_score }
    }
    foreach ($k in @($signals.Keys)) {
        $raw = $signals[$k].raw_score
        $norm = if ($max -gt 0) { [Math]::Round(($raw / $max) * 100, 1) } else { 0 }
        $signals[$k].score = $norm
    }
    return $signals
}

function Get-Category($score, $categories) {
    # Sort categories by minimum_score descending, return first that score meets
    $sorted = $categories.GetEnumerator() | Sort-Object { $_.Value.minimum_score } -Descending
    foreach ($cat in $sorted) {
        if ($score -ge $cat.Value.minimum_score) { return $cat.Key }
    }
    return 'ParkingLot'
}

function Invoke-Overrides($workstreams, $signals, $overrides, $categories) {
    $today = Get-Date
    $final = @{}

    foreach ($ws in $workstreams) {
        $wsId     = $ws.id
        $score    = $signals[$wsId].score        # normalized 0-100
        $rawScore = $signals[$wsId].raw_score
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

        $final[$wsId] = @{
            workstream       = $ws
            score            = $score
            raw_score        = $rawScore
            category         = $category
            override_applied = $overrideApplied
            override_reason  = $overrideReason
            mention_count    = $signals[$wsId].mention_count
            signal_counts    = $signals[$wsId].signal_counts
            evidence_files   = $signals[$wsId].evidence_files
        }
    }
    return $final
}

# --- V1.2 Attention scoring -------------------------------------------------
# Computes component scores (strategic/activity/override/trend) plus a combined
# attention_score for each workstream. Uses windowed file records produced by
# Get-SourceFileRecords + Get-ActivityWindowBuckets. Stable-context folders are
# excluded from activity contribution via source-weights.yaml.

function Measure-WorkstreamActivityV2 {
    param(
        [System.Collections.Generic.List[hashtable]] $Records,
        [object[]] $Workstreams,
        [hashtable] $Model,
        [bool] $DecayEnabled,
        [int]  $HalfLifeDays
    )

    $results = @{}
    foreach ($ws in $Workstreams) {
        $results[$ws.id] = @{
            activity_current  = 0.0
            activity_previous = 0.0
            activity_older    = 0.0
            activity_files    = [System.Collections.Generic.List[hashtable]]::new()
            context_files     = [System.Collections.Generic.List[hashtable]]::new()
        }
    }

    # Alias regex per workstream (reuses existing patterns)
    $aliasPatterns = @{}
    foreach ($ws in $Workstreams) {
        $terms = [System.Collections.Generic.List[string]]::new()
        $terms.Add([regex]::Escape($ws.name))
        $terms.Add([regex]::Escape($ws.id))
        foreach ($a in $ws.aliases) { $terms.Add([regex]::Escape($a)) }
        $aliasPatterns[$ws.id] = '(?i)\b(' + ($terms -join '|') + ')\b'
    }

    $stakeKeys = @($Model.stakeholder_weights.Keys)
    $stakePattern = $null
    if ($stakeKeys.Count -gt 0) {
        $escaped = $stakeKeys | ForEach-Object { [regex]::Escape($_) }
        $stakePattern = '(?i)(' + ($escaped -join '|') + ')'
    }

    $now = Get-Date

    foreach ($rec in $Records) {
        try { $content = Get-Content $rec.FullPath -Raw -Encoding UTF8 -ErrorAction Stop } catch { continue }
        if ([string]::IsNullOrWhiteSpace($content)) { continue }

        # Signal points for this file (single pass across all workstreams)
        $sigPoints = 0.0
        foreach ($sig in $script:SIGNAL_PATTERNS.Keys) {
            if ($content -imatch $script:SIGNAL_PATTERNS[$sig]) {
                $w = if ($Model.signals.ContainsKey($sig)) { $Model.signals[$sig] } else { 1 }
                $sigPoints += $w
            }
        }
        if ($stakePattern) {
            $stakeMatches = [regex]::Matches($content, $stakePattern)
            foreach ($m in $stakeMatches) {
                $canon = $stakeKeys | Where-Object { $_ -ieq $m.Value } | Select-Object -First 1
                if ($canon) { $sigPoints += $Model.stakeholder_weights[$canon] }
            }
        }
        if ($sigPoints -lt 1) { $sigPoints = 1 }   # baseline "activity present"

        # Recency decay for current-window contribution
        $ageDays = ($now - $rec.LastWriteTime).TotalDays
        $decay = 1.0
        if ($DecayEnabled -and $HalfLifeDays -gt 0 -and $ageDays -gt 0) {
            $decay = [Math]::Pow(0.5, $ageDays / [double]$HalfLifeDays)
        }

        foreach ($ws in $Workstreams) {
            $wsId = $ws.id
            if (-not ($content -match $aliasPatterns[$wsId])) { continue }

            if ($rec.IncludeForContext) {
                $results[$wsId].context_files.Add(@{
                    rel     = $rec.RelPath
                    weight  = $rec.SourceWeight
                    written = $rec.LastWriteTime
                    window  = $rec.Window
                })
            }

            if ($rec.IncludeForActivity) {
                $contribution = $sigPoints * [double]$rec.SourceWeight
                switch ($rec.Window) {
                    'current'  {
                        $results[$wsId].activity_current  += ($contribution * $decay)
                        $results[$wsId].activity_files.Add(@{
                            rel = $rec.RelPath; weight = $rec.SourceWeight; written = $rec.LastWriteTime; window = 'current'
                        })
                    }
                    'previous' {
                        $results[$wsId].activity_previous += $contribution
                    }
                    default    {
                        $results[$wsId].activity_older    += ($contribution * 0.25)
                    }
                }
            }
        }
    }
    return $results
}

function Get-AttentionScores {
    param(
        [object[]] $Workstreams,
        [hashtable] $ActivityMap,
        [object[]] $Overrides,
        [hashtable] $Model,
        [hashtable] $TrendRules
    )

    $today = Get-Date

    # Normalisation anchors
    $maxAct = 0.0
    foreach ($ws in $Workstreams) {
        $a = $ActivityMap[$ws.id].activity_current
        if ($a -gt $maxAct) { $maxAct = $a }
    }
    $maxStrategic = 0
    foreach ($ws in $Workstreams) { if ($ws.strategic_weight -gt $maxStrategic) { $maxStrategic = $ws.strategic_weight } }
    if ($maxStrategic -le 0) { $maxStrategic = 10 }

    # Attention formula (defaults match sprint spec)
    $fw = if ($Model -is [hashtable] -and $Model.ContainsKey('attention_formula') -and $Model.attention_formula) { $Model.attention_formula } else { $null }
    if (-not $fw) { $fw = @{ strategic_weight_percent = 20; activity_weight_percent = 60; override_weight_percent = 15; trend_weight_percent = 5 } }
    $wStrategic = [double]$fw.strategic_weight_percent / 100.0
    $wActivity  = [double]$fw.activity_weight_percent  / 100.0
    $wOverride  = [double]$fw.override_weight_percent  / 100.0
    $wTrend     = [double]$fw.trend_weight_percent     / 100.0

    # Effective overrides map
    $overrideMap = @{}
    foreach ($ov in $Overrides) {
        if (-not $ov.workstream_id) { continue }
        if ($ov.expires) {
            try {
                $exp = [datetime]::Parse($ov.expires)
                if ($today -gt $exp) { continue }
            } catch { continue }
        }
        $overrideMap[$ov.workstream_id] = $ov
    }

    $result = @{}
    foreach ($ws in $Workstreams) {
        $wsId = $ws.id
        $act  = $ActivityMap[$wsId]

        $strategic = [double]$ws.strategic_weight / [double]$maxStrategic * 100.0
        $activity  = if ($maxAct -gt 0) { $act.activity_current / $maxAct * 100.0 } else { 0.0 }

        $curr = [double]$act.activity_current
        $prev = [double]$act.activity_previous
        $delta = $curr - $prev
        $deltaPct = 0.0
        if ($prev -gt 0) {
            $deltaPct = ($delta / $prev) * 100.0
        } elseif ($curr -gt 0) {
            $deltaPct = 100.0
        }

        $incThr = [double]$TrendRules.increasing_delta_percent
        $decThr = [double]$TrendRules.decreasing_delta_percent

        if ($deltaPct -ge $incThr) {
            $trendDirection = 'increasing'; $trendSymbol = $TrendRules.increasing_symbol; $trendScore = 100.0
        } elseif ($deltaPct -le $decThr) {
            $trendDirection = 'decreasing'; $trendSymbol = $TrendRules.decreasing_symbol; $trendScore = 0.0
        } else {
            $trendDirection = 'stable';     $trendSymbol = $TrendRules.stable_symbol;     $trendScore = 50.0
        }

        $overrideScore    = 0.0
        $overrideApplied  = $false
        $overrideReason   = ''
        $overrideCategory = ''
        if ($overrideMap.ContainsKey($wsId)) {
            $ov = $overrideMap[$wsId]
            $overrideCategory = $ov.force_category
            $overrideReason   = $ov.reason
            $overrideApplied  = $true
            $overrideScore = switch ($ov.force_category) {
                'P1'         { 100.0 }
                'P2'         {  60.0 }
                'Watch'      {  30.0 }
                'ParkingLot' {  10.0 }
                default      {   0.0 }
            }
        }

        $attention = ($strategic * $wStrategic) + ($activity * $wActivity) + ($overrideScore * $wOverride) + ($trendScore * $wTrend)
        $attention = [Math]::Round([Math]::Min([Math]::Max($attention, 0.0), 100.0), 1)

        $trendReason = switch ($trendDirection) {
            'increasing' { "Activity signals up {0}% vs prior 14 days." -f [int][Math]::Round($deltaPct) }
            'decreasing' { "Activity signals down {0}% vs prior 14 days." -f [int][Math]::Round($deltaPct) }
            default      {
                if ($curr -eq 0 -and $prev -eq 0) { 'No recent activity in either window.' }
                else { 'Activity roughly steady vs prior 14 days.' }
            }
        }

        $result[$wsId] = @{
            strategic_score         = [Math]::Round($strategic, 1)
            activity_score          = [Math]::Round($activity, 1)
            activity_score_current  = [Math]::Round($curr, 2)
            activity_score_previous = [Math]::Round($prev, 2)
            override_score          = $overrideScore
            override_applied        = $overrideApplied
            override_reason         = $overrideReason
            override_category       = $overrideCategory
            trend_direction         = $trendDirection
            trend_symbol            = $trendSymbol
            trend_score             = $trendScore
            trend_delta             = [Math]::Round($delta, 2)
            trend_delta_percent     = [Math]::Round($deltaPct, 1)
            trend_reason            = $trendReason
            attention_score         = $attention
        }
    }
    return $result
}

function Get-AttentionCategoryHint {
    param([double] $Attention)
    if ($Attention -ge 70) { return 'P1' }
    if ($Attention -ge 40) { return 'P2' }
    if ($Attention -ge 20) { return 'Watch' }
    return 'ParkingLot'
}

function Merge-AttentionIntoResults {
    <#
        Overwrites signals map's `.score` with attention_score BEFORE Invoke-Overrides,
        so category derivation and downstream sorting all key off the new signal.
    #>
    param(
        [hashtable] $Signals,
        [hashtable] $AttentionMap
    )
    foreach ($wsId in $Signals.Keys) {
        if ($AttentionMap.ContainsKey($wsId)) {
            $Signals[$wsId].score = $AttentionMap[$wsId].attention_score
        }
    }
}

# --- Markdown Generation ----------------------------------------------------

function Format-WorkstreamSection($r) {
    $ws  = $r.workstream
    $ovr = if ($r.override_applied) { "Yes - $($r.override_reason)" } else { 'No' }
    $ev  = if ($r.evidence_files.Count -gt 0) {
        ($r.evidence_files | Select-Object -First 5 | ForEach-Object { "- ``$_``" }) -join "`n"
    } else { '- No mentions detected in scanned files.' }

    $sigs = ($r.signal_counts.GetEnumerator() |
             Where-Object { $_.Value -gt 0 } |
             ForEach-Object { "$($_.Key): $($_.Value)" }) -join ', '
    $sigLine = if ($sigs) { $sigs } else { 'none detected' }

    $action = switch ($r.category) {
        'P1'         { 'Review progress this week. Ensure blockers are visible to stakeholders.' }
        'P2'         { 'Keep moving. Unblock dependencies where possible.' }
        'Watch'      { 'Monitor. Escalate to P1 if a blocker or deadline appears.' }
        'ParkingLot' { 'Parked. Revisit when capacity allows.' }
        default      { 'Review.' }
    }

    # V1.2 component-score line (kept out of the summary paragraph so the UI's
    # summary regex `**Signals:**...\n\n{notes}\n\n**Evidence:**` continues to
    # capture the workstream description cleanly).
    $attention = if ($r.ContainsKey('attention_score')) { $r.attention_score } else { $r.score }
    $activity  = if ($r.ContainsKey('activity_score'))  { $r.activity_score }  else { '-' }
    $strategic = if ($r.ContainsKey('strategic_score')) { $r.strategic_score } else { '-' }
    $trendSym  = if ($r.ContainsKey('trend_symbol'))    { $r.trend_symbol }    else { '-' }
    $trendPct  = if ($r.ContainsKey('trend_delta_percent')) {
        $p = $r.trend_delta_percent
        if ($p -gt 0) { "+$p%" } else { "$p%" }
    } else { '-' }

    $componentLine = "**Attention:** $attention  **Activity:** $activity  **Strategic:** $strategic  **Trend:** $trendSym $trendPct"

    return @"
### $($ws.name)

**Status:** $($r.category)  **Score:** $($r.score)  **Override:** $ovr
$componentLine
**Mentions:** $($r.mention_count)  **Signals:** $sigLine

$($ws.notes)

**Evidence:**
$ev

**Recommended next action:**
- $action

"@
}

function Build-CategorySection($label, $items) {
    if (-not $items -or $items.Count -eq 0) { return "## $label`n`n_None._`n" }
    $body = ($items | ForEach-Object { Format-WorkstreamSection $_ }) -join ''
    return "## $label`n`n$body"
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
    foreach ($cat in @($groups.Keys)) {
        $groups[$cat] = @($groups[$cat] | Sort-Object { $_.score } -Descending)
    }

    # Score table
    $tableRows = ($finalResults.Values |
        Sort-Object { $_.score } -Descending |
        ForEach-Object {
            $ovr  = if ($_.override_applied) { 'yes' } else { '' }
            $top  = if ($_.evidence_files.Count -gt 0) { $_.evidence_files[0] } else { '-' }
            $act  = switch ($_.category) {
                'P1' { 'Review & report' }; 'P2' { 'Progress' }
                'Watch' { 'Monitor' }; default { 'Park' }
            }
            "| $($_.workstream.name) | $($_.category) | $($_.score) | $ovr | ``$top`` | $act |"
        }) -join "`n"

    # Overrides applied section
    $overrideLines = ($finalResults.Values |
        Where-Object { $_.override_applied } |
        ForEach-Object { "- **$($_.workstream.name)** -> $($_.category): $($_.override_reason)" }) -join "`n"
    if (-not $overrideLines) { $overrideLines = '_None active._' }

    # Source coverage
    $folderList = ($SCAN_FOLDERS | ForEach-Object { "- ``$_``" }) -join "`n"
    $recapLine  = if ($latestRecap) { "- ``$latestRecap``" } else { '- No recap files found in `01-inbox/copilot-activity/`.' }

    # Build blocked/escalation candidates
    $escalated = @($finalResults.Values |
        Where-Object { $_.signal_counts['escalation'] -gt 0 } |
        ForEach-Object { "- **$($_.workstream.name)** - escalation signal detected." })
    $escalatedSection = if ($escalated) { $escalated -join "`n" } else { '_None detected._' }

    $p1Names    = ($groups['P1']    | ForEach-Object { $_.workstream.name }) -join ', '
    $watchNames = ($groups['Watch'] | ForEach-Object { $_.workstream.name }) -join ', '
    if (-not $p1Names)    { $p1Names    = 'none' }
    if (-not $watchNames) { $watchNames = 'none' }
    $execSummary = "Primary focus: **$p1Names**. Watch items: **$watchNames**. " +
                   "Human overrides are active - see Human Overrides section for details."

    $p1Section  = Build-CategorySection 'P1 Focus'      $groups['P1']
    $p2Section  = Build-CategorySection 'P2 Focus'      $groups['P2']
    $wSection   = Build-CategorySection 'Watch List'    $groups['Watch']
    $plSection  = Build-CategorySection 'Parking Lot'   $groups['ParkingLot']

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->
# Current Focus Dashboard

Project: **Project Matryoshka V1.2 - David Brain**
Scope: **Lapu-Lapu**
Generated: **$now**
Primary activity window: **$($model.windows.primary_days) days**
Secondary reference window: **$($model.windows.secondary_days) days**

---

## Executive Summary

$execSummary

---

$p1Section
$p2Section
$wSection
$plSection

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

- This file is generated by ``scripts/generate-current-focus.ps1``.
- Do not edit this file directly.
- To change workstream priorities: edit ``00-context/priority-overrides.yaml``.
- To change scoring behaviour: edit ``00-context/scoring-model.yaml``.
- To add workstreams: edit ``00-context/workstreams.yaml``.
- To provide new activity evidence: drop a recap into ``01-inbox/copilot-activity/`` and regenerate.
"@
}

function Build-Json($finalResults, $meta) {
    $items = $finalResults.Values | Sort-Object { $_.score } -Descending | ForEach-Object {
        [ordered]@{
            id                      = $_.workstream.id
            name                    = $_.workstream.name
            category                = $_.category
            score                   = $_.score
            raw_score               = $_.raw_score
            strategic_weight        = $_.workstream.strategic_weight
            override_applied        = $_.override_applied
            override_reason         = $_.override_reason
            mention_count           = $_.mention_count
            evidence_files          = @($_.evidence_files | Select-Object -First 5)
            # V4.0 Sprint 18: primary objective mapping - consumed by weekly-report
            # generator's automated executive-summary composer.
            primary_objectives      = if ($_.workstream.primary_objectives) { @($_.workstream.primary_objectives) } else { @() }
            # V1.2 additions (never remove keys above; UI depends on them)
            attention_score         = if ($_.ContainsKey('attention_score'))         { $_.attention_score }         else { $_.score }
            strategic_score         = if ($_.ContainsKey('strategic_score'))         { $_.strategic_score }         else { $null }
            activity_score          = if ($_.ContainsKey('activity_score'))          { $_.activity_score }          else { $null }
            activity_score_current  = if ($_.ContainsKey('activity_score_current'))  { $_.activity_score_current }  else { $null }
            activity_score_previous = if ($_.ContainsKey('activity_score_previous')) { $_.activity_score_previous } else { $null }
            override_score          = if ($_.ContainsKey('override_score'))          { $_.override_score }          else { $null }
            override_category       = if ($_.ContainsKey('override_category'))       { $_.override_category }       else { '' }
            trend_direction         = if ($_.ContainsKey('trend_direction'))         { $_.trend_direction }         else { 'stable' }
            trend_symbol            = if ($_.ContainsKey('trend_symbol'))            { $_.trend_symbol }            else { '' }
            trend_score             = if ($_.ContainsKey('trend_score'))             { $_.trend_score }             else { $null }
            trend_delta             = if ($_.ContainsKey('trend_delta'))             { $_.trend_delta }             else { 0 }
            trend_delta_percent     = if ($_.ContainsKey('trend_delta_percent'))     { $_.trend_delta_percent }     else { 0 }
            trend_reason            = if ($_.ContainsKey('trend_reason'))            { $_.trend_reason }            else { '' }
            health                  = if ($_.ContainsKey('health'))                  { $_.health }                  else { $null }
        }
    }
    $output = [ordered]@{
        generated   = $meta.generated
        generator   = 'scripts/generate-current-focus.ps1'
        version     = 'V3.0'
        workstreams = @($items)
    }
    return $output | ConvertTo-Json -Depth 6
}

# --- V1.3 Trends artifacts --------------------------------------------------

function Build-TrendsMarkdown {
    param(
        [object[]] $Workstreams,
        [hashtable] $AttentionMap,
        [hashtable] $Windows,
        [string]   $NowStamp
    )

    $rows = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($ws in $Workstreams) {
        $a = $AttentionMap[$ws.id]
        if (-not $a) { continue }
        $rows.Add(@{
            id        = $ws.id
            name      = $ws.name
            current   = [double]$a.activity_score_current
            previous  = [double]$a.activity_score_previous
            delta     = [double]$a.trend_delta
            deltaPct  = [double]$a.trend_delta_percent
            direction = [string]$a.trend_direction
            symbol    = [string]$a.trend_symbol
            reason    = [string]$a.trend_reason
        })
    }

    $sorted = @($rows | Sort-Object -Property @{ Expression = 'deltaPct'; Descending = $true }, @{ Expression = 'current'; Descending = $true })

    $inc = @($sorted | Where-Object { $_.direction -eq 'increasing' })
    $dec = @($sorted | Where-Object { $_.direction -eq 'decreasing' })
    $stab = @($sorted | Where-Object { $_.direction -eq 'stable' })

    $execSummary = "In the last $($Windows.current.days) days, $($inc.Count) workstream(s) are increasing, $($dec.Count) decreasing, and $($stab.Count) stable."
    if ($inc.Count -gt 0) { $execSummary += " Rising: **" + (($inc | ForEach-Object { $_.name }) -join ', ') + "**." }
    if ($dec.Count -gt 0) { $execSummary += " Falling: **" + (($dec | ForEach-Object { $_.name }) -join ', ') + "**." }

    $tableLines = foreach ($r in $sorted) {
        $deltaPctStr = if ($r.deltaPct -gt 0) { "+{0:N1}%" -f $r.deltaPct } else { "{0:N1}%" -f $r.deltaPct }
        "| $($r.name) | $([Math]::Round($r.current,2)) | $([Math]::Round($r.previous,2)) | $([Math]::Round($r.delta,2)) | $deltaPctStr | $($r.symbol) $($r.direction) | $($r.reason) |"
    }
    $tableRows = $tableLines -join "`n"

    $incSection = if ($inc.Count -gt 0) {
        ($inc | ForEach-Object { "- **$($_.name)** $($_.symbol) delta $([Math]::Round($_.deltaPct,1))%. $($_.reason)" }) -join "`n"
    } else { '_None._' }

    $decSection = if ($dec.Count -gt 0) {
        ($dec | ForEach-Object { "- **$($_.name)** $($_.symbol) delta $([Math]::Round($_.deltaPct,1))%. $($_.reason)" }) -join "`n"
    } else { '_None._' }

    $stabSection = if ($stab.Count -gt 0) {
        ($stab | ForEach-Object { "- **$($_.name)** $($_.symbol) delta $([Math]::Round($_.deltaPct,1))%. $($_.reason)" }) -join "`n"
    } else { '_None._' }

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Current Focus Trends

Generated: $NowStamp
Current window: $($Windows.current.days) days
Previous window: $($Windows.previous.days) days (offset $($Windows.previous.offset_days) days)

## Executive Summary

$execSummary

## Trend Table

| Workstream | Current Activity Score | Previous Activity Score | Delta | Delta % | Trend | Reason |
|---|---:|---:|---:|---:|---|---|
$tableRows

## Increasing Attention

$incSection

## Decreasing Attention

$decSection

## Stable Attention

$stabSection

## Notes

Trend is based on recent activity signals only. Strategic weight and human overrides are not sufficient by themselves to create an increasing trend.
"@
}

function Build-TrendsJson {
    param(
        [object[]] $Workstreams,
        [hashtable] $AttentionMap,
        [hashtable] $Windows,
        [string]   $GeneratedIso
    )

    $items = foreach ($ws in $Workstreams) {
        $a = $AttentionMap[$ws.id]
        if (-not $a) { continue }
        [ordered]@{
            id                   = $ws.id
            name                 = $ws.name
            currentActivityScore = [double]$a.activity_score_current
            previousActivityScore = [double]$a.activity_score_previous
            delta                = [double]$a.trend_delta
            deltaPercent         = [double]$a.trend_delta_percent
            trendDirection       = [string]$a.trend_direction
            trendSymbol          = [string]$a.trend_symbol
            trendReason          = [string]$a.trend_reason
        }
    }

    $out = [ordered]@{
        generated          = $GeneratedIso
        generator          = 'scripts/generate-current-focus.ps1'
        version            = 'V1.3'
        currentWindowDays  = [int]$Windows.current.days
        previousWindowDays = [int]$Windows.previous.days
        offsetDays         = [int]$Windows.previous.offset_days
        workstreams        = @($items)
    }
    return $out | ConvertTo-Json -Depth 6
}

# --- V1.4 Morning briefing --------------------------------------------------

function Get-BriefingSourceInputs {
    param([System.Collections.Generic.List[hashtable]] $Records)

    $out = [System.Collections.Generic.List[hashtable]]::new()

    $recent = @($Records | Where-Object {
        $_.IncludeForActivity -and $_.Window -eq 'current'
    } | Sort-Object -Property @{ Expression = { $_.SourceWeight }; Descending = $true },
                              @{ Expression = { $_.LastWriteTime }; Descending = $true } | Select-Object -First 8)

    foreach ($r in $recent) {
        $out.Add(@{
            path   = $r.RelPath
            weight = [double]$r.SourceWeight
            window = $r.Window
            date   = $r.LastWriteTime.ToString('yyyy-MM-dd')
        })
    }
    return $out
}

function Format-BriefingWorkstreamSection {
    param([hashtable] $Result, [hashtable] $Attention)

    $notes = if ($Result.workstream.notes) { $Result.workstream.notes } else { 'Strategic workstream tracked in workstreams.yaml.' }
    $why = @()
    $why += "- $notes"
    if ($Result.override_applied -and $Result.override_reason) {
        $why += "- Human override: $($Result.override_reason)"
    }
    if ($Result.strategic_score -ge 80) {
        $why += "- High strategic weight ($($Result.workstream.strategic_weight)/10)."
    }

    $changed = @()
    if ($Attention) {
        $changed += "- Trend: $($Attention.trend_symbol) $($Attention.trend_direction) ($($Attention.trend_delta_percent)% vs prior 14 days)."
        $changed += "- Activity score: $($Attention.activity_score) (current window)."
        if ($Attention.activity_score_previous -gt 0) {
            $changed += "- Previous-window activity: $($Attention.activity_score_previous)."
        } else {
            $changed += "- No measurable activity in the previous window."
        }
    }

    $action = switch ($Result.category) {
        'P1'         { 'Review progress this week. Ensure blockers are visible to stakeholders.' }
        'P2'         { 'Keep moving. Unblock dependencies where possible.' }
        'Watch'      { 'Monitor. Escalate to P1 if a blocker or deadline appears.' }
        'ParkingLot' { 'Parked. Revisit when capacity allows.' }
        default      { 'Review.' }
    }

    $whyBlock     = $why     -join "`n"
    $changedBlock = $changed -join "`n"

    return @"
### $($Result.workstream.name)

Category: **$($Result.category)**  Attention: **$($Result.attention_score)**  Override: $(if ($Result.override_applied) { 'Yes' } else { 'No' })

Why it matters:
$whyBlock

What changed:
$changedBlock

Recommended next action:
- $action

"@
}

function Build-MorningBriefingMarkdown {
    param(
        [hashtable] $FinalResults,
        [hashtable] $AttentionMap,
        [System.Collections.Generic.List[hashtable]] $Records,
        [hashtable] $Windows,
        [object[]] $DecisionRegistry,
        [object[]] $RiskRegister,
        [string]   $NowStamp
    )

    $DecisionRegistry = @($DecisionRegistry | Where-Object { $null -ne $_ })
    $RiskRegister     = @($RiskRegister     | Where-Object { $null -ne $_ })

    $all = @($FinalResults.Values | Sort-Object { $_.attention_score } -Descending)

    $primary = @($all | Where-Object { $_.category -eq 'P1' } | Select-Object -First 5)
    if ($primary.Count -eq 0) { $primary = $all | Select-Object -First 3 }

    # V1.7 Top 5 Risks + Rising Risks (registry-backed)
    $severityRank = @{ 'High' = 0; 'Medium' = 1; 'Low' = 2 }
    $openRisks    = @($RiskRegister | Where-Object { $_.status -ne 'closed' })
    $topRisks     = @($openRisks | Sort-Object `
        @{ Expression = { $severityRank[$_.severity] }; Ascending = $true },
        @{ Expression = { $_.agingDays }; Descending = $true } | Select-Object -First 5)
    $risingRisks  = @($openRisks | Where-Object { $_.trend -eq 'increasing' } | Sort-Object { $_.agingDays } -Descending | Select-Object -First 8)

    # V1.6 Decision Pressure: registry-based, oldest open first.
    $pendingDecisions = @($DecisionRegistry | Where-Object { $_.status -ne 'closed' } | Select-Object -First 8)

    $escalated = @($all | Where-Object {
        $_.signal_counts.ContainsKey('escalation') -and $_.signal_counts['escalation'] -gt 0
    } | Select-Object -First 8)

    # Executive snapshot
    $p1Count    = @($all | Where-Object { $_.category -eq 'P1' }).Count
    $watchCount = @($all | Where-Object { $_.category -eq 'Watch' }).Count
    $incCount   = @($all | Where-Object { $_.trend_direction -eq 'increasing' }).Count
    $topName    = if ($all.Count -gt 0) { $all[0].workstream.name } else { 'none' }
    $execSnap   = "The Lapu-Lapu operating picture shows $p1Count P1 workstream(s) and $watchCount watch item(s). " +
                  "$incCount workstream(s) show increasing activity in the last $($Windows.current.days) days. " +
                  "Top attention today is on **$topName**."

    $primaryBlock = if ($primary.Count -gt 0) {
        ($primary | ForEach-Object { Format-BriefingWorkstreamSection -Result $_ -Attention $AttentionMap[$_.workstream.id] }) -join ''
    } else { "_No workstream is currently marked as primary focus._`n" }

    $risingBlock = if ($risingRisks.Count -gt 0) {
        ($risingRisks | ForEach-Object {
            $wsName = if ($_.workstream) { $_.workstream } else { '(no workstream)' }
            $ownerText = if ($_.owner) { "owner: $($_.owner)" } else { 'owner: unassigned' }
            $act = $_.recommendedAction
            $actLine = if ($act -is [System.Collections.IDictionary]) {
                $cls = if ($act.actionClass) { "[$($act.actionClass)] " } else { '' }
                $nxt = if ($act.nextAction) { $act.nextAction } else { "$($act.verb) by $($act.dueBy)" }
                "${cls}P$($act.priority) - $nxt"
            } else { '' }
            "- **$wsName** - $($_.severity) severity, aging $($_.agingDays) days, $ownerText`n  - $($_.title) [$($_.riskId)]`n  - $actLine"
        }) -join "`n"
    } else { '_No rising risks in the current window._' }

    $topRisksBlock = if ($topRisks.Count -gt 0) {
        ($topRisks | ForEach-Object {
            $wsName = if ($_.workstream) { $_.workstream } else { '(no workstream)' }
            $ownerText = if ($_.owner) { "owner: $($_.owner)" } else { 'owner: unassigned' }
            $act = $_.recommendedAction
            $actLine = if ($act -is [System.Collections.IDictionary]) {
                $cls = if ($act.actionClass) { "[$($act.actionClass)] " } else { '' }
                $nxt = if ($act.nextAction) { $act.nextAction } else { "$($act.verb) by $($act.dueBy)" }
                "${cls}P$($act.priority) - $nxt"
            } else { '' }
            "- **$wsName** - $($_.severity) severity, $($_.trend) trend, aging $($_.agingDays) days, $ownerText`n  - $($_.title) [$($_.riskId)]`n  - $actLine"
        }) -join "`n"
    } else { '_No open risks in the registry._' }

    $decisionBlock = if ($pendingDecisions.Count -gt 0) {
        ($pendingDecisions | ForEach-Object {
            $wsName = if ($_.workstream) { $_.workstream } else { '(no workstream)' }
            $ownerText = if ($_.owner) { "owner: $($_.owner)" } else { 'owner: unassigned' }
            $act = $_.recommendedFollowUp
            $actLine = if ($act -is [System.Collections.IDictionary]) {
                $cls = if ($act.actionClass) { "[$($act.actionClass)] " } else { '' }
                $nxt = if ($act.nextAction) { $act.nextAction } else { "$($act.verb) by $($act.dueBy)" }
                "${cls}P$($act.priority) - $nxt"
            } else { '' }
            "- **$wsName** - Pending $($_.decisionAgeDays) days, $ownerText`n  - $($_.title) [$($_.decisionId)]`n  - $actLine"
        }) -join "`n"
    } else {
        '_No pending decisions in the registry._'
    }

    $escalatedBlock = if ($escalated.Count -gt 0) {
        ($escalated | ForEach-Object { "- **$($_.workstream.name)** - escalation signal detected." }) -join "`n"
    } else { '_No escalation-tagged workstreams detected._' }

    $actionsBlock = if ($primary.Count -gt 0) {
        ($primary | ForEach-Object {
            $action = switch ($_.category) {
                'P1'         { 'Review progress this week. Ensure blockers are visible to stakeholders.' }
                'P2'         { 'Keep moving. Unblock dependencies where possible.' }
                'Watch'      { 'Monitor. Escalate to P1 if a blocker or deadline appears.' }
                'ParkingLot' { 'Parked. Revisit when capacity allows.' }
                default      { 'Review.' }
            }
            "- **$($_.workstream.name)**: $action"
        }) -join "`n"
    } else { '_No recommended actions today._' }

    $sourceInputs = Get-BriefingSourceInputs -Records $Records
    $sourceBlock = if ($sourceInputs.Count -gt 0) {
        ($sourceInputs | ForEach-Object { "- ``$($_.path)`` ($($_.date), weight $($_.weight))" }) -join "`n"
    } else { '_No high-signal source files in the current window._' }

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Lapu-Lapu Morning Briefing

Generated: $NowStamp

## Executive Snapshot

$execSnap

## Today's Primary Focus

$primaryBlock

## Top 5 Risks

$topRisksBlock

## Rising Risks

$risingBlock

## Decision Watch

$decisionBlock

## Blocked / Escalation Candidates

$escalatedBlock

## Recommended Actions for David

$actionsBlock

## Source Inputs

$sourceBlock

## Agent Notes

- This file is generated.
- Edit workstreams.yaml, priority-overrides.yaml, scoring-model.yaml, source-weights.yaml, or activity-windows.yaml to change behavior.
"@
}

function Build-MorningBriefingJson {
    param(
        [hashtable] $FinalResults,
        [hashtable] $AttentionMap,
        [System.Collections.Generic.List[hashtable]] $Records,
        [hashtable] $Windows,
        [object[]] $DecisionRegistry,
        [object[]] $RiskRegister,
        [string]   $GeneratedIso
    )

    $DecisionRegistry = @($DecisionRegistry | Where-Object { $null -ne $_ })
    $RiskRegister     = @($RiskRegister     | Where-Object { $null -ne $_ })

    $all = @($FinalResults.Values | Sort-Object { $_.attention_score } -Descending)

    $primary = @($all | Where-Object { $_.category -eq 'P1' } | Select-Object -First 5)
    if ($primary.Count -eq 0) { $primary = $all | Select-Object -First 3 }

    # V1.7 Risk highlights
    $severityRankJson = @{ 'High' = 0; 'Medium' = 1; 'Low' = 2 }
    $openRisksJson    = @($RiskRegister | Where-Object { $_.status -ne 'closed' })
    $topRisksJson     = @($openRisksJson | Sort-Object `
        @{ Expression = { $severityRankJson[$_.severity] }; Ascending = $true },
        @{ Expression = { $_.agingDays }; Descending = $true } | Select-Object -First 5)
    $risingRisksJson  = @($openRisksJson | Where-Object { $_.trend -eq 'increasing' } | Sort-Object { $_.agingDays } -Descending | Select-Object -First 10)

    $topRisksList = foreach ($r in $topRisksJson) {
        [ordered]@{
            riskId            = $r.riskId
            workstream        = $r.workstream
            title             = $r.title
            owner             = $r.owner
            ownerConfidence   = $r.ownerConfidence
            escalationPath    = @($r.escalationPath)
            severity          = $r.severity
            trend             = $r.trend
            agingDays         = $r.agingDays
            recencyDays       = $r.recencyDays
            firstSeenDate     = $r.firstSeenDate
            lastSeenDate      = $r.lastSeenDate
            recommendedAction = $r.recommendedAction
        }
    }

    $risingRisksList = foreach ($r in $risingRisksJson) {
        [ordered]@{
            riskId            = $r.riskId
            workstream        = $r.workstream
            title             = $r.title
            owner             = $r.owner
            ownerConfidence   = $r.ownerConfidence
            severity          = $r.severity
            agingDays         = $r.agingDays
            recencyDays       = $r.recencyDays
            firstSeenDate     = $r.firstSeenDate
            lastSeenDate      = $r.lastSeenDate
            recommendedAction = $r.recommendedAction
        }
    }

    $rising = @($all | Where-Object {
        $_.trend_direction -eq 'increasing' -and (
            ($_.signal_counts.ContainsKey('risk_logged') -and $_.signal_counts['risk_logged'] -gt 0) -or
            ($_.signal_counts.ContainsKey('escalation')  -and $_.signal_counts['escalation']  -gt 0)
        )
    })

    $decisions = @($all | Where-Object {
        $_.signal_counts.ContainsKey('decision_logged') -and $_.signal_counts['decision_logged'] -gt 0
    } | Select-Object -First 6)

    $escalated = @($all | Where-Object {
        $_.signal_counts.ContainsKey('escalation') -and $_.signal_counts['escalation'] -gt 0
    } | Select-Object -First 8)

    $primaryList = foreach ($p in $primary) {
        $a = $AttentionMap[$p.workstream.id]
        [ordered]@{
            id                    = $p.workstream.id
            name                  = $p.workstream.name
            category              = $p.category
            attentionScore        = if ($a) { $a.attention_score } else { $p.score }
            strategicScore        = if ($a) { $a.strategic_score } else { $null }
            activityScore         = if ($a) { $a.activity_score }  else { $null }
            trendDirection        = if ($a) { $a.trend_direction } else { 'stable' }
            trendSymbol           = if ($a) { $a.trend_symbol }    else { '' }
            deltaPercent          = if ($a) { $a.trend_delta_percent } else { 0 }
            overrideApplied       = $p.override_applied
            overrideReason        = $p.override_reason
            whyItMatters          = $p.workstream.notes
            recommendedNextAction = switch ($p.category) {
                'P1'         { 'Review progress this week. Ensure blockers are visible to stakeholders.' }
                'P2'         { 'Keep moving. Unblock dependencies where possible.' }
                'Watch'      { 'Monitor. Escalate to P1 if a blocker or deadline appears.' }
                'ParkingLot' { 'Parked. Revisit when capacity allows.' }
                default      { 'Review.' }
            }
            topEvidence           = @($p.evidence_files | Select-Object -First 3)
        }
    }

    $risingList = foreach ($r in $rising) {
        [ordered]@{
            id             = $r.workstream.id
            name           = $r.workstream.name
            trendSymbol    = $r.trend_symbol
            deltaPercent   = $r.trend_delta_percent
            riskSignals    = if ($r.signal_counts.ContainsKey('risk_logged')) { $r.signal_counts['risk_logged'] } else { 0 }
            escalationSignals = if ($r.signal_counts.ContainsKey('escalation')) { $r.signal_counts['escalation'] } else { 0 }
        }
    }

    $decisionList = foreach ($d in $decisions) {
        [ordered]@{
            id              = $d.workstream.id
            name            = $d.workstream.name
            decisionSignals = if ($d.signal_counts.ContainsKey('decision_logged')) { $d.signal_counts['decision_logged'] } else { 0 }
        }
    }

    # V1.6 Decision Pressure: registry-derived, oldest open decisions first.
    $decisionPressureList = foreach ($e in ($DecisionRegistry | Where-Object { $_.status -ne 'closed' } | Select-Object -First 10)) {
        [ordered]@{
            decisionId      = $e.decisionId
            workstream      = $e.workstream
            title           = $e.title
            owner           = $e.owner
            ownerConfidence = $e.ownerConfidence
            escalationPath  = @($e.escalationPath)
            decisionAgeDays = $e.decisionAgeDays
            recencyDays     = $e.recencyDays
            firstSeenDate   = $e.firstSeenDate
            lastSeenDate    = $e.lastSeenDate
            dateDetected    = $e.dateDetected
            followUp        = $e.recommendedFollowUp
        }
    }

    $escList = foreach ($e in $escalated) {
        [ordered]@{
            id               = $e.workstream.id
            name             = $e.workstream.name
            escalationSignals= if ($e.signal_counts.ContainsKey('escalation')) { $e.signal_counts['escalation'] } else { 0 }
            category         = $e.category
        }
    }

    $actionList = foreach ($p in $primary) {
        $action = switch ($p.category) {
            'P1'         { 'Review progress this week. Ensure blockers are visible to stakeholders.' }
            'P2'         { 'Keep moving. Unblock dependencies where possible.' }
            'Watch'      { 'Monitor. Escalate to P1 if a blocker or deadline appears.' }
            'ParkingLot' { 'Parked. Revisit when capacity allows.' }
            default      { 'Review.' }
        }
        [ordered]@{
            id     = $p.workstream.id
            name   = $p.workstream.name
            action = $action
        }
    }

    $sourceInputs = Get-BriefingSourceInputs -Records $Records
    $sourceList = foreach ($s in $sourceInputs) {
        [ordered]@{
            path   = $s.path
            weight = $s.weight
            window = $s.window
            date   = $s.date
        }
    }

    $p1Count    = @($all | Where-Object { $_.category -eq 'P1' }).Count
    $watchCount = @($all | Where-Object { $_.category -eq 'Watch' }).Count
    $incCount   = @($all | Where-Object { $_.trend_direction -eq 'increasing' }).Count
    $topName    = if ($all.Count -gt 0) { $all[0].workstream.name } else { 'none' }
    $execSnap = "The Lapu-Lapu operating picture shows $p1Count P1 workstream(s) and $watchCount watch item(s). " +
                "$incCount workstream(s) show increasing activity in the last $($Windows.current.days) days. " +
                "Top attention today is on $topName."

    $out = [ordered]@{
        generated                     = $GeneratedIso
        generator                     = 'scripts/generate-current-focus.ps1'
        version                       = 'V3.0'
        executiveSnapshot             = $execSnap
        primaryFocus                  = @($primaryList)
        risingRisks                   = @($risingList)
        topRisks                      = @($topRisksList)
        risksTrendingUp               = @($risingRisksList)
        decisionWatch                 = @($decisionList)
        decisionPressure              = @($decisionPressureList)
        blockedOrEscalationCandidates = @($escList)
        recommendedActionsForDavid    = @($actionList)
        sourceInputs                  = @($sourceList)
    }
    return $out | ConvertTo-Json -Depth 6
}

# --- V1.6 Decision Intelligence ---------------------------------------------

$script:DECISION_KEYWORDS = @(
    'Decision', 'Decided', 'Approved', 'Agreed', 'Consensus',
    'Green Light', 'Proceed with', 'Selected', 'Chosen'
)

# V2.0: pending-decision keywords - lines that indicate David needs to decide,
# rather than lines that record a decision already made.
$script:PENDING_DECISION_KEYWORDS = @(
    'Question', 'TBD', 'Awaiting decision', 'Need to decide', 'Open question',
    'Pending decision', 'Decision needed', 'Decide', 'Requires decision',
    'Awaiting sign-off', 'Approval needed', 'Confirm'
)

function New-DecisionId {
    param([string] $Seed)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Seed.ToLowerInvariant())
        $hash  = $sha1.ComputeHash($bytes)
        $hex   = -join ($hash | ForEach-Object { $_.ToString('x2') })
        return 'D-' + $hex.Substring(0, 10)
    } finally { $sha1.Dispose() }
}

# V4.0 Phase 1 - Canonical MatryoshkaItem validation.
# Mirror of ui/src/lib/matryoshka-item.ts validateItem(). Runs the same quality
# gates in PowerShell so the generator can produce 00-context/generated/rejected-items.json
# during the V3-to-V4 migration window.

$script:MAT_REQUIRED_FIELDS = @(
    'id', 'type', 'title', 'owner', 'owner_confidence',
    'why_it_matters', 'next_action', 'action_class',
    'status', 'status_reason', 'aging_days',
    'source', 'context_summary', 'confidence_score',
    'first_seen', 'last_updated'
)

$script:MAT_APPROVED_VERBS_REGEX = '(?i)^\s*(Send|Ask|Confirm|Decide|Investigate|Deploy|Create|Publish|Write|Complete|Finish|Implement|Escalate|Contact|Choose|Approve|Assign|Close|Draft|Schedule|Present|Review with|Sign|Verify)\b'
$script:MAT_VAGUE_VERBS_REGEX   = '(?i)\b(look into|handle|touch base|circle back|keep an eye|check on)\b'
$script:MAT_IMPACT_WORDS_REGEX  = '(?i)\b(because|so that|otherwise|risk|impact|blocks|delays|prevents|enables|requires|deadline|outcome|drives|unblocks|depends on)\b'
$script:MAT_BANNED_TITLE_REGEX  = '(?i)^\s*(escalate|todo|fix)\s*:'

# --- V4.0 Sprint 19 - Corpus Title Normalization ---------------------------
# Applied at decision + risk extraction time to eliminate malformed titles
# BEFORE they enter the canonical model. Two-stage:
#   1. Normalize-CorpusTitle: strip source-markup noise (bold, tags, prefixes)
#   2. Test-CorpusTitleValid: reject titles that are still garbage after cleanup
# Extraction sites `continue` past any candidate that fails validation so
# downstream consumers (registry, matryoshka-items.json, weekly report,
# dashboard) never see the noise. Drop counts are logged to pipeline output.

$script:MAT_TITLE_STRIP_TAGS_REGEX     = '(?i)\s*\[(?:ISSUE|NEW|WIP|TODO|BLOCKED|DRAFT|DEFERRED|CLOSED|OPEN|risk[^\]]*|decision[^\]]*|action[^\]]*|score[^\]]*)\]\s*'
$script:MAT_TITLE_STRIP_SCORE_REGEX    = '(?i)\s*[\(\[]?score\s*\d+[\)\]]?\s*'
$script:MAT_TITLE_STRIP_OWNER_REGEX    = '(?i)\s+[-—–]?\s*owner\s*:\s*[^;\r\n]+'
$script:MAT_TITLE_STRIP_SEVERITY_REGEX = '(?i)\s*\((?:risk|decision|action|item)/[a-z]+\)\s*'
$script:MAT_TITLE_STRIP_META_REGEX     = '(?i)\s*(?:next\s*:|source\s*:|via\s*:|by\s*:|conf\s*:|generated_?on\s*:).*$'
$script:MAT_TITLE_STRIP_ELLIPSIS       = '(?:\s*(?:\.{3}|…)\s*[-—–]?.*)$'

function Normalize-CorpusTitle {
    <#
        V4.0 Sprint 19: strips known-noisy markup fragments from a raw title
        candidate BEFORE it enters the canonical model. Returns the cleaned
        string. Idempotent - running twice produces the same result.
    #>
    param([string] $Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return '' }
    $t = ($Raw -replace '\s+', ' ').Trim()
    # Repeat until stable so nested `[ISSUE] [ISSUE]` gets fully unwound.
    for ($i = 0; $i -lt 3; $i++) {
        $before = $t
        $t = $t -replace $script:MAT_TITLE_STRIP_TAGS_REGEX,     ' '
        $t = $t -replace $script:MAT_TITLE_STRIP_SCORE_REGEX,    ' '
        $t = $t -replace $script:MAT_TITLE_STRIP_OWNER_REGEX,    ''
        $t = $t -replace $script:MAT_TITLE_STRIP_SEVERITY_REGEX, ' '
        $t = $t -replace $script:MAT_TITLE_STRIP_META_REGEX,     ''
        $t = $t -replace '\*\*', ''
        $t = $t -replace '__', ''
        $t = $t -replace '`+', ''
        $t = $t -replace '^\s*(?:#{1,6}|>+)\s*', ''
        $t = $t -replace '^\s*[-*•]\s+', ''
        $t = $t -replace $script:MAT_TITLE_STRIP_ELLIPSIS, ''
        $t = $t.Trim().Trim(':', '—', '-', '–', '.', ',', ';')
        $t = ($t -replace '\s+', ' ').Trim()
        if ($t -eq $before) { break }
    }
    return $t
}

function Test-CorpusTitleValid {
    <#
        V4.0 Sprint 19: returns @{ ok = <bool>; reason = <string> }.
        Rejects titles that are still noise after Normalize-CorpusTitle.
        Rules:
          - non-empty, >= 3 chars
          - not entirely numeric / decimal score (0.05, 70, 0.083)
          - not a bare person name (single stakeholder identifier)
          - at least 3 meaningful word tokens
          - at least one alphabetic character
    #>
    param([string] $Title, [string[]] $StakeholderNames = @())
    if ([string]::IsNullOrWhiteSpace($Title)) {
        return @{ ok = $false; reason = 'empty after normalization' }
    }
    $t = $Title.Trim()
    if ($t.Length -lt 3) {
        return @{ ok = $false; reason = 'too short' }
    }
    if ($t -match '^\s*\-?\d+(?:\.\d+)?\s*$') {
        return @{ ok = $false; reason = "numeric-only title '$t'" }
    }
    if ($t -match '^\s*(?:score\s+)?\d+(?:\.\d+)?\s*(?:score)?\s*$') {
        return @{ ok = $false; reason = "score fragment '$t'" }
    }
    $letterCount = ([regex]::Matches($t, '[A-Za-z]')).Count
    if ($letterCount -lt 3) {
        return @{ ok = $false; reason = 'insufficient alphabetic content' }
    }
    $words = @($t -split '\s+' | Where-Object { $_ -match '[A-Za-z]' -and $_.Length -ge 2 })
    if ($words.Count -lt 3) {
        return @{ ok = $false; reason = "only $($words.Count) meaningful word(s)" }
    }
    foreach ($n in $StakeholderNames) {
        if ($n -and $t -match ('^\s*' + [regex]::Escape($n) + '\s*$')) {
            return @{ ok = $false; reason = "person-name-only '$n'" }
        }
    }
    return @{ ok = $true; reason = '' }
}

$script:MAT_TITLE_DROPS = [System.Collections.Generic.List[hashtable]]::new()

function Add-TitleDropRecord {
    param([string] $Kind, [string] $RawTitle, [string] $NormalizedTitle, [string] $Reason, [string] $SourcePath)
    [void]$script:MAT_TITLE_DROPS.Add(@{
        kind       = $Kind
        rawTitle   = $RawTitle
        normalized = $NormalizedTitle
        reason     = $Reason
        source     = $SourcePath
    })
}

function Test-MatryoshkaItem {
    <#
        V4.0 Phase 1 validator. Given a candidate hashtable with MatryoshkaItem-
        shaped fields, returns:
            @{ ok = $true;  item = <candidate> }
            @{ ok = $false; errors = @(@{ itemId; field; reason }, ...) }
        Mirrors ui/src/lib/matryoshka-item.ts validateItem() rules 1:1.
    #>
    param([hashtable] $Candidate)

    $errors = [System.Collections.Generic.List[hashtable]]::new()
    $id = if ($Candidate.ContainsKey('id') -and $Candidate.id) { [string]$Candidate.id } else { '(no-id)' }

    foreach ($f in $script:MAT_REQUIRED_FIELDS) {
        $v = $null
        if ($Candidate.ContainsKey($f)) { $v = $Candidate[$f] }
        $missing = $false
        if ($null -eq $v) { $missing = $true }
        elseif ($v -is [string] -and [string]::IsNullOrWhiteSpace($v)) { $missing = $true }
        if ($missing) {
            # V4.0 Sprint 15: promote the missing-why gap to its own error code
            # so the rejected-items report separates 'missing' from 'weak/generic/duplicate'.
            $fieldLabel = if ($f -eq 'why_it_matters') { 'missing_why_it_matters' } else { $f }
            $errors.Add(@{ itemId = $id; field = $fieldLabel; reason = 'missing required field' })
        }
    }

    $title = if ($Candidate.ContainsKey('title')) { [string]$Candidate.title } else { '' }
    if ($title) {
        if ($title.Length -gt 140) {
            $errors.Add(@{ itemId = $id; field = 'title'; reason = 'exceeds 140 chars' })
        }
        if ($title -match $script:MAT_BANNED_TITLE_REGEX) {
            $errors.Add(@{ itemId = $id; field = 'title'; reason = "title must not start with imperative verb (Escalate/Todo/Fix) - that's what action_class is for" })
        }
    }

    $why = if ($Candidate.ContainsKey('why_it_matters')) { [string]$Candidate.why_it_matters } else { '' }
    if ([string]::IsNullOrWhiteSpace($why)) {
        # Only report 'missing' if the required-field pass didn't already flag it.
        # (It always does; skip to avoid double-counting.)
    }
    else {
        # V4.0 Sprint 15 validator v2: split the single 'why_it_matters' error
        # into distinct categories so the rejected-items report shows exactly
        # where the semantic gap is.
        $isGeneric = ($why -match $script:MAT_WHY_GENERIC_REGEX) -or ($why.Trim().Length -lt 15)
        if ($isGeneric) {
            $errors.Add(@{ itemId = $id; field = 'generic_why_it_matters'; reason = 'matches generic pattern (needs attention / tbd / follow up required) - replace with concrete impact statement' })
        }
        $sentences = @($why -split '[.!?]' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($sentences.Count -gt 1) {
            $errors.Add(@{ itemId = $id; field = 'why_it_matters'; reason = 'must be exactly 1 sentence' })
        }
        if (-not $isGeneric -and $why -notmatch $script:MAT_IMPACT_WORDS_REGEX) {
            $errors.Add(@{ itemId = $id; field = 'weak_why_it_matters'; reason = 'must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)' })
        }
        # Duplicate check: was this exact string seen 2+ times across the corpus?
        if ($script:MAT_WHY_FINGERPRINTS -is [System.Collections.IDictionary]) {
            $fp = ($why.Trim().ToLowerInvariant())
            if ($fp -and $script:MAT_WHY_FINGERPRINTS.ContainsKey($fp) -and [int]$script:MAT_WHY_FINGERPRINTS[$fp] -ge 2) {
                $errors.Add(@{ itemId = $id; field = 'duplicate_why_it_matters'; reason = ("shares why_it_matters with {0} other item(s) - each item needs a specific impact statement" -f ([int]$script:MAT_WHY_FINGERPRINTS[$fp] - 1)) })
            }
        }
    }

    $next = if ($Candidate.ContainsKey('next_action')) { [string]$Candidate.next_action } else { '' }
    if ($next) {
        $words = @($next.Trim() -split '\s+' | Where-Object { $_ })
        if ($words.Count -lt 5) {
            $errors.Add(@{ itemId = $id; field = 'next_action'; reason = 'must be at least 5 meaningful words' })
        }
        if ($next -notmatch $script:MAT_APPROVED_VERBS_REGEX) {
            $errors.Add(@{ itemId = $id; field = 'next_action'; reason = 'must start with an approved imperative verb (Send/Ask/Confirm/Decide/Investigate/Deploy/Create/Publish/Write/Complete/Finish/Implement/Escalate/Contact/Choose/Approve/Assign/Close/Draft/Schedule/Present/Sign/Verify)' })
        }
        if ($next -match $script:MAT_VAGUE_VERBS_REGEX) {
            $errors.Add(@{ itemId = $id; field = 'next_action'; reason = 'contains vague verb (look into / handle / touch base / circle back / keep an eye / check on) - replace with concrete action' })
        }
    }

    if ($Candidate.ContainsKey('confidence_score') -and $null -ne $Candidate.confidence_score) {
        $cs = [double]$Candidate.confidence_score
        if ($cs -lt 0.0 -or $cs -gt 1.0) {
            $errors.Add(@{ itemId = $id; field = 'confidence_score'; reason = 'must be in [0,1]' })
        }
    }

    if ($Candidate.ContainsKey('aging_days') -and $null -ne $Candidate.aging_days -and [int]$Candidate.aging_days -lt 0) {
        $errors.Add(@{ itemId = $id; field = 'aging_days'; reason = 'must be non-negative' })
    }

    if ($errors.Count -eq 0) {
        return @{ ok = $true; item = $Candidate }
    }
    return @{ ok = $false; errors = @($errors) }
}

function ConvertTo-MatryoshkaCandidate {
    <#
        V4.0 Phase 1 adapter. Maps a V3.x decision or risk entry hashtable to a
        MatryoshkaItem-shaped candidate hashtable so it can be run through
        Test-MatryoshkaItem. Preserves V3 field values; fills in V4-only fields
        with best-effort derivations (or leaves them blank so the validator
        will flag the specific gap).
    #>
    param(
        [ValidateSet('decision','risk')] [string] $Kind,
        [hashtable] $Entry
    )

    $act = if ($Kind -eq 'decision') { $Entry.recommendedFollowUp } else { $Entry.recommendedAction }
    $actionClass = ''
    $nextAction  = ''
    if ($act -is [System.Collections.IDictionary]) {
        if ($act.actionClass) { $actionClass = [string]$act.actionClass }
        if ($act.nextAction)  { $nextAction  = [string]$act.nextAction  }
    }

    $ownerConfidence = if ($Entry.ownerConfidence) { [string]$Entry.ownerConfidence } else { '' }
    # V4 taxonomy only has high|medium|low - remap legacy V3 values.
    switch ($ownerConfidence) {
        'workstream-map' { $ownerConfidence = 'low'    }
        'name-proximity' { $ownerConfidence = 'medium' }
        'unknown'        { $ownerConfidence = 'low'    }
    }

    $ageDays = if ($Kind -eq 'decision') { [int]([Math]::Max(0, [int]$Entry.decisionAgeDays)) } else { [int]([Math]::Max(0, [int]$Entry.agingDays)) }
    $firstSeen  = if ($Entry.firstSeenDate) { [string]$Entry.firstSeenDate } else { '' }
    $lastUpdate = if ($Entry.lastSeenDate)  { [string]$Entry.lastSeenDate  } else { '' }
    $confScore  = 0.0
    if ($Kind -eq 'decision' -and $Entry.decisionConfidence) { $confScore = [double]$Entry.decisionConfidence }
    elseif ($Kind -eq 'risk' -and $Entry.riskConfidence)     { $confScore = [double]$Entry.riskConfidence }
    if ($confScore -gt 1.0) { $confScore = 1.0 }
    if ($confScore -lt 0.0) { $confScore = 0.0 }

    $primarySource = ''
    if ($Entry.sourceFiles -and @($Entry.sourceFiles).Count -gt 0) {
        $primarySource = [string](@($Entry.sourceFiles)[0])
    }

    $contextSummary = ''
    # V4.0 Phase 5: prefer the source-paragraph excerpt when Apply-ContextLinking
    # has already enriched the entry. Falls back to V3 free-text on unenriched runs.
    if ($Entry.ContainsKey('contextSummary') -and -not [string]::IsNullOrWhiteSpace([string]$Entry.contextSummary)) {
        $contextSummary = [string]$Entry.contextSummary
    }
    elseif ($Kind -eq 'decision' -and $Entry.decisionSummary) { $contextSummary = [string]$Entry.decisionSummary }
    elseif ($Kind -eq 'risk' -and $Entry.impact)              { $contextSummary = [string]$Entry.impact }

    $whyItMatters = ''
    # V4.0 Sprint 15: prefer the canonical extractor output when available.
    if ($Entry.ContainsKey('whyItMatters') -and -not [string]::IsNullOrWhiteSpace([string]$Entry.whyItMatters)) {
        $whyItMatters = [string]$Entry.whyItMatters
    }
    elseif ($Entry.impact) { $whyItMatters = [string]$Entry.impact }
    elseif ($Kind -eq 'decision' -and $Entry.decisionPrompt) { $whyItMatters = [string]$Entry.decisionPrompt }

    # V4.0 Phase 1c: use the canonical status ladder when available (populated
    # by Apply-MatryoshkaStatus). Falls back to inline derivation for entries
    # that pre-date the enrichment pass.
    if ($Entry.ContainsKey('matryoshkaStatus') -and $Entry.matryoshkaStatus) {
        $status       = [string]$Entry.matryoshkaStatus
        $statusReason = if ($Entry.matryoshkaStatusReason) { [string]$Entry.matryoshkaStatusReason } else { '' }
    } else {
        $status = 'green'
        if ($Kind -eq 'risk' -and $Entry.severity -eq 'High') { $status = 'red' }
        elseif ($actionClass -eq 'BLOCKED') { $status = 'red' }
        elseif ($ownerConfidence -eq 'low') { $status = 'amber' }
        elseif ($confScore -lt 0.4)         { $status = 'amber' }

        $statusReason =
            if ($Kind -eq 'risk' -and $Entry.severity -eq 'High') { 'high-severity risk' }
            elseif ($actionClass -eq 'BLOCKED')                   { 'blocked action_class' }
            elseif ($ownerConfidence -eq 'low')                   { 'owner not confirmed' }
            elseif ($confScore -lt 0.4)                           { "low confidence ($confScore)" }
            else                                                  { 'active progress, no blockers' }
    }

    $matType = if ($Kind -eq 'decision') { 'decision' } else { 'risk' }
    $entryId = if ($Kind -eq 'decision') { [string]$Entry.decisionId } else { [string]$Entry.riskId }

    return @{
        id                = $entryId
        type              = $matType
        title             = if ($Entry.title) { [string]$Entry.title } else { '' }
        owner             = if ($Entry.owner) { [string]$Entry.owner } else { '' }
        suggested_owner   = if ($Entry.ContainsKey('suggestedOwner')) { [string]$Entry.suggestedOwner } else { '' }
        owner_confidence  = $ownerConfidence
        why_it_matters    = $whyItMatters
        next_action       = $nextAction
        action_class      = $actionClass
        workstream        = if ($Entry.workstream) { [string]$Entry.workstream } else { '' }
        status            = $status
        status_reason     = $statusReason
        aging_days        = $ageDays
        stale             = if ($Entry.ContainsKey('stale')) { [bool]$Entry.stale } else { $false }
        source            = $primarySource
        context_summary   = $contextSummary
        related_items     = @()
        confidence_score  = $confScore
        merged_from       = @()
        first_seen        = $firstSeen
        last_updated      = $lastUpdate
    }
}

function Get-StaleFlag {
    <#
        V4.0 Phase 3: staleness predicate.
        Returns $true when an entry should be hidden from the priority inbox
        and collapsed on registers.

        Rules (in order):
          - Actively updated in last 7 days   -> NOT stale
          - Actively worked (DO/DECIDE class) -> NOT stale
          - High severity risk (equivalent to red) -> NOT stale
          - Age > 30 days                     -> STALE
          - No update in > 14 days            -> STALE
          - Otherwise                         -> NOT stale
    #>
    param([hashtable] $Entry, [string] $Kind)

    $age = 0
    if ($Kind -eq 'decision' -and $Entry.decisionAgeDays) { $age = [int]$Entry.decisionAgeDays }
    elseif ($Kind -eq 'risk' -and $Entry.agingDays)       { $age = [int]$Entry.agingDays }

    $daysSinceUpdate = if ($null -ne $Entry.recencyDays) { [int]$Entry.recencyDays } else { $age }

    if ($daysSinceUpdate -le 7) { return $false }

    $act = if ($Kind -eq 'decision') { $Entry.recommendedFollowUp } else { $Entry.recommendedAction }
    if ($act -is [System.Collections.IDictionary]) {
        $cls = [string]$act.actionClass
        if ($cls -eq 'DO' -or $cls -eq 'DECIDE') { return $false }
    }

    if ($Kind -eq 'risk' -and $Entry.severity -eq 'High') { return $false }

    if ($age -gt 30) { return $true }
    if ($daysSinceUpdate -gt 14) { return $true }
    return $false
}

# V4.0 Phase 6 - Dedup + unified confidence.
# Fuzzy-groups items by Jaccard-token similarity on their normalized titles
# (within same workstream + kind), keeps the freshest as the winner, records
# the merged IDs on `mergedFrom`, and unions source-file lists so the confidence
# formula sees all mentions. Confidence uses the V4.0 unified formula.

$script:MAT_TITLE_STOPWORDS = @(
    'a','an','the','of','to','for','and','or','in','on','at','by','with','from',
    'is','are','was','were','be','been','being','has','have','had','do','does',
    'this','that','these','those','it','its','as','but','if','not','no','yes',
    'we','they','you','i','our','your','their',
    'into','including','includes','include','onto','upon','via','across','about',
    'per','also','still','then','than','some','any','more','most','less','when',
    'while','before','after','over','under','between','among','both','either','each'
)

function Get-TitleTokens {
    <#
        Extracts meaningful (>=3 char) tokens from a title, lower-cased, with
        stopwords removed. Used by the Phase 6 Jaccard similarity check.
    #>
    param([string] $Title)
    if ([string]::IsNullOrWhiteSpace($Title)) { return @() }
    $norm = Get-NormalizedTitle -Title $Title
    if (-not $norm) { return @() }
    $tokens = @($norm -split '[^a-z0-9]+' | Where-Object { $_ -and $_.Length -ge 3 -and ($script:MAT_TITLE_STOPWORDS -notcontains $_) })
    return @($tokens | Sort-Object -Unique)
}

function Get-JaccardSimilarity {
    param([string[]] $A, [string[]] $B)
    if (-not $A -or -not $B) { return 0.0 }
    $aSet = @($A | Sort-Object -Unique)
    $bSet = @($B | Sort-Object -Unique)
    if ($aSet.Count -eq 0 -or $bSet.Count -eq 0) { return 0.0 }
    $bLookup = @{}
    foreach ($t in $bSet) { $bLookup[$t] = $true }
    $intersection = 0
    foreach ($t in $aSet) { if ($bLookup.ContainsKey($t)) { $intersection++ } }
    $union = $aSet.Count + $bSet.Count - $intersection
    if ($union -eq 0) { return 0.0 }
    return ([double]$intersection) / [double]$union
}

function Test-TitleSimilarity {
    <#
        V4.0 Phase 6a similarity predicate: returns $true if two token sets
        describe the same underlying item. Uses TWO heuristics because raw
        extracted titles from V3.x are noisy paragraph fragments:
          1. Jaccard >= $JaccardThreshold (default 0.5) - catches concise-title dupes
          2. Containment >= $ContainmentThreshold AND intersection >= 3 - catches
             the "same short phrase quoted inside two longer sentences" case
             (Ingenium rehearsal example from the spec).
        Either passing counts as a match.
    #>
    param(
        [string[]] $A,
        [string[]] $B,
        [double]   $JaccardThreshold = 0.5,
        [double]   $ContainmentThreshold = 0.7,
        [int]      $MinIntersectionForContainment = 3
    )
    if (-not $A -or -not $B) { return $false }
    $aSet = @($A | Sort-Object -Unique)
    $bSet = @($B | Sort-Object -Unique)
    if ($aSet.Count -eq 0 -or $bSet.Count -eq 0) { return $false }
    $bLookup = @{}
    foreach ($t in $bSet) { $bLookup[$t] = $true }
    $intersection = 0
    foreach ($t in $aSet) { if ($bLookup.ContainsKey($t)) { $intersection++ } }
    if ($intersection -eq 0) { return $false }

    $union = $aSet.Count + $bSet.Count - $intersection
    $jaccard = if ($union -gt 0) { ([double]$intersection) / [double]$union } else { 0.0 }
    if ($jaccard -ge $JaccardThreshold) { return $true }

    $minSet = [Math]::Min($aSet.Count, $bSet.Count)
    if ($minSet -gt 0) {
        $containment = ([double]$intersection) / [double]$minSet
        if ($containment -ge $ContainmentThreshold -and $intersection -ge $MinIntersectionForContainment) {
            return $true
        }
    }
    return $false
}

function Get-SourceQualityWeight {
    <#
        V4.0 Phase 6c: source-quality weight for the unified confidence formula.
        High-signal authoritative sources (curated 02-work + 00-context/generated
        registers) score 1.0. Meeting/status/reporting sources score 0.7. Inbox
        archive material scores 0.4. Anything else defaults to 0.5.
    #>
    param([string[]] $SourceFiles)
    if (-not $SourceFiles -or @($SourceFiles).Count -eq 0) { return 0.5 }
    $best = 0.0
    foreach ($p in @($SourceFiles)) {
        $lc = ([string]$p).ToLowerInvariant() -replace '\\','/'
        $score = 0.5
        if ($lc -match '(?i)02-work/(tasks|decisions|key-results)\.md$') { $score = 1.0 }
        elseif ($lc -match '(?i)00-context/generated/') { $score = 1.0 }
        elseif ($lc -match '(?i)03-reporting/') { $score = 0.7 }
        elseif ($lc -match '(?i)01-inbox/copilot-activity/') { $score = 0.7 }
        elseif ($lc -match '(?i)01-inbox/archive/') { $score = 0.4 }
        elseif ($lc -match '(?i)01-inbox/') { $score = 0.6 }
        if ($score -gt $best) { $best = $score }
    }
    return $best
}

function Get-UnifiedConfidence {
    <#
        V4.0 Phase 6c unified confidence formula:
            0.4 * owner_confidence_weight (high=1.0, medium=0.5, low=0.0)
          + 0.3 * min(1, log10(mention_count+1) / log10(6))
          + 0.2 * recency_weight (1.0 if <=7d, linear to 0 at 30d)
          + 0.1 * source_quality_weight
        Clamped to [0,1].
    #>
    param([hashtable] $Entry, [string] $Kind)

    $oc = if ($Entry.ownerConfidence) { [string]$Entry.ownerConfidence } else { 'low' }
    $ocWeight = switch ($oc) {
        'high'           { 1.0 }
        'medium'         { 0.5 }
        'name-proximity' { 0.5 }
        default          { 0.0 }
    }

    $mentions = if ($Entry.sourceFiles) { @($Entry.sourceFiles).Count } else { 0 }
    if ($mentions -lt 1) { $mentions = 1 }
    $mentionTerm = 0.0
    if ($mentions -gt 0) {
        $numer = [Math]::Log10([double]($mentions + 1))
        $denom = [Math]::Log10(6.0)
        $mentionTerm = $numer / $denom
        if ($mentionTerm -gt 1.0) { $mentionTerm = 1.0 }
    }

    $recency = if ($null -ne $Entry.recencyDays) { [double]$Entry.recencyDays } else {
        if ($Kind -eq 'decision' -and $Entry.decisionAgeDays) { [double]$Entry.decisionAgeDays }
        elseif ($Kind -eq 'risk' -and $Entry.agingDays)       { [double]$Entry.agingDays }
        else { 30.0 }
    }
    $recencyWeight = 0.0
    if ($recency -le 7)      { $recencyWeight = 1.0 }
    elseif ($recency -ge 30) { $recencyWeight = 0.0 }
    else                     { $recencyWeight = (30.0 - $recency) / 23.0 }

    $sourceWeight = Get-SourceQualityWeight -SourceFiles $Entry.sourceFiles

    $score = (0.4 * $ocWeight) + (0.3 * $mentionTerm) + (0.2 * $recencyWeight) + (0.1 * $sourceWeight)
    if ($score -lt 0.0) { $score = 0.0 }
    if ($score -gt 1.0) { $score = 1.0 }
    return [Math]::Round($score, 3)
}

function Merge-DuplicateEntries {
    <#
        V4.0 Phase 6a-b: fuzzy dedup pass across a set of already-finalized
        decision or risk entries. Groups by Jaccard token similarity >= 0.6 on
        their normalized titles, within the same workstream + kind. In each
        group the entry with the most recent lastSeenDate is the winner; loser
        IDs are stored on the winner's `mergedFrom` array and their source files
        are unioned into the winner's sourceFiles. `mentionCount`,
        `unifiedConfidence`, and (a refreshed) `stale` flag are recomputed on
        the winner. Loser entries are dropped from the returned collection.

        Returns @{ items = <deduped entries>; mergedGroups = @(...) }.
    #>
    param(
        [object[]] $Entries,
        [ValidateSet('decision','risk')] [string] $Kind,
        [double]   $Threshold = 0.5
    )

    $entries = @($Entries | Where-Object { $null -ne $_ })
    if ($entries.Count -eq 0) { return @{ items = @(); mergedGroups = @() } }

    # Pre-compute tokens for each entry.
    $meta = @()
    foreach ($e in $entries) {
        $meta += [pscustomobject]@{
            Entry    = $e
            Tokens   = Get-TitleTokens -Title ([string]$e.title)
            Group    = -1
            LastSeen = if ($e.lastSeenDate) { [string]$e.lastSeenDate } else { '' }
        }
    }

    # Greedy grouping: each entry joins the first group it exceeds threshold
    # against (representative-based), respecting workstream + kind.
    $groupReps = @()   # array of meta entries that represent each group
    $groupIdx  = 0
    foreach ($m in $meta) {
        $joined = $false
        for ($g = 0; $g -lt $groupReps.Count; $g++) {
            $rep = $groupReps[$g]
            if ([string]$rep.Entry.workstream -ne [string]$m.Entry.workstream) { continue }
            if (Test-TitleSimilarity -A $m.Tokens -B $rep.Tokens -JaccardThreshold $Threshold) {
                $m.Group = $g
                $joined  = $true
                break
            }
        }
        if (-not $joined) {
            $m.Group    = $groupIdx
            $groupReps += $m
            $groupIdx++
        }
    }

    $mergedGroups = [System.Collections.Generic.List[hashtable]]::new()
    $winners      = [System.Collections.Generic.List[hashtable]]::new()

    for ($g = 0; $g -lt $groupIdx; $g++) {
        $members = @($meta | Where-Object { $_.Group -eq $g })
        if ($members.Count -eq 1) {
            $solo = $members[0].Entry
            $solo.mentionCount      = if ($solo.sourceFiles) { @($solo.sourceFiles).Count } else { 1 }
            $solo.mergedFrom        = @()
            $solo.unifiedConfidence = Get-UnifiedConfidence -Entry $solo -Kind $Kind
            $winners.Add($solo)
            continue
        }

        # Winner = most recent lastSeenDate (fall back to age asc = age smallest = freshest).
        $sorted = $members | Sort-Object -Property @{ Expression = { $_.LastSeen }; Descending = $true }
        $winnerMeta = $sorted[0]
        $winner     = $winnerMeta.Entry

        $losers = @($sorted | Select-Object -Skip 1 | ForEach-Object { $_.Entry })

        $unionSources = [System.Collections.Generic.List[string]]::new()
        foreach ($p in @($winner.sourceFiles)) { if ($p -and -not $unionSources.Contains($p)) { $unionSources.Add($p) } }
        foreach ($l in $losers) {
            foreach ($p in @($l.sourceFiles)) { if ($p -and -not $unionSources.Contains($p)) { $unionSources.Add($p) } }
        }
        $winner.sourceFiles = @($unionSources)

        $mergedIds = @($losers | ForEach-Object { if ($Kind -eq 'decision') { $_.decisionId } else { $_.riskId } })
        $winner.mergedFrom   = @($mergedIds)
        $winner.mentionCount = $unionSources.Count + $losers.Count   # unique source files + duplicate item mentions

        # Recompute freshness-sensitive fields on the winner using its own
        # (winner's) lastSeenDate; other losers dropped.
        $winner.unifiedConfidence = Get-UnifiedConfidence -Entry $winner -Kind $Kind
        # Refresh staleness on the winner in case source-union bumps it out of stale.
        $winner.stale = Get-StaleFlag -Entry $winner -Kind $Kind

        $winners.Add($winner)

        $mergedGroups.Add(@{
            winnerId  = if ($Kind -eq 'decision') { $winner.decisionId } else { $winner.riskId }
            mergedIds = @($mergedIds)
            title     = [string]$winner.title
            workstream = [string]$winner.workstream
            confidence = [double]$winner.unifiedConfidence
        })
    }

    return @{
        items        = @($winners)
        mergedGroups = @($mergedGroups)
    }
}

# V4.0 Phase 4 - Daily Delta System.
# Persists a rolling per-day snapshot of all live decisions + risks under
# 00-context/generated/snapshots/YYYY-MM-DD.json, computes added/removed/changed
# vs. the most recent prior snapshot, and stamps a `delta` object on every
# entry (days_since_last_touched, updated_since_yesterday, change_summary).

function Get-SnapshotDir {
    return (Join-Path $GEN 'snapshots')
}

function Get-ItemFingerprint {
    <#
        V4.0 Phase 4b: content-only SHA1 of `title|owner|status|next_action|last_updated`.
        Intentionally ignores confidence/aging/log so timestamp drift alone
        does not register as a change.
    #>
    param([hashtable] $Item)
    $seed = @(
        [string]$Item.title,
        [string]$Item.owner,
        [string]$Item.status,
        [string]$Item.nextAction,
        [string]$Item.lastSeenDate
    ) -join '|'
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($seed.ToLowerInvariant())
        $hash  = $sha1.ComputeHash($bytes)
        return (-join ($hash | ForEach-Object { $_.ToString('x2') })).Substring(0, 16)
    } finally { $sha1.Dispose() }
}

function ConvertTo-SnapshotEntry {
    <#
        V4.0 Phase 4a: minimal, stable per-item shape for snapshotting.
        Deliberately narrow so fingerprints are content-driven.
    #>
    param(
        [ValidateSet('decision','risk')] [string] $Kind,
        [hashtable] $Entry
    )
    $act = if ($Kind -eq 'decision') { $Entry.recommendedFollowUp } else { $Entry.recommendedAction }
    $nextAction = ''
    if ($act -is [System.Collections.IDictionary] -and $act.nextAction) { $nextAction = [string]$act.nextAction }

    $status = 'open'
    if ($Kind -eq 'risk' -and $Entry.severity -eq 'High') { $status = 'red' }
    elseif ($Entry.status -eq 'closed')                   { $status = 'closed' }
    elseif ($Entry.ownerConfidence -eq 'low')             { $status = 'amber' }

    $item = [ordered]@{
        id           = if ($Kind -eq 'decision') { [string]$Entry.decisionId } else { [string]$Entry.riskId }
        kind         = $Kind
        title        = if ($Entry.title) { [string]$Entry.title } else { '' }
        owner        = if ($Entry.owner) { [string]$Entry.owner } else { 'Unassigned' }
        workstream   = if ($Entry.workstream) { [string]$Entry.workstream } else { '' }
        status       = $status
        nextAction   = $nextAction
        lastSeenDate = if ($Entry.lastSeenDate) { [string]$Entry.lastSeenDate } else { '' }
        stale        = if ($Entry.ContainsKey('stale')) { [bool]$Entry.stale } else { $false }
    }
    $item.fingerprint = Get-ItemFingerprint -Item $item
    return $item
}

function Get-DailyDelta {
    <#
        V4.0 Phase 4b: computes { added, removed, changed, stale } between two
        snapshot arrays. Also returns per-id change hashtables for downstream
        `change_summary` synthesis.
    #>
    param([object[]] $Today, [object[]] $Yesterday)

    $todayList = @($Today | Where-Object { $null -ne $_ })
    $yList     = @($Yesterday | Where-Object { $null -ne $_ })

    $ymap = @{}; foreach ($y in $yList)     { $ymap[[string]$y.id] = $y }
    $tmap = @{}; foreach ($t in $todayList) { $tmap[[string]$t.id] = $t }

    $addedIds     = [System.Collections.Generic.List[string]]::new()
    $removedIds   = [System.Collections.Generic.List[string]]::new()
    $changedIds   = [System.Collections.Generic.List[string]]::new()
    $staleIds     = [System.Collections.Generic.List[string]]::new()
    $unchangedIds = [System.Collections.Generic.List[string]]::new()

    foreach ($t in $todayList) {
        $tid = [string]$t.id
        if ([bool]$t.stale) { $staleIds.Add($tid) }
        if (-not $ymap.ContainsKey($tid)) {
            $addedIds.Add($tid)
            continue
        }
        if ([string]$t.fingerprint -ne [string]$ymap[$tid].fingerprint) {
            $changedIds.Add($tid)
        } elseif (-not [bool]$t.stale) {
            $unchangedIds.Add($tid)
        }
    }
    foreach ($y in $yList) {
        $yid = [string]$y.id
        if (-not $tmap.ContainsKey($yid)) { $removedIds.Add($yid) }
    }

    return @{
        added     = @($addedIds)
        removed   = @($removedIds)
        changed   = @($changedIds)
        stale     = @($staleIds)
        unchanged = @($unchangedIds)
        todayMap  = $tmap
        priorMap  = $ymap
    }
}

function Get-ChangeSummary {
    <#
        Human-readable diff between a prior and current snapshot entry.
        Returns '' when the entry is unchanged.
    #>
    param([hashtable] $Prior, [hashtable] $Current)
    if (-not $Prior -or -not $Current) { return '' }
    $bits = [System.Collections.Generic.List[string]]::new()
    if ([string]$Prior.owner -ne [string]$Current.owner) {
        $bits.Add("owner: $($Prior.owner) -> $($Current.owner)")
    }
    if ([string]$Prior.status -ne [string]$Current.status) {
        $bits.Add("status: $($Prior.status) -> $($Current.status)")
    }
    if ([string]$Prior.nextAction -ne [string]$Current.nextAction) {
        $bits.Add('next-action rephrased')
    }
    if ([string]$Prior.title -ne [string]$Current.title) {
        $bits.Add('title updated')
    }
    if ([bool]$Prior.stale -ne [bool]$Current.stale) {
        $bits.Add($(if ($Current.stale) { 'became stale' } else { 'no longer stale' }))
    }
    return ($bits -join '; ')
}

function Get-PriorSnapshot {
    <#
        Loads the most recent snapshot dated strictly earlier than $TodayIso.
        Returns @{ date; items = @() } or $null if none exists.
    #>
    param([string] $TodayIso)
    $dir = Get-SnapshotDir
    if (-not (Test-Path $dir)) { return $null }
    $files = @(Get-ChildItem $dir -Filter '*.json' -File -ErrorAction SilentlyContinue |
                Where-Object { $_.BaseName -match '^\d{4}-\d{2}-\d{2}$' -and $_.BaseName -lt $TodayIso } |
                Sort-Object BaseName -Descending)
    if ($files.Count -eq 0) { return $null }
    try {
        $raw = Get-Content -LiteralPath $files[0].FullName -Raw -Encoding UTF8
        $obj = $raw | ConvertFrom-Json -AsHashtable
        return @{ date = $files[0].BaseName; items = @($obj.items) }
    } catch {
        return $null
    }
}

function Write-DailySnapshot {
    <#
        Persists today's snapshot and updates snapshots/INDEX.json.
        Trims snapshots older than 30 days (rolling retention).
    #>
    param(
        [string]   $TodayIso,
        [object[]] $Items,
        [hashtable] $DeltaSummary,
        [string]   $GeneratedIso
    )
    $dir = Get-SnapshotDir
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $snap = [ordered]@{
        date      = $TodayIso
        generated = $GeneratedIso
        version   = 'V4.0-phase4-snapshot'
        itemCount = @($Items).Count
        items     = @($Items)
    }
    $snapPath = Join-Path $dir "$TodayIso.json"
    [System.IO.File]::WriteAllText($snapPath, ($snap | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))

    # Update INDEX.json (append/replace today's row, trim to last 30 rows).
    $indexPath = Join-Path $dir 'INDEX.json'
    $index = [ordered]@{ updated = $GeneratedIso; snapshots = @() }
    if (Test-Path $indexPath) {
        try {
            $raw = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
            $existing = $raw | ConvertFrom-Json -AsHashtable
            if ($existing.snapshots) { $index.snapshots = @($existing.snapshots) }
        } catch { }
    }
    $index.snapshots = @($index.snapshots | Where-Object { [string]$_.date -ne $TodayIso })
    $index.snapshots += [ordered]@{
        date        = $TodayIso
        itemCount   = @($Items).Count
        addedIds    = @($DeltaSummary.added)
        removedIds  = @($DeltaSummary.removed)
        changedIds  = @($DeltaSummary.changed)
        staleCount  = @($DeltaSummary.stale).Count
    }
    $index.snapshots = @($index.snapshots | Sort-Object { $_.date } -Descending | Select-Object -First 60)
    $index.updated = $GeneratedIso
    [System.IO.File]::WriteAllText($indexPath, ($index | ConvertTo-Json -Depth 5), (New-Object System.Text.UTF8Encoding($false)))

    # Retention: delete snapshot files older than 30 days.
    $cutoff = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd')
    Get-ChildItem $dir -Filter '*.json' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -match '^\d{4}-\d{2}-\d{2}$' -and $_.BaseName -lt $cutoff } |
        ForEach-Object {
            try { Remove-Item $_.FullName -Force -ErrorAction Stop } catch { }
        }

    return $snapPath
}

function Apply-DailyDelta {
    <#
        Stamps a `delta` hashtable onto every live decision + risk entry using
        the diff against yesterday's snapshot. Fields:
          - daysSinceLastTouched
          - updatedSinceYesterday
          - changeSummary (present only when non-empty)
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks,
        [datetime] $Now
    )

    $todayIso  = $Now.ToString('yyyy-MM-dd')
    $prior     = Get-PriorSnapshot -TodayIso $todayIso
    $priorMap  = @{}
    if ($prior -and $prior.items) {
        foreach ($p in @($prior.items)) { $priorMap[[string]$p.id] = $p }
    }

    $todaySnaps = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($d in $Decisions) { if ($d) { $todaySnaps.Add((ConvertTo-SnapshotEntry -Kind 'decision' -Entry $d)) } }
    foreach ($r in $Risks)     { if ($r) { $todaySnaps.Add((ConvertTo-SnapshotEntry -Kind 'risk'     -Entry $r)) } }

    $delta = Get-DailyDelta -Today @($todaySnaps) -Yesterday @(if ($prior) { $prior.items } else { @() })

    $priorDateStr = if ($prior) { $prior.date } else { $todayIso }
    $priorDate = try { [datetime]::ParseExact($priorDateStr, 'yyyy-MM-dd', $null) } catch { $Now.Date }

    $stamp = {
        param($entries, $kind)
        foreach ($e in $entries) {
            if (-not $e) { continue }
            $id = if ($kind -eq 'decision') { [string]$e.decisionId } else { [string]$e.riskId }
            $todaySnap = $null
            foreach ($s in $todaySnaps) { if ([string]$s.id -eq $id) { $todaySnap = $s; break } }
            $priorSnap = if ($priorMap.ContainsKey($id)) { $priorMap[$id] } else { $null }

            $lastSeen = if ($e.lastSeenDate) {
                try { [datetime]::ParseExact([string]$e.lastSeenDate, 'yyyy-MM-dd', $null) } catch { $priorDate }
            } else { $priorDate }
            $days = [int](($Now.Date - $lastSeen.Date).TotalDays)
            if ($days -lt 0) { $days = 0 }

            $updated = $false
            if (-not $priorSnap) {
                $updated = $true
            } elseif ($todaySnap -and [string]$todaySnap.fingerprint -ne [string]$priorSnap.fingerprint) {
                $updated = $true
            }

            $summary = if ($priorSnap -and $todaySnap) { Get-ChangeSummary -Prior $priorSnap -Current $todaySnap } else { '' }
            if (-not $priorSnap) { $summary = 'first appearance' }

            $e.delta = [ordered]@{
                daysSinceLastTouched   = $days
                updatedSinceYesterday  = $updated
                changeSummary          = $summary
            }
        }
    }
    & $stamp $Decisions 'decision'
    & $stamp $Risks     'risk'

    return @{
        delta       = $delta
        snapshots   = @($todaySnaps)
        priorDate   = $priorDateStr
    }
}

# V4.0 Phase 5 - Context linking.
# Reads the primary source file for each entry and captures:
#   - contextSummary: 2 lines before + matched line + 2 lines after (per spec 5a)
#   - contextMetadata: last_mention timestamp + last_activity + actors named in
#     the source paragraph (per spec 5a-bis)
# Deterministic pattern matching only, no LLM. Cached per file so we don't
# re-read a source multiple times per pass.

$script:MAT_SOURCE_TEXT_CACHE = @{}

function Get-CachedSourceLines {
    param([string] $AbsPath)
    if ([string]::IsNullOrWhiteSpace($AbsPath)) { return @() }
    if (-not (Test-Path -LiteralPath $AbsPath)) { return @() }
    if ($script:MAT_SOURCE_TEXT_CACHE.ContainsKey($AbsPath)) {
        return $script:MAT_SOURCE_TEXT_CACHE[$AbsPath]
    }
    try {
        $raw = Get-Content -LiteralPath $AbsPath -Raw -Encoding UTF8 -ErrorAction Stop
        $lines = @(($raw -replace "`r`n", "`n") -split "`n")
    } catch {
        $lines = @()
    }
    $script:MAT_SOURCE_TEXT_CACHE[$AbsPath] = $lines
    return $lines
}

function Get-ContextSummary {
    <#
        V4.0 Phase 5a: extracts a 5-line window around a matched line in the
        source file. Falls back to the first non-empty line of the file when
        no seed match is found. Trimmed to 300 chars.
    #>
    param(
        [string] $AbsSourcePath,
        [string] $SeedText
    )
    if ([string]::IsNullOrWhiteSpace($AbsSourcePath)) { return '' }
    $lines = Get-CachedSourceLines -AbsPath $AbsSourcePath
    if ($lines.Count -eq 0) { return '' }

    $idx = -1
    if (-not [string]::IsNullOrWhiteSpace($SeedText)) {
        # Try successively shorter prefixes of the seed so we still match when
        # the title was truncated / rephrased.
        $trimmed = ($SeedText -replace '^\s*[-*>#]+\s*', '').Trim()
        $candidates = @()
        if ($trimmed.Length -ge 60) { $candidates += $trimmed.Substring(0, 60) }
        if ($trimmed.Length -ge 40) { $candidates += $trimmed.Substring(0, 40) }
        if ($trimmed.Length -ge 20) { $candidates += $trimmed.Substring(0, 20) }
        $candidates += $trimmed

        foreach ($cand in $candidates) {
            if ([string]::IsNullOrWhiteSpace($cand)) { continue }
            $needle = $cand.ToLowerInvariant()
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if (($lines[$i]).ToLowerInvariant().Contains($needle)) {
                    $idx = $i
                    break
                }
            }
            if ($idx -ge 0) { break }
        }
    }

    if ($idx -lt 0) {
        # Fallback: first non-empty, non-frontmatter, non-heading line.
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $l = $lines[$i].Trim()
            if ([string]::IsNullOrWhiteSpace($l)) { continue }
            if ($l -match '^---\s*$') { continue }
            if ($l -match '^\s*(type|source|date|generated_on|status|window_days)\s*:') { continue }
            $idx = $i
            break
        }
    }
    if ($idx -lt 0) { return '' }

    $start = [Math]::Max(0, $idx - 2)
    $end   = [Math]::Min($lines.Count - 1, $idx + 2)
    $window = @($lines[$start..$end]) -join ' '
    $summary = ($window -replace '\s+', ' ').Trim()
    if ($summary.Length -gt 300) { $summary = $summary.Substring(0, 297) + '...' }
    return $summary
}

function Get-ContextActors {
    <#
        Returns the set of stakeholder names mentioned in the primary source
        file for an entry.
    #>
    param(
        [string]   $AbsSourcePath,
        [string[]] $StakeholderNames
    )
    if ([string]::IsNullOrWhiteSpace($AbsSourcePath) -or -not $StakeholderNames -or $StakeholderNames.Count -eq 0) { return @() }
    $lines = Get-CachedSourceLines -AbsPath $AbsSourcePath
    if ($lines.Count -eq 0) { return @() }
    $text = ($lines -join "`n").ToLowerInvariant()
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($n in $StakeholderNames) {
        if ([string]::IsNullOrWhiteSpace($n)) { continue }
        $needle = $n.ToLowerInvariant()
        $needleFirstToken = ($needle -split '\s+' | Select-Object -First 1)
        $pattern = '\b' + [regex]::Escape($needle) + '\b'
        if ($text -match $pattern) { $hits.Add($n); continue }
        # Also match on just the first-name token for people-style names.
        if ($needleFirstToken -and $needleFirstToken.Length -ge 4) {
            $patternFirst = '\b' + [regex]::Escape($needleFirstToken) + '\b'
            if ($text -match $patternFirst) { $hits.Add($n) }
        }
    }
    return @($hits | Sort-Object -Unique)
}

function Get-ContextMetadata {
    <#
        V4.0 Phase 5a-bis: structured metadata layer alongside the text summary.
        Returns { lastMention; lastActivity; actors; primarySource }.
    #>
    param(
        [hashtable] $Entry,
        [string]    $RootPath,
        [string[]]  $StakeholderNames
    )
    $sourceFiles = @($Entry.sourceFiles)
    if ($sourceFiles.Count -eq 0) {
        return @{
            lastMention   = if ($Entry.lastSeenDate) { [string]$Entry.lastSeenDate } else { '' }
            lastActivity  = if ($Entry.lastSeenDate) { [string]$Entry.lastSeenDate } else { '' }
            actors        = @()
            primarySource = ''
        }
    }

    # Primary source = most-recently-modified among the entry's sourceFiles.
    $best = $null
    $bestTime = [datetime]::MinValue
    foreach ($rel in $sourceFiles) {
        if ([string]::IsNullOrWhiteSpace($rel)) { continue }
        $abs = Join-Path $RootPath $rel
        if (-not (Test-Path -LiteralPath $abs)) { continue }
        $item = Get-Item -LiteralPath $abs -ErrorAction SilentlyContinue
        if (-not $item) { continue }
        if ($item.LastWriteTime -gt $bestTime) {
            $bestTime = $item.LastWriteTime
            $best     = $rel
        }
    }
    if (-not $best) { $best = [string]$sourceFiles[0] }

    $absPrimary = Join-Path $RootPath $best
    $actors = Get-ContextActors -AbsSourcePath $absPrimary -StakeholderNames $StakeholderNames

    $lastMention = if ($bestTime -ne [datetime]::MinValue) { $bestTime.ToString('yyyy-MM-dd') }
                   elseif ($Entry.lastSeenDate) { [string]$Entry.lastSeenDate }
                   else { '' }
    $lastActivity = if ($Entry.lastSeenDate) { [string]$Entry.lastSeenDate } else { $lastMention }

    return @{
        lastMention   = $lastMention
        lastActivity  = $lastActivity
        actors        = @($actors)
        primarySource = $best
    }
}

function Apply-ContextLinking {
    <#
        V4.0 Phase 5 orchestrator: enriches every decision + risk entry with
        contextSummary + contextMetadata built from its primary source file.
        Refreshes contextSummary in preference to the V3 free-text summary but
        keeps the V3 fields intact for backward compat.
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks,
        [string]   $RootPath,
        [hashtable] $Model
    )

    $script:MAT_SOURCE_TEXT_CACHE = @{}
    $stakeholderNames = @()
    if ($Model -and $Model.stakeholder_weights) {
        $stakeholderNames = @($Model.stakeholder_weights.Keys)
    }

    $enrichedCount = 0
    $actorHits     = 0
    foreach ($kind in @('decision','risk')) {
        $entries = if ($kind -eq 'decision') { $Decisions } else { $Risks }
        foreach ($e in $entries) {
            if (-not $e) { continue }
            $meta = Get-ContextMetadata -Entry $e -RootPath $RootPath -StakeholderNames $stakeholderNames
            $seed = if ($e.title) { [string]$e.title } else { '' }
            $abs  = if ($meta.primarySource) { Join-Path $RootPath ([string]$meta.primarySource) } else { '' }
            $summary = if ($abs) { Get-ContextSummary -AbsSourcePath $abs -SeedText $seed } else { '' }
            # Fall back to existing V3 free-text if the source read produced nothing.
            if ([string]::IsNullOrWhiteSpace($summary)) {
                if ($kind -eq 'decision' -and $e.decisionSummary) { $summary = [string]$e.decisionSummary }
                elseif ($kind -eq 'risk' -and $e.impact)          { $summary = [string]$e.impact }
            }

            $e.contextSummary  = $summary
            $e.contextMetadata = [ordered]@{
                lastMention   = [string]$meta.lastMention
                lastActivity  = [string]$meta.lastActivity
                actors        = @($meta.actors)
                primarySource = [string]$meta.primarySource
            }
            $enrichedCount++
            if (@($meta.actors).Count -gt 0) { $actorHits++ }
        }
    }

    # Free the cache once we're done - up to 100 source files may have been
    # slurped into memory during enrichment.
    $script:MAT_SOURCE_TEXT_CACHE = @{}

    return @{
        enrichedCount = $enrichedCount
        actorHits     = $actorHits
    }
}

# --- V4.0 Sprint 15 - Semantic Impact Extraction (why_it_matters) ---------
# 4-tier extraction ladder producing a single-sentence impact statement
# per entry. Tiers (highest confidence first):
#   Tier 1: explicit rationale (because / due to / so that / ...)
#   Tier 2: risk consequence  (blocks / delays / prevents / ...)  [risks]
#   Tier 3: decision impact   (unblocks / cannot proceed / ...)   [decisions]
#   Tier 4: context fallback  (first impact-word sentence from contextSummary)
# Rejects generic phrases (Needs attention / Important issue / TBD / ...).

$script:MAT_WHY_TIER1_REGEX  = '(?i)\b(because|due to|so that|in order to|required for|needed to|to enable|to avoid|otherwise|as a result|hence|thereby)\b'
$script:MAT_WHY_TIER2_REGEX  = '(?i)\b(may delay|will delay|delays|blocks|prevents|impacts|at risk|risks to|results in|leads to|causes|jeopardis|jeopardiz|disrupts|breach|breaches|violates|non-compliance|compliance gap|dependency|dependent on)\b'
$script:MAT_WHY_TIER3_REGEX  = '(?i)\b(unblocks|enables|before .* can (proceed|begin|start)|cannot proceed|pending decision|awaiting decision|until (a |this |the )?decision|approval required|approval needed|holds up|held up|gating)\b'
$script:MAT_WHY_GENERIC_REGEX = '(?i)^(needs attention|important issue|follow[- ]up required|see above|tbd|placeholder|no summary( available)?|refer to (context|source)|to be determined|update required|pending)[.!?\s]*$'

function Split-IntoSentences {
    <#
        Deterministic sentence splitter. Splits on . ! ? boundaries.
        Preserves in-sentence punctuation like Mr./Dr. only imperfectly;
        that's acceptable for impact extraction (we favour a slightly-long
        sentence over a broken one).

        V4.0 Sprint 18 tightening: strips inline bold markers and rejects
        sentences that are pure markdown noise. Kept intentionally forgiving
        so downstream validator acceptance isn't gutted - the executive-summary
        composer applies stricter filtering separately.
    #>
    param([string] $Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $t = ($Text -replace '\s+', ' ').Trim()
    # Fold bullet markers into sentence-ending punctuation.
    $t = $t -replace '(?m)^\s*[-*•]\s+', '. '
    $parts = [System.Text.RegularExpressions.Regex]::Split($t, '(?<=[.!?])\s+')
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $parts) {
        $s = $p.Trim()
        if ([string]::IsNullOrWhiteSpace($s)) { continue }
        # Strip trailing punctuation duplicates but keep one.
        $s = $s -replace '\s*[.!?]+\s*$', '.'
        # Strip inline bold markers - they read poorly in narrative slots.
        $s = $s -replace '\*\*', ''
        if ($s.Length -lt 10) { continue }              # too short to be an impact sentence
        # Reject sentences that start with pure markup punctuation.
        if ($s -match '^\s*(?:##+|`|\||:)') { continue }
        # Reject if fewer than 8 alphabetic characters (emoji-only / punctuation soup).
        $letterCount = ([regex]::Matches($s, '[A-Za-z]')).Count
        if ($letterCount -lt 8) { continue }
        if ($s.Length -gt 260) { $s = $s.Substring(0, 259) + '…' }
        [void]$out.Add($s)
    }
    return @($out)
}

function Test-GenericWhy {
    <#
        Returns $true when the candidate string matches a rejected generic phrase.
    #>
    param([string] $Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $true }
    $t = $Text.Trim()
    if ($t.Length -lt 15) { return $true }
    if ($t -match $script:MAT_WHY_GENERIC_REGEX) { return $true }
    return $false
}

function Get-WhyItMatters {
    <#
        V4.0 Sprint 15 extraction ladder.
        Returns @{
            text       = <single-sentence impact statement, or ''>
            confidence = <double 0..1>
            source     = <'explicit-rationale'|'risk-consequence'|'decision-impact'|'context-fallback'|'none'>
        }
    #>
    param(
        [hashtable] $Entry,
        [ValidateSet('decision','risk')] [string] $Kind
    )

    # --- Assemble the source-text pool in preference order.
    $sources = [System.Collections.Generic.List[string]]::new()
    if ($Entry.contextSummary)                                       { [void]$sources.Add([string]$Entry.contextSummary) }
    if ($Kind -eq 'risk'     -and $Entry.impact)                     { [void]$sources.Add([string]$Entry.impact) }
    if ($Kind -eq 'decision' -and $Entry.decisionPrompt)             { [void]$sources.Add([string]$Entry.decisionPrompt) }
    if ($Kind -eq 'decision' -and $Entry.decisionSummary)            { [void]$sources.Add([string]$Entry.decisionSummary) }

    $combined = ($sources -join ' ')
    $sentences = @(Split-IntoSentences -Text $combined)

    if ($sentences.Count -eq 0) {
        return @{ text = ''; confidence = 0.0; source = 'none' }
    }

    # --- Tier 1: explicit rationale ---
    foreach ($s in $sentences) {
        if ($s -match $script:MAT_WHY_TIER1_REGEX -and -not (Test-GenericWhy -Text $s)) {
            return @{ text = $s; confidence = 0.90; source = 'explicit-rationale' }
        }
    }

    # --- Tier 2: risk consequence (risks + decisions with consequence language) ---
    if ($Kind -eq 'risk') {
        foreach ($s in $sentences) {
            if ($s -match $script:MAT_WHY_TIER2_REGEX -and -not (Test-GenericWhy -Text $s)) {
                return @{ text = $s; confidence = 0.75; source = 'risk-consequence' }
            }
        }
    }

    # --- Tier 3: decision impact ---
    if ($Kind -eq 'decision') {
        foreach ($s in $sentences) {
            if ($s -match $script:MAT_WHY_TIER3_REGEX -and -not (Test-GenericWhy -Text $s)) {
                return @{ text = $s; confidence = 0.65; source = 'decision-impact' }
            }
        }
        # Decisions may still surface tier-2 consequence phrasing (unblocks / dependency).
        foreach ($s in $sentences) {
            if ($s -match $script:MAT_WHY_TIER2_REGEX -and -not (Test-GenericWhy -Text $s)) {
                return @{ text = $s; confidence = 0.60; source = 'decision-impact' }
            }
        }
    }

    # --- Tier 4: context fallback ---
    # Pick the first non-generic sentence that mentions ANY impact word.
    foreach ($s in $sentences) {
        if ($s -match $script:MAT_IMPACT_WORDS_REGEX -and -not (Test-GenericWhy -Text $s)) {
            return @{ text = $s; confidence = 0.30; source = 'context-fallback' }
        }
    }

    # No impact-word sentence found - return the first meaningful sentence at
    # very low confidence so downstream can decide whether to keep it.
    foreach ($s in $sentences) {
        if (-not (Test-GenericWhy -Text $s)) {
            return @{ text = $s; confidence = 0.15; source = 'context-fallback' }
        }
    }

    return @{ text = ''; confidence = 0.0; source = 'none' }
}

function Apply-WhyItMatters {
    <#
        V4.0 Sprint 15 orchestrator: stamps whyItMatters + whyItMattersConfidence
        + whyItMattersSource on every live decision + risk entry. Returns
        aggregate counts for the pipeline log.

        Non-destructive: existing V3 impact / decisionPrompt / decisionSummary
        fields are left in place. Downstream consumers (validator, canonical
        emit, weekly report) prefer whyItMatters when non-empty.
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks
    )

    $counts = @{
        total          = 0
        tier1          = 0
        tier2          = 0
        tier3          = 0
        tier4          = 0
        none           = 0
        highConfidence = 0    # >= 0.6
    }
    foreach ($kind in @('decision','risk')) {
        $entries = if ($kind -eq 'decision') { $Decisions } else { $Risks }
        foreach ($e in $entries) {
            if (-not $e) { continue }
            $res = Get-WhyItMatters -Entry $e -Kind $kind
            $e.whyItMatters           = [string]$res.text
            $e.whyItMattersConfidence = [double]$res.confidence
            $e.whyItMattersSource     = [string]$res.source
            $counts.total += 1
            switch ($res.source) {
                'explicit-rationale' { $counts.tier1 += 1 }
                'risk-consequence'   { $counts.tier2 += 1 }
                'decision-impact'    { $counts.tier3 += 1 }
                'context-fallback'   { $counts.tier4 += 1 }
                default              { $counts.none  += 1 }
            }
            if ([double]$res.confidence -ge 0.6) { $counts.highConfidence += 1 }
        }
    }
    return $counts
}

# V4.0 Phase 1c - Deterministic status ladder.
# First-match-wins rules. Red requires a HARD signal; soft signals only warrant
# amber. Trend direction is intentionally not a status input.

function Get-MatryoshkaStatus {
    <#
        Returns @{ status = 'red'|'amber'|'green'; reason = <string> }.
        Consumes V3.x + Phase 5 enriched fields directly (no adapter needed).
    #>
    param(
        [hashtable] $Entry,
        [ValidateSet('decision','risk')] [string] $Kind,
        [datetime]  $Now
    )

    $reasons = [System.Collections.Generic.List[string]]::new()
    $status  = 'green'

    $act = if ($Kind -eq 'decision') { $Entry.recommendedFollowUp } else { $Entry.recommendedAction }
    $actionClass = ''
    $nextAction  = ''
    if ($act -is [System.Collections.IDictionary]) {
        if ($act.actionClass) { $actionClass = [string]$act.actionClass }
        if ($act.nextAction)  { $nextAction  = [string]$act.nextAction  }
    }

    $contextText = ''
    if ($Entry.ContainsKey('contextSummary') -and $Entry.contextSummary) {
        $contextText = [string]$Entry.contextSummary
    }
    elseif ($Kind -eq 'decision' -and $Entry.decisionSummary) { $contextText = [string]$Entry.decisionSummary }
    elseif ($Kind -eq 'risk' -and $Entry.impact)              { $contextText = [string]$Entry.impact }

    $ownerConfidence = if ($Entry.ownerConfidence) { [string]$Entry.ownerConfidence } else { 'low' }
    # V4 taxonomy remap - workstream-map / name-proximity / unknown all pre-date Sprint 10a.
    switch ($ownerConfidence) {
        'workstream-map' { $ownerConfidence = 'low'    }
        'name-proximity' { $ownerConfidence = 'medium' }
        'unknown'        { $ownerConfidence = 'low'    }
    }

    $confidenceScore = if ($Entry.ContainsKey('unifiedConfidence') -and $Entry.unifiedConfidence) {
        [double]$Entry.unifiedConfidence
    } elseif ($Kind -eq 'decision' -and $Entry.decisionConfidence) {
        [double]$Entry.decisionConfidence
    } elseif ($Kind -eq 'risk' -and $Entry.riskConfidence) {
        [double]$Entry.riskConfidence
    } else { 0.0 }

    # --- RED (hard signals only) ---
    if ($actionClass -eq 'BLOCKED') {
        $status = 'red'; $reasons.Add('BLOCKED by external dependency')
    }
    if ($contextText -match '(?i)\b(blocker|show[- ]?stopper|critical|urgent|compliance gap|outage)\b') {
        $status = 'red'; $reasons.Add('blocker keyword in context')
    }
    if ($Kind -eq 'decision' -and $Entry.decisionDeadline) {
        $deadlineStr = [string]$Entry.decisionDeadline
        if ($deadlineStr -match '^\d{4}-\d{2}-\d{2}') {
            $todayStr = $Now.ToString('yyyy-MM-dd')
            if ($deadlineStr -lt $todayStr) {
                $status = 'red'; $reasons.Add("deadline breached ($deadlineStr)")
            }
        }
    }
    if ($Kind -eq 'risk' -and $Entry.severity -eq 'High') {
        $status = 'red'; $reasons.Add('high-severity risk')
    }

    # --- AMBER (only if not already red) ---
    if ($status -ne 'red') {
        if ($nextAction -match '(?i)\b(awaiting|waiting|uncertain|pending|tbd)\b') {
            $status = 'amber'; $reasons.Add('waiting on external input')
        }
        if ($confidenceScore -lt 0.4) {
            $status = 'amber'; $reasons.Add(("low confidence ({0:F2})" -f $confidenceScore))
        }
        if ($ownerConfidence -eq 'low') {
            $status = 'amber'; $reasons.Add('owner not confirmed')
        }
    }

    # --- GREEN (default) ---
    if ($status -eq 'green' -and $reasons.Count -eq 0) {
        $reasons.Add('active progress, no blockers')
    }

    return @{
        status = $status
        reason = ($reasons -join '; ')
    }
}

function Apply-MatryoshkaStatus {
    <#
        V4.0 Phase 1c orchestrator: stamps `matryoshkaStatus` +
        `matryoshkaStatusReason` on every live decision + risk entry using
        Get-MatryoshkaStatus. Non-destructive - V3.x `status` fields untouched.
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks,
        [datetime] $Now
    )

    $counts = @{ red = 0; amber = 0; green = 0 }
    foreach ($kind in @('decision','risk')) {
        $entries = if ($kind -eq 'decision') { $Decisions } else { $Risks }
        foreach ($e in $entries) {
            if (-not $e) { continue }
            $res = Get-MatryoshkaStatus -Entry $e -Kind $kind -Now $Now
            $e.matryoshkaStatus       = [string]$res.status
            $e.matryoshkaStatusReason = [string]$res.reason
            $counts[$res.status] += 1
        }
    }
    return $counts
}

function Get-FocusSignals {
    <#
        V4.0 Phase 9 (Sprint 13a): computes three canonical focus dimensions
        for an entry. Deterministic - derived from Phase 1c/2/3/4/5/7 fields
        already stamped on the entry. Booleans stand alone (an item can be
        both `engaged` AND `awaitingOthers`, or none of the three).

        Returns:
          @{
            engaged           = <bool>   # David/team touched or owns this recently
            attentionRequired = <bool>   # David must act (RED, or DO/DECIDE on him, or unassigned)
            awaitingOthers    = <bool>   # blocked by an external party
            reasons           = @{ engaged=<str>; attentionRequired=<str>; awaitingOthers=<str> }
          }
    #>
    param(
        [hashtable] $Entry,
        [ValidateSet('decision','risk')] [string] $Kind,
        [datetime]  $Now
    )

    $signals = [ordered]@{
        engaged           = $false
        attentionRequired = $false
        awaitingOthers    = $false
        reasons           = [ordered]@{
            engaged           = ''
            attentionRequired = ''
            awaitingOthers    = ''
        }
    }

    # --- Pull the fields we depend on -------------------------------------
    $owner = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }
    $ownerIsDavid  = $owner -match '(?i)^\s*david(\s+klan)?\s*$'
    $ownerUnassigned = $owner -match '(?i)^\s*unassigned\s*$'

    $ownerConfidence = if ($Entry.ownerConfidence) { [string]$Entry.ownerConfidence } else { 'low' }
    switch ($ownerConfidence) {
        'workstream-map' { $ownerConfidence = 'low'    }
        'name-proximity' { $ownerConfidence = 'medium' }
        'unknown'        { $ownerConfidence = 'low'    }
    }

    $status = if ($Entry.matryoshkaStatus) { [string]$Entry.matryoshkaStatus } else { 'green' }

    $act = if ($Kind -eq 'decision') { $Entry.recommendedFollowUp } else { $Entry.recommendedAction }
    $actionClass = ''
    $nextAction  = ''
    if ($act -is [System.Collections.IDictionary]) {
        if ($act.actionClass) { $actionClass = [string]$act.actionClass }
        if ($act.nextAction)  { $nextAction  = [string]$act.nextAction  }
    }

    $ageDays = if ($Kind -eq 'decision' -and $Entry.decisionAgeDays) {
        [int]$Entry.decisionAgeDays
    } elseif ($Kind -eq 'risk' -and $Entry.agingDays) {
        [int]$Entry.agingDays
    } else { 0 }

    $recencyDays = if ($Entry.recencyDays) { [int]$Entry.recencyDays } else { $ageDays }

    $updatedRecently = $false
    if ($Entry.delta -is [System.Collections.IDictionary]) {
        if ($Entry.delta.updatedSinceYesterday) { $updatedRecently = [bool]$Entry.delta.updatedSinceYesterday }
        $daysSince = if ($Entry.delta.daysSinceLastTouched) { [int]$Entry.delta.daysSinceLastTouched } else { 999 }
        if ($daysSince -le 7) { $updatedRecently = $true }
    }

    $contextText = ''
    if ($Entry.ContainsKey('contextSummary') -and $Entry.contextSummary) {
        $contextText = [string]$Entry.contextSummary
    }

    # --- engaged ----------------------------------------------------------
    $engagedReasons = [System.Collections.Generic.List[string]]::new()
    if ($updatedRecently)             { $engagedReasons.Add('touched in the last 7 days') }
    if ($recencyDays -le 7)           { $engagedReasons.Add("recency $recencyDays d") }
    if ($ownerIsDavid -and $status -ne 'green') { $engagedReasons.Add('David owns and item not green') }
    if ($engagedReasons.Count -gt 0) {
        $signals.engaged = $true
        $signals.reasons.engaged = ($engagedReasons -join '; ')
    }

    # --- attentionRequired ------------------------------------------------
    $attnReasons = [System.Collections.Generic.List[string]]::new()
    if ($status -eq 'red')                                    { $attnReasons.Add('matryoshka status RED') }
    if ($ownerUnassigned)                                     { $attnReasons.Add('owner unassigned') }
    if ($actionClass -in @('DO','DECIDE') -and ($ownerIsDavid -or $ownerUnassigned)) {
        $attnReasons.Add("$actionClass on David/unassigned")
    }
    if ($ownerConfidence -eq 'low' -and $status -ne 'green')  { $attnReasons.Add('owner not confirmed') }
    if ($Kind -eq 'decision' -and $Entry.decisionDeadline) {
        $deadlineStr = [string]$Entry.decisionDeadline
        if ($deadlineStr -match '^\d{4}-\d{2}-\d{2}') {
            $todayStr = $Now.ToString('yyyy-MM-dd')
            $soonStr  = $Now.AddDays(3).ToString('yyyy-MM-dd')
            if ($deadlineStr -lt $todayStr) { $attnReasons.Add("deadline breached $deadlineStr") }
            elseif ($deadlineStr -le $soonStr) { $attnReasons.Add("deadline within 3d ($deadlineStr)") }
        }
    }
    if ($attnReasons.Count -gt 0) {
        $signals.attentionRequired = $true
        $signals.reasons.attentionRequired = ($attnReasons -join '; ')
    }

    # --- awaitingOthers ---------------------------------------------------
    $waitReasons = [System.Collections.Generic.List[string]]::new()
    if ($actionClass -eq 'BLOCKED') { $waitReasons.Add('BLOCKED action_class') }
    if ($nextAction -match '(?i)\b(awaiting|waiting on|waiting for|pending response|pending vendor|pending customer|pending client)\b') {
        $waitReasons.Add('nextAction mentions waiting')
    }
    if ($contextText -match '(?i)\b(awaiting|pending vendor|pending customer|pending client|escalated to (aws|vendor))\b') {
        $waitReasons.Add('context mentions external wait')
    }
    if ($actionClass -eq 'FOLLOW_UP' -and -not $ownerIsDavid -and -not $ownerUnassigned) {
        $waitReasons.Add('FOLLOW_UP with external owner')
    }
    if ($waitReasons.Count -gt 0) {
        $signals.awaitingOthers = $true
        $signals.reasons.awaitingOthers = ($waitReasons -join '; ')
    }

    return $signals
}

function Apply-FocusSignals {
    <#
        V4.0 Phase 9 (Sprint 13a) orchestrator: stamps `focusSignals` on every
        live decision + risk entry. Non-destructive - existing status fields
        untouched. Returns aggregate counts for the pipeline log.
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks,
        [datetime] $Now
    )

    $counts = @{ engaged = 0; attentionRequired = 0; awaitingOthers = 0; total = 0 }
    foreach ($kind in @('decision','risk')) {
        $entries = if ($kind -eq 'decision') { $Decisions } else { $Risks }
        foreach ($e in $entries) {
            if (-not $e) { continue }
            $sig = Get-FocusSignals -Entry $e -Kind $kind -Now $Now
            $e.focusSignals = $sig
            $counts.total += 1
            if ($sig.engaged)           { $counts.engaged           += 1 }
            if ($sig.attentionRequired) { $counts.attentionRequired += 1 }
            if ($sig.awaitingOthers)    { $counts.awaitingOthers    += 1 }
        }
    }
    return $counts
}

function Get-PriorityScore {
    <#
        V4.0 Sprint 13b: canonical priority score for a single decision or risk.
        Returns @{ score = <int 0..100>; reason = <string> }.

        Weighted sum of five bounded factors (each 0..1):
          - impact         (weight 0.25)
          - ownership      (weight 0.20)
          - deadline       (weight 0.20)
          - status         (weight 0.20)
          - engagement     (weight 0.15)

        Consumes Phase 1c (matryoshkaStatus), Phase 2 (actionClass), Phase 7
        (ownerConfidence), Sprint 13a (focusSignals) directly. Deterministic.
    #>
    param(
        [hashtable] $Entry,
        [ValidateSet('decision','risk')] [string] $Kind,
        [datetime]  $Now
    )

    # --- pulled fields ---------------------------------------------------
    $owner = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }
    $ownerIsDavid  = $owner -match '(?i)^\s*david(\s+klan)?\s*$'
    $ownerUnassigned = $owner -match '(?i)^\s*unassigned\s*$'

    $ownerConfidence = if ($Entry.ownerConfidence) { [string]$Entry.ownerConfidence } else { 'low' }
    switch ($ownerConfidence) {
        'workstream-map' { $ownerConfidence = 'low'    }
        'name-proximity' { $ownerConfidence = 'medium' }
        'unknown'        { $ownerConfidence = 'low'    }
    }

    $status = if ($Entry.matryoshkaStatus) { [string]$Entry.matryoshkaStatus } else { 'green' }

    $signals = if ($Entry.focusSignals -is [System.Collections.IDictionary]) { $Entry.focusSignals } else { @{} }

    # --- impact ----------------------------------------------------------
    $impact = 0.5
    $impactReason = ''
    if ($Kind -eq 'risk') {
        switch ($Entry.severity) {
            'High'   { $impact = 1.0; $impactReason = 'high severity' }
            'Medium' { $impact = 0.6; $impactReason = 'medium severity' }
            'Low'    { $impact = 0.3; $impactReason = 'low severity' }
            default  { $impact = 0.4 }
        }
    } else {
        # Decision impact proxy (no per-decision impact field yet):
        #   decisionRequired + not-yet-Decided  -> 0.75 (needs a real call)
        #   Decided / closed                    -> 0.25 (housekeeping only)
        #   otherwise                           -> 0.55
        $lifecycle = if ($Entry.decisionStatus) { [string]$Entry.decisionStatus } else { '' }
        if ($Entry.status -eq 'closed' -or $lifecycle -eq 'Decided') {
            $impact = 0.25; $impactReason = 'decided / closed'
        } elseif ($Entry.decisionRequired) {
            $impact = 0.75; $impactReason = 'decision required'
        } else {
            $impact = 0.55; $impactReason = 'informational decision'
        }
    }

    # --- ownership -------------------------------------------------------
    $ownershipReason = ''
    if ($ownerUnassigned)              { $ownership = 1.00; $ownershipReason = 'needs owner' }
    elseif ($ownerIsDavid)             { $ownership = 0.85; $ownershipReason = 'David owns' }
    elseif ($ownerConfidence -eq 'low'){ $ownership = 0.70; $ownershipReason = 'owner unconfirmed' }
    elseif ($ownerConfidence -eq 'medium') { $ownership = 0.55; $ownershipReason = 'ownership inferred' }
    else                                { $ownership = 0.40; $ownershipReason = 'owner confirmed' }

    # --- deadline --------------------------------------------------------
    $deadline = 0.2
    $deadlineReason = 'no deadline'
    $deadlineStr = ''
    if ($Kind -eq 'decision' -and $Entry.decisionDeadline) { $deadlineStr = [string]$Entry.decisionDeadline }
    if ($deadlineStr -match '^\d{4}-\d{2}-\d{2}') {
        $todayStr = $Now.ToString('yyyy-MM-dd')
        try {
            $dl = [datetime]::ParseExact($deadlineStr.Substring(0,10),'yyyy-MM-dd',$null)
            $daysToDeadline = [int]([Math]::Round(($dl - $Now.Date).TotalDays))
            if ($deadlineStr -lt $todayStr) { $deadline = 1.00; $deadlineReason = "breached $deadlineStr" }
            elseif ($daysToDeadline -le 3)  { $deadline = 0.90; $deadlineReason = "due in ${daysToDeadline}d" }
            elseif ($daysToDeadline -le 7)  { $deadline = 0.75; $deadlineReason = "due in ${daysToDeadline}d" }
            elseif ($daysToDeadline -le 14) { $deadline = 0.55; $deadlineReason = "due in ${daysToDeadline}d" }
            else                            { $deadline = 0.35; $deadlineReason = "due in ${daysToDeadline}d" }
        } catch { $deadline = 0.35; $deadlineReason = "deadline $deadlineStr" }
    }
    # aging fallback for risks (no deadline field on risks)
    if ($Kind -eq 'risk') {
        $agingDays = if ($Entry.agingDays) { [int]$Entry.agingDays } else { 0 }
        $agingFactor = if ($agingDays -ge 30) { 0.9 } elseif ($agingDays -ge 14) { 0.7 } elseif ($agingDays -ge 7) { 0.5 } else { 0.3 }
        if ($agingFactor -gt $deadline) { $deadline = $agingFactor; $deadlineReason = "aging ${agingDays}d" }
    }

    # --- status ----------------------------------------------------------
    switch ($status) {
        'red'   { $statusF = 1.00; $statusReason = 'status RED' }
        'amber' { $statusF = 0.60; $statusReason = 'status AMBER' }
        'green' { $statusF = 0.20; $statusReason = 'status GREEN' }
        default { $statusF = 0.40; $statusReason = 'status unknown' }
    }

    # --- engagement ------------------------------------------------------
    $engagement = 0.40
    $engagementReason = 'neutral'
    if ($signals.attentionRequired) { $engagement = 1.00; $engagementReason = 'attention required' }
    elseif ($signals.engaged -and -not $signals.awaitingOthers) { $engagement = 0.75; $engagementReason = 'active engagement' }
    elseif ($signals.awaitingOthers -and -not $signals.attentionRequired) { $engagement = 0.30; $engagementReason = 'awaiting others (dampened)' }

    # --- weighted sum ----------------------------------------------------
    $wImpact     = 0.25
    $wOwnership  = 0.20
    $wDeadline   = 0.20
    $wStatus     = 0.20
    $wEngagement = 0.15

    $raw = ($impact * $wImpact) + ($ownership * $wOwnership) + ($deadline * $wDeadline) + ($statusF * $wStatus) + ($engagement * $wEngagement)
    $score = [int][Math]::Round($raw * 100)
    if ($score -lt 0)   { $score = 0 }
    if ($score -gt 100) { $score = 100 }

    $reason = ("impact={0:F2}({1}); ownership={2:F2}({3}); deadline={4:F2}({5}); status={6:F2}({7}); engagement={8:F2}({9})" -f `
        $impact, $impactReason, $ownership, $ownershipReason, $deadline, $deadlineReason, $statusF, $statusReason, $engagement, $engagementReason)

    return @{
        score  = $score
        reason = $reason
        factors = [ordered]@{
            impact     = [Math]::Round($impact, 2)
            ownership  = [Math]::Round($ownership, 2)
            deadline   = [Math]::Round($deadline, 2)
            status     = [Math]::Round($statusF, 2)
            engagement = [Math]::Round($engagement, 2)
        }
    }
}

function Get-PriorityReasonBullets {
    <#
        V4.0 Sprint 17: builds a human-readable bullet list explaining WHY an
        item scored what it did. Combines:
          - the semantic impact statement (whyItMatters, Sprint 15)
          - the status ladder trigger (matryoshkaStatusReason, Phase 1c)
          - focus signals (attentionRequired / engaged / awaitingOthers, 13a)
          - ownership signals (unassigned / suggested owner)
          - deadline / aging pressure

        Bullets are ordered by discriminating power: whyItMatters first when
        we have a Tier 1/2/3 extraction, then hard signals (red / breached /
        high-severity), then engagement, then metadata.

        Returns @{ bullets = <string[]>; reasonText = <bulletized string> }.
    #>
    param(
        [hashtable] $Entry,
        [ValidateSet('decision','risk')] [string] $Kind,
        [datetime]  $Now
    )

    $bullets = [System.Collections.Generic.List[string]]::new()

    # --- WHY: the semantic impact statement (highest signal when confident) ---
    $why     = if ($Entry.whyItMatters)          { [string]$Entry.whyItMatters }          else { '' }
    $whyConf = if ($Entry.whyItMattersConfidence){ [double]$Entry.whyItMattersConfidence } else { 0.0 }
    $whySrc  = if ($Entry.whyItMattersSource)    { [string]$Entry.whyItMattersSource }    else { 'none' }
    if ($why -and $whyConf -ge 0.5) {
        # Trim to a compact bullet; drop redundant trailing period.
        $t = $why -replace '\s+', ' '
        $t = $t.Trim().TrimEnd('.')
        if ($t.Length -gt 180) { $t = $t.Substring(0, 179) + '…' }
        [void]$bullets.Add("Why it matters: $t")
    }

    # --- HARD status signals ---
    $status = if ($Entry.matryoshkaStatus) { [string]$Entry.matryoshkaStatus } else { 'green' }
    $reasonText = if ($Entry.matryoshkaStatusReason) { [string]$Entry.matryoshkaStatusReason } else { '' }

    if ($Kind -eq 'risk' -and $Entry.severity -eq 'High') {
        [void]$bullets.Add('High-severity risk')
    }
    if ($status -eq 'red') {
        # Surface the underlying red trigger when it's not already implied.
        if ($reasonText -and $reasonText -notmatch '(?i)high-severity risk') {
            $short = ($reasonText -split ';')[0].Trim()
            if ($short) { [void]$bullets.Add("Status RED: $short") }
        } elseif (-not ($Kind -eq 'risk' -and $Entry.severity -eq 'High')) {
            [void]$bullets.Add('Status RED')
        }
    }

    # --- Deadline pressure (decisions) ---
    if ($Kind -eq 'decision' -and $Entry.decisionDeadline) {
        $dlStr = [string]$Entry.decisionDeadline
        if ($dlStr -match '^\d{4}-\d{2}-\d{2}') {
            try {
                $dl = [datetime]::ParseExact($dlStr.Substring(0,10),'yyyy-MM-dd',$null)
                $daysTo = [int]([Math]::Round(($dl - $Now.Date).TotalDays))
                if ($daysTo -lt 0)      { [void]$bullets.Add("Deadline breached $([Math]::Abs($daysTo))d ago ($dlStr)") }
                elseif ($daysTo -le 3)  { [void]$bullets.Add("Deadline in ${daysTo}d ($dlStr)") }
                elseif ($daysTo -le 7)  { [void]$bullets.Add("Deadline in ${daysTo}d") }
            } catch { }
        }
    }

    # --- Aging (all kinds) ---
    $ageDays = if ($Kind -eq 'decision' -and $Entry.decisionAgeDays) {
        [int]$Entry.decisionAgeDays
    } elseif ($Kind -eq 'risk' -and $Entry.agingDays) {
        [int]$Entry.agingDays
    } else { 0 }
    if ($ageDays -ge 14) {
        $noun = if ($Kind -eq 'decision') { 'Decision' } else { 'Risk' }
        [void]$bullets.Add("$noun aged $ageDays days without resolution")
    }

    # --- Ownership gap ---
    $owner = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }
    if ($owner -match '(?i)^\s*unassigned\s*$') {
        if ($Entry.suggestedOwner) {
            [void]$bullets.Add("Owner unassigned (suggested: $($Entry.suggestedOwner))")
        } else {
            [void]$bullets.Add('Owner unassigned - needs assignment')
        }
    }

    # --- Focus signals (Sprint 13a) ---
    $sigs = if ($Entry.focusSignals -is [System.Collections.IDictionary]) { $Entry.focusSignals } else { $null }
    if ($sigs) {
        if ($sigs.attentionRequired) {
            $r = if ($sigs.reasons -and $sigs.reasons.attentionRequired) { [string]$sigs.reasons.attentionRequired } else { '' }
            if ($r) { [void]$bullets.Add("Attention required ($r)") } else { [void]$bullets.Add('Attention required') }
        }
        if ($sigs.engaged) {
            [void]$bullets.Add('Active engagement detected')
        }
        if ($sigs.awaitingOthers) {
            [void]$bullets.Add('Awaiting external party')
        }
    }

    # --- Fallback context (only if we produced nothing above) ---
    if ($bullets.Count -eq 0 -and $why) {
        $t = $why -replace '\s+', ' '
        $t = $t.Trim().TrimEnd('.')
        if ($t.Length -gt 180) { $t = $t.Substring(0, 179) + '…' }
        [void]$bullets.Add("Context: $t (source: $whySrc)")
    }
    if ($bullets.Count -eq 0) {
        [void]$bullets.Add('No specific triggers - baseline score')
    }

    $reasonText = ($bullets | ForEach-Object { "- $_" }) -join "`n"
    return @{
        bullets    = @($bullets)
        reasonText = $reasonText
    }
}

function Apply-PriorityScore {
    <#
        V4.0 Sprint 13b + Sprint 17 orchestrator: stamps `priorityScore` +
        `priorityReason` (human-readable bullets, Sprint 17) +
        `priorityReasonBullets` (string[]) + `priorityReasonDebug` (raw factor
        breakdown, Sprint 13b) + `priorityFactors` (numeric) on every live
        decision + risk. Non-destructive. Returns @{ min; max; mean; count }.
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks,
        [datetime] $Now
    )

    $sum = 0.0; $min = 101; $max = -1; $count = 0
    foreach ($kind in @('decision','risk')) {
        $entries = if ($kind -eq 'decision') { $Decisions } else { $Risks }
        foreach ($e in $entries) {
            if (-not $e) { continue }
            $res = Get-PriorityScore -Entry $e -Kind $kind -Now $Now
            $e.priorityScore        = [int]$res.score
            $e.priorityReasonDebug  = [string]$res.reason   # Sprint 13b factor breakdown
            $e.priorityFactors      = $res.factors
            # Sprint 17: human-readable bullets built AFTER whyItMatters + focusSignals stamped.
            $bulletsRes = Get-PriorityReasonBullets -Entry $e -Kind $kind -Now $Now
            $e.priorityReasonBullets = @($bulletsRes.bullets)
            $e.priorityReason        = [string]$bulletsRes.reasonText
            $sum += $res.score
            if ($res.score -lt $min) { $min = $res.score }
            if ($res.score -gt $max) { $max = $res.score }
            $count += 1
        }
    }
    if ($count -eq 0) { return @{ min = 0; max = 0; mean = 0; count = 0 } }
    return @{
        min   = $min
        max   = $max
        mean  = [Math]::Round($sum / $count, 1)
        count = $count
    }
}

function Get-StructuredDecisionAction {
    <#
        Converts the ad-hoc `recommendedFollowUp` string into a structured object.
        V4.0 Phase 2: adds `actionClass` (DO | DECIDE | FOLLOW_UP | INVESTIGATE | BLOCKED)
        and imperative `nextAction` sentence. Legacy `verb` retained for back-compat.

        Classification rules:
          - Unassigned owner  -> DECIDE (assign owner first)
          - status=closed     -> DECIDE (archive-or-reopen)
          - age >= 14, owner is David  -> DO (David escalates today)
          - age >= 14, other owner     -> FOLLOW_UP (contact owner today)
          - age >= 7                   -> FOLLOW_UP (confirm this week)
          - fresh                      -> FOLLOW_UP (check in in 7 days)
    #>
    param([hashtable] $Entry, [datetime] $Now)

    $rawTitle = if ($Entry.title) { [string]$Entry.title } else { '' }
    $subject  = if ($rawTitle.Length -gt 100) { $rawTitle.Substring(0, 97) + '...' } else { $rawTitle }
    $owner    = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }
    $ownerIsDavid = $owner -match '(?i)^\s*david(\s+klan)?\s*$'
    $isUnassigned = $owner -match '(?i)^\s*unassigned\s*$'
    $escTarget = if ($Entry.escalationPath -and @($Entry.escalationPath).Count -gt 0) {
        [string](@($Entry.escalationPath)[0])
    } else { 'the workstream lead' }
    $wsLabel = if ($Entry.workstream) { [string]$Entry.workstream } else { 'this decision' }
    $decisionAge = if ($Entry.decisionAgeDays) { [int]$Entry.decisionAgeDays } else { 0 }

    if ($isUnassigned) {
        return [ordered]@{
            priority     = 2
            verb         = 'Confirm'
            actionClass  = 'DECIDE'
            nextAction   = "Assign an owner for $wsLabel before this decision can move"
            subject      = $subject
            targetOwner  = 'Unassigned'
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Owner not yet confirmed; ownership must precede action.'
        }
    }

    if ($Entry.status -eq 'closed') {
        return [ordered]@{
            priority     = 5
            verb         = 'Archive'
            actionClass  = 'DECIDE'
            nextAction   = "Decide whether to archive $($Entry.decisionId) or reopen"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.AddDays(30).ToString('yyyy-MM-dd')
            rationale    = 'Decision closed; archive after next reporting cycle.'
        }
    }
    if ($decisionAge -ge 14) {
        if ($ownerIsDavid) {
            return [ordered]@{
                priority     = 1
                verb         = 'Escalate'
                actionClass  = 'DO'
                nextAction   = "Send escalation on $wsLabel to $escTarget today"
                subject      = $subject
                targetOwner  = $owner
                dueBy        = $Now.ToString('yyyy-MM-dd')
                rationale    = "Pending $decisionAge days - David to escalate to $escTarget today."
            }
        }
        return [ordered]@{
            priority     = 1
            verb         = 'Escalate'
            actionClass  = 'FOLLOW_UP'
            nextAction   = "Contact $owner today - decision on $wsLabel aged $decisionAge days without resolution"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.ToString('yyyy-MM-dd')
            rationale    = "Pending $decisionAge days - direct outreach to owner today."
        }
    }
    if ($decisionAge -ge 7) {
        return [ordered]@{
            priority     = 2
            verb         = 'Confirm'
            actionClass  = 'FOLLOW_UP'
            nextAction   = "Confirm status with $owner this week and record outcome"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Aging 7+ days - confirm status and communicate resolution this week.'
        }
    }
    return [ordered]@{
        priority     = 4
        verb         = 'Track'
        actionClass  = 'FOLLOW_UP'
        nextAction   = "Check in with $owner in 7 days on $wsLabel"
        subject      = $subject
        targetOwner  = $owner
        dueBy        = $Now.AddDays(7).ToString('yyyy-MM-dd')
        rationale    = 'Fresh decision - monitor for follow-through.'
    }
}

function Get-DecisionRegistry {
    <#
        Scans context-eligible file records for decision-signal phrases and
        returns deduplicated decision entries with V1.8 fields:
          - firstSeenDate / lastSeenDate / decisionAgeDays / recencyDays
          - owner + ownerConfidence + escalationPath + stakeholders
          - recommendedFollowUp as a structured object
    #>
    param(
        [System.Collections.Generic.List[hashtable]] $Records,
        [object[]] $Workstreams,
        [hashtable] $Model,
        [hashtable] $OwnershipMap = @{}
    )

    $now = Get-Date

    $aliasMap = @{}
    $nameToId = @{}
    foreach ($ws in $Workstreams) {
        $aliasMap[$ws.name.ToLowerInvariant()] = $ws.name
        $aliasMap[$ws.id.ToLowerInvariant()]   = $ws.name
        foreach ($a in $ws.aliases) { $aliasMap[$a.ToLowerInvariant()] = $ws.name }
        $nameToId[$ws.name] = $ws.id
    }
    $aliasKeys = @($aliasMap.Keys | Sort-Object { -($_.Length) })

    $stakeKeys = @($Model.stakeholder_weights.Keys)

    # Line-level decision phrase capture (bullet or heading prefix tolerated).
    # V2.0 adds a second pattern for PENDING decisions that need David's input.
    $keywordAlt = ($script:DECISION_KEYWORDS | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $decisionRegex = '(?im)^\s*(?:[-*>]\s+)?(?:\*\*)?(' + $keywordAlt + ')(?:\*\*)?\s*[:\-]\s*(.+?)\s*$'
    $pendingAlt = ($script:PENDING_DECISION_KEYWORDS | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $pendingRegex = '(?im)^\s*(?:[-*>]\s+)?(?:\*\*)?(' + $pendingAlt + ')(?:\*\*)?\s*[:\-]\s+(.+?)\s*$'

    $decisions = @{}

    foreach ($rec in $Records) {
        if (-not $rec.IncludeForContext) { continue }
        try {
            $content = Get-Content -LiteralPath $rec.FullPath -Raw -Encoding UTF8 -ErrorAction Stop
        } catch { continue }
        if ([string]::IsNullOrWhiteSpace($content)) { continue }

        $normalised = $content -replace "`r`n", "`n"
        $lines = $normalised -split "`n"
        $currentHeading = ''
        $headingRegex   = '^##\s+(D\d+\s*[\u2014\-]\s*.+?)\s*$'

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $h = [regex]::Match($line, $headingRegex)
            if ($h.Success) {
                $currentHeading = ($h.Groups[1].Value -replace '\s+', ' ').Trim()
                continue
            }

            $m = [regex]::Match($line, $decisionRegex)
            $matchType = 'recorded'
            if (-not $m.Success) {
                $m = [regex]::Match($line, $pendingRegex)
                if (-not $m.Success) { continue }
                $matchType = 'pending'
            }

            $keyword = $m.Groups[1].Value
            $body    = ($m.Groups[2].Value.Trim() -replace '\s+', ' ')
            # Strip Markdown emphasis that leaks in from patterns like `**Decision:** Approved`
            $body = $body -replace '^\s*\*+\s*', ''
            $body = $body -replace '\s*\*+\s*$', ''
            $body = $body.Trim().TrimEnd('.', ',', ';', ':')
            if ($body.Length -lt 2 -or $body.Length -gt 300) { continue }

            # Small context window (5 lines around) for workstream / owner / status / summary heuristics
            $ctxStart = [Math]::Max(0, $i - 3)
            $ctxEnd   = [Math]::Min($lines.Count - 1, $i + 6)
            $context  = ($lines[$ctxStart..$ctxEnd] -join "`n")
            $lcContext = $context.ToLowerInvariant()

            # Prefer H2 heading as title when the file uses the `## Dxxx  ETitle` convention.
            $titleRaw = if ($currentHeading) { $currentHeading } else { $body }
            $title    = if ($titleRaw.Length -gt 140) { $titleRaw.Substring(0, 137) + '...' } else { $titleRaw }

            # V4.0 Sprint 19: normalize + validate title BEFORE record creation.
            # Malformed / numeric-only / bare-name titles get dropped and logged
            # so downstream consumers never see them.
            $normalizedTitle = Normalize-CorpusTitle -Raw $title
            $titleCheck = Test-CorpusTitleValid -Title $normalizedTitle -StakeholderNames $stakeKeys
            if (-not $titleCheck.ok) {
                Add-TitleDropRecord -Kind 'decision' -RawTitle $title -NormalizedTitle $normalizedTitle -Reason $titleCheck.reason -SourcePath $rec.RelPath
                continue
            }
            $title = $normalizedTitle

            # If a "**Summary:** ..." line exists nearby, capture it as the summary.
            $summaryMatch = [regex]::Match($context, '(?im)^\s*\*\*Summary:\*\*\s*(.+?)\s*$')
            $summary = if ($summaryMatch.Success) {
                ($summaryMatch.Groups[1].Value -replace '\s+', ' ').Trim()
            } else {
                "${keyword}: $body"
            }
            if ($summary.Length -gt 240) { $summary = $summary.Substring(0, 237) + '...' }

            # V2.0: extract business impact from context if present.
            $impact = Get-ImpactFromContext -Context $context
            # V2.0: decision-specific explicit deadline (**By:**, **Deadline:**, **Due:**)
            $explicitDeadline = Get-DeadlineFromContext -Context $context
            # V2.5: execution tracking - outcome, linked actions, completion signal.
            $outcome          = Get-OutcomeFromContext -Context $context
            $linkedActions    = Get-LinkedActionsFromContext -Context $context
            $completionSignal = Get-CompletionSignalFromContext -Context $context
            # V4.0 Phase 7: explicit ownership marker
            $explicitOwner    = Get-OwnerFromContext -Context $context

            # V2.5 fallback: `**Decision:** <ResolutionVerb>` (Approved / Deferred /
            # Rejected / Superseded / Reversed / Deprecated / Locked / Confirmed)
            # is itself an outcome + completion signal, even without an explicit
            # `**Outcome:**` marker.
            if (-not $outcome -and $keyword -match '^(?i)Decision$' -and $body -match '^(?i)(Approved|Deferred|Rejected|Superseded|Reversed|Deprecated|Locked|Confirmed)\b') {
                $outcome = $body
                if (-not $completionSignal) { $completionSignal = 'completed' }
            }

            # Workstream via longest-alias-first
            $workstream = ''
            foreach ($k in $aliasKeys) {
                if ($lcContext -match ('\b' + [regex]::Escape($k) + '\b')) {
                    $workstream = $aliasMap[$k]; break
                }
            }

            # Owner via stakeholder name presence in context
            $owner = ''
            foreach ($n in $stakeKeys) {
                if ($context -match ('(?i)\b' + [regex]::Escape($n) + '\b')) { $owner = $n; break }
            }

            # Status heuristic
            $status = 'open'
            if ($context -match '(?i)\b(closed|resolved|superseded|reversed|deprecated)\b') { $status = 'closed' }

            $seed = ($workstream + '|' + $title + '|' + $rec.RelPath)
            $decisionId = New-DecisionId -Seed $seed

            if (-not $decisions.ContainsKey($decisionId)) {
                $decisions[$decisionId] = @{
                    decisionId          = $decisionId
                    title               = $title
                    dateDetected        = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                    firstSeenDate       = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                    lastSeenDate        = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                    status              = $status
                    owner               = $owner
                    ownerConfidence     = 'unknown'
                    suggestedOwner      = ''
                    _explicitOwner      = $explicitOwner
                    escalationPath      = [System.Collections.Generic.List[string]]::new()
                    stakeholders        = [System.Collections.Generic.List[string]]::new()
                    workstream          = $workstream
                    sourceFiles         = [System.Collections.Generic.List[string]]::new()
                    decisionAgeDays     = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
                    recencyDays         = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
                    decisionSummary     = $summary
                    impact              = $impact
                    decisionConfidence  = 0.0
                    # V2.0 decision triggering
                    type                = $matchType
                    decisionRequired    = ($matchType -eq 'pending')
                    decisionPrompt      = if ($matchType -eq 'pending') { $body } else { '' }
                    decisionDeadline    = $explicitDeadline
                    # V2.5 execution intelligence
                    decisionStatus       = 'Pending'
                    decisionOutcome      = $outcome
                    linkedActions        = [System.Collections.Generic.List[hashtable]]::new()
                    completionSignal     = $completionSignal
                    timeToEscalationRisk = $null
                    themeTags            = [System.Collections.Generic.List[string]]::new()
                    # V3.0 adaptive intelligence
                    outcomeQuality       = 'Unknown'
                    recurrenceCount      = 0
                    recommendedFollowUp = $null
                    _detectedOn         = $rec.LastWriteTime
                    _lastSeenOn         = $rec.LastWriteTime
                }
                foreach ($la in @($linkedActions)) { $decisions[$decisionId].linkedActions.Add($la) }
            }

            $entry = $decisions[$decisionId]
            if (-not $entry.sourceFiles.Contains($rec.RelPath)) { $entry.sourceFiles.Add($rec.RelPath) }
            if (-not $entry.owner      -and $owner)      { $entry.owner      = $owner }
            if (-not $entry.workstream -and $workstream) { $entry.workstream = $workstream }
            if (-not $entry.impact     -and $impact)     { $entry.impact     = $impact }
            if (-not $entry.decisionDeadline -and $explicitDeadline) { $entry.decisionDeadline = $explicitDeadline }
            # V4.0 Phase 7: prefer explicit owner marker if found in any sighting
            if (-not $entry._explicitOwner -and $explicitOwner) { $entry._explicitOwner = $explicitOwner }
            # V2.5: prefer any captured outcome; upgrade completionSignal (completed trumps in-progress)
            if (-not $entry.decisionOutcome -and $outcome) { $entry.decisionOutcome = $outcome }
            if ($completionSignal -eq 'completed') { $entry.completionSignal = 'completed' }
            elseif ($completionSignal -eq 'in-progress' -and $entry.completionSignal -ne 'completed') { $entry.completionSignal = 'in-progress' }
            # Merge linked actions - dedupe on trimmed text (case-insensitive)
            if ($linkedActions -and @($linkedActions).Count -gt 0) {
                $existingTexts = @($entry.linkedActions | ForEach-Object { ([string]$_.text).ToLowerInvariant() })
                foreach ($la in @($linkedActions)) {
                    $key = ([string]$la.text).ToLowerInvariant()
                    if ($existingTexts -notcontains $key -and $entry.linkedActions.Count -lt 5) {
                        $entry.linkedActions.Add($la)
                        $existingTexts += $key
                    }
                }
            }
            # Any pending sighting upgrades type/decisionRequired (pending trumps recorded on dedupe)
            if ($matchType -eq 'pending') {
                $entry.type = 'pending'
                $entry.decisionRequired = $true
                if (-not $entry.decisionPrompt) { $entry.decisionPrompt = $body }
            }

            # firstSeen = earliest, lastSeen = latest
            if ($rec.LastWriteTime -lt $entry._detectedOn) {
                $entry._detectedOn     = $rec.LastWriteTime
                $entry.dateDetected    = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                $entry.firstSeenDate   = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                $entry.decisionAgeDays = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
            }
            if ($rec.LastWriteTime -gt $entry._lastSeenOn) {
                $entry._lastSeenOn  = $rec.LastWriteTime
                $entry.lastSeenDate = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                $entry.recencyDays  = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
            }

            # Any closed sighting closes the decision
            if ($status -eq 'closed') { $entry.status = 'closed' }
        }
    }

    foreach ($e in $decisions.Values) {
        # V4.0 Phase 7 ownership hierarchy:
        #   high   = explicit **Owner:** marker in source context
        #   medium = name-proximity (stakeholder appears in nearby text)
        #   low    = only workstream-map suggestion, or truly unowned
        # Escalation path + stakeholders always come from the map (structural, not ownership).
        $mapEntry = $null
        if ($e.workstream -and $nameToId.ContainsKey($e.workstream)) {
            $wsId = $nameToId[$e.workstream]
            if ($OwnershipMap.ContainsKey($wsId)) { $mapEntry = $OwnershipMap[$wsId] }
        }
        if ($mapEntry) {
            foreach ($n in $mapEntry.escalationPath) {
                if (-not $e.escalationPath.Contains($n)) { $e.escalationPath.Add($n) }
            }
            foreach ($n in $mapEntry.stakeholders) {
                if (-not $e.stakeholders.Contains($n)) { $e.stakeholders.Add($n) }
            }
        }
        if ($e._explicitOwner) {
            $e.owner = $e._explicitOwner
            $e.suggestedOwner = ''
            $e.ownerConfidence = 'high'
        } elseif ($e.owner) {
            $e.suggestedOwner = ''
            $e.ownerConfidence = 'medium'
        } elseif ($mapEntry -and $mapEntry.owner) {
            $e.owner = 'Unassigned'
            $e.suggestedOwner = $mapEntry.owner
            $e.ownerConfidence = 'low'
        } else {
            $e.owner = 'Unassigned'
            $e.suggestedOwner = ''
            $e.ownerConfidence = 'low'
        }

        # V1.8 structured action
        $e.recommendedFollowUp = Get-StructuredDecisionAction -Entry $e -Now $now

        # V2.0: if an explicit decisionDeadline was captured, override the
        # aging-derived dueBy so the action reflects the real deadline.
        if ($e.decisionDeadline -and ($e.recommendedFollowUp -is [System.Collections.IDictionary])) {
            $e.recommendedFollowUp.dueBy = $e.decisionDeadline
        }

        # V4.0 Phase 3: staleness flag (must run AFTER action classification
        # because it consults the actionClass).
        $e.stale = Get-StaleFlag -Entry $e -Kind 'decision'

        # V2.0 David Brain: confidence score
        $e.decisionConfidence = Get-EntryConfidence -Entry $e

        # V2.0 heuristic promotion: high-priority recorded decisions
        # (P1 Escalate or P2 Confirm) require David's attention even without
        # an explicit "Question:" marker. Preserve `type = recorded` so the
        # priority inbox can distinguish 'new question' from 'stalled action'.
        if (-not $e.decisionRequired -and ($e.recommendedFollowUp -is [System.Collections.IDictionary])) {
            $p = $e.recommendedFollowUp.priority
            if ($p -is [int] -and $p -le 2) {
                $e.decisionRequired = $true
                if (-not $e.decisionPrompt) {
                    $e.decisionPrompt = "Recorded decision aged $($e.decisionAgeDays) days - confirm status or escalate."
                }
            }
        }

        # V2.5 Execution Intelligence: lifecycle + escalation risk
        $e.decisionStatus       = Get-DecisionLifecycleStatus -Entry $e -Now $now
        $e.timeToEscalationRisk = Get-EscalationRisk -Kind 'decision' -Entry $e -Now $now
        # A decided item should no longer be flagged as requiring a decision.
        if ($e.decisionStatus -eq 'Decided') { $e.decisionRequired = $false }

        # V3.0 Adaptive Intelligence: action inference + outcome quality
        # If no marker-derived actions exist for a still-Pending decision,
        # synthesize 1-3 inferred follow-ups. Mark them with actionSource='inferred'.
        if ($e.decisionStatus -ne 'Decided' -and (@($e.linkedActions).Count -eq 0)) {
            $inferred = Get-InferredActions -Entry $e -Now $now
            foreach ($ia in @($inferred)) { $e.linkedActions.Add($ia) }
        }
        $e.outcomeQuality  = Get-OutcomeQuality -Entry $e
        $e.recurrenceCount = 0    # populated in the second pass below
    }

    # V3.0 recurrence detection: normalize titles and count occurrences.
    # Any decision whose normalized title appears 2+ times gets recurrenceCount>=2.
    $titleCounts = @{}
    foreach ($e in $decisions.Values) {
        $norm = Get-NormalizedTitle -Title $e.title
        if (-not $norm) { continue }
        if (-not $titleCounts.ContainsKey($norm)) { $titleCounts[$norm] = 0 }
        $titleCounts[$norm] += 1
    }
    foreach ($e in $decisions.Values) {
        $norm = Get-NormalizedTitle -Title $e.title
        if ($norm -and $titleCounts.ContainsKey($norm)) {
            $e.recurrenceCount = [int]$titleCounts[$norm]
        }
    }

    # Sort: open before closed; within each group, oldest first
    # V4.0 Phase 6: fuzzy-dedup groups of similar decisions within the same
    # workstream. Winner (freshest lastSeenDate) absorbs source files + IDs.
    $dedupResult = Merge-DuplicateEntries -Entries @($decisions.Values) -Kind 'decision'
    $script:MAT_MERGED_DECISIONS = @($dedupResult.mergedGroups)
    $deduped = @($dedupResult.items)
    return @($deduped | Sort-Object `
        @{ Expression = { if ($_.status -eq 'closed') { 1 } else { 0 } }; Ascending = $true },
        @{ Expression = { $_.decisionAgeDays };                            Descending = $true })
}

function Build-DecisionRegistryMarkdown {
    param(
        [object[]] $Decisions,
        [string]   $NowStamp
    )

    $open      = @($Decisions | Where-Object { $_.status -ne 'closed' })
    $closed    = @($Decisions | Where-Object { $_.status -eq 'closed' })
    $escalate  = @($open | Where-Object { $_.decisionAgeDays -ge 14 })
    $recent    = @($closed | Sort-Object { $_._detectedOn } -Descending | Select-Object -First 8)

    function _RenderEntry($e) {
        $ownerText = if ($e.owner) { $e.owner } else { '-' }
        $wsText    = if ($e.workstream) { $e.workstream } else { '-' }
        $sources   = if ($e.sourceFiles.Count -gt 0) {
            ($e.sourceFiles | Select-Object -First 5 | ForEach-Object { "  - ``$_``" }) -join "`n"
        } else { '  - (no source captured)' }

        $escalationText = if ($e.escalationPath -and $e.escalationPath.Count -gt 0) {
            ($e.escalationPath -join ' -> ')
        } else { '-' }
        $stakeText = if ($e.stakeholders -and $e.stakeholders.Count -gt 0) {
            ($e.stakeholders -join ', ')
        } else { '-' }

        $act = $e.recommendedFollowUp
        $actionText = if ($act -is [System.Collections.IDictionary]) {
            $classBit = if ($act.actionClass) { "[$($act.actionClass)] " } else { '' }
            $nextBit  = if ($act.nextAction) { $act.nextAction } else { "$($act.verb): $($act.subject)" }
            "${classBit}P$($act.priority) - $nextBit (owner: $($act.targetOwner), by $($act.dueBy))"
        } else {
            "$act"
        }

        $lifecycleText = if ($e.decisionStatus) { $e.decisionStatus } else { '-' }
        $outcomeText   = if ($e.decisionOutcome) { $e.decisionOutcome } else { '-' }
        $escText       = if ($null -ne $e.timeToEscalationRisk) { "$($e.timeToEscalationRisk) day(s)" } else { 'n/a' }
        $linkedText    = if ($e.linkedActions -and @($e.linkedActions).Count -gt 0) {
            (@($e.linkedActions) | ForEach-Object {
                $ownerBit = if ($_.owner) { " owner: $($_.owner)" } else { '' }
                $dueBit   = if ($_.dueBy) { " due: $($_.dueBy)" } else { '' }
                "  - [$($_.status)] $($_.text)$ownerBit$dueBit"
            }) -join "`n"
        } else { '  - (no linked actions)' }

        return @"
### $($e.decisionId) - $($e.title)

- Workstream: **$wsText**
- Owner: **$ownerText** _(confidence: $($e.ownerConfidence))_
- Escalation Path: $escalationText
- Stakeholders: $stakeText
- Status: **$($e.status)**
- Lifecycle: **$lifecycleText**
- Outcome: $outcomeText
- Time to escalation: **$escText**
- First seen: **$($e.firstSeenDate)** ($($e.decisionAgeDays) days ago)
- Last seen: **$($e.lastSeenDate)** ($($e.recencyDays) days ago)
- Follow-up: $actionText
- Linked actions:
$linkedText
- Sources:
$sources

"@
    }

    $openBlock     = if ($open.Count -gt 0)     { ($open     | ForEach-Object { _RenderEntry $_ }) -join '' } else { "_No open decisions detected._`n" }
    $escalateBlock = if ($escalate.Count -gt 0) { ($escalate | ForEach-Object { _RenderEntry $_ }) -join '' } else { "_No decisions past the 14-day escalation threshold._`n" }
    $closedBlock   = if ($recent.Count -gt 0)   { ($recent   | ForEach-Object { _RenderEntry $_ }) -join '' } else { "_No recently closed decisions._`n" }

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Decision Registry

Generated: $NowStamp

Total: **$($Decisions.Count)** decisions ($($open.Count) open / $($closed.Count) closed)

## Oldest Unresolved Decisions (escalation candidates)

$escalateBlock

## Open Decisions

$openBlock

## Recently Closed Decisions

$closedBlock

## Notes

Decisions are auto-extracted from context-eligible files (see 00-context/source-weights.yaml).
Follow-up recommendations are age-based:
- 0-6 days: Monitor
- 7-13 days: Confirm status this week
- 14+ days: Escalate
"@
}

function Build-DecisionRegistryJson {
    param(
        [object[]] $Decisions,
        [string]   $GeneratedIso
    )

    $items = foreach ($e in $Decisions) {
        [ordered]@{
            decisionId          = $e.decisionId
            title               = $e.title
            dateDetected        = $e.dateDetected
            firstSeenDate       = $e.firstSeenDate
            lastSeenDate        = $e.lastSeenDate
            status              = $e.status
            type                = $e.type
            decisionRequired    = $e.decisionRequired
            decisionPrompt      = $e.decisionPrompt
            decisionDeadline    = $e.decisionDeadline
            decisionStatus      = $e.decisionStatus
            decisionOutcome     = $e.decisionOutcome
            completionSignal    = $e.completionSignal
            linkedActions       = @($e.linkedActions)
            timeToEscalationRisk= $e.timeToEscalationRisk
            outcomeQuality      = $e.outcomeQuality
            recurrenceCount     = $e.recurrenceCount
            owner               = $e.owner
            ownerConfidence     = $e.ownerConfidence
            suggestedOwner      = if ($e.ContainsKey('suggestedOwner')) { [string]$e.suggestedOwner } else { '' }
            escalationPath      = @($e.escalationPath)
            stakeholders        = @($e.stakeholders)
            workstream          = $e.workstream
            sourceFiles         = @($e.sourceFiles)
            decisionAgeDays     = $e.decisionAgeDays
            recencyDays         = $e.recencyDays
            decisionSummary     = $e.decisionSummary
            impact              = $e.impact
            decisionConfidence  = $e.decisionConfidence
            unifiedConfidence   = if ($e.ContainsKey('unifiedConfidence')) { [double]$e.unifiedConfidence } else { 0.0 }
            mentionCount        = if ($e.ContainsKey('mentionCount'))     { [int]$e.mentionCount }        else { @($e.sourceFiles).Count }
            mergedFrom          = if ($e.ContainsKey('mergedFrom'))       { @($e.mergedFrom) }            else { @() }
            stale               = if ($e.ContainsKey('stale')) { [bool]$e.stale } else { $false }
            delta               = if ($e.ContainsKey('delta') -and $e.delta) { $e.delta } else { [ordered]@{ daysSinceLastTouched = 0; updatedSinceYesterday = $true; changeSummary = 'first appearance' } }
            contextSummary      = if ($e.ContainsKey('contextSummary'))  { [string]$e.contextSummary } else { '' }
            contextMetadata     = if ($e.ContainsKey('contextMetadata') -and $e.contextMetadata) { $e.contextMetadata } else { [ordered]@{ lastMention = ''; lastActivity = ''; actors = @(); primarySource = '' } }
            whyItMatters           = if ($e.ContainsKey('whyItMatters'))           { [string]$e.whyItMatters }           else { '' }
            whyItMattersConfidence = if ($e.ContainsKey('whyItMattersConfidence')) { [double]$e.whyItMattersConfidence } else { 0.0 }
            whyItMattersSource     = if ($e.ContainsKey('whyItMattersSource'))     { [string]$e.whyItMattersSource }     else { 'none' }
            matryoshkaStatus       = if ($e.ContainsKey('matryoshkaStatus'))       { [string]$e.matryoshkaStatus }       else { '' }
            matryoshkaStatusReason = if ($e.ContainsKey('matryoshkaStatusReason')) { [string]$e.matryoshkaStatusReason } else { '' }
            focusSignals           = if ($e.ContainsKey('focusSignals') -and $e.focusSignals) { $e.focusSignals } else { [ordered]@{ engaged = $false; attentionRequired = $false; awaitingOthers = $false; reasons = [ordered]@{ engaged=''; attentionRequired=''; awaitingOthers='' } } }
            priorityScore          = if ($e.ContainsKey('priorityScore'))   { [int]$e.priorityScore }   else { 0 }
            priorityReason         = if ($e.ContainsKey('priorityReason'))  { [string]$e.priorityReason } else { '' }
            priorityReasonBullets  = if ($e.ContainsKey('priorityReasonBullets') -and $e.priorityReasonBullets) { @($e.priorityReasonBullets) } else { @() }
            priorityReasonDebug    = if ($e.ContainsKey('priorityReasonDebug'))    { [string]$e.priorityReasonDebug }    else { '' }
            priorityFactors        = if ($e.ContainsKey('priorityFactors') -and $e.priorityFactors) { $e.priorityFactors } else { [ordered]@{ impact=0.0; ownership=0.0; deadline=0.0; status=0.0; engagement=0.0 } }
            recommendedFollowUp = $e.recommendedFollowUp
        }
    }

    $openCount     = @($Decisions | Where-Object { $_.status -ne 'closed' }).Count
    $closedCount   = @($Decisions | Where-Object { $_.status -eq 'closed' }).Count
    $ownedCount    = @($Decisions | Where-Object { $_.ownerConfidence -in @('high', 'medium', 'workstream-map', 'name-proximity') }).Count
    $pendingCount  = @($Decisions | Where-Object { $_.decisionRequired }).Count
    $decidedCount  = @($Decisions | Where-Object { $_.decisionStatus -eq 'Decided' }).Count
    $expiredCount  = @($Decisions | Where-Object { $_.decisionStatus -eq 'Expired' }).Count
    $lifecyclePending = @($Decisions | Where-Object { $_.decisionStatus -eq 'Pending' }).Count
    $recurringCount   = @($Decisions | Where-Object { [int]$_.recurrenceCount -ge 2 }).Count
    $inferredActionCount = 0
    foreach ($d in $Decisions) {
        foreach ($la in @($d.linkedActions)) {
            if ($la -is [System.Collections.IDictionary] -and $la.actionSource -eq 'inferred') { $inferredActionCount += 1 }
        }
    }

    $out = [ordered]@{
        generated   = $GeneratedIso
        generator   = 'scripts/generate-current-focus.ps1'
        version     = 'V3.0'
        totals      = [ordered]@{
            total              = $Decisions.Count
            open               = $openCount
            closed             = $closedCount
            authorativelyOwned = $ownedCount
            pendingDecisions   = $pendingCount
            lifecycle          = [ordered]@{
                pending = $lifecyclePending
                decided = $decidedCount
                expired = $expiredCount
            }
            outcomeQuality     = [ordered]@{
                high    = @($Decisions | Where-Object { $_.outcomeQuality -eq 'High' }).Count
                medium  = @($Decisions | Where-Object { $_.outcomeQuality -eq 'Medium' }).Count
                low     = @($Decisions | Where-Object { $_.outcomeQuality -eq 'Low' }).Count
                unknown = @($Decisions | Where-Object { $_.outcomeQuality -eq 'Unknown' }).Count
            }
            recurring          = $recurringCount
            inferredActions    = $inferredActionCount
            mergedGroups       = if ($script:MAT_MERGED_DECISIONS) { @($script:MAT_MERGED_DECISIONS).Count } else { 0 }
            mergedItems        = if ($script:MAT_MERGED_DECISIONS) { @(@($script:MAT_MERGED_DECISIONS) | ForEach-Object { @($_.mergedIds).Count } | Measure-Object -Sum).Sum } else { 0 }
        }
        decisions   = @($items)
        mergedGroups = if ($script:MAT_MERGED_DECISIONS) { @($script:MAT_MERGED_DECISIONS) } else { @() }
    }
    return $out | ConvertTo-Json -Depth 6
}

# --- V1.7 Risk Intelligence -------------------------------------------------

$script:RISK_KEYWORDS = @(
    'Risk', 'At Risk', 'Blocked', 'Dependency', 'Awaiting',
    'Escalation', 'Concern', 'Compliance Gap', 'Capacity Issue'
)

function New-RiskId {
    param([string] $Seed)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Seed.ToLowerInvariant())
        $hash  = $sha1.ComputeHash($bytes)
        $hex   = -join ($hash | ForEach-Object { $_.ToString('x2') })
        return 'R-' + $hex.Substring(0, 10)
    } finally { $sha1.Dispose() }
}

# --- V1.8 Ownership Intelligence: shared helpers ----------------------------

function Get-EndOfWeekDate {
    param([datetime] $Now)
    # Friday of the current work-week. If already Fri-Sun, roll to next Friday.
    $offset = (5 - [int]$Now.DayOfWeek + 7) % 7
    if ($offset -eq 0 -and $Now.DayOfWeek -eq [DayOfWeek]::Friday -and $Now.Hour -ge 17) { $offset = 7 }
    if ($offset -eq 0 -and $Now.DayOfWeek -in @([DayOfWeek]::Saturday, [DayOfWeek]::Sunday)) { $offset = 5 }
    return $Now.AddDays($offset).Date.ToString('yyyy-MM-dd')
}

# --- V2.0 David Brain: confidence scoring + impact extraction ---------------

function Get-EntryConfidence {
    <#
        Computes a 0-1 confidence score for a registry entry based on:
          - ownerConfidence: workstream-map (+0.5), name-proximity (+0.25), else 0
          - sourceFiles count: log-scaled up to +0.3
          - recencyDays: <=7 -> +0.2, 8-30 -> +0.1, else 0
        The result is clamped to [0, 1] and rounded to 2dp so JSON stays compact.
    #>
    param([hashtable] $Entry)
    $score = 0.0
    switch ($Entry.ownerConfidence) {
        # V4.0 taxonomy
        'high'           { $score += 0.5 }
        'medium'         { $score += 0.25 }
        'low'            { $score += 0.0 }
        # V3.x backward-compat (in case any legacy value slips through)
        'workstream-map' { $score += 0.5 }
        'name-proximity' { $score += 0.25 }
        default          { $score += 0.0 }
    }
    $srcCount = 0
    if ($Entry.sourceFiles) { $srcCount = @($Entry.sourceFiles).Count }
    if ($srcCount -gt 0) {
        $bonus = [Math]::Log10([double]($srcCount + 1)) * 0.3
        $score += [Math]::Min(0.3, $bonus)
    }
    $recency = if ($Entry.ContainsKey('recencyDays') -and $null -ne $Entry.recencyDays) { [int]$Entry.recencyDays } else { 999 }
    if ($recency -le 7)  { $score += 0.2 }
    elseif ($recency -le 30) { $score += 0.1 }
    return [Math]::Round([Math]::Min(1.0, [Math]::Max(0.0, $score)), 2)
}

function Get-ImpactFromContext {
    <#
        Extracts the `**Impact:**` line body from a context block, if present.
        Falls back to empty string.
    #>
    param([string] $Context)
    if ([string]::IsNullOrWhiteSpace($Context)) { return '' }
    $m = [regex]::Match($Context, '(?im)^\s*(?:[-*>]\s+)?\*\*Impact:\*\*\s*(.+?)\s*$')
    if (-not $m.Success) { return '' }
    $val = ($m.Groups[1].Value -replace '\s+', ' ').Trim()
    if ($val.Length -gt 240) { $val = $val.Substring(0, 237) + '...' }
    return $val
}

function Get-DeadlineFromContext {
    <#
        Extracts an explicit deadline from `**By:** / **Deadline:** / **Due:** /
        **Due by:** / **Target date:**` markers in the context block.
        Returns ISO date string on success; empty string on failure.
    #>
    param([string] $Context)
    if ([string]::IsNullOrWhiteSpace($Context)) { return '' }
    $m = [regex]::Match($Context, '(?im)^\s*(?:[-*>]\s+)?\*\*(?:By|Deadline|Due|Due\s+by|Target\s+date)[:\s]?\*\*\s*(.+?)\s*$')
    if (-not $m.Success) { return '' }
    $raw = ($m.Groups[1].Value -replace '\s+', ' ').Trim().TrimEnd('.', ',', ';')
    # Try several common date formats
    $formats = @('yyyy-MM-dd','MM/dd/yyyy','dd/MM/yyyy','MMM d yyyy','MMMM d, yyyy','yyyy/MM/dd')
    [datetime] $parsed = [datetime]::MinValue
    foreach ($fmt in $formats) {
        if ([datetime]::TryParseExact($raw, $fmt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref] $parsed)) {
            return $parsed.ToString('yyyy-MM-dd')
        }
    }
    if ([datetime]::TryParse($raw, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref] $parsed)) {
        return $parsed.ToString('yyyy-MM-dd')
    }
    return ''
}

# --- V2.5 Execution Intelligence: lifecycle + outcomes + linked actions -----

function Get-OutcomeFromContext {
    <#
        Extracts the `**Outcome:**` / `**Decision:**` / `**Resolution:**` /
        `**Result:**` line body from a context block. Empty string on miss.
    #>
    param([string] $Context)
    if ([string]::IsNullOrWhiteSpace($Context)) { return '' }
    $m = [regex]::Match($Context, '(?im)^\s*(?:[-*>]\s+)?\*\*(?:Outcome|Resolution|Result)[:\s]?\*\*\s*(.+?)\s*$')
    if (-not $m.Success) { return '' }
    $val = ($m.Groups[1].Value -replace '\s+', ' ').Trim().TrimEnd('.', ',', ';', ':')
    if ($val.Length -gt 240) { $val = $val.Substring(0, 237) + '...' }
    return $val
}

function Get-OwnerFromContext {
    <#
        V4.0 Phase 7: extracts an explicit `**Owner:**` marker from a context
        block. Returns the raw owner name (no verification against ownership map).
        Empty string on miss.

        Presence of this marker is the only signal that produces
        ownerConfidence='high' in the V4 hierarchy.
    #>
    param([string] $Context)
    if ([string]::IsNullOrWhiteSpace($Context)) { return '' }
    $m = [regex]::Match($Context, '(?im)^\s*(?:[-*>]\s+)?\*\*Owner[:\s]?\*\*\s*(.+?)\s*$')
    if (-not $m.Success) { return '' }
    $val = ($m.Groups[1].Value -replace '\s+', ' ').Trim().TrimEnd('.', ',', ';', ':')
    if ($val.Length -gt 100) { $val = $val.Substring(0, 100) }
    return $val
}

function Get-CompletionSignalFromContext {
    <#
        Scans a context block for explicit completion markers.
        Returns one of: 'completed' | 'in-progress' | ''.
    #>
    param([string] $Context)
    if ([string]::IsNullOrWhiteSpace($Context)) { return '' }
    if ($Context -match '(?im)^\s*(?:[-*>]\s+)?\*\*(?:Completed|Done|Delivered|Shipped|Signed[- ]off)[:\s]?\*\*') { return 'completed' }
    if ($Context -match '(?i)\bstatus[:\s]+(?:done|completed|closed|resolved|delivered|shipped|signed[- ]off)\b') { return 'completed' }
    if ($Context -match '(?im)^\s*(?:[-*>]\s+)?\*\*(?:In[- ]progress|WIP|Working|Underway)[:\s]?\*\*') { return 'in-progress' }
    if ($Context -match '(?i)\bstatus[:\s]+(?:in[- ]progress|wip|working|underway|active)\b') { return 'in-progress' }
    return ''
}

function Get-LinkedActionsFromContext {
    <#
        Extracts `**Action:** ...` lines from a context block, plus any inline
        owner and due-date hints (e.g. `(owner: X, due: 2026-07-20)`). Returns
        an array of small hashtables. Cap at 5 to keep JSON small.
    #>
    param([string] $Context)
    $out = [System.Collections.Generic.List[hashtable]]::new()
    if ([string]::IsNullOrWhiteSpace($Context)) { return @() }
    $lines = ($Context -replace "`r`n", "`n") -split "`n"
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $m = [regex]::Match($line, '(?i)^\s*(?:[-*>]\s+)?\*\*(?:Action|Next\s*step|Follow[- ]up|Task)[:\s]?\*\*\s*(.+?)\s*$')
        if (-not $m.Success) { continue }
        $body = $m.Groups[1].Value.Trim()
        if ($body.Length -lt 3 -or $body.Length -gt 240) { continue }
        $owner = ''
        $due   = ''
        $status = ''
        $ownerM = [regex]::Match($body, '(?i)\(?\s*owner[:\s]+([^),]+?)\s*(?:[,)]|$)')
        if ($ownerM.Success) { $owner = $ownerM.Groups[1].Value.Trim() }
        $dueM = [regex]::Match($body, '(?i)\bdue[:\s]+([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}|[A-Z][a-z]{2,8}\s+\d{1,2}(?:,\s*\d{4})?)')
        if ($dueM.Success) {
            $rawDue = $dueM.Groups[1].Value.Trim()
            [datetime] $parsed = [datetime]::MinValue
            if ([datetime]::TryParse($rawDue, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref] $parsed)) {
                $due = $parsed.ToString('yyyy-MM-dd')
            } else { $due = $rawDue }
        }
        if     ($body -match '(?i)\b(done|completed|delivered|shipped|signed[- ]off|closed|resolved)\b') { $status = 'completed' }
        elseif ($body -match '(?i)\b(in[- ]progress|wip|working|underway|started)\b')                    { $status = 'in-progress' }
        elseif ($body -match '(?i)\b(blocked|waiting|stalled)\b')                                        { $status = 'blocked' }
        else                                                                                             { $status = 'pending' }
        # Strip trailing metadata parens for cleaner text
        $text = ($body -replace '\s*\((?:owner|due)[:\s].*?\)\s*$', '').Trim()
        if ($text.Length -gt 200) { $text = $text.Substring(0, 197) + '...' }
        $out.Add([ordered]@{
            text         = $text
            owner        = $owner
            dueBy        = $due
            status       = $status
            actionSource = 'marker'
        })
        if ($out.Count -ge 5) { break }
    }
    return @($out)
}

# --- V3.0 Adaptive Intelligence: action inference + outcome quality + recurrence

function Get-InferredActions {
    <#
        Fires when a decision has no linked actions captured from **Action:** markers.
        Synthesizes 1-3 sensible follow-ups based on the entry's owner, escalation
        path, structured recommendation, deadline, and aging. Every inferred item
        is tagged with actionSource='inferred' so consumers can distinguish
        marker-derived actions from synthesized ones.
    #>
    param([hashtable] $Entry, [datetime] $Now)

    $out = [System.Collections.Generic.List[hashtable]]::new()
    $owner  = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }
    $wsText = if ($Entry.workstream) { [string]$Entry.workstream } else { '(no workstream)' }
    $rec    = $Entry.recommendedFollowUp
    $priority = if ($rec -is [System.Collections.IDictionary] -and $rec.priority) { [int]$rec.priority } else { 4 }
    $verb     = if ($rec -is [System.Collections.IDictionary] -and $rec.verb)     { [string]$rec.verb } else { 'Track' }
    $due      = if ($rec -is [System.Collections.IDictionary] -and $rec.dueBy)    { [string]$rec.dueBy } else { $Now.AddDays(7).ToString('yyyy-MM-dd') }

    # Rule 1: escalation path
    if ($priority -le 1) {
        $escTarget = 'the workstream owner'
        if ($Entry.escalationPath -and @($Entry.escalationPath).Count -gt 0) {
            $escTarget = @($Entry.escalationPath)[0]
        }
        $out.Add([ordered]@{
            text         = "Escalate to ${escTarget}: pending 14+ days on $wsText"
            owner        = $owner
            dueBy        = $due
            status       = 'pending'
            actionSource = 'inferred'
        })
    }

    # Rule 2: aging (7-13d) or P2 - confirmation
    if (($priority -eq 2) -or ([int]$Entry.decisionAgeDays -ge 7 -and [int]$Entry.decisionAgeDays -lt 14)) {
        $out.Add([ordered]@{
            text         = "Confirm status with $owner and record outcome"
            owner        = $owner
            dueBy        = $due
            status       = 'pending'
            actionSource = 'inferred'
        })
    }

    # Rule 3: aged 30+ days with no outcome - archive or resurface
    if ([int]$Entry.decisionAgeDays -ge 30 -and -not $Entry.decisionOutcome) {
        $out.Add([ordered]@{
            text         = "Archive $($Entry.decisionId) or resurface with fresh rationale"
            owner        = $owner
            dueBy        = $Now.AddDays(3).ToString('yyyy-MM-dd')
            status       = 'pending'
            actionSource = 'inferred'
        })
    }

    # Rule 4: fresh decisions - monitor
    if ($out.Count -eq 0 -and $verb -eq 'Track') {
        $out.Add([ordered]@{
            text         = "Monitor $wsText for follow-through - re-check in 7 days"
            owner        = $owner
            dueBy        = $Now.AddDays(7).ToString('yyyy-MM-dd')
            status       = 'pending'
            actionSource = 'inferred'
        })
    }

    return @($out)
}

function Get-NormalizedTitle {
    <#
        Normalises a decision title for recurrence detection: strips leading
        `D### -` numbering, casts to lower, collapses whitespace, drops trailing
        punctuation. Returns empty string on empty input.
    #>
    param([string] $Title)
    if ([string]::IsNullOrWhiteSpace($Title)) { return '' }
    $t = $Title -replace '^\s*D\d+\s*[\u2014\-:]\s*', ''   # strip D001 -
    $t = $t -replace '^\s*(?:Agreed|Deferred|Approved|Rejected|Locked|Reversed|Superseded|Confirmed)\s*:\s*', ''
    $t = ($t.ToLowerInvariant() -replace '\s+', ' ').Trim().TrimEnd('.', ',', ';', ':')
    return $t
}

function Get-OutcomeQuality {
    <#
        Rates the quality/confidence of a decision's recorded outcome.
          - High    : Decided AND explicit outcome AND (completed action OR completion signal)
          - Medium  : Decided AND explicit outcome (no completed action yet)
          - Low     : Decided but outcome is only the V2.5 fallback (`**Decision:** verb`)
                       OR status closed with no outcome text
          - Unknown : not Decided
    #>
    param([hashtable] $Entry)

    if ($Entry.decisionStatus -ne 'Decided') { return 'Unknown' }

    $hasOutcome = -not [string]::IsNullOrWhiteSpace([string]$Entry.decisionOutcome)
    $completedAction = $false
    if ($Entry.linkedActions) {
        foreach ($a in @($Entry.linkedActions)) {
            if ($a -is [System.Collections.IDictionary] -and $a.status -eq 'completed') { $completedAction = $true; break }
        }
    }
    $completionSignal = if ($Entry.ContainsKey('completionSignal')) { [string]$Entry.completionSignal } else { '' }

    # Fallback outcomes are single-token resolution verbs (Approved/Deferred/etc).
    # A richer outcome contains 3+ words or a comma/period.
    $outcomeText = [string]$Entry.decisionOutcome
    $isFallback  = $false
    if ($hasOutcome) {
        $wordCount = ($outcomeText -split '\s+').Count
        $isFallback = ($wordCount -le 2 -and $outcomeText -match '^(?i)(Approved|Deferred|Rejected|Superseded|Reversed|Deprecated|Locked|Confirmed)\b')
    }

    if ($hasOutcome -and -not $isFallback -and ($completedAction -or $completionSignal -eq 'completed')) { return 'High' }
    if ($hasOutcome -and -not $isFallback) { return 'Medium' }
    if ($hasOutcome -and $isFallback) { return 'Low' }
    return 'Low'
}

function Get-DecisionLifecycleStatus {
    <#
        Computes the V2.5 lifecycle bucket for a decision entry.
        Buckets: 'Decided' | 'Expired' | 'Pending'.

        - Decided : source status is 'closed' OR any linked action is 'completed'
                    OR a completion signal was captured OR an explicit outcome is present.
        - Expired : still open AND decisionDeadline is in the past by 3+ days
                    OR decisionAgeDays >= 30 and no outcome + no completed action.
        - Pending : otherwise (still awaiting a decision).
    #>
    param([hashtable] $Entry, [datetime] $Now)

    $hasOutcome = -not [string]::IsNullOrWhiteSpace([string]$Entry.decisionOutcome)
    $completionSignal = if ($Entry.ContainsKey('completionSignal')) { [string]$Entry.completionSignal } else { '' }
    $completedAction = $false
    if ($Entry.ContainsKey('linkedActions') -and $Entry.linkedActions) {
        foreach ($a in @($Entry.linkedActions)) {
            if ($a -is [System.Collections.IDictionary] -and $a.status -eq 'completed') { $completedAction = $true; break }
        }
    }

    if ($Entry.status -eq 'closed' -or $completionSignal -eq 'completed' -or $completedAction -or $hasOutcome) {
        return 'Decided'
    }

    $deadline = [string]$Entry.decisionDeadline
    if ($deadline) {
        [datetime] $parsedDl = [datetime]::MinValue
        if ([datetime]::TryParseExact($deadline, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref] $parsedDl)) {
            if (($Now - $parsedDl).TotalDays -ge 3) { return 'Expired' }
        }
    }
    if ([int]$Entry.decisionAgeDays -ge 30) { return 'Expired' }
    return 'Pending'
}

# --- V2.5 Escalation prediction --------------------------------------------

function Get-EscalationRisk {
    <#
        Predicts days until an entry needs escalation (0 = escalate today).
        Returns $null when not applicable (closed / decided with outcome).

        Decisions:
          - Decided or closed -> $null
          - decisionAgeDays >= 14 -> 0
          - deadline present -> max(0, daysUntilDeadline - 3)
          - else -> max(0, 14 - decisionAgeDays)

        Risks:
          - closed -> $null
          - High severity -> 0
          - agingDays >= 14 -> 0
          - trend 'increasing' -> max(1, floor((14 - agingDays) / 2))
          - else -> max(0, 14 - agingDays)
    #>
    param(
        [ValidateSet('decision','risk')] [string] $Kind,
        [hashtable] $Entry,
        [datetime]  $Now
    )
    if ($Kind -eq 'decision') {
        if ($Entry.status -eq 'closed') { return $null }
        $lifecycle = if ($Entry.ContainsKey('decisionStatus')) { [string]$Entry.decisionStatus } else { '' }
        if ($lifecycle -eq 'Decided') { return $null }
        $age = if ($Entry.ContainsKey('decisionAgeDays')) { [int]$Entry.decisionAgeDays } else { 0 }
        if ($age -ge 14) { return 0 }
        $deadline = [string]$Entry.decisionDeadline
        if ($deadline) {
            [datetime] $parsedDl = [datetime]::MinValue
            if ([datetime]::TryParseExact($deadline, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref] $parsedDl)) {
                $delta = [int][Math]::Floor(($parsedDl - $Now).TotalDays) - 3
                return [int][Math]::Max(0, $delta)
            }
        }
        return [int][Math]::Max(0, 14 - $age)
    }
    else {
        if ($Entry.status -eq 'closed') { return $null }
        if ($Entry.severity -eq 'High') { return 0 }
        $age = if ($Entry.ContainsKey('agingDays')) { [int]$Entry.agingDays } else { 0 }
        if ($age -ge 14) { return 0 }
        if ($Entry.trend -eq 'increasing') {
            return [int][Math]::Max(1, [Math]::Floor((14 - $age) / 2.0))
        }
        return [int][Math]::Max(0, 14 - $age)
    }
}

function Get-StructuredRiskAction {
    <#
        Converts the ad-hoc `recommendedAction` string into a structured object
        with priority (1-5), verb, subject, targetOwner, dueBy (ISO date), and
        a short rationale.

        V4.0 Phase 2: adds `actionClass` (DO | DECIDE | FOLLOW_UP | INVESTIGATE | BLOCKED)
        and imperative `nextAction` sentence. Legacy `verb` retained for back-compat.

        Classification rules:
          - Unassigned owner            -> DECIDE (assign owner first)
          - status=closed               -> DECIDE (archive-or-reopen)
          - severity=High, David-owned  -> DO (David escalates today)
          - severity=High, other owner  -> FOLLOW_UP (contact owner today)
          - trend=increasing & age>=7   -> INVESTIGATE (understand root cause)
          - age >= 14                   -> FOLLOW_UP (owner unresponsive)
          - age >= 7                    -> FOLLOW_UP (review mitigation)
          - fresh                       -> FOLLOW_UP (monitor)
    #>
    param([hashtable] $Entry, [datetime] $Now)

    $rawTitle = if ($Entry.title) { [string]$Entry.title } else { '' }
    $subject  = if ($rawTitle.Length -gt 100) { $rawTitle.Substring(0, 97) + '...' } else { $rawTitle }
    $owner    = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }
    $ownerIsDavid = $owner -match '(?i)^\s*david(\s+klan)?\s*$'
    $isUnassigned = $owner -match '(?i)^\s*unassigned\s*$'
    $escTarget = if ($Entry.escalationPath -and @($Entry.escalationPath).Count -gt 0) {
        [string](@($Entry.escalationPath)[0])
    } else { 'the workstream lead' }
    $wsLabel = if ($Entry.workstream) { [string]$Entry.workstream } else { 'this risk' }
    $ageDays = if ($Entry.agingDays) { [int]$Entry.agingDays } else { 0 }

    if ($isUnassigned) {
        return [ordered]@{
            priority     = 2
            verb         = 'Investigate'
            actionClass  = 'DECIDE'
            nextAction   = "Assign an owner for $wsLabel risk before it can be actioned"
            subject      = $subject
            targetOwner  = 'Unassigned'
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Owner not yet confirmed; ownership must precede mitigation.'
        }
    }

    if ($Entry.status -eq 'closed') {
        return [ordered]@{
            priority     = 5
            verb         = 'Archive'
            actionClass  = 'DECIDE'
            nextAction   = "Decide whether to archive $($Entry.riskId) or reopen"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.AddDays(30).ToString('yyyy-MM-dd')
            rationale    = 'Risk marked closed; archive after next reporting cycle.'
        }
    }
    if ($Entry.severity -eq 'High') {
        if ($ownerIsDavid) {
            return [ordered]@{
                priority     = 1
                verb         = 'Escalate'
                actionClass  = 'DO'
                nextAction   = "Send escalation on $wsLabel to $escTarget today"
                subject      = $subject
                targetOwner  = $owner
                dueBy        = $Now.ToString('yyyy-MM-dd')
                rationale    = 'High severity - David to escalate today.'
            }
        }
        return [ordered]@{
            priority     = 1
            verb         = 'Escalate'
            actionClass  = 'FOLLOW_UP'
            nextAction   = "Contact $owner today about high-severity $wsLabel risk"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.ToString('yyyy-MM-dd')
            rationale    = 'High severity - direct outreach to owner today.'
        }
    }
    if ($Entry.trend -eq 'increasing' -and $ageDays -ge 7) {
        return [ordered]@{
            priority     = 2
            verb         = 'Investigate'
            actionClass  = 'INVESTIGATE'
            nextAction   = "Investigate why $wsLabel risk trend is increasing (aged $ageDays days)"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Rising signal aged 7+ days - understand root cause this week.'
        }
    }
    if ($ageDays -ge 14) {
        return [ordered]@{
            priority     = 2
            verb         = 'Escalate'
            actionClass  = 'FOLLOW_UP'
            nextAction   = "Confirm with $owner why $wsLabel remains unresolved after $ageDays days"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = "Unresolved $ageDays days - contact owner this week."
        }
    }
    if ($ageDays -ge 7) {
        return [ordered]@{
            priority     = 3
            verb         = 'Review'
            actionClass  = 'FOLLOW_UP'
            nextAction   = "Review mitigation plan for $wsLabel with $owner this week"
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Aging 7+ days - review mitigation plan this week.'
        }
    }
    return [ordered]@{
        priority     = 4
        verb         = 'Monitor'
        actionClass  = 'FOLLOW_UP'
        nextAction   = "Monitor $wsLabel - re-check in 7 days"
        subject      = $subject
        targetOwner  = $owner
        dueBy        = $Now.AddDays(7).ToString('yyyy-MM-dd')
        rationale    = 'Fresh signal - continue to observe.'
    }
}

function Get-RiskRegister {
    <#
        Scans context-eligible file records for risk-signal phrases and returns
        deduplicated risk entries with V1.8 fields:
          - firstSeenDate / lastSeenDate / agingDays / recencyDays
          - owner + ownerConfidence (workstream-map | name-proximity | unknown)
          - escalationPath / stakeholders
          - recommendedAction as a structured object
    #>
    param(
        [System.Collections.Generic.List[hashtable]] $Records,
        [object[]] $Workstreams,
        [hashtable] $Model,
        [hashtable] $OwnershipMap = @{}
    )

    $now = Get-Date

    # Alias -> workstream (longest-first for greedy match); also track workstream.id
    $aliasMap = @{}     # lowercased alias -> workstream name
    $nameToId = @{}     # workstream name -> workstream id (for ownership-map lookup)
    foreach ($ws in $Workstreams) {
        $aliasMap[$ws.name.ToLowerInvariant()] = $ws.name
        $aliasMap[$ws.id.ToLowerInvariant()]   = $ws.name
        foreach ($a in $ws.aliases) { $aliasMap[$a.ToLowerInvariant()] = $ws.name }
        $nameToId[$ws.name] = $ws.id
    }
    $aliasKeys = @($aliasMap.Keys | Sort-Object { -($_.Length) })

    $stakeKeys = @($Model.stakeholder_weights.Keys)

    # Line-level risk phrase capture. Two patterns:
    #  A) Structured: `- **Risk:** description`
    #  B) Narrative:  `- Risk of losing access to X`  or  `- Blocked by Y`
    # We iterate lines and try A first, then B.
    $keywordAlt   = ($script:RISK_KEYWORDS | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $strongRegex  = '(?im)^\s*(?:[-*>]\s+)?(?:\*\*)?(' + $keywordAlt + ')(?:\*\*)?\s*[:\-]\s+(.+?)\s*$'
    $narrativeRegex = '(?im)^\s*[-*>]\s+(?:\*\*)?(.{0,240}?\b(' + $keywordAlt + ')\b.{0,240}?)\s*$'
    # False-positive filter: skip lines that look like YAML/config or scoring rows
    # (e.g. `escalation: 10`, `- risk_logged: 33`), or labeled metadata lines
    # like `- **Focus:** …` / `- **Tags:** #x #y` that mention risk keywords in
    # their body but aren't themselves risks.
    $noiseRegex   = '(?i)(?:^\s*#|_mention|_weight|risk_logged|escalation_signals?|signal_counts|meeting_mention|patterns\s*\{)'
    $labelNoiseRegex = '(?im)^\s*[-*>]?\s*\*\*(?:Focus|Description|Work\s*Types?|Tags|Purpose|Request|Note|Priority|Scope|Impact|Owner|Contacts?|Related|Members|Team|Sub[- ]?Teams?|Systems?|Objectives?|Aliases?|Dependencies|Status|Summary|Decision|Date|Assignees?|Roles?|Links?|Notes?)\s*:?\*\*'

    $risks = @{}

    foreach ($rec in $Records) {
        if (-not $rec.IncludeForContext) { continue }
        try {
            $content = Get-Content -LiteralPath $rec.FullPath -Raw -Encoding UTF8 -ErrorAction Stop
        } catch { continue }
        if ([string]::IsNullOrWhiteSpace($content)) { continue }

        $normalised     = $content -replace "`r`n", "`n"
        $lines          = $normalised -split "`n"
        $currentHeading = ''
        $headingRegex   = '^##\s+(R\d+\s*[\u2014\-]\s*.+?)\s*$'

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $h = [regex]::Match($line, $headingRegex)
            if ($h.Success) {
                $currentHeading = ($h.Groups[1].Value -replace '\s+', ' ').Trim()
                continue
            }

            if ($line -match $noiseRegex) { continue }
            if ($line -match $labelNoiseRegex) { continue }

            $m = [regex]::Match($line, $strongRegex)
            $keyword = $null
            $body    = $null
            if ($m.Success) {
                $keyword = $m.Groups[1].Value
                $body    = ($m.Groups[2].Value.Trim() -replace '\s+', ' ')
            } else {
                $mm = [regex]::Match($line, $narrativeRegex)
                if (-not $mm.Success) { continue }
                $keyword = $mm.Groups[2].Value
                $body    = ($mm.Groups[1].Value.Trim() -replace '\s+', ' ')
            }
            $body    = $body -replace '^\s*\*+\s*', ''
            $body    = $body -replace '\s*\*+\s*$', ''
            $body    = $body.Trim().TrimEnd('.', ',', ';', ':')
            if ($body.Length -lt 5 -or $body.Length -gt 300) { continue }

            $ctxStart = [Math]::Max(0, $i - 3)
            $ctxEnd   = [Math]::Min($lines.Count - 1, $i + 6)
            $context  = ($lines[$ctxStart..$ctxEnd] -join "`n")
            $lcContext = $context.ToLowerInvariant()

            $titleRaw = if ($currentHeading) { $currentHeading } else { $body }
            $title    = if ($titleRaw.Length -gt 140) { $titleRaw.Substring(0, 137) + '...' } else { $titleRaw }

            # V4.0 Sprint 19: normalize + validate risk title BEFORE record creation.
            $normalizedTitle = Normalize-CorpusTitle -Raw $title
            $titleCheck = Test-CorpusTitleValid -Title $normalizedTitle -StakeholderNames $stakeKeys
            if (-not $titleCheck.ok) {
                Add-TitleDropRecord -Kind 'risk' -RawTitle $title -NormalizedTitle $normalizedTitle -Reason $titleCheck.reason -SourcePath $rec.RelPath
                continue
            }
            $title = $normalizedTitle

            # V2.0: extract business impact from context if present.
            $impact = Get-ImpactFromContext -Context $context
            # V4.0 Phase 7: explicit ownership marker
            $explicitOwner = Get-OwnerFromContext -Context $context

            $workstream = ''
            foreach ($k in $aliasKeys) {
                if ($lcContext -match ('\b' + [regex]::Escape($k) + '\b')) {
                    $workstream = $aliasMap[$k]; break
                }
            }

            $owner = ''
            foreach ($n in $stakeKeys) {
                if ($context -match ('(?i)\b' + [regex]::Escape($n) + '\b')) { $owner = $n; break }
            }

            # Severity heuristic
            $severity = 'Medium'
            if ($lcContext -match '\b(critical|blocker|urgent|showstopper|severe|compliance gap|capacity issue|escalation|high[- ]severity|high[- ]impact|high[- ]priority)\b') {
                $severity = 'High'
            } elseif ($lcContext -match '\b(minor|low[- ]severity|low[- ]impact|low priority)\b') {
                $severity = 'Low'
            }

            # Status heuristic
            $status = 'open'
            if ($lcContext -match '\b(resolved|closed|mitigated|remediated|no longer[- ]a[- ]risk|no risk)\b') { $status = 'closed' }

            $seed = ($workstream + '|' + $title + '|' + $rec.RelPath)
            $riskId = New-RiskId -Seed $seed

            if (-not $risks.ContainsKey($riskId)) {
                $risks[$riskId] = @{
                    riskId              = $riskId
                    title               = $title
                    workstream          = $workstream
                    owner               = $owner
                    ownerConfidence     = 'unknown'
                    suggestedOwner      = ''
                    _explicitOwner      = $explicitOwner
                    escalationPath      = [System.Collections.Generic.List[string]]::new()
                    stakeholders        = [System.Collections.Generic.List[string]]::new()
                    severity            = $severity
                    status              = $status
                    trend               = 'stable'
                    sourceFiles         = [System.Collections.Generic.List[string]]::new()
                    agingDays           = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
                    recencyDays         = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
                    impact              = $impact
                    riskConfidence      = 0.0
                    recommendedAction   = $null
                    dateDetected        = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                    firstSeenDate       = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                    lastSeenDate        = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                    keyword             = $keyword
                    _detectedOn         = $rec.LastWriteTime
                    _lastSeenOn         = $rec.LastWriteTime
                    _currentCount       = 0
                    _previousCount      = 0
                }
            }

            $entry = $risks[$riskId]
            if (-not $entry.sourceFiles.Contains($rec.RelPath)) { $entry.sourceFiles.Add($rec.RelPath) }
            if (-not $entry.owner      -and $owner)      { $entry.owner = $owner }
            if (-not $entry.workstream -and $workstream) { $entry.workstream = $workstream }
            if (-not $entry.impact     -and $impact)     { $entry.impact = $impact }
            # V4.0 Phase 7: prefer explicit owner marker if found in any sighting
            if (-not $entry._explicitOwner -and $explicitOwner) { $entry._explicitOwner = $explicitOwner }

            # Severity may only escalate up
            if ($severity -eq 'High') { $entry.severity = 'High' }
            elseif ($severity -eq 'Medium' -and $entry.severity -eq 'Low') { $entry.severity = 'Medium' }

            if ($status -eq 'closed') { $entry.status = 'closed' }

            # firstSeen = earliest, lastSeen = latest
            if ($rec.LastWriteTime -lt $entry._detectedOn) {
                $entry._detectedOn   = $rec.LastWriteTime
                $entry.dateDetected  = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                $entry.firstSeenDate = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                $entry.agingDays     = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
            }
            if ($rec.LastWriteTime -gt $entry._lastSeenOn) {
                $entry._lastSeenOn  = $rec.LastWriteTime
                $entry.lastSeenDate = $rec.LastWriteTime.ToString('yyyy-MM-dd')
                $entry.recencyDays  = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
            }

            switch ($rec.Window) {
                'current'  { $entry._currentCount  += 1 }
                'previous' { $entry._previousCount += 1 }
            }
        }
    }

    foreach ($e in $risks.Values) {
        $cur  = $e._currentCount
        $prev = $e._previousCount
        if     ($cur -gt $prev -and $cur -gt 0) { $e.trend = 'increasing' }
        elseif ($cur -lt $prev -and $prev -gt 0) { $e.trend = 'decreasing' }
        else                                     { $e.trend = 'stable' }

        # V4.0 Phase 7 ownership hierarchy (see decision registry for full comment)
        $mapEntry = $null
        if ($e.workstream -and $nameToId.ContainsKey($e.workstream)) {
            $wsId = $nameToId[$e.workstream]
            if ($OwnershipMap.ContainsKey($wsId)) { $mapEntry = $OwnershipMap[$wsId] }
        }
        if ($mapEntry) {
            foreach ($n in $mapEntry.escalationPath) {
                if (-not $e.escalationPath.Contains($n)) { $e.escalationPath.Add($n) }
            }
            foreach ($n in $mapEntry.stakeholders) {
                if (-not $e.stakeholders.Contains($n)) { $e.stakeholders.Add($n) }
            }
        }
        if ($e._explicitOwner) {
            $e.owner = $e._explicitOwner
            $e.suggestedOwner = ''
            $e.ownerConfidence = 'high'
        } elseif ($e.owner) {
            $e.suggestedOwner = ''
            $e.ownerConfidence = 'medium'
        } elseif ($mapEntry -and $mapEntry.owner) {
            $e.owner = 'Unassigned'
            $e.suggestedOwner = $mapEntry.owner
            $e.ownerConfidence = 'low'
        } else {
            $e.owner = 'Unassigned'
            $e.suggestedOwner = ''
            $e.ownerConfidence = 'low'
        }

        # V1.8 structured action (replaces canned string)
        $e.recommendedAction = Get-StructuredRiskAction -Entry $e -Now $now

        # V2.0 David Brain: confidence score
        $e.riskConfidence = Get-EntryConfidence -Entry $e

        # V2.5 Execution Intelligence: escalation prediction
        $e.timeToEscalationRisk = Get-EscalationRisk -Kind 'risk' -Entry $e -Now $now

        # V4.0 Phase 3: staleness flag
        $e.stale = Get-StaleFlag -Entry $e -Kind 'risk'
    }

    $severityRank = @{ 'High' = 0; 'Medium' = 1; 'Low' = 2 }
    # V4.0 Phase 6: fuzzy-dedup groups of similar risks within the same
    # workstream. Winner (freshest lastSeenDate) absorbs source files + IDs.
    $dedupResult = Merge-DuplicateEntries -Entries @($risks.Values) -Kind 'risk'
    $script:MAT_MERGED_RISKS = @($dedupResult.mergedGroups)
    $deduped = @($dedupResult.items)
    return @($deduped | Sort-Object `
        @{ Expression = { if ($_.status -eq 'closed') { 1 } else { 0 } }; Ascending = $true },
        @{ Expression = { $severityRank[$_.severity] };                    Ascending = $true },
        @{ Expression = { $_.agingDays };                                  Descending = $true })
}

function Build-RiskRegisterMarkdown {
    param(
        [object[]] $Risks,
        [string]   $NowStamp
    )

    $Risks = @($Risks | Where-Object { $null -ne $_ })

    $open       = @($Risks | Where-Object { $_.status -ne 'closed' })
    $closed     = @($Risks | Where-Object { $_.status -eq 'closed' })
    $high       = @($open | Where-Object { $_.severity -eq 'High' })
    $rising     = @($open | Where-Object { $_.trend    -eq 'increasing' })
    $escalated  = @($open | Where-Object { $_.agingDays -ge 14 })
    $recent     = @($closed | Sort-Object { $_._detectedOn } -Descending | Select-Object -First 5)

    function _RenderRisk($e) {
        $ownerText = if ($e.owner)      { $e.owner }      else { '-' }
        $wsText    = if ($e.workstream) { $e.workstream } else { '-' }
        $sources   = if ($e.sourceFiles.Count -gt 0) {
            ($e.sourceFiles | Select-Object -First 5 | ForEach-Object { "  - ``$_``" }) -join "`n"
        } else { '  - (no source captured)' }

        $escalationText = if ($e.escalationPath -and $e.escalationPath.Count -gt 0) {
            ($e.escalationPath -join ' -> ')
        } else { '-' }
        $stakeText = if ($e.stakeholders -and $e.stakeholders.Count -gt 0) {
            ($e.stakeholders -join ', ')
        } else { '-' }

        # Structured action is a hashtable now
        $act = $e.recommendedAction
        $actionText = if ($act -is [System.Collections.IDictionary]) {
            $classBit = if ($act.actionClass) { "[$($act.actionClass)] " } else { '' }
            $nextBit  = if ($act.nextAction) { $act.nextAction } else { "$($act.verb): $($act.subject)" }
            "${classBit}P$($act.priority) - $nextBit (owner: $($act.targetOwner), by $($act.dueBy))"
        } else {
            "$act"
        }
        $escText = if ($null -ne $e.timeToEscalationRisk) { "$($e.timeToEscalationRisk) day(s)" } else { 'n/a' }

        return @"
### $($e.riskId) - $($e.title)

- Workstream: **$wsText**
- Owner: **$ownerText** _(confidence: $($e.ownerConfidence))_
- Escalation Path: $escalationText
- Stakeholders: $stakeText
- Severity: **$($e.severity)**
- Status: **$($e.status)**
- Trend: **$($e.trend)**
- Time to escalation: **$escText**
- First seen: **$($e.firstSeenDate)** ($($e.agingDays) days ago)
- Last seen: **$($e.lastSeenDate)** ($($e.recencyDays) days ago)
- Recommended action: $actionText
- Sources:
$sources

"@
    }

    $highBlock   = if ($high.Count      -gt 0) { ($high      | ForEach-Object { _RenderRisk $_ }) -join '' } else { "_No high-severity open risks._`n" }
    $risingBlock = if ($rising.Count    -gt 0) { ($rising    | ForEach-Object { _RenderRisk $_ }) -join '' } else { "_No rising risks in the current window._`n" }
    $oldBlock    = if ($escalated.Count -gt 0) { ($escalated | ForEach-Object { _RenderRisk $_ }) -join '' } else { "_No risks past the 14-day escalation threshold._`n" }
    $openBlock   = if ($open.Count      -gt 0) { ($open      | ForEach-Object { _RenderRisk $_ }) -join '' } else { "_No open risks detected._`n" }
    $closedBlock = if ($recent.Count    -gt 0) { ($recent    | ForEach-Object { _RenderRisk $_ }) -join '' } else { "_No recently closed risks._`n" }

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Risk Register

Generated: $NowStamp

Total: **$($Risks.Count)** risks ($($open.Count) open / $($closed.Count) closed / $($high.Count) high-severity / $($rising.Count) rising)

## Highest Severity Open Risks

$highBlock

## Fastest Growing Risks (increasing trend)

$risingBlock

## Oldest / Escalated Risks (14+ days)

$oldBlock

## All Open Risks

$openBlock

## Recently Closed Risks

$closedBlock

## Notes

Risks are auto-extracted from context-eligible files (see 00-context/source-weights.yaml).
Severity is heuristic (High: critical/blocker/urgent/escalation/compliance gap; Low: minor/low priority; else Medium).
Trend compares current vs previous 14-day windows; recommended action layers severity, trend, and aging.
"@
}

function Build-RiskRegisterJson {
    param(
        [object[]] $Risks,
        [string]   $GeneratedIso
    )

    $Risks = @($Risks | Where-Object { $null -ne $_ })

    $items = foreach ($e in $Risks) {
        [ordered]@{
            riskId            = $e.riskId
            title             = $e.title
            workstream        = $e.workstream
            owner             = $e.owner
            ownerConfidence   = $e.ownerConfidence
            suggestedOwner    = if ($e.ContainsKey('suggestedOwner')) { [string]$e.suggestedOwner } else { '' }
            escalationPath    = @($e.escalationPath)
            stakeholders      = @($e.stakeholders)
            severity          = $e.severity
            status            = $e.status
            trend             = $e.trend
            agingDays         = $e.agingDays
            recencyDays       = $e.recencyDays
            firstSeenDate     = $e.firstSeenDate
            lastSeenDate      = $e.lastSeenDate
            dateDetected      = $e.dateDetected
            sourceFiles       = @($e.sourceFiles)
            impact            = $e.impact
            riskConfidence    = $e.riskConfidence
            timeToEscalationRisk = $e.timeToEscalationRisk
            unifiedConfidence = if ($e.ContainsKey('unifiedConfidence')) { [double]$e.unifiedConfidence } else { 0.0 }
            mentionCount      = if ($e.ContainsKey('mentionCount'))     { [int]$e.mentionCount }        else { @($e.sourceFiles).Count }
            mergedFrom        = if ($e.ContainsKey('mergedFrom'))       { @($e.mergedFrom) }            else { @() }
            stale             = if ($e.ContainsKey('stale')) { [bool]$e.stale } else { $false }
            delta             = if ($e.ContainsKey('delta') -and $e.delta) { $e.delta } else { [ordered]@{ daysSinceLastTouched = 0; updatedSinceYesterday = $true; changeSummary = 'first appearance' } }
            contextSummary    = if ($e.ContainsKey('contextSummary'))  { [string]$e.contextSummary } else { '' }
            contextMetadata   = if ($e.ContainsKey('contextMetadata') -and $e.contextMetadata) { $e.contextMetadata } else { [ordered]@{ lastMention = ''; lastActivity = ''; actors = @(); primarySource = '' } }
            whyItMatters           = if ($e.ContainsKey('whyItMatters'))           { [string]$e.whyItMatters }           else { '' }
            whyItMattersConfidence = if ($e.ContainsKey('whyItMattersConfidence')) { [double]$e.whyItMattersConfidence } else { 0.0 }
            whyItMattersSource     = if ($e.ContainsKey('whyItMattersSource'))     { [string]$e.whyItMattersSource }     else { 'none' }
            matryoshkaStatus       = if ($e.ContainsKey('matryoshkaStatus'))       { [string]$e.matryoshkaStatus }       else { '' }
            matryoshkaStatusReason = if ($e.ContainsKey('matryoshkaStatusReason')) { [string]$e.matryoshkaStatusReason } else { '' }
            focusSignals           = if ($e.ContainsKey('focusSignals') -and $e.focusSignals) { $e.focusSignals } else { [ordered]@{ engaged = $false; attentionRequired = $false; awaitingOthers = $false; reasons = [ordered]@{ engaged=''; attentionRequired=''; awaitingOthers='' } } }
            priorityScore          = if ($e.ContainsKey('priorityScore'))   { [int]$e.priorityScore }   else { 0 }
            priorityReason         = if ($e.ContainsKey('priorityReason'))  { [string]$e.priorityReason } else { '' }
            priorityReasonBullets  = if ($e.ContainsKey('priorityReasonBullets') -and $e.priorityReasonBullets) { @($e.priorityReasonBullets) } else { @() }
            priorityReasonDebug    = if ($e.ContainsKey('priorityReasonDebug'))    { [string]$e.priorityReasonDebug }    else { '' }
            priorityFactors        = if ($e.ContainsKey('priorityFactors') -and $e.priorityFactors) { $e.priorityFactors } else { [ordered]@{ impact=0.0; ownership=0.0; deadline=0.0; status=0.0; engagement=0.0 } }
            recommendedAction = $e.recommendedAction
        }
    }

    $openCount   = @($Risks | Where-Object { $_.status -ne 'closed' }).Count
    $closedCount = @($Risks | Where-Object { $_.status -eq 'closed' }).Count
    $highCount   = @($Risks | Where-Object { $_.status -ne 'closed' -and $_.severity -eq 'High' }).Count
    $risingCount = @($Risks | Where-Object { $_.status -ne 'closed' -and $_.trend    -eq 'increasing' }).Count
    $ownedCount  = @($Risks | Where-Object { $_.ownerConfidence -in @('high', 'medium', 'workstream-map', 'name-proximity') }).Count
    $imminentCount = @($Risks | Where-Object { $_.status -ne 'closed' -and $null -ne $_.timeToEscalationRisk -and [int]$_.timeToEscalationRisk -le 3 }).Count

    $out = [ordered]@{
        generated   = $GeneratedIso
        generator   = 'scripts/generate-current-focus.ps1'
        version     = 'V3.0'
        totals      = [ordered]@{
            total          = $Risks.Count
            open           = $openCount
            closed         = $closedCount
            high           = $highCount
            rising         = $risingCount
            authorativelyOwned = $ownedCount
            imminentEscalation = $imminentCount
            mergedGroups   = if ($script:MAT_MERGED_RISKS) { @($script:MAT_MERGED_RISKS).Count } else { 0 }
            mergedItems    = if ($script:MAT_MERGED_RISKS) { @(@($script:MAT_MERGED_RISKS) | ForEach-Object { @($_.mergedIds).Count } | Measure-Object -Sum).Sum } else { 0 }
        }
        risks       = @($items)
        mergedGroups = if ($script:MAT_MERGED_RISKS) { @($script:MAT_MERGED_RISKS) } else { @() }
    }
    return $out | ConvertTo-Json -Depth 6
}

# --- V2.0 David Brain: workstream health + priority inbox -------------------

function Get-WorkstreamHealth {
    <#
        Computes a Red/Amber/Green health status per workstream by combining
        attention scoring + open risks + open decisions + trend direction.
        Returns { workstreamId -> @{ status, color, reason } }.

        Red:   attention >= 70 AND (any High open risk OR any 14+d open decision OR trend=decreasing)
        Amber: attention in 40..70 OR (P1 with any open Medium+ risk)
        Green: everything else
    #>
    param(
        [hashtable]                                       $FinalResults,
        [object[]]                                        $Decisions,
        [object[]]                                        $Risks
    )

    $risksByWs = @{}
    foreach ($r in ($Risks | Where-Object { $null -ne $_ -and $_.status -ne 'closed' -and $_.workstream })) {
        if (-not $risksByWs.ContainsKey($r.workstream)) { $risksByWs[$r.workstream] = [System.Collections.Generic.List[hashtable]]::new() }
        $risksByWs[$r.workstream].Add($r)
    }
    $decsByWs = @{}
    foreach ($d in ($Decisions | Where-Object { $null -ne $_ -and $_.status -ne 'closed' -and $_.workstream })) {
        if (-not $decsByWs.ContainsKey($d.workstream)) { $decsByWs[$d.workstream] = [System.Collections.Generic.List[hashtable]]::new() }
        $decsByWs[$d.workstream].Add($d)
    }

    $out = @{}
    foreach ($wsId in @($FinalResults.Keys)) {
        $entry = $FinalResults[$wsId]
        if (-not $entry) { continue }
        $wsName = if ($entry.ContainsKey('workstream') -and $entry.workstream -and $entry.workstream.ContainsKey('name')) { [string]$entry.workstream.name } else { '' }
        $attention = if ($entry.ContainsKey('attention_score') -and $null -ne $entry.attention_score) { [double]$entry.attention_score } elseif ($entry.ContainsKey('score')) { [double]$entry.score } else { 0.0 }
        $trend = if ($entry.ContainsKey('trend_direction') -and $entry.trend_direction) { [string]$entry.trend_direction } else { 'stable' }
        $category = if ($entry.ContainsKey('category')) { [string]$entry.category } else { '' }

        $wsRisks = @()
        if ($wsName -and $risksByWs.ContainsKey($wsName)) { $wsRisks = @($risksByWs[$wsName]) }
        $wsDecs  = @()
        if ($wsName -and $decsByWs.ContainsKey($wsName))  { $wsDecs  = @($decsByWs[$wsName]) }

        $highRisks        = @($wsRisks | Where-Object { $_ -and $_.severity -eq 'High' })
        $mediumOrHigh     = @($wsRisks | Where-Object { $_ -and ($_.severity -eq 'High' -or $_.severity -eq 'Medium') })
        $oldOpenDecisions = @($wsDecs  | Where-Object { $_ -and [int]$_.decisionAgeDays -ge 14 })

        $status  = 'Green'
        $reasons = [System.Collections.Generic.List[string]]::new()

        if ($attention -ge 70 -and ($highRisks.Count -gt 0 -or $oldOpenDecisions.Count -gt 0 -or $trend -eq 'decreasing')) {
            $status = 'Red'
            if ($highRisks.Count        -gt 0) { $reasons.Add("$($highRisks.Count) high-severity open risk(s)") }
            if ($oldOpenDecisions.Count -gt 0) { $reasons.Add("$($oldOpenDecisions.Count) decision(s) open 14+ days") }
            if ($trend -eq 'decreasing')       { $reasons.Add('activity trend decreasing') }
        }
        elseif ($attention -ge 40 -or ($category -eq 'P1' -and $mediumOrHigh.Count -gt 0)) {
            $status = 'Amber'
            if ($mediumOrHigh.Count -gt 0) { $reasons.Add("$($mediumOrHigh.Count) open risk(s) at Medium+") }
            if ($attention -ge 40 -and $attention -lt 70) { $reasons.Add("attention $([Math]::Round($attention,1)) in watch band") }
        }
        else {
            $reasons.Add('no active risks or aged decisions on this workstream')
        }

        $color = switch ($status) { 'Red' { '#c62828' }; 'Amber' { '#f9a825' }; default { '#2e7d32' } }
        $out[$wsId] = [ordered]@{
            status            = $status
            color             = $color
            reason            = ($reasons -join '; ')
            openRiskCount     = [int]$wsRisks.Count
            highRiskCount     = [int]$highRisks.Count
            openDecisionCount = [int]$wsDecs.Count
            oldDecisionCount  = [int]$oldOpenDecisions.Count
        }
    }
    return $out
}

function New-InboxItem {
    <#
        Normalises a decision or risk entry into a common inbox-item shape so
        the David inbox can rank both types side-by-side.
    #>
    param(
        [ValidateSet('decision','risk')] [string] $Kind,
        [hashtable] $Entry
    )

    if ($Kind -eq 'decision') {
        $act = $Entry.recommendedFollowUp
        $confidence = if ($Entry.ContainsKey('decisionConfidence')) { [double]$Entry.decisionConfidence } else { 0.0 }
        $ageDays = $Entry.decisionAgeDays
    } else {
        $act = $Entry.recommendedAction
        $confidence = if ($Entry.ContainsKey('riskConfidence')) { [double]$Entry.riskConfidence } else { 0.0 }
        $ageDays = $Entry.agingDays
    }
    $priority = if ($act -is [System.Collections.IDictionary] -and $act.priority) { [int]$act.priority } else { 3 }
    $verb     = if ($act -is [System.Collections.IDictionary]) { [string]$act.verb } else { '' }
    $actionClass = if ($act -is [System.Collections.IDictionary] -and $act.actionClass) { [string]$act.actionClass } else { '' }
    $nextAction  = if ($act -is [System.Collections.IDictionary] -and $act.nextAction)  { [string]$act.nextAction }  else { '' }
    $dueBy    = if ($act -is [System.Collections.IDictionary]) { [string]$act.dueBy } else { '' }

    return [ordered]@{
        kind            = $Kind
        id              = if ($Kind -eq 'decision') { $Entry.decisionId } else { $Entry.riskId }
        title           = $Entry.title
        workstream      = $Entry.workstream
        owner           = $Entry.owner
        ownerConfidence = $Entry.ownerConfidence
        suggestedOwner  = if ($Entry.ContainsKey('suggestedOwner')) { [string]$Entry.suggestedOwner } else { '' }
        priority        = $priority
        verb            = $verb
        actionClass     = $actionClass
        nextAction      = $nextAction
        dueBy           = $dueBy
        deadline        = if ($Kind -eq 'decision' -and $Entry.decisionDeadline) { $Entry.decisionDeadline } else { $dueBy }
        confidence      = [Math]::Round($confidence, 2)
        ageDays         = $ageDays
        severity        = if ($Kind -eq 'risk') { $Entry.severity } else { $null }
        trend           = if ($Kind -eq 'risk') { $Entry.trend } else { $null }
        decisionRequired= if ($Kind -eq 'decision') { $Entry.decisionRequired } else { $false }
        # V2.5 execution intelligence pass-through
        decisionStatus       = if ($Kind -eq 'decision' -and $Entry.ContainsKey('decisionStatus')) { [string]$Entry.decisionStatus } else { '' }
        decisionOutcome      = if ($Kind -eq 'decision' -and $Entry.ContainsKey('decisionOutcome')) { [string]$Entry.decisionOutcome } else { '' }
        timeToEscalationRisk = if ($Entry.ContainsKey('timeToEscalationRisk')) { $Entry.timeToEscalationRisk } else { $null }
        linkedActionCount    = if ($Kind -eq 'decision' -and $Entry.ContainsKey('linkedActions')) { @($Entry.linkedActions).Count } else { 0 }
        # V3.0 adaptive intelligence pass-through
        outcomeQuality       = if ($Kind -eq 'decision' -and $Entry.ContainsKey('outcomeQuality')) { [string]$Entry.outcomeQuality } else { 'Unknown' }
        recurrenceCount      = if ($Kind -eq 'decision' -and $Entry.ContainsKey('recurrenceCount')) { [int]$Entry.recurrenceCount } else { 1 }
        actionSource         = if ($Kind -eq 'decision' -and $Entry.ContainsKey('linkedActions') -and @($Entry.linkedActions).Count -gt 0) {
                                    $srcs = @(@($Entry.linkedActions) | ForEach-Object { [string]$_.actionSource } | Sort-Object -Unique)
                                    ($srcs -join '+')
                                } else { '' }
        rankingScore         = 0.0
        personalizationSignals = @()
        impact          = $Entry.impact
        rationale       = if ($act -is [System.Collections.IDictionary]) { [string]$act.rationale } else { '' }
        # V4.0 Phase 4: daily-delta pass-through
        delta           = if ($Entry.ContainsKey('delta') -and $Entry.delta) { $Entry.delta } else { [ordered]@{ daysSinceLastTouched = 0; updatedSinceYesterday = $true; changeSummary = 'first appearance' } }
        # V4.0 Sprint 13a: focus signals pass-through
        focusSignals    = if ($Entry.ContainsKey('focusSignals') -and $Entry.focusSignals) { $Entry.focusSignals } else { [ordered]@{ engaged = $false; attentionRequired = $false; awaitingOthers = $false; reasons = [ordered]@{ engaged=''; attentionRequired=''; awaitingOthers='' } } }
        # V4.0 Sprint 13b: canonical priority score
        priorityScore   = if ($Entry.ContainsKey('priorityScore'))  { [int]$Entry.priorityScore }   else { 0 }
        priorityReason  = if ($Entry.ContainsKey('priorityReason')) { [string]$Entry.priorityReason } else { '' }
        priorityReasonBullets = if ($Entry.ContainsKey('priorityReasonBullets') -and $Entry.priorityReasonBullets) { @($Entry.priorityReasonBullets) } else { @() }
        priorityReasonDebug   = if ($Entry.ContainsKey('priorityReasonDebug')) { [string]$Entry.priorityReasonDebug } else { '' }
        priorityFactors = if ($Entry.ContainsKey('priorityFactors') -and $Entry.priorityFactors) { $Entry.priorityFactors } else { [ordered]@{ impact=0.0; ownership=0.0; deadline=0.0; status=0.0; engagement=0.0 } }
        # V4.0 Sprint 15: why_it_matters pass-through
        whyItMatters           = if ($Entry.ContainsKey('whyItMatters'))           { [string]$Entry.whyItMatters }           else { '' }
        whyItMattersConfidence = if ($Entry.ContainsKey('whyItMattersConfidence')) { [double]$Entry.whyItMattersConfidence } else { 0.0 }
        whyItMattersSource     = if ($Entry.ContainsKey('whyItMattersSource'))     { [string]$Entry.whyItMattersSource }     else { 'none' }
    }
}

function Get-DavidInbox {
    <#
        Ranks the items David should decide/action today.
        Includes:
          - Any decision with decisionRequired=true and lifecycle != 'Decided'
          - Any risk with severity=High AND ownerConfidence != 'unknown'
          - Any decision or risk whose action priority is P1 (Escalate today)
          - Any entry whose timeToEscalationRisk is <=3 (imminent escalation)
        Sort: priority asc, then rankingScore desc (personalization),
        then timeToEscalationRisk asc, then deadline asc, then confidence desc,
        then ageDays desc.

        V3.0: accepts optional -Preferences (from Read-DavidPreferences) and
        -Insights (from Get-ExecutionInsights) which together compute a per-item
        rankingScore + personalizationSignals used as the secondary sort key.
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks,
        [hashtable] $Preferences = $null,
        [hashtable] $Insights    = $null
    )

    $items = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($d in ($Decisions | Where-Object { $_.decisionRequired -and $_.decisionStatus -ne 'Decided' })) {
        # V4.0 Phase 3: exclude stale entries from priority inbox.
        if ($d.ContainsKey('stale') -and $d.stale) { continue }
        $items.Add((New-InboxItem -Kind 'decision' -Entry $d))
    }
    foreach ($r in $Risks) {
        if ($r.status -eq 'closed') { continue }
        # V4.0 Phase 3: exclude stale risks from priority inbox.
        if ($r.ContainsKey('stale') -and $r.stale) { continue }
        $isHigh = ($r.severity -eq 'High')
        $act = $r.recommendedAction
        $isP1 = ($act -is [System.Collections.IDictionary] -and $act.priority -eq 1)
        $imminent = ($null -ne $r.timeToEscalationRisk -and [int]$r.timeToEscalationRisk -le 3)
        # V4.0 Phase 7: include High risks when there's any ownership signal at all
        # (explicit/proximity OR at least a workstream-map suggestion)
        $hasOwnershipSignal = ($r.ownerConfidence -in @('high','medium','workstream-map','name-proximity')) -or ($r.suggestedOwner)
        if (($isHigh -and $hasOwnershipSignal) -or $isP1 -or $imminent) {
            $items.Add((New-InboxItem -Kind 'risk' -Entry $r))
        }
    }

    # V3.0 personalization: compute rankingScore and attach signals per item.
    if ($Preferences) {
        $overloadedOwners = @{}
        $delayedWorkstreams = @{}
        $missedIds = @{}
        if ($Insights) {
            foreach ($o in @($Insights.overloadedOwners)) {
                if ($o.itemCount -ge $Preferences.penalties.overloadedOwnerThreshold) { $overloadedOwners[[string]$o.owner] = $true }
            }
            foreach ($d in @($Insights.delayedDecisions)) {
                if ($d.workstream) { $delayedWorkstreams[[string]$d.workstream] = $true }
            }
            foreach ($m in @($Insights.missedDeadlines)) {
                if ($m.id) { $missedIds[[string]$m.id] = $true }
            }
        }

        foreach ($it in $items) {
            $score = 0.0
            $signals = [System.Collections.Generic.List[hashtable]]::new()

            # Static boosts
            if ($it.workstream -and $Preferences.priorityBoosts.workstream.ContainsKey([string]$it.workstream)) {
                $delta = [double]$Preferences.priorityBoosts.workstream[[string]$it.workstream]
                $score += $delta
                $signals.Add(@{ source = 'workstream-boost'; delta = $delta; reason = "preferred workstream: $($it.workstream)" })
            }
            if ($it.owner -and $Preferences.priorityBoosts.owner.ContainsKey([string]$it.owner)) {
                $delta = [double]$Preferences.priorityBoosts.owner[[string]$it.owner]
                $score += $delta
                $signals.Add(@{ source = 'owner-boost'; delta = $delta; reason = "preferred owner: $($it.owner)" })
            }
            if ($it.kind -and $Preferences.priorityBoosts.kind.ContainsKey([string]$it.kind)) {
                $delta = [double]$Preferences.priorityBoosts.kind[[string]$it.kind]
                if ($delta -ne 0.0) {
                    $score += $delta
                    $signals.Add(@{ source = 'kind-boost'; delta = $delta; reason = "kind bias: $($it.kind)" })
                }
            }

            # Confidence-based penalty
            if ([double]$it.confidence -lt [double]$Preferences.penalties.lowConfidenceThreshold) {
                $delta = -[double]$Preferences.penalties.lowConfidencePenalty
                $score += $delta
                $signals.Add(@{ source = 'low-confidence'; delta = $delta; reason = "confidence $($it.confidence) < $($Preferences.penalties.lowConfidenceThreshold)" })
            }

            # Bonuses
            if ([int]$it.recurrenceCount -ge 2) {
                $delta = [double]$Preferences.bonuses.recurringDecisionBonus
                $score += $delta
                $signals.Add(@{ source = 'recurring'; delta = $delta; reason = "recurring $($it.recurrenceCount)x - prior decision didn't stick" })
            }
            if ($null -ne $it.timeToEscalationRisk -and [int]$it.timeToEscalationRisk -le 1) {
                $delta = [double]$Preferences.bonuses.imminentEscalationBonus
                $score += $delta
                $signals.Add(@{ source = 'imminent-escalation'; delta = $delta; reason = "escalates in $($it.timeToEscalationRisk)d" })
            }
            if ($it.kind -eq 'decision' -and $it.actionSource -eq 'inferred') {
                $delta = [double]$Preferences.bonuses.inferredActionBonus
                $score += $delta
                $signals.Add(@{ source = 'inferred-action'; delta = $delta; reason = 'no explicit **Action:** marker - inference applied' })
            }
            if ($it.id -and $missedIds.ContainsKey([string]$it.id)) {
                $delta = [double]$Preferences.bonuses.missedDeadlineBonus
                $score += $delta
                $signals.Add(@{ source = 'missed-deadline'; delta = $delta; reason = 'past decisionDeadline - jump P1' })
            }

            # Overloaded-owner penalty (skip for P1 - never dampen escalate-today items)
            if ([int]$it.priority -gt 1 -and $it.owner -and $overloadedOwners.ContainsKey([string]$it.owner)) {
                $delta = -[double]$Preferences.penalties.overloadedOwnerPenalty
                $score += $delta
                $signals.Add(@{ source = 'overloaded-owner'; delta = $delta; reason = "owner $($it.owner) already at capacity" })
            }

            # Learning-loop confidence tuning (applied to the displayed confidence
            # AND scored into the ranking so both surfaces move together).
            if ($Insights) {
                if ($it.workstream -and $delayedWorkstreams.ContainsKey([string]$it.workstream) -and $it.verb -eq 'Escalate') {
                    $delta = [double]$Preferences.learning.delayedWorkstreamConfidenceBonus
                    $score += $delta
                    $signals.Add(@{ source = 'learning:delayed-workstream'; delta = $delta; reason = "workstream has delayed decisions - boost escalate confidence" })
                }
                if ($it.owner -and $overloadedOwners.ContainsKey([string]$it.owner)) {
                    $delta = -[double]$Preferences.learning.overloadedOwnerConfidencePenalty
                    $score += $delta
                    $signals.Add(@{ source = 'learning:overloaded-owner'; delta = $delta; reason = 'signal is noisier when owner is over-capacity' })
                }
            }

            $it.rankingScore = [Math]::Round($score, 3)
            $it.personalizationSignals = @($signals)
        }
    }

    return @($items | Sort-Object `
        @{ Expression = { -[int]$_.priorityScore }; Ascending = $true },
        @{ Expression = { [int]$_.priority }; Ascending = $true },
        @{ Expression = { -[double]$_.rankingScore }; Ascending = $true },
        @{ Expression = { if ($null -ne $_.timeToEscalationRisk) { [int]$_.timeToEscalationRisk } else { 9999 } }; Ascending = $true },
        @{ Expression = { if ($_.deadline) { $_.deadline } else { '9999-12-31' } }; Ascending = $true },
        @{ Expression = { [double]$_.confidence }; Descending = $true },
        @{ Expression = { [int]$_.ageDays }; Descending = $true })
}

# V2.5 stopwords for cluster theme extraction (below).
$script:CLUSTER_STOPWORDS = @(
    'the','and','for','with','from','into','onto','this','that','these','those',
    'about','around','over','under','through','after','before','than','then',
    'have','has','had','was','were','been','being','will','would','should','could',
    'a','an','of','to','in','on','at','by','as','is','are','be','it','its',
    'not','no','yes','or','but','if','so','do','does','did','doing',
    'we','you','he','she','they','their','our','my','your','his','her',
    'decision','decisions','risk','risks','issue','issues','need','needs','please',
    'update','status','week','weekly','daily','morning','next','upcoming',
    'action','actions','follow','followup','task','tasks','question','pending',
    'high','medium','low','open','closed','resolved','escalate','tbd','deadline',
    'confirm','approval','required','requires','confirming','approving'
)

function Get-DecisionClusters {
    <#
        Groups inbox items into clusters using two dimensions:
          1) workstream (primary key; items without workstream group under '(none)')
          2) theme (bag-of-words heuristic within a workstream cluster)

        Returns a sorted array of hashtables:
          @{ workstream; theme; itemCount; p1Count; topPriority;
             minEscalationRisk; itemIds; kinds }
    #>
    param([object[]] $Items)

    $byWs = @{}
    foreach ($it in @($Items | Where-Object { $null -ne $_ })) {
        $ws = if ($it.workstream) { [string]$it.workstream } else { '(none)' }
        if (-not $byWs.ContainsKey($ws)) { $byWs[$ws] = [System.Collections.Generic.List[hashtable]]::new() }
        $byWs[$ws].Add($it)
    }

    $clusters = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($ws in @($byWs.Keys)) {
        $wsItems = @($byWs[$ws])
        # Extract theme tokens from titles: 4+ char lowercase words, minus stopwords.
        $tokenIndex = @{}   # token -> list of items
        foreach ($it in $wsItems) {
            $title = if ($it.title) { [string]$it.title } else { '' }
            $tokens = [regex]::Matches($title.ToLowerInvariant(), '[a-z]{4,}') | ForEach-Object { $_.Value }
            $unique = @($tokens | Sort-Object -Unique) | Where-Object { $script:CLUSTER_STOPWORDS -notcontains $_ }
            foreach ($t in $unique) {
                if (-not $tokenIndex.ContainsKey($t)) { $tokenIndex[$t] = [System.Collections.Generic.List[hashtable]]::new() }
                $tokenIndex[$t].Add($it)
            }
        }

        # Greedy: pick the token that covers the most uncovered items, repeat.
        $covered = [System.Collections.Generic.HashSet[string]]::new()
        $themeBuckets = [System.Collections.Generic.List[hashtable]]::new()
        while ($true) {
            $best = $null
            $bestCount = 1
            foreach ($t in @($tokenIndex.Keys)) {
                $available = @($tokenIndex[$t] | Where-Object { -not $covered.Contains([string]$_.id) })
                if ($available.Count -gt $bestCount) {
                    $bestCount = $available.Count
                    $best = $t
                }
            }
            if (-not $best) { break }
            $group = @($tokenIndex[$best] | Where-Object { -not $covered.Contains([string]$_.id) })
            foreach ($g in $group) { [void]$covered.Add([string]$g.id) }
            $themeBuckets.Add(@{ theme = $best; items = $group })
        }

        # Any leftover items form a '(misc)' bucket.
        $leftover = @($wsItems | Where-Object { -not $covered.Contains([string]$_.id) })
        if ($leftover.Count -gt 0) { $themeBuckets.Add(@{ theme = '(misc)'; items = $leftover }) }

        foreach ($b in $themeBuckets) {
            $group = @($b.items)
            $priorities = @($group | ForEach-Object { [int]$_.priority })
            $top = if ($priorities.Count -gt 0) { ($priorities | Measure-Object -Minimum).Minimum } else { 5 }
            $p1 = @($group | Where-Object { [int]$_.priority -eq 1 }).Count
            $ttrs = @($group | Where-Object { $null -ne $_.timeToEscalationRisk } | ForEach-Object { [int]$_.timeToEscalationRisk })
            $minTtr = if ($ttrs.Count -gt 0) { ($ttrs | Measure-Object -Minimum).Minimum } else { $null }
            $ids = @($group | ForEach-Object { [string]$_.id })
            $kinds = @($group | ForEach-Object { [string]$_.kind } | Sort-Object -Unique)
            $clusters.Add([ordered]@{
                workstream        = $ws
                theme             = $b.theme
                itemCount         = $group.Count
                topPriority       = $top
                p1Count           = $p1
                minEscalationRisk = $minTtr
                kinds             = $kinds
                itemIds           = $ids
            })
        }
    }

    return @($clusters | Sort-Object `
        @{ Expression = { [int]$_.topPriority }; Ascending = $true },
        @{ Expression = { -[int]$_.p1Count }; Ascending = $true },
        @{ Expression = { -[int]$_.itemCount }; Ascending = $true },
        @{ Expression = { [string]$_.workstream }; Ascending = $true })
}

# --- V3.0 Adaptive Intelligence: execution insights + learning signals ------

function Get-ExecutionInsights {
    <#
        Aggregates cross-cutting patterns across decisions and risks. Feeds the
        priority-inbox re-ranking and the confidence-tuning learning loop.

        Returns a hashtable with:
          - delayedDecisions      : decisions Pending 14+ days
          - missedDeadlines       : decisions with decisionDeadline < now AND lifecycle != Decided
          - overloadedOwners      : top-N owners by open item count (>= threshold)
          - recurringDecisions    : distinct normalized titles with recurrenceCount >= 2
          - stalePendingByWorkstream : workstreams with >= 3 Pending decisions
          - highSeverityAgedRisks : High-severity risks aged 14+ days
    #>
    param(
        [object[]] $Decisions,
        [object[]] $Risks,
        [datetime] $Now,
        [int]      $OverloadThreshold = 3
    )

    $Decisions = @($Decisions | Where-Object { $null -ne $_ })
    $Risks     = @($Risks     | Where-Object { $null -ne $_ })

    $delayed = @($Decisions | Where-Object {
        $_.decisionStatus -eq 'Pending' -and [int]$_.decisionAgeDays -ge 14
    } | ForEach-Object {
        [ordered]@{
            id         = $_.decisionId
            title      = $_.title
            workstream = $_.workstream
            owner      = $_.owner
            ageDays    = $_.decisionAgeDays
        }
    })

    $missed = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($d in $Decisions) {
        if ($d.decisionStatus -eq 'Decided') { continue }
        $dl = [string]$d.decisionDeadline
        if (-not $dl) { continue }
        [datetime] $parsed = [datetime]::MinValue
        if ([datetime]::TryParseExact($dl, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref] $parsed)) {
            if ($parsed -lt $Now.Date) {
                $missed.Add([ordered]@{
                    id           = $d.decisionId
                    title        = $d.title
                    workstream   = $d.workstream
                    owner        = $d.owner
                    deadline     = $dl
                    daysOverdue  = [int][Math]::Floor(($Now.Date - $parsed).TotalDays)
                })
            }
        }
    }

    # Overloaded owners: count open decisions + open risks per owner
    $ownerLoad = @{}
    foreach ($d in $Decisions) {
        if ($d.decisionStatus -eq 'Decided') { continue }
        $o = if ($d.owner) { [string]$d.owner } else { 'unassigned' }
        if (-not $ownerLoad.ContainsKey($o)) { $ownerLoad[$o] = @{ owner = $o; decisions = 0; risks = 0; p1 = 0; confidenceSum = 0.0; confidenceCount = 0 } }
        $ownerLoad[$o].decisions += 1
        if (($d.recommendedFollowUp -is [System.Collections.IDictionary]) -and [int]$d.recommendedFollowUp.priority -le 1) { $ownerLoad[$o].p1 += 1 }
        if ($null -ne $d.decisionConfidence) { $ownerLoad[$o].confidenceSum += [double]$d.decisionConfidence; $ownerLoad[$o].confidenceCount += 1 }
    }
    foreach ($r in $Risks) {
        if ($r.status -eq 'closed') { continue }
        $o = if ($r.owner) { [string]$r.owner } else { 'unassigned' }
        if (-not $ownerLoad.ContainsKey($o)) { $ownerLoad[$o] = @{ owner = $o; decisions = 0; risks = 0; p1 = 0; confidenceSum = 0.0; confidenceCount = 0 } }
        $ownerLoad[$o].risks += 1
        if (($r.recommendedAction -is [System.Collections.IDictionary]) -and [int]$r.recommendedAction.priority -le 1) { $ownerLoad[$o].p1 += 1 }
        if ($null -ne $r.riskConfidence) { $ownerLoad[$o].confidenceSum += [double]$r.riskConfidence; $ownerLoad[$o].confidenceCount += 1 }
    }
    $overloaded = @(
        $ownerLoad.Values | ForEach-Object {
            $total = [int]$_.decisions + [int]$_.risks
            $avg = if ([int]$_.confidenceCount -gt 0) { [Math]::Round($_.confidenceSum / $_.confidenceCount, 2) } else { 0.0 }
            [ordered]@{
                owner        = $_.owner
                itemCount    = $total
                decisions    = $_.decisions
                risks        = $_.risks
                p1Count      = $_.p1
                avgConfidence= $avg
            }
        } | Where-Object { [int]$_.itemCount -ge $OverloadThreshold -and $_.owner -notin @('Unassigned', 'unassigned', '') } |
            Sort-Object @{ Expression = { -[int]$_.itemCount } }, @{ Expression = { -[int]$_.p1Count } }
    )

    # Recurring decisions: pick unique titles with recurrenceCount >= 2
    $recurring = [System.Collections.Generic.List[hashtable]]::new()
    $seenNorm = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($d in $Decisions) {
        if ([int]$d.recurrenceCount -lt 2) { continue }
        $norm = Get-NormalizedTitle -Title $d.title
        if (-not $norm) { continue }
        if ($seenNorm.Add($norm)) {
            $recurring.Add([ordered]@{
                normalizedTitle = $norm
                count           = [int]$d.recurrenceCount
                exampleTitle    = $d.title
                exampleId       = $d.decisionId
                workstream      = $d.workstream
            })
        }
    }

    # Workstreams with >= 3 Pending decisions
    $stalePending = [System.Collections.Generic.List[hashtable]]::new()
    $byWs = @{}
    foreach ($d in $Decisions) {
        if ($d.decisionStatus -ne 'Pending') { continue }
        $ws = if ($d.workstream) { [string]$d.workstream } else { '(none)' }
        if (-not $byWs.ContainsKey($ws)) { $byWs[$ws] = [System.Collections.Generic.List[int]]::new() }
        $byWs[$ws].Add([int]$d.decisionAgeDays)
    }
    foreach ($ws in @($byWs.Keys)) {
        $ages = @($byWs[$ws])
        if ($ages.Count -ge 3) {
            $avgAge = if ($ages.Count -gt 0) { [Math]::Round((($ages | Measure-Object -Average).Average), 1) } else { 0 }
            $stalePending.Add([ordered]@{
                workstream  = $ws
                count       = $ages.Count
                avgAgeDays  = $avgAge
            })
        }
    }

    $highAgedRisks = @($Risks | Where-Object {
        $_.status -ne 'closed' -and $_.severity -eq 'High' -and [int]$_.agingDays -ge 14
    } | ForEach-Object {
        [ordered]@{
            id         = $_.riskId
            title      = $_.title
            workstream = $_.workstream
            owner      = $_.owner
            ageDays    = $_.agingDays
        }
    })

    return @{
        delayedDecisions          = $delayed
        missedDeadlines           = @($missed)
        overloadedOwners          = $overloaded
        recurringDecisions        = @($recurring)
        stalePendingByWorkstream  = @($stalePending | Sort-Object @{ Expression = { -[int]$_.count } })
        highSeverityAgedRisks     = $highAgedRisks
    }
}

function Build-ExecutionInsightsMarkdown {
    param([hashtable] $Insights, [string] $NowStamp)

    $renderList = {
        param($items, $line)
        if ($items.Count -gt 0) { ($items | ForEach-Object { & $line $_ }) -join "`n" } else { '_None._' }
    }

    $delayedBlock = & $renderList @($Insights.delayedDecisions) {
        param($d) "- **$($d.title)** - $($d.workstream) - owner $($d.owner) - aged **$($d.ageDays)d** ($($d.id))"
    }
    $missedBlock = & $renderList @($Insights.missedDeadlines) {
        param($d) "- **$($d.title)** - deadline $($d.deadline) (**$($d.daysOverdue)d** overdue) - owner $($d.owner)"
    }
    $overloadedBlock = & $renderList @($Insights.overloadedOwners) {
        param($o) "- **$($o.owner)** - $($o.itemCount) open items ($($o.decisions) decisions / $($o.risks) risks, $($o.p1Count) P1), avg confidence $($o.avgConfidence)"
    }
    $recurringBlock = & $renderList @($Insights.recurringDecisions) {
        param($r) "- **$($r.exampleTitle)** - $($r.count) occurrences - $($r.workstream) ($($r.exampleId))"
    }
    $staleBlock = & $renderList @($Insights.stalePendingByWorkstream) {
        param($w) "- **$($w.workstream)** - $($w.count) Pending decisions, avg age $($w.avgAgeDays)d"
    }
    $agedRiskBlock = & $renderList @($Insights.highSeverityAgedRisks) {
        param($r) "- **$($r.title)** - $($r.workstream) - owner $($r.owner) - aged **$($r.ageDays)d** ($($r.id))"
    }

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# Execution Insights

Generated: $NowStamp

Cross-cutting patterns detected across the decision registry and risk register.
These signals feed the priority-inbox re-ranking and the confidence-tuning learning loop.

## Delayed Decisions (Pending 14+ days)

$delayedBlock

## Missed Deadlines (past decisionDeadline, still Pending)

$missedBlock

## Overloaded Owners (>= 3 open items)

$overloadedBlock

## Recurring Decisions (same normalized title 2+ times)

$recurringBlock

## Stale Pending by Workstream (>= 3 Pending)

$staleBlock

## High-Severity Aged Risks (14+ days)

$agedRiskBlock

## Notes

- **delayedDecisions** and **stalePendingByWorkstream** boost the confidence of any Escalate action on their workstream.
- **overloadedOwners** trigger a down-rank on non-P1 items assigned to that owner in David's inbox.
- **missedDeadlines** always jump to P1 with escalate-today priority regardless of static priority.
- **recurringDecisions** get a small ranking boost - the same question resurfacing means the prior decision didn't stick.
"@
}

function Build-ExecutionInsightsJson {
    param([hashtable] $Insights, [string] $GeneratedIso)
    $out = [ordered]@{
        generated = $GeneratedIso
        generator = 'scripts/generate-current-focus.ps1'
        version   = 'V3.0'
        totals    = [ordered]@{
            delayedDecisions          = @($Insights.delayedDecisions).Count
            missedDeadlines           = @($Insights.missedDeadlines).Count
            overloadedOwners          = @($Insights.overloadedOwners).Count
            recurringDecisions        = @($Insights.recurringDecisions).Count
            stalePendingByWorkstream  = @($Insights.stalePendingByWorkstream).Count
            highSeverityAgedRisks     = @($Insights.highSeverityAgedRisks).Count
        }
        delayedDecisions          = @($Insights.delayedDecisions)
        missedDeadlines           = @($Insights.missedDeadlines)
        overloadedOwners          = @($Insights.overloadedOwners)
        recurringDecisions        = @($Insights.recurringDecisions)
        stalePendingByWorkstream  = @($Insights.stalePendingByWorkstream)
        highSeverityAgedRisks     = @($Insights.highSeverityAgedRisks)
    }
    return $out | ConvertTo-Json -Depth 6
}

function Build-DavidInboxMarkdown {
    param(
        [object[]] $Items,
        [string]   $NowStamp,
        [int]      $P1Cap = 5,
        [int]      $P2Cap = 10,
        [int]      $P3Cap = 10
    )
    $Items = @($Items | Where-Object { $null -ne $_ })

    $p1 = @($Items | Where-Object { [int]$_.priority -eq 1 } | Select-Object -First $P1Cap)
    $p2 = @($Items | Where-Object { [int]$_.priority -eq 2 } | Select-Object -First $P2Cap)
    $p3 = @($Items | Where-Object { [int]$_.priority -eq 3 } | Select-Object -First $P3Cap)

    function _RenderInbox($it) {
        $wsName = if ($it.workstream) { $it.workstream } else { '(no workstream)' }
        $ownerText = if ($it.owner) { $it.owner } else { 'unassigned' }
        $sevBit = if ($it.kind -eq 'risk') { " (severity: $($it.severity), trend: $($it.trend))" } else { '' }
        $flagBit = if ($it.decisionRequired) { ' [DECISION REQUIRED]' } else { '' }
        $ttrBit = if ($null -ne $it.timeToEscalationRisk) { " [escalation in $($it.timeToEscalationRisk)d]" } else { '' }
        $lifecycleBit = if ($it.decisionStatus) { " [$($it.decisionStatus)]" } else { '' }
        $outcomeBit   = if ($it.decisionOutcome) { "`n- **Outcome**: $($it.decisionOutcome)" } else { '' }
        $impactBit    = if ($it.impact) { "`n- **Impact**: $($it.impact)" } else { '' }
        $linkedBit    = if ([int]$it.linkedActionCount -gt 0) { "`n- **Linked actions**: $($it.linkedActionCount)" } else { '' }
        $classLabel   = if ($it.actionClass) { $it.actionClass } else { $it.verb }
        $nextLine     = if ($it.nextAction) { "`n- **Next**: $($it.nextAction)" } else { '' }
        @"
### [$classLabel] P$($it.priority) - $wsName$lifecycleBit$flagBit$ttrBit

- **What**: $($it.title)$sevBit
- **Owner**: $ownerText ($($it.ownerConfidence))
- **Deadline**: $($it.deadline)
- **Confidence**: $($it.confidence)
- **Age**: $($it.ageDays) days$nextLine
- **Rationale**: $($it.rationale)$outcomeBit$impactBit$linkedBit
- **Source**: $($it.kind) $($it.id)

"@
    }

    $renderTier = {
        param($list)
        if ($list.Count -gt 0) { ($list | ForEach-Object { _RenderInbox $_ }) -join '' }
        else { "_None._`n" }
    }

    $p1Block = & $renderTier $p1
    $p2Block = & $renderTier $p2
    $p3Block = & $renderTier $p3

    $clusters = Get-DecisionClusters -Items $Items
    $clusterRows = if ($clusters.Count -gt 0) {
        ($clusters | ForEach-Object {
            $minTtr = if ($null -ne $_.minEscalationRisk) { "$($_.minEscalationRisk)d" } else { '-' }
            "- **$($_.workstream)** / _$($_.theme)_ - $($_.itemCount) item(s), P$($_.topPriority), $($_.p1Count) P1, min escalation: $minTtr"
        }) -join "`n"
    } else { '_No clusters detected._' }

    return @"
<!-- GENERATED FILE: Do not edit directly. Regenerate using scripts/generate-current-focus.ps1 -->

# David's Priority Inbox

Generated: $NowStamp

Candidates: **$($Items.Count)** | P1: **$($p1.Count) (cap $P1Cap)** | P2: **$($p2.Count) (cap $P2Cap)** | P3: **$($p3.Count) (cap $P3Cap)**

Sort: priority asc, then time to escalation, then deadline, then confidence, then age.

## P1 - Escalate today (top $P1Cap)

$p1Block

## P2 - Confirm or investigate this week (top $P2Cap)

$p2Block

## P3 - Review this week (top $P3Cap)

$p3Block

## Clusters (workstream / theme)

$clusterRows

## How this list was built

- **Decisions**: any entry where ``decisionRequired = true`` AND lifecycle != Decided (explicit ``Question:``/``TBD:`` marker OR heuristic promotion of P1/P2 recorded decisions).
- **Risks**: any open High-severity risk with a known owner, OR any risk whose structured action is P1, OR any risk whose ``timeToEscalationRisk <= 3``.
- Tiers are capped: P1 top $P1Cap so David sees a real inbox (not a wall). P2/P3 keep visibility on the next 10 each.
- Clusters group inbox items by workstream first, then by the most common non-stopword token in their titles (theme). Use them to batch decisions with a single owner conversation.
"@
}

function Build-DavidInboxJson {
    param(
        [object[]] $Items,
        [string]   $GeneratedIso,
        [int]      $P1Cap = 5,
        [int]      $P2Cap = 10,
        [int]      $P3Cap = 10
    )
    $Items = @($Items | Where-Object { $null -ne $_ })

    $p1 = @($Items | Where-Object { [int]$_.priority -eq 1 } | Select-Object -First $P1Cap)
    $p2 = @($Items | Where-Object { [int]$_.priority -eq 2 } | Select-Object -First $P2Cap)
    $p3 = @($Items | Where-Object { [int]$_.priority -eq 3 } | Select-Object -First $P3Cap)
    $selected = @($p1 + $p2 + $p3)

    $clusters = Get-DecisionClusters -Items $Items

    # V4.0 Phase 4: daily-delta ribbon (populated by Apply-DailyDelta earlier
    # in Main). Falls back to zeros if the delta pass has not run.
    $deltaRibbon = if ($script:MAT_DAILY_DELTA) {
        [ordered]@{
            addedCount     = @($script:MAT_DAILY_DELTA.added).Count
            changedCount   = @($script:MAT_DAILY_DELTA.changed).Count
            removedCount   = @($script:MAT_DAILY_DELTA.removed).Count
            staleCount     = @($script:MAT_DAILY_DELTA.stale).Count
            comparedAgainst = if ($script:MAT_DAILY_DELTA_PRIOR_DATE) { [string]$script:MAT_DAILY_DELTA_PRIOR_DATE } else { '' }
        }
    } else {
        [ordered]@{ addedCount = 0; changedCount = 0; removedCount = 0; staleCount = 0; comparedAgainst = '' }
    }

    $out = [ordered]@{
        generated = $GeneratedIso
        generator = 'scripts/generate-current-focus.ps1'
        version   = 'V3.0'
        caps      = [ordered]@{ p1 = $P1Cap; p2 = $P2Cap; p3 = $P3Cap }
        totals    = [ordered]@{
            candidates    = $Items.Count
            selected      = $selected.Count
            byPriority    = [ordered]@{
                p1 = @($Items | Where-Object { $_.priority -eq 1 }).Count
                p2 = @($Items | Where-Object { $_.priority -eq 2 }).Count
                p3 = @($Items | Where-Object { $_.priority -eq 3 }).Count
                p4 = @($Items | Where-Object { $_.priority -eq 4 }).Count
                p5 = @($Items | Where-Object { $_.priority -eq 5 }).Count
            }
            tiers         = [ordered]@{
                p1Shown = $p1.Count
                p2Shown = $p2.Count
                p3Shown = $p3.Count
            }
            clusters      = $clusters.Count
            imminentEscalation = @($Items | Where-Object { $null -ne $_.timeToEscalationRisk -and [int]$_.timeToEscalationRisk -le 3 }).Count
            personalized  = @($Items | Where-Object { @($_.personalizationSignals).Count -gt 0 }).Count
            dailyDelta    = $deltaRibbon
        }
        dailyDelta = $deltaRibbon
        tiers     = [ordered]@{
            p1 = @($p1)
            p2 = @($p2)
            p3 = @($p3)
        }
        clusters  = @($clusters)
        items     = @($selected)
    }
    return $out | ConvertTo-Json -Depth 6
}

# --- Main -------------------------------------------------------------------

Write-Host ""
Write-Host "Project Matryoshka V1.2 - Current Focus Generator" -ForegroundColor Cyan
Write-Host "Root: $ROOT"
Write-Host ""

# Load control files
$workstreams   = Read-Workstreams     (Join-Path $CTX 'workstreams.yaml')
$overrides     = Read-Overrides       (Join-Path $CTX 'priority-overrides.yaml')
$model         = Read-ScoringModel    (Join-Path $CTX 'scoring-model.yaml')
$sourceWeights = Read-SourceWeights   (Join-Path $CTX 'source-weights.yaml')
$activityWin   = Read-ActivityWindows (Join-Path $CTX 'activity-windows.yaml')
$ownershipMap  = Read-OwnershipMap    (Join-Path $CTX 'ownership-map.yaml')
$preferences   = Read-DavidPreferences (Join-Path $CTX 'david-preferences.yaml')

# Preserve attention formula on the model if the parser did not capture it.
if ($model -is [hashtable] -and -not $model.ContainsKey('attention_formula')) {
    $model['attention_formula'] = $null
}

Write-Host "Loaded $($workstreams.Count) workstreams, $($overrides.Count) overrides, $($sourceWeights.Count) source-weight rules, $($ownershipMap.Count) ownership entries."

# Collect source files (legacy path retained for V1.1 evidence/mention tallies)
$allFiles = Get-SourceFiles $ROOT $SCAN_FOLDERS
Write-Host "Scanning $($allFiles.Count) files (legacy)..."

# V1.2: windowed file records feed the new component scoring
$records = Get-SourceFileRecords -Root $ROOT -Folders $SCAN_FOLDERS -WeightEntries $sourceWeights
$records = Get-ActivityWindowBuckets -Records $records -Windows $activityWin
$curCount = @($records | Where-Object { $_.Window -eq 'current' }).Count
$prvCount = @($records | Where-Object { $_.Window -eq 'previous' }).Count
Write-Host "V1.2 records: $($records.Count) total (current=$curCount, previous=$prvCount)."

# Detect latest recap
$recapDir    = Join-Path (Join-Path $ROOT '01-inbox') 'copilot-activity'
$latestRecap = $null
if (Test-Path $recapDir) {
    $latest = Get-ChildItem $recapDir -Filter '*.md' -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -ne 'README.md' } |
              Sort-Object Name -Descending | Select-Object -First 1
    if ($latest) { $latestRecap = $latest.FullName.Replace($ROOT,'').TrimStart('\').TrimStart('/') }
}

# Score
$signals      = Measure-WorkstreamSignals $allFiles $workstreams $model
$signals      = Get-NormalizedScores $signals

# V1.2: component scoring (strategic / activity / override / trend / attention)
$activityMap  = Measure-WorkstreamActivityV2 -Records $records -Workstreams $workstreams -Model $model `
                    -DecayEnabled $activityWin.decay.enabled -HalfLifeDays $activityWin.decay.half_life_days
$attentionMap = Get-AttentionScores -Workstreams $workstreams -ActivityMap $activityMap `
                    -Overrides $overrides -Model $model -TrendRules $activityWin.trends

# Replace legacy normalized score with attention_score prior to override + categorization
Merge-AttentionIntoResults -Signals $signals -AttentionMap $attentionMap

$finalResults = Invoke-Overrides $workstreams $signals $overrides $model.categories

# Inject V1.2 component fields into every final result
foreach ($wsId in @($finalResults.Keys)) {
    if (-not $attentionMap.ContainsKey($wsId)) { continue }
    $a = $attentionMap[$wsId]
    foreach ($k in @($a.Keys)) {
        $finalResults[$wsId][$k] = $a[$k]
    }
}

# Prefer recent operational evidence over stable-context evidence in the displayed list.
# Legacy `evidence_files` remain populated with all mentions; we just reorder + trim.
$windowRank = @{ 'current' = 0; 'previous' = 1; 'older' = 2 }
foreach ($wsId in @($finalResults.Keys)) {
    if (-not $activityMap.ContainsKey($wsId)) { continue }
    $wsAct = $activityMap[$wsId]
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $ranked = [System.Collections.Generic.List[string]]::new()

    $sortedActivity = @($wsAct.activity_files | Sort-Object `
        @{ Expression = { $windowRank[$_.window] };      Ascending = $true },
        @{ Expression = { $_.weight };                   Descending = $true },
        @{ Expression = { $_.written };                  Descending = $true })
    foreach ($f in $sortedActivity) { if ($seen.Add($f.rel)) { $ranked.Add($f.rel) } }

    $sortedContext = @($wsAct.context_files | Sort-Object `
        @{ Expression = { $windowRank[$_.window] };      Ascending = $true },
        @{ Expression = { $_.weight };                   Descending = $true },
        @{ Expression = { $_.written };                  Descending = $true })
    foreach ($f in $sortedContext) { if ($seen.Add($f.rel)) { $ranked.Add($f.rel) } }

    if ($ranked.Count -gt 0) {
        $newList = [System.Collections.Generic.List[string]]::new()
        foreach ($rel in ($ranked | Select-Object -First 8)) { $newList.Add($rel) }
        $finalResults[$wsId].evidence_files = $newList
    }
}

# Ensure output directory exists
if (-not (Test-Path $GEN)) { New-Item -ItemType Directory -Path $GEN -Force | Out-Null }

$meta = @{ generated = (Get-Date -Format 'yyyy-MM-dd HH:mm') }

# Write markdown
$md = Build-Dashboard $workstreams $finalResults $model $allFiles $latestRecap
[System.IO.File]::WriteAllText($OUT_MD, $md, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_MD.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# Write JSON
$json = Build-Json $finalResults $meta
[System.IO.File]::WriteAllText($OUT_JSON, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# --- V1.3 Trends artifacts ---
$generatedIso = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
$trendsMd   = Build-TrendsMarkdown -Workstreams $workstreams -AttentionMap $attentionMap -Windows $activityWin -NowStamp $meta.generated
$trendsJson = Build-TrendsJson     -Workstreams $workstreams -AttentionMap $attentionMap -Windows $activityWin -GeneratedIso $generatedIso
[System.IO.File]::WriteAllText($OUT_TRENDS_MD,   $trendsMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_TRENDS_JSON, $trendsJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_TRENDS_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_TRENDS_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# --- V1.6 Decision Registry (must run before the briefing so it can consume it) ---
$decisions       = @(Get-DecisionRegistry -Records $records -Workstreams $workstreams -Model $model -OwnershipMap $ownershipMap)

# --- V1.7 Risk Register (must run before the briefing so it can consume it) ---
$risks         = @(Get-RiskRegister -Records $records -Workstreams $workstreams -Model $model -OwnershipMap $ownershipMap)

# --- V4.0 Phase 4: Daily delta + rolling snapshot -------------------------
# Must run AFTER both registries finalize and BEFORE the JSON emitters so the
# `delta` object lands on every entry. Persists today's snapshot + INDEX and
# trims files older than 30 days.
$deltaResult = Apply-DailyDelta -Decisions $decisions -Risks $risks -Now (Get-Date)
$snapshotPath = Write-DailySnapshot -TodayIso ((Get-Date).ToString('yyyy-MM-dd')) -Items @($deltaResult.snapshots) -DeltaSummary $deltaResult.delta -GeneratedIso $generatedIso
Write-Host "Written: $($snapshotPath.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green
Write-Host ("Daily delta: +{0} added / {1} changed / {2} removed / {3} stale (vs {4})" -f `
    @($deltaResult.delta.added).Count, `
    @($deltaResult.delta.changed).Count, `
    @($deltaResult.delta.removed).Count, `
    @($deltaResult.delta.stale).Count, `
    $deltaResult.priorDate) -ForegroundColor Yellow
$script:MAT_DAILY_DELTA = $deltaResult.delta
$script:MAT_DAILY_DELTA_PRIOR_DATE = $deltaResult.priorDate

# --- V4.0 Phase 5: Context linking (source-paragraph summary + actors) ----
# Enriches every decision + risk entry with contextSummary + contextMetadata
# by reading each entry's primary source file. Deterministic, no LLM.
$contextResult = Apply-ContextLinking -Decisions $decisions -Risks $risks -RootPath $ROOT -Model $model
Write-Host ("Context linking: enriched {0} entries; {1} carry stakeholder actors" -f `
    $contextResult.enrichedCount, $contextResult.actorHits) -ForegroundColor Yellow

# --- V4.0 Sprint 15: Why-it-matters extraction ----------------------------
# 4-tier ladder producing a single-sentence impact statement per entry.
# Runs AFTER context linking so the extractor has the source-paragraph excerpt
# available, and BEFORE the status ladder + priority score so downstream can
# key off whyItMattersConfidence.
$whyStats = Apply-WhyItMatters -Decisions $decisions -Risks $risks
Write-Host ("Why-it-matters: T1={0} / T2={1} / T3={2} / T4={3} / none={4} (high-confidence: {5}/{6})" -f `
    $whyStats.tier1, $whyStats.tier2, $whyStats.tier3, $whyStats.tier4, $whyStats.none, `
    $whyStats.highConfidence, $whyStats.total) -ForegroundColor Yellow

# --- V4.0 Phase 1c: Deterministic status ladder ---------------------------
# Populates matryoshkaStatus + matryoshkaStatusReason on every entry using the
# canonical Get-MatryoshkaStatus rules. Runs AFTER context linking so the
# context_summary blocker-keyword check has real text to scan.
$statusCounts = Apply-MatryoshkaStatus -Decisions $decisions -Risks $risks -Now (Get-Date)
Write-Host ("Matryoshka status ladder: {0} red / {1} amber / {2} green" -f `
    $statusCounts.red, $statusCounts.amber, $statusCounts.green) -ForegroundColor Yellow

# --- V4.0 Sprint 13a: Focus signals (engaged / attentionRequired / awaitingOthers) ---
# Deterministic canonical signal dimensions derived from Phase 1c/2/3/4/5/7 fields.
# Runs AFTER status ladder so signals can consume matryoshkaStatus directly.
$focusCounts = Apply-FocusSignals -Decisions $decisions -Risks $risks -Now (Get-Date)
Write-Host ("Focus signals: {0} engaged / {1} attentionRequired / {2} awaitingOthers (of {3})" -f `
    $focusCounts.engaged, $focusCounts.attentionRequired, $focusCounts.awaitingOthers, $focusCounts.total) -ForegroundColor Yellow

# --- V4.0 Sprint 13b: Priority score ---------------------------------------
# Deterministic weighted-sum ranking (impact / ownership / deadline / status /
# engagement) stamped on every decision + risk. Consumes Phase 1c + Sprint 13a.
$priorityStats = Apply-PriorityScore -Decisions $decisions -Risks $risks -Now (Get-Date)
Write-Host ("Priority score: min={0} / mean={1} / max={2} across {3} items" -f `
    $priorityStats.min, $priorityStats.mean, $priorityStats.max, $priorityStats.count) -ForegroundColor Yellow

# --- V1.6 Decision Registry JSON/MD emit ---
$decRegMd        = Build-DecisionRegistryMarkdown -Decisions $decisions -NowStamp $meta.generated
$decRegJson      = Build-DecisionRegistryJson     -Decisions $decisions -GeneratedIso $generatedIso
[System.IO.File]::WriteAllText($OUT_DECREG_MD,   $decRegMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_DECREG_JSON, $decRegJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_DECREG_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_DECREG_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# --- V1.7 Risk Register JSON/MD emit ---
$riskRegMd     = Build-RiskRegisterMarkdown -Risks $risks -NowStamp $meta.generated
$riskRegJson   = Build-RiskRegisterJson     -Risks $risks -GeneratedIso $generatedIso
[System.IO.File]::WriteAllText($OUT_RISKREG_MD,   $riskRegMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_RISKREG_JSON, $riskRegJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_RISKREG_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_RISKREG_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# --- V2.0 David Brain: workstream health + priority inbox ---
$healthMap = Get-WorkstreamHealth -FinalResults $finalResults -Decisions $decisions -Risks $risks
foreach ($wsId in @($finalResults.Keys)) {
    if ($healthMap.ContainsKey($wsId)) {
        $finalResults[$wsId].health = $healthMap[$wsId]
    }
}

# Rewrite current-focus.json/.md now that finalResults carries health
$md = Build-Dashboard $workstreams $finalResults $model $allFiles $latestRecap
[System.IO.File]::WriteAllText($OUT_MD, $md, (New-Object System.Text.UTF8Encoding($false)))
$json = Build-Json $finalResults $meta
[System.IO.File]::WriteAllText($OUT_JSON, $json, (New-Object System.Text.UTF8Encoding($false)))

# --- V3.0 Adaptive Intelligence: execution insights + personalized inbox ---
$insights     = Get-ExecutionInsights -Decisions $decisions -Risks $risks -Now (Get-Date) -OverloadThreshold $preferences.penalties.overloadedOwnerThreshold
$insightsMd   = Build-ExecutionInsightsMarkdown -Insights $insights -NowStamp $meta.generated
$insightsJson = Build-ExecutionInsightsJson     -Insights $insights -GeneratedIso $generatedIso
[System.IO.File]::WriteAllText($OUT_INSIGHTS_MD,   $insightsMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_INSIGHTS_JSON, $insightsJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_INSIGHTS_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_INSIGHTS_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

$inboxItems = @(Get-DavidInbox -Decisions $decisions -Risks $risks -Preferences $preferences -Insights $insights)
$inboxMd    = Build-DavidInboxMarkdown -Items $inboxItems -NowStamp $meta.generated -P1Cap 5 -P2Cap 10 -P3Cap 10
$inboxJson  = Build-DavidInboxJson     -Items $inboxItems -GeneratedIso $generatedIso -P1Cap 5 -P2Cap 10 -P3Cap 10
[System.IO.File]::WriteAllText($OUT_INBOX_MD,   $inboxMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_INBOX_JSON, $inboxJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_INBOX_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_INBOX_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# --- V1.4 Morning briefing (enriched with decision registry in V1.6) ---
$briefMd   = Build-MorningBriefingMarkdown -FinalResults $finalResults -AttentionMap $attentionMap -Records $records -Windows $activityWin -DecisionRegistry $decisions -RiskRegister $risks -NowStamp $meta.generated
$briefJson = Build-MorningBriefingJson     -FinalResults $finalResults -AttentionMap $attentionMap -Records $records -Windows $activityWin -DecisionRegistry $decisions -RiskRegister $risks -GeneratedIso $generatedIso
[System.IO.File]::WriteAllText($OUT_BRIEF_MD,   $briefMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_BRIEF_JSON, $briefJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_BRIEF_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_BRIEF_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# --- V4.0 Phase 1: quality-gate validation pass -----------------------------
# Runs every non-stale decision + risk through Test-MatryoshkaItem. Writes
# 00-context/generated/rejected-items.{md,json} showing where the current V3.x
# corpus does NOT yet satisfy the V4.0 canonical contract. Warnings only - the
# generator still emits V3.x artifacts. This lets us see the migration gap
# before Phase 1's fail-closed emitters land.

$rejectionRecords = [System.Collections.Generic.List[hashtable]]::new()
$acceptedCount = 0
$candidateCount = 0
$fieldFailures = @{}

# V4.0 Sprint 16: collect every candidate (accepted + rejected) so we can
# emit matryoshka-items.json as the canonical system-of-record output.
$script:MAT_CANONICAL_ITEMS = [System.Collections.Generic.List[object]]::new()

# V4.0 Sprint 15: pre-compute why_it_matters fingerprint counts so
# Test-MatryoshkaItem can flag duplicates (validator v2 new check).
$script:MAT_WHY_FINGERPRINTS = @{}
foreach ($kind in @('decision','risk')) {
    $source = if ($kind -eq 'decision') { $decisions } else { $risks }
    foreach ($entry in $source) {
        if ($entry.ContainsKey('stale') -and $entry.stale) { continue }
        if ($entry.status -eq 'closed') { continue }
        $why = ''
        if ($entry.ContainsKey('whyItMatters') -and $entry.whyItMatters) { $why = [string]$entry.whyItMatters }
        elseif ($entry.impact)                                            { $why = [string]$entry.impact }
        $fp = $why.Trim().ToLowerInvariant()
        if ($fp) {
            if ($script:MAT_WHY_FINGERPRINTS.ContainsKey($fp)) {
                $script:MAT_WHY_FINGERPRINTS[$fp] = [int]$script:MAT_WHY_FINGERPRINTS[$fp] + 1
            } else {
                $script:MAT_WHY_FINGERPRINTS[$fp] = 1
            }
        }
    }
}

foreach ($kind in @('decision','risk')) {
    $source = if ($kind -eq 'decision') { $decisions } else { $risks }
    foreach ($entry in $source) {
        # Only validate live (non-stale, non-closed) items - stale items are
        # already excluded from surfacing so their V4 gaps aren't user-facing.
        if ($entry.ContainsKey('stale') -and $entry.stale) { continue }
        if ($entry.status -eq 'closed') { continue }
        $candidateCount++
        $candidate = ConvertTo-MatryoshkaCandidate -Kind $kind -Entry $entry
        $result = Test-MatryoshkaItem -Candidate $candidate

        # V4.0 Sprint 16: collect the canonical item + validation outcome +
        # enriched V4 fields for the matryoshka-items.json emit below.
        $canonical = [ordered]@{
            id                     = [string]$candidate.id
            type                   = [string]$candidate.type
            title                  = [string]$candidate.title
            owner                  = [string]$candidate.owner
            suggested_owner        = if ($candidate.ContainsKey('suggested_owner')) { [string]$candidate.suggested_owner } else { '' }
            owner_confidence       = [string]$candidate.owner_confidence
            why_it_matters         = [string]$candidate.why_it_matters
            why_it_matters_confidence = if ($entry.ContainsKey('whyItMattersConfidence')) { [double]$entry.whyItMattersConfidence } else { 0.0 }
            why_it_matters_source     = if ($entry.ContainsKey('whyItMattersSource'))     { [string]$entry.whyItMattersSource }     else { 'none' }
            next_action            = [string]$candidate.next_action
            action_class           = [string]$candidate.action_class
            workstream             = [string]$candidate.workstream
            status                 = [string]$candidate.status
            status_reason          = [string]$candidate.status_reason
            aging_days             = [int]$candidate.aging_days
            stale                  = [bool]$candidate.stale
            source                 = [string]$candidate.source
            context_summary        = [string]$candidate.context_summary
            context_metadata       = if ($entry.ContainsKey('contextMetadata') -and $entry.contextMetadata) { $entry.contextMetadata } else { [ordered]@{ lastMention=''; lastActivity=''; actors=@(); primarySource='' } }
            confidence_score       = [double]$candidate.confidence_score
            merged_from            = @($candidate.merged_from)
            first_seen             = [string]$candidate.first_seen
            last_updated           = [string]$candidate.last_updated
            focus_signals          = if ($entry.ContainsKey('focusSignals') -and $entry.focusSignals) { $entry.focusSignals } else { [ordered]@{ engaged=$false; attentionRequired=$false; awaitingOthers=$false; reasons=[ordered]@{ engaged=''; attentionRequired=''; awaitingOthers='' } } }
            priority_score         = if ($entry.ContainsKey('priorityScore'))   { [int]$entry.priorityScore }    else { 0 }
            priority_reason        = if ($entry.ContainsKey('priorityReason'))  { [string]$entry.priorityReason } else { '' }
            priority_reason_bullets = if ($entry.ContainsKey('priorityReasonBullets') -and $entry.priorityReasonBullets) { @($entry.priorityReasonBullets) } else { @() }
            priority_reason_debug  = if ($entry.ContainsKey('priorityReasonDebug')) { [string]$entry.priorityReasonDebug } else { '' }
            priority_factors       = if ($entry.ContainsKey('priorityFactors') -and $entry.priorityFactors) { $entry.priorityFactors } else { [ordered]@{ impact=0.0; ownership=0.0; deadline=0.0; status=0.0; engagement=0.0 } }
            delta                  = if ($entry.ContainsKey('delta') -and $entry.delta) { $entry.delta } else { [ordered]@{ daysSinceLastTouched=0; updatedSinceYesterday=$true; changeSummary='first appearance' } }
            validated              = [bool]$result.ok
            validation_errors      = if ($result.ok) { @() } else { @($result.errors | ForEach-Object { [ordered]@{ field=[string]$_.field; reason=[string]$_.reason } }) }
        }
        # V4.0 Sprint 16: preserve type-specific fields the canonical schema doesn't yet name
        # (severity for risks, decision deadline for decisions) so downstream consumers don't
        # need a fallback to the V3 registries just to render one field.
        if ($kind -eq 'risk') {
            $canonical.severity = if ($entry.severity) { [string]$entry.severity } else { '' }
            $canonical.trend    = if ($entry.trend)    { [string]$entry.trend }    else { '' }
        } else {
            $canonical.decision_deadline = if ($entry.decisionDeadline) { [string]$entry.decisionDeadline } else { '' }
            $canonical.decision_status   = if ($entry.decisionStatus)   { [string]$entry.decisionStatus }   else { '' }
        }
        [void]$script:MAT_CANONICAL_ITEMS.Add($canonical)

        if ($result.ok) {
            $acceptedCount++
            continue
        }
        foreach ($err in $result.errors) {
            $key = [string]$err.field
            if (-not $fieldFailures.ContainsKey($key)) { $fieldFailures[$key] = 0 }
            $fieldFailures[$key] = [int]$fieldFailures[$key] + 1
        }
        $rejectionRecords.Add(@{
            itemId     = $candidate.id
            itemKind   = $kind
            title      = $candidate.title
            workstream = $candidate.workstream
            owner      = $candidate.owner
            errors     = @($result.errors)
        })
    }
}

$byFieldOrdered = [ordered]@{}
foreach ($k in ($fieldFailures.Keys | Sort-Object { -[int]$fieldFailures[$_] })) {
    $byFieldOrdered[$k] = [int]$fieldFailures[$k]
}

$rejectedReport = [ordered]@{
    generated = $generatedIso
    generator = 'scripts/generate-current-focus.ps1'
    version   = 'V4.0-phase1-validator'
    totals    = [ordered]@{
        candidates = $candidateCount
        accepted   = $acceptedCount
        rejected   = $rejectionRecords.Count
        byField    = $byFieldOrdered
    }
    rejections = @($rejectionRecords | ForEach-Object {
        [ordered]@{
            itemId     = $_.itemId
            itemKind   = $_.itemKind
            title      = $_.title
            workstream = $_.workstream
            owner      = $_.owner
            errors     = @($_.errors | ForEach-Object {
                [ordered]@{
                    itemId = $_.itemId
                    field  = $_.field
                    reason = $_.reason
                }
            })
        }
    })
}
$rejectedJson = $rejectedReport | ConvertTo-Json -Depth 8

$rejectedMdLines = [System.Collections.Generic.List[string]]::new()
$rejectedMdLines.Add('# V4.0 Phase 1 - Rejected Items') | Out-Null
$rejectedMdLines.Add('') | Out-Null
$rejectedMdLines.Add("_Generated: $($meta.generated)_") | Out-Null
$rejectedMdLines.Add('') | Out-Null
$rejectedMdLines.Add("Validated **$candidateCount** live decision/risk candidates against the V4.0 canonical schema. **$acceptedCount** pass; **$($rejectionRecords.Count)** need fixing before the V4.0 fail-closed emitters land.") | Out-Null
$rejectedMdLines.Add('') | Out-Null
$rejectedMdLines.Add('## Failure counts by field') | Out-Null
$rejectedMdLines.Add('') | Out-Null
if ($byFieldOrdered.Count -gt 0) {
    $rejectedMdLines.Add('| Field | Count |') | Out-Null
    $rejectedMdLines.Add('|---|---:|') | Out-Null
    foreach ($k in $byFieldOrdered.Keys) {
        $rejectedMdLines.Add("| $k | $($byFieldOrdered[$k]) |") | Out-Null
    }
} else {
    $rejectedMdLines.Add('_No failures._') | Out-Null
}
$rejectedMdLines.Add('') | Out-Null
$rejectedMdLines.Add('## Rejections (top 30)') | Out-Null
$rejectedMdLines.Add('') | Out-Null
$topRejections = @($rejectionRecords | Select-Object -First 30)
if ($topRejections.Count -eq 0) {
    $rejectedMdLines.Add('_All candidates passed._') | Out-Null
} else {
    foreach ($r in $topRejections) {
        $rejectedMdLines.Add("### $($r.itemKind) $($r.itemId) - $($r.workstream)") | Out-Null
        $rejectedMdLines.Add('') | Out-Null
        $rejectedMdLines.Add("- **Title:** $($r.title)") | Out-Null
        $rejectedMdLines.Add("- **Owner:** $($r.owner)") | Out-Null
        $rejectedMdLines.Add('- **Errors:**') | Out-Null
        foreach ($e in $r.errors) {
            $rejectedMdLines.Add("  - `$($e.field)`: $($e.reason)") | Out-Null
        }
        $rejectedMdLines.Add('') | Out-Null
    }
}
$rejectedMd = ($rejectedMdLines -join "`n")

[System.IO.File]::WriteAllText($OUT_REJECTED_MD,   $rejectedMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_REJECTED_JSON, $rejectedJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_REJECTED_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_REJECTED_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green
Write-Host "V4.0 validation: $acceptedCount accepted, $($rejectionRecords.Count) rejected of $candidateCount live candidates" -ForegroundColor Yellow

# --- V4.0 Sprint 16: canonical system-of-record emit ----------------------
# matryoshka-items.json becomes the primary consumption contract. Every live
# item is emitted (validated OR not) with the `validated` flag telling
# downstream consumers whether it passed all quality gates. The weekly-report
# generator + future dashboard code can prefer this file over the V3 registry
# emitters - reducing drift as those older artifacts get phased out.
$canonicalItems  = @($script:MAT_CANONICAL_ITEMS)
$validatedItems  = @($canonicalItems | Where-Object { $_.validated })
$rejectedItems   = @($canonicalItems | Where-Object { -not $_.validated })
$byActionClass   = @{}
foreach ($it in $canonicalItems) {
    $ac = if ($it.action_class) { [string]$it.action_class } else { '(none)' }
    if (-not $byActionClass.ContainsKey($ac)) { $byActionClass[$ac] = 0 }
    $byActionClass[$ac] += 1
}
$byActionClassOrdered = [ordered]@{}
foreach ($k in ($byActionClass.Keys | Sort-Object)) { $byActionClassOrdered[$k] = [int]$byActionClass[$k] }

$itemsReport = [ordered]@{
    generated = $generatedIso
    generator = 'scripts/generate-current-focus.ps1'
    version   = 'V4.0-sprint16'
    schema    = 'ui/src/lib/matryoshka-item.ts (MatryoshkaItem)'
    totals    = [ordered]@{
        total         = $canonicalItems.Count
        validated     = $validatedItems.Count
        rejected      = $rejectedItems.Count
        byType        = [ordered]@{
            decision = @($canonicalItems | Where-Object { $_.type -eq 'decision' }).Count
            risk     = @($canonicalItems | Where-Object { $_.type -eq 'risk' }).Count
        }
        byActionClass = $byActionClassOrdered
        byStatus      = [ordered]@{
            red   = @($canonicalItems | Where-Object { $_.status -eq 'red' }).Count
            amber = @($canonicalItems | Where-Object { $_.status -eq 'amber' }).Count
            green = @($canonicalItems | Where-Object { $_.status -eq 'green' }).Count
        }
    }
    items = @($canonicalItems | Sort-Object { -[int]$_.priority_score })
}
$itemsJson = $itemsReport | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($OUT_ITEMS_JSON, $itemsJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_ITEMS_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green
Write-Host ("Canonical items: {0} total ({1} validated / {2} rejected)" -f $canonicalItems.Count, $validatedItems.Count, $rejectedItems.Count) -ForegroundColor Yellow

# V4.0 Sprint 19: report Corpus title-normalization drops for the pipeline log.
$titleDrops = @($script:MAT_TITLE_DROPS)
if ($titleDrops.Count -gt 0) {
    $decDrops  = @($titleDrops | Where-Object { $_.kind -eq 'decision' }).Count
    $riskDrops = @($titleDrops | Where-Object { $_.kind -eq 'risk' }).Count
    $topReasons = @($titleDrops | Group-Object { $_.reason } | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name) ($($_.Count))" })
    Write-Host ("Title normalization: dropped {0} decision + {1} risk candidate(s); top: {2}" -f $decDrops, $riskDrops, ($topReasons -join '; ')) -ForegroundColor Yellow
} else {
    Write-Host "Title normalization: 0 candidates dropped" -ForegroundColor Yellow
}

# Summary to console
Write-Host ""
Write-Host "Category summary:" -ForegroundColor Yellow
$finalResults.Values | Sort-Object { $_.score } -Descending | ForEach-Object {
    $flag = if ($_.override_applied) { ' [override]' } else { '' }
    Write-Host ("  [{0}] {1}{2}  (score: {3})" -f $_.category.PadRight(10), $_.workstream.name, $flag, $_.score)
}
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host ""
