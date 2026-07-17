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
    return @($decisions.Values | Sort-Object `
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
        }
        decisions   = @($items)
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
    }

    $severityRank = @{ 'High' = 0; 'Medium' = 1; 'Low' = 2 }
    return @($risks.Values | Sort-Object `
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
        }
        risks       = @($items)
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
        $items.Add((New-InboxItem -Kind 'decision' -Entry $d))
    }
    foreach ($r in $Risks) {
        if ($r.status -eq 'closed') { continue }
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
        }
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
$decRegMd        = Build-DecisionRegistryMarkdown -Decisions $decisions -NowStamp $meta.generated
$decRegJson      = Build-DecisionRegistryJson     -Decisions $decisions -GeneratedIso $generatedIso
[System.IO.File]::WriteAllText($OUT_DECREG_MD,   $decRegMd,   (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($OUT_DECREG_JSON, $decRegJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Written: $($OUT_DECREG_MD.Replace($ROOT,'').TrimStart('\'))"   -ForegroundColor Green
Write-Host "Written: $($OUT_DECREG_JSON.Replace($ROOT,'').TrimStart('\'))" -ForegroundColor Green

# --- V1.7 Risk Register (must run before the briefing so it can consume it) ---
$risks         = @(Get-RiskRegister -Records $records -Workstreams $workstreams -Model $model -OwnershipMap $ownershipMap)
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
