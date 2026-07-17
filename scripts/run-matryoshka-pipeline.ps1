#Requires -Version 7.0
<#
.SYNOPSIS
    Project Matryoshka - Automated Intake Pipeline runner.

.DESCRIPTION
    Detects the newest Copilot 14-day activity recap in
    01-inbox/copilot-activity/, compares it against
    00-context/automation-state.json, and if the recap is new:
      1. Regenerates every Current Focus artifact via
         scripts/generate-current-focus.ps1.
      2. Validates all generated JSON files.
      3. Updates 00-context/automation-state.json.
      4. Commits source + generated files to Git (local only).
    The script never pushes and never overwrites prior recaps.

.NOTES
    Target shell: PowerShell 7.6.3+ (pwsh).
    Path:  C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.3.0_x64__8wekyb3d8bbwe\pwsh.exe

    Idempotent: repeated runs with no new recap exit cleanly with exit code 0.
    Do NOT push in this script. Pushing is intentionally left to the operator.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# UTF-8 everywhere so generated files render arrow/emoji characters correctly.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

$RepoRoot     = 'C:\Users\kladavi\OneDrive - Manulife\Projects\LapuLapu'
Set-Location -LiteralPath $RepoRoot

$ActivityDir  = Join-Path $RepoRoot '01-inbox\copilot-activity'
$StateFile    = Join-Path $RepoRoot '00-context\automation-state.json'
$Generator    = Join-Path $RepoRoot 'scripts\generate-current-focus.ps1'

$GeneratedFiles = @(
    '00-context\generated\current-focus.json',
    '00-context\generated\current-focus.md',
    '00-context\generated\current-focus-trends.json',
    '00-context\generated\current-focus-trends.md',
    '00-context\generated\morning-briefing.json',
    '00-context\generated\morning-briefing.md'
)

