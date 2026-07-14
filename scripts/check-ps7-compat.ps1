#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repoRoot = Split-Path $PSScriptRoot -Parent
$files = @(
    'scripts\run-matryoshka-pipeline.ps1',
    'scripts\report-areas.ps1',
    'scripts\generate-current-focus.v1_1.ps1',
    'scripts\generate-current-focus.ps1',
    'scripts\backfill-area-tags.ps1',
    'ui\scripts\restart-dev.ps1',
    'ui\scripts\health-check.ps1',
    'ui\scripts\fix-heading-mojibake.ps1',
    'ui\scripts\dev-server.ps1'
)

# Patterns worth flagging
$ps5RemovedPatterns = @(
    @{ Pattern = '(?im)^\s*workflow\s+\w'                ; Note = 'workflow keyword removed in PS7' }
    @{ Pattern = 'New-WebServiceProxy'                    ; Note = 'removed in PS7' }
    @{ Pattern = 'Get-EventLog\b'                         ; Note = 'removed in PS7 (use Get-WinEvent)' }
    @{ Pattern = 'Send-MailMessage'                       ; Note = 'deprecated (still works in PS7)' }
    @{ Pattern = 'Add-Type\s+-Assembly\s+System\.Web'     ; Note = 'System.Web not always available on PS7 Core' }
)

$ps7OnlyPatterns = @(
    @{ Pattern = '(?<!\\)\?\?\s'                          ; Note = '?? null-coalescing (PS7+)' }
    @{ Pattern = '\?\.\w'                                 ; Note = '?. null-conditional (PS7+)' }
    @{ Pattern = '-Parallel\b'                            ; Note = 'ForEach-Object -Parallel (PS7+)' }
    @{ Pattern = '\s\&\&\s'                               ; Note = '&& chain operator (PS7+)' }
    @{ Pattern = '\s\|\|\s'                               ; Note = '|| chain operator (PS7+)' }
    @{ Pattern = 'ConvertFrom-Json[^\r\n]*-AsHashtable'   ; Note = '-AsHashtable (PS6+, OK on PS7)' }
)

foreach ($rel in $files) {
    $path = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $path)) { "MISSING  $rel"; continue }

    # AST parse
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
    $parseState = if ($errors -and $errors.Count -gt 0) { "PARSE_ERR($($errors.Count))" } else { 'PARSE_OK' }

    # #Requires -Version detection
    $head = Get-Content -LiteralPath $path -TotalCount 5 -Encoding UTF8
    $reqVer = 'none'
    foreach ($line in $head) {
        if ($line -match '^\s*#Requires\s+-Version\s+([\d.]+)') { $reqVer = $Matches[1]; break }
    }

    # Pattern hits
    $body = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $flags = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $ps5RemovedPatterns) {
        if ($body -match $p.Pattern) { $flags.Add("legacy: $($p.Note)") }
    }
    foreach ($p in $ps7OnlyPatterns) {
        if ($body -match $p.Pattern) { $flags.Add("PS7-only: $($p.Note)") }
    }
    $flagsStr = if ($flags.Count -gt 0) { $flags -join ' | ' } else { '-' }

    "{0,-48} req={1,-4} {2,-14} flags={3}" -f $rel, $reqVer, $parseState, $flagsStr

    if ($errors -and $errors.Count -gt 0) {
        foreach ($e in ($errors | Select-Object -First 3)) {
            "     ERR line {0}: {1}" -f $e.Extent.StartLineNumber, $e.Message
        }
    }
}
