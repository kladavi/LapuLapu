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

# Control files are inputs to the generator, not evidence — exclude to prevent
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
        }
    }
    $output = [ordered]@{
        generated   = $meta.generated
        generator   = 'scripts/generate-current-focus.ps1'
        version     = 'V1.2'
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
            $actLine = if ($act -is [System.Collections.IDictionary]) { "P$($act.priority) $($act.verb) by $($act.dueBy)" } else { '' }
            "- **$wsName** - $($_.severity) severity, aging $($_.agingDays) days, $ownerText`n  - $($_.title) [$($_.riskId)]`n  - $actLine"
        }) -join "`n"
    } else { '_No rising risks in the current window._' }

    $topRisksBlock = if ($topRisks.Count -gt 0) {
        ($topRisks | ForEach-Object {
            $wsName = if ($_.workstream) { $_.workstream } else { '(no workstream)' }
            $ownerText = if ($_.owner) { "owner: $($_.owner)" } else { 'owner: unassigned' }
            $act = $_.recommendedAction
            $actLine = if ($act -is [System.Collections.IDictionary]) { "P$($act.priority) $($act.verb) by $($act.dueBy)" } else { '' }
            "- **$wsName** - $($_.severity) severity, $($_.trend) trend, aging $($_.agingDays) days, $ownerText`n  - $($_.title) [$($_.riskId)]`n  - $actLine"
        }) -join "`n"
    } else { '_No open risks in the registry._' }

    $decisionBlock = if ($pendingDecisions.Count -gt 0) {
        ($pendingDecisions | ForEach-Object {
            $wsName = if ($_.workstream) { $_.workstream } else { '(no workstream)' }
            $ownerText = if ($_.owner) { "owner: $($_.owner)" } else { 'owner: unassigned' }
            $act = $_.recommendedFollowUp
            $actLine = if ($act -is [System.Collections.IDictionary]) { "P$($act.priority) $($act.verb) by $($act.dueBy)" } else { '' }
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
        version                       = 'V1.8'
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
        Verbs: Track (fresh), Confirm (aging 7+), Escalate (14+), Archive (closed).
    #>
    param([hashtable] $Entry, [datetime] $Now)

    $rawTitle = if ($Entry.title) { [string]$Entry.title } else { '' }
    $subject  = if ($rawTitle.Length -gt 100) { $rawTitle.Substring(0, 97) + '...' } else { $rawTitle }
    $owner    = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }

    if ($Entry.status -eq 'closed') {
        return [ordered]@{
            priority     = 5
            verb         = 'Archive'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.AddDays(30).ToString('yyyy-MM-dd')
            rationale    = 'Decision closed; archive after next reporting cycle.'
        }
    }
    if ($Entry.decisionAgeDays -ge 14) {
        return [ordered]@{
            priority     = 1
            verb         = 'Escalate'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.ToString('yyyy-MM-dd')
            rationale    = 'Pending 14+ days without resolution - escalate today.'
        }
    }
    if ($Entry.decisionAgeDays -ge 7) {
        return [ordered]@{
            priority     = 2
            verb         = 'Confirm'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Aging 7+ days - confirm status and communicate resolution this week.'
        }
    }
    return [ordered]@{
        priority     = 4
        verb         = 'Track'
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

    # Line-level decision phrase capture (bullet or heading prefix tolerated)
    $keywordAlt = ($script:DECISION_KEYWORDS | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $decisionRegex = '(?im)^\s*(?:[-*>]\s+)?(?:\*\*)?(' + $keywordAlt + ')(?:\*\*)?\s*[:\-]\s*(.+?)\s*$'

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
            if (-not $m.Success) { continue }

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

            # Prefer H2 heading as title when the file uses the `## Dxxx — Title` convention.
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
                    escalationPath      = [System.Collections.Generic.List[string]]::new()
                    stakeholders        = [System.Collections.Generic.List[string]]::new()
                    workstream          = $workstream
                    sourceFiles         = [System.Collections.Generic.List[string]]::new()
                    decisionAgeDays     = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
                    recencyDays         = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
                    decisionSummary     = $summary
                    recommendedFollowUp = $null
                    _detectedOn         = $rec.LastWriteTime
                    _lastSeenOn         = $rec.LastWriteTime
                }
            }

            $entry = $decisions[$decisionId]
            if (-not $entry.sourceFiles.Contains($rec.RelPath)) { $entry.sourceFiles.Add($rec.RelPath) }
            if (-not $entry.owner      -and $owner)      { $entry.owner      = $owner }
            if (-not $entry.workstream -and $workstream) { $entry.workstream = $workstream }

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
        # V1.8 owner resolution + confidence
        $mapEntry = $null
        if ($e.workstream -and $nameToId.ContainsKey($e.workstream)) {
            $wsId = $nameToId[$e.workstream]
            if ($OwnershipMap.ContainsKey($wsId)) { $mapEntry = $OwnershipMap[$wsId] }
        }
        if ($mapEntry -and $mapEntry.owner) {
            $e.owner           = $mapEntry.owner
            $e.ownerConfidence = 'workstream-map'
            foreach ($n in $mapEntry.escalationPath) {
                if (-not $e.escalationPath.Contains($n)) { $e.escalationPath.Add($n) }
            }
            foreach ($n in $mapEntry.stakeholders) {
                if (-not $e.stakeholders.Contains($n)) { $e.stakeholders.Add($n) }
            }
        } elseif ($e.owner) {
            $e.ownerConfidence = 'name-proximity'
        } else {
            $e.ownerConfidence = 'unknown'
        }

        # V1.8 structured action
        $e.recommendedFollowUp = Get-StructuredDecisionAction -Entry $e -Now $now
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
            "P$($act.priority) - $($act.verb): $($act.subject) (owner: $($act.targetOwner), by $($act.dueBy))"
        } else {
            "$act"
        }

        return @"
### $($e.decisionId) - $($e.title)

- Workstream: **$wsText**
- Owner: **$ownerText** _(confidence: $($e.ownerConfidence))_
- Escalation Path: $escalationText
- Stakeholders: $stakeText
- Status: **$($e.status)**
- First seen: **$($e.firstSeenDate)** ($($e.decisionAgeDays) days ago)
- Last seen: **$($e.lastSeenDate)** ($($e.recencyDays) days ago)
- Follow-up: $actionText
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
            owner               = $e.owner
            ownerConfidence     = $e.ownerConfidence
            escalationPath      = @($e.escalationPath)
            stakeholders        = @($e.stakeholders)
            workstream          = $e.workstream
            sourceFiles         = @($e.sourceFiles)
            decisionAgeDays     = $e.decisionAgeDays
            recencyDays         = $e.recencyDays
            decisionSummary     = $e.decisionSummary
            recommendedFollowUp = $e.recommendedFollowUp
        }
    }

    $openCount   = @($Decisions | Where-Object { $_.status -ne 'closed' }).Count
    $closedCount = @($Decisions | Where-Object { $_.status -eq 'closed' }).Count
    $ownedCount  = @($Decisions | Where-Object { $_.ownerConfidence -eq 'workstream-map' }).Count

    $out = [ordered]@{
        generated   = $GeneratedIso
        generator   = 'scripts/generate-current-focus.ps1'
        version     = 'V1.8'
        totals      = [ordered]@{
            total              = $Decisions.Count
            open               = $openCount
            closed             = $closedCount
            authorativelyOwned = $ownedCount
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

function Get-StructuredRiskAction {
    <#
        Converts the ad-hoc `recommendedAction` string into a structured object
        with priority (1-5), verb, subject, targetOwner, dueBy (ISO date), and
        a short rationale. Consumers (dashboard, briefing, action engine) can
        render or execute against this shape.
    #>
    param([hashtable] $Entry, [datetime] $Now)

    $rawTitle = if ($Entry.title) { [string]$Entry.title } else { '' }
    $subject  = if ($rawTitle.Length -gt 100) { $rawTitle.Substring(0, 97) + '...' } else { $rawTitle }
    $owner    = if ($Entry.owner) { [string]$Entry.owner } else { 'unassigned' }

    if ($Entry.status -eq 'closed') {
        return [ordered]@{
            priority     = 5
            verb         = 'Archive'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.AddDays(30).ToString('yyyy-MM-dd')
            rationale    = 'Risk marked closed; archive after next reporting cycle.'
        }
    }
    if ($Entry.severity -eq 'High') {
        return [ordered]@{
            priority     = 1
            verb         = 'Escalate'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = $Now.ToString('yyyy-MM-dd')
            rationale    = 'High severity - notify workstream owner today.'
        }
    }
    if ($Entry.trend -eq 'increasing' -and $Entry.agingDays -ge 7) {
        return [ordered]@{
            priority     = 2
            verb         = 'Investigate'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Rising signal aged 7+ days - confirm mitigation this week.'
        }
    }
    if ($Entry.agingDays -ge 14) {
        return [ordered]@{
            priority     = 2
            verb         = 'Escalate'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Unresolved 14+ days - escalate this week.'
        }
    }
    if ($Entry.agingDays -ge 7) {
        return [ordered]@{
            priority     = 3
            verb         = 'Review'
            subject      = $subject
            targetOwner  = $owner
            dueBy        = Get-EndOfWeekDate $Now
            rationale    = 'Aging 7+ days - review mitigation plan this week.'
        }
    }
    return [ordered]@{
        priority     = 4
        verb         = 'Monitor'
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
                    escalationPath      = [System.Collections.Generic.List[string]]::new()
                    stakeholders        = [System.Collections.Generic.List[string]]::new()
                    severity            = $severity
                    status              = $status
                    trend               = 'stable'
                    sourceFiles         = [System.Collections.Generic.List[string]]::new()
                    agingDays           = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
                    recencyDays         = [int][Math]::Max(0, ($now - $rec.LastWriteTime).TotalDays)
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

        # V1.8 owner resolution + confidence
        $mapEntry = $null
        if ($e.workstream -and $nameToId.ContainsKey($e.workstream)) {
            $wsId = $nameToId[$e.workstream]
            if ($OwnershipMap.ContainsKey($wsId)) { $mapEntry = $OwnershipMap[$wsId] }
        }
        if ($mapEntry -and $mapEntry.owner) {
            $e.owner           = $mapEntry.owner
            $e.ownerConfidence = 'workstream-map'
            foreach ($n in $mapEntry.escalationPath) {
                if (-not $e.escalationPath.Contains($n)) { $e.escalationPath.Add($n) }
            }
            foreach ($n in $mapEntry.stakeholders) {
                if (-not $e.stakeholders.Contains($n)) { $e.stakeholders.Add($n) }
            }
        } elseif ($e.owner) {
            $e.ownerConfidence = 'name-proximity'
        } else {
            $e.ownerConfidence = 'unknown'
        }

        # V1.8 structured action (replaces canned string)
        $e.recommendedAction = Get-StructuredRiskAction -Entry $e -Now $now
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
            "P$($act.priority) - $($act.verb): $($act.subject) (owner: $($act.targetOwner), by $($act.dueBy))"
        } else {
            "$act"
        }

        return @"
### $($e.riskId) - $($e.title)

- Workstream: **$wsText**
- Owner: **$ownerText** _(confidence: $($e.ownerConfidence))_
- Escalation Path: $escalationText
- Stakeholders: $stakeText
- Severity: **$($e.severity)**
- Status: **$($e.status)**
- Trend: **$($e.trend)**
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
            recommendedAction = $e.recommendedAction
        }
    }

    $openCount   = @($Risks | Where-Object { $_.status -ne 'closed' }).Count
    $closedCount = @($Risks | Where-Object { $_.status -eq 'closed' }).Count
    $highCount   = @($Risks | Where-Object { $_.status -ne 'closed' -and $_.severity -eq 'High' }).Count
    $risingCount = @($Risks | Where-Object { $_.status -ne 'closed' -and $_.trend    -eq 'increasing' }).Count
    $ownedCount  = @($Risks | Where-Object { $_.ownerConfidence -eq 'workstream-map' }).Count

    $out = [ordered]@{
        generated   = $GeneratedIso
        generator   = 'scripts/generate-current-focus.ps1'
        version     = 'V1.8'
        totals      = [ordered]@{
            total          = $Risks.Count
            open           = $openCount
            closed         = $closedCount
            high           = $highCount
            rising         = $risingCount
            authorativelyOwned = $ownedCount
        }
        risks       = @($items)
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