function Write-Log {
    param([string] $Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "[$ts] $Message"
}

function Get-PwshPath {
    $preferred = 'C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.3.0_x64__8wekyb3d8bbwe\pwsh.exe'
    if (Test-Path -LiteralPath $preferred) { return $preferred }
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'pwsh (PowerShell 7+) not found. Install PowerShell 7 or update the path in run-matryoshka-pipeline.ps1.'
}

function Read-StateFile {
    param([string] $Path)
    $default = [ordered]@{
        lastProcessedActivityFile      = ''
        lastProcessedActivityHash      = ''
        lastProcessedCorpusSignature   = ''
        lastSuccessfulRun              = ''
        lastCommitHash                 = ''
        status                         = 'initialized'
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        ($default | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Path -Encoding UTF8
        return $default
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            ($default | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Path -Encoding UTF8
            return $default
        }
        $obj = $raw | ConvertFrom-Json -AsHashtable
        # Fill in any missing keys with defaults so downstream code can trust the shape.
        foreach ($k in $default.Keys) {
            if (-not $obj.ContainsKey($k)) { $obj[$k] = $default[$k] }
        }
        return $obj
    } catch {
        Write-Log "State file malformed; resetting to defaults. Reason: $($_.Exception.Message)"
        ($default | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Path -Encoding UTF8
        return $default
    }
}

function Save-StateFile {
    param([hashtable] $State, [string] $Path)
    ($State | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Path -Encoding UTF8
}

# --- V1.5 additions: logging + pipeline-health ---------------------------

$LogDir = Join-Path $RepoRoot 'logs'
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile    = Join-Path $LogDir ("matryoshka-pipeline-{0}.log" -f (Get-Date -Format 'yyyy-MM-dd'))
$HealthFile = Join-Path $RepoRoot '00-context\generated\pipeline-health.json'

function New-HealthObject {
    [ordered]@{
        lastRun                  = ''
        status                   = 'unknown'
        message                  = ''
        triggeredBy              = ''
        lastActivityFile         = ''
        lastActivityHash         = ''
        lastCorpusSignature      = ''
        currentFocusGenerated    = $false
        trendsGenerated          = $false
        morningBriefingGenerated = $false
        jsonValidated            = $false
        gitCommitted             = $false
        lastCommitHash           = ''
    }
}

function Save-HealthFile {
    param($Health, [string] $Path)
    $Health.lastRun = (Get-Date).ToString('s')
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    ($Health | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Path -Encoding UTF8
}

# --- V3.1 addition: corpus signature ------------------------------------------
# Compute a lightweight fingerprint of every corpus file the generator scans.
# Trigger fires when the fingerprint changes OR when a new 14-day recap arrives.
# We intentionally hash a manifest string (path|size|mtime) rather than every
# file's contents so it stays fast on large inboxes.

$CorpusScanFolders = @(
    '00-context',
    '01-inbox',
    (Join-Path '01-inbox' 'copilot-activity'),
    '02-work',
    (Join-Path '03-reporting' 'weekly'),
    'docs'
)
$CorpusExts = @('.md', '.txt', '.eml', '.yaml', '.yml')
# Generated artifacts must not participate in the signature or the pipeline
# would loop forever (its own outputs would look like new inputs).
$CorpusExcludeSubstrings = @(
    '00-context\generated',
    '00-context/generated',
    '00-context\automation-state.json',
    '00-context/automation-state.json'
)

function Get-CorpusSignature {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($folder in $CorpusScanFolders) {
        $abs = Join-Path $RepoRoot $folder
        if (-not (Test-Path -LiteralPath $abs)) { continue }
        Get-ChildItem -LiteralPath $abs -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $ext = $_.Extension.ToLowerInvariant()
                if ($CorpusExts -notcontains $ext) { return $false }
                foreach ($ex in $CorpusExcludeSubstrings) {
                    if ($_.FullName -like "*$ex*") { return $false }
                }
                return $true
            } |
            Sort-Object FullName |
            ForEach-Object {
                $rel = $_.FullName.Substring($RepoRoot.Length).TrimStart('\','/')
                [void]$sb.Append($rel)
                [void]$sb.Append('|')
                [void]$sb.Append($_.Length)
                [void]$sb.Append('|')
                [void]$sb.Append($_.LastWriteTimeUtc.Ticks)
                [void]$sb.Append("`n")
            }
    }
    if ($sb.Length -eq 0) { return '' }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $sha   = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
        return (-join ($hash | ForEach-Object { $_.ToString('x2') }))
    } finally { $sha.Dispose() }
}

# --- Locate newest recap ----------------------------------------------------

function Invoke-MatryoshkaPipeline {
    param($Health)

    Write-Log "Pipeline start. Repo: $RepoRoot"

    $state = Read-StateFile -Path $StateFile

    # --- Trigger 1: newest 14-day activity recap (optional) --------------------
    $recapChanged = $false
    $hash = ''
    $latest = $null
    if (Test-Path -LiteralPath $ActivityDir) {
        $latest = Get-ChildItem -LiteralPath $ActivityDir -File -Filter '*-14-day-activity.md' -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1
    }
    if ($latest) {
        Write-Log "Latest recap: $($latest.Name) (modified $($latest.LastWriteTime.ToString('s')))"
        $Health.lastActivityFile = $latest.Name
        # V4.0 Phase 8a: 0-byte guard - do NOT mark an empty recap as processed.
        # An empty file is treated as if no recap arrived at all: recap trigger stays
        # false, corpus-signature trigger can still fire if other files changed.
        if ($latest.Length -eq 0) {
            Write-Log "WARNING: latest recap '$($latest.Name)' is 0 bytes - not treating as new content."
            $Health.lastActivityHash = ''
        } else {
            $hash = (Get-FileHash -LiteralPath $latest.FullName -Algorithm SHA256).Hash
            $Health.lastActivityHash = $hash
            if ($state.lastProcessedActivityHash -ne $hash) {
                $recapChanged = $true
                Write-Log "Recap hash changed. Previous: '$($state.lastProcessedActivityHash)'  new: '$hash'"
            }
        }
    } else {
        Write-Log 'No 14-day activity recap found.'
    }

    # --- Trigger 2 (V3.1): corpus signature ------------------------------------
    Write-Log 'Computing corpus signature.'
    $corpusSig = Get-CorpusSignature
    $Health.lastCorpusSignature = $corpusSig
    $corpusChanged = ($state.lastProcessedCorpusSignature -ne $corpusSig)
    if ($corpusChanged) {
        Write-Log "Corpus signature changed. Previous: '$($state.lastProcessedCorpusSignature)'  new: '$corpusSig'"
    } else {
        Write-Log 'Corpus signature unchanged since previous run.'
    }

    if (-not $recapChanged -and -not $corpusChanged) {
        Write-Log 'Nothing to do: no new recap and no corpus changes.'
        $Health.status         = 'no-op'
        $Health.message        = 'No new recap and corpus signature unchanged.'
        $Health.triggeredBy    = 'none'
        $Health.lastCommitHash = $state.lastCommitHash
        return
    }

    $Health.triggeredBy = if ($recapChanged -and $corpusChanged) { 'recap+corpus' }
                          elseif ($recapChanged)                  { 'recap' }
                          else                                     { 'corpus' }
    Write-Log "Trigger: $($Health.triggeredBy)"

    # --- Run generator ----------------------------------------------------------

    $pwshPath = Get-PwshPath
    Write-Log "Invoking generator via $pwshPath"
    & $pwshPath -NoLogo -NoProfile -File $Generator
    if ($LASTEXITCODE -ne 0) {
        throw "Generator exited with code $LASTEXITCODE."
    }

    $Health.currentFocusGenerated    = Test-Path -LiteralPath (Join-Path $RepoRoot '00-context\generated\current-focus.json')
    $Health.trendsGenerated          = Test-Path -LiteralPath (Join-Path $RepoRoot '00-context\generated\current-focus-trends.json')
    $Health.morningBriefingGenerated = Test-Path -LiteralPath (Join-Path $RepoRoot '00-context\generated\morning-briefing.json')

    # --- Validate generated JSON ------------------------------------------------

    Write-Log 'Validating generated JSON files.'
    foreach ($relJson in ($GeneratedFiles | Where-Object { $_ -like '*.json' })) {
        $abs = Join-Path $RepoRoot $relJson
        if (-not (Test-Path -LiteralPath $abs)) { throw "Missing generated file: $relJson" }
        try {
            Get-Content -LiteralPath $abs -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
            Write-Log "  OK: $relJson"
        } catch {
            throw "Invalid JSON in $relJson : $($_.Exception.Message)"
        }
    }
    $Health.jsonValidated = $true

    # --- Update automation-state.json -------------------------------------------

    $now = (Get-Date).ToString('s')
    # Only mark the recap as processed if it was a real (non-empty) file that we
    # actually hashed. 0-byte guard (V4.0 Phase 8a) leaves this untouched so the
    # recap re-fires the moment content arrives.
    if ($latest -and $latest.Length -gt 0 -and $Health.lastActivityHash) {
        $state.lastProcessedActivityFile = $latest.Name
        $state.lastProcessedActivityHash = $Health.lastActivityHash
    }
    # Recompute corpus signature AFTER generator run so the generator's own
    # mtime changes on control YAMLs don't cause a phantom retrigger.
    $state.lastProcessedCorpusSignature = Get-CorpusSignature
    $state.lastSuccessfulRun            = $now
    $state.status                       = 'success'
    Save-StateFile -State $state -Path $StateFile
    Write-Log "Automation state updated (lastSuccessfulRun=$now)."

    # --- Git commit (local only, never push) ------------------------------------

    Write-Log 'Staging Git changes.'
    git status --short

    git add `
        '01-inbox' `
        '00-context/generated' `
        '00-context/automation-state.json'

    $staged = git diff --cached --name-only
    if (-not $staged) {
        Write-Log 'No staged changes. Nothing to commit.'
        $Health.status         = 'success'
        $Health.message        = 'Generator ran but produced no diffs to commit.'
        $Health.lastCommitHash = $state.lastCommitHash
        return
    }

    Write-Log "Files staged for commit:`n$staged"

    git commit -m 'Update Project Matryoshka automated intake outputs'
    if ($LASTEXITCODE -ne 0) {
        throw "git commit failed with exit code $LASTEXITCODE"
    }
    $commit = (git rev-parse HEAD).Trim()
    Write-Log "Committed outputs: $commit"
    $Health.gitCommitted   = $true
    $Health.lastCommitHash = $commit

    # Record the commit hash back into automation-state for full audit trail.
    $state = Read-StateFile -Path $StateFile
    $state.lastCommitHash = $commit
    Save-StateFile -State $state -Path $StateFile

    git add '00-context/automation-state.json'
    $stagedState = git diff --cached --name-only
    if ($stagedState) {
        git commit -m 'Record Project Matryoshka automation state'
        if ($LASTEXITCODE -ne 0) {
            throw "git commit (state) failed with exit code $LASTEXITCODE"
        }
        $stateCommit = (git rev-parse HEAD).Trim()
        Write-Log "Recorded state commit: $stateCommit"
    } else {
        Write-Log 'State commit skipped: no additional changes to record.'
    }

    $Health.status  = 'success'
    $Health.message = 'New recap processed and committed.'
    Write-Log 'Pipeline complete. Push intentionally skipped.'
}

# --- Orchestration ----------------------------------------------------------

Start-Transcript -Path $LogFile -Append -Force | Out-Null

$health = New-HealthObject
try {
    Invoke-MatryoshkaPipeline -Health $health
} catch {
    $health.status  = 'error'
    $health.message = $_.Exception.Message
    Write-Log "PIPELINE ERROR: $($_.Exception.Message)"
    throw
} finally {
    try {
        Save-HealthFile -Health $health -Path $HealthFile
        Write-Log "Health written: $HealthFile"
    } catch {
        Write-Warning "Failed to write health file: $($_.Exception.Message)"
    }
    try { Stop-Transcript | Out-Null } catch { }
}
