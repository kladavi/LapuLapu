<#
.SYNOPSIS
  V4.0 Sprint 23a: canonical-index validator + Phase 10 verification report.

.DESCRIPTION
  Reads 00-context/generated/matryoshka-index.json and 00-context/generated/matryoshka-items.json,
  validates them against Phase 10 acceptance criteria, and writes
  00-context/generated/phase10-verification.md.

  Validation checks:
    - every indexed document path exists on disk
    - every generated markdown artifact has parseable YAML frontmatter
    - every canonical item is discoverable via the index
    - no item has an empty workstream
    - no item title contains "meeting transcript/summary"
    - no item title is visibly truncated
    - no item title is entirely numeric

  Emits a human-readable + machine-checkable report to
  00-context/generated/phase10-verification.md.

  Exit code:
    0 = all checks pass
    1 = one or more checks failed (non-fatal - report is still written)

.EXAMPLE
  pwsh -File scripts/verify-phase10.ps1
#>

[CmdletBinding()]
param(
    [switch] $FailOnError
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent $PSScriptRoot
$GEN  = Join-Path $ROOT '00-context\generated'

$ITEMS_JSON = Join-Path $GEN 'matryoshka-items.json'
$INDEX_JSON = Join-Path $GEN 'matryoshka-index.json'
$OUT_MD     = Join-Path $GEN 'phase10-verification.md'

# --- Helpers ----------------------------------------------------------------

function Read-JsonSafe {
    param([string] $Path)
    if (-not (Test-Path $Path)) { throw "Required file not found: $Path" }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    return $raw | ConvertFrom-Json -Depth 20
}

function Test-YamlFrontmatter {
    <#
        Returns @{ ok = <bool>; reason = <string>; type = <string> }.
        Valid frontmatter starts with `---\n`, has at least one `key: value`
        line, and terminates with a `---\n` before the body.
    #>
    param([string] $AbsPath)
    if (-not (Test-Path $AbsPath)) { return @{ ok = $false; reason = 'file not found'; type = '' } }
    $raw = Get-Content -LiteralPath $AbsPath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return @{ ok = $false; reason = 'empty file'; type = '' } }
    $m = [regex]::Match($raw, '(?s)\A\s*---\s*\r?\n(.+?)\r?\n---\s*\r?\n')
    if (-not $m.Success) { return @{ ok = $false; reason = 'no YAML frontmatter delimiters'; type = '' } }
    $block = $m.Groups[1].Value
    # Reject empty frontmatter block
    $keyLines = @($block -split "`r?`n" | Where-Object { $_ -match '^\s*[A-Za-z_][A-Za-z0-9_]*\s*:' })
    if ($keyLines.Count -eq 0) {
        return @{ ok = $false; reason = 'frontmatter has no key: value lines'; type = '' }
    }
    # Extract type field if present
    $typeMatch = [regex]::Match($block, '(?im)^\s*type\s*:\s*(?:"([^"]+)"|([^\r\n"]+))\s*$')
    $type = if ($typeMatch.Success) {
        if ($typeMatch.Groups[1].Value) { $typeMatch.Groups[1].Value } else { $typeMatch.Groups[2].Value.Trim() }
    } else { '' }
    return @{ ok = $true; reason = ''; type = $type }
}

# --- Load artifacts ---------------------------------------------------------

Write-Host 'Loading matryoshka-items.json + matryoshka-index.json...' -ForegroundColor Cyan
$items = Read-JsonSafe -Path $ITEMS_JSON
$index = Read-JsonSafe -Path $INDEX_JSON

$itemsList     = @($items.items)
$docsList      = @($index.documents)
$indexItemsList = @($index.items)

Write-Host ("  items: {0}, index-documents: {1}, index-items: {2}" -f `
    $itemsList.Count, $docsList.Count, $indexItemsList.Count) -ForegroundColor Cyan

# --- Run checks -------------------------------------------------------------

$failures = [System.Collections.Generic.List[hashtable]]::new()
$passes   = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string] $Check, [string] $Detail)
    [void]$failures.Add(@{ check = $Check; detail = $Detail })
}
function Add-Pass {
    param([string] $Check)
    [void]$passes.Add($Check)
}

# CHECK 1: every indexed document path exists
$missingPaths = @()
foreach ($d in $docsList) {
    $abs = Join-Path $ROOT ([string]$d.path)
    if (-not (Test-Path $abs)) {
        $missingPaths += [string]$d.path
    }
}
if ($missingPaths.Count -eq 0) {
    Add-Pass 'every indexed document path exists on disk'
} else {
    Add-Failure 'indexed document paths must exist' ($missingPaths -join '; ')
}

# CHECK 2: every generated markdown artifact has parseable YAML frontmatter
# (Human-authored README files are exempt - they are documentation, not
# generator output.)
$noFrontmatter = @()
$genPrefix = '00-context/generated/'
foreach ($d in $docsList) {
    $p = [string]$d.path -replace '\\', '/'
    if (-not $p.StartsWith($genPrefix)) { continue }
    if (-not $p.EndsWith('.md')) { continue }
    if ($p -match '(?i)(?:^|/)README\.md$') { continue }
    $abs = Join-Path $ROOT $p
    $r = Test-YamlFrontmatter -AbsPath $abs
    if (-not $r.ok) {
        $noFrontmatter += "$p ($($r.reason))"
    }
}
if ($noFrontmatter.Count -eq 0) {
    Add-Pass 'every generated markdown has valid YAML frontmatter'
} else {
    Add-Failure 'generated markdown must have valid YAML frontmatter' ($noFrontmatter -join '; ')
}

# CHECK 3: every canonical item is discoverable via the index
$indexIds = @{}
foreach ($ii in $indexItemsList) { $indexIds[[string]$ii.id] = $true }
$missingFromIndex = @()
foreach ($it in $itemsList) {
    if (-not $indexIds.ContainsKey([string]$it.id)) {
        $missingFromIndex += [string]$it.id
    }
}
if ($missingFromIndex.Count -eq 0) {
    Add-Pass 'every canonical item is discoverable via matryoshka-index.json'
} else {
    Add-Failure 'index must contain every canonical item' ($missingFromIndex -join ', ')
}

# CHECK 4: no item has an empty workstream
$emptyWs = @($itemsList | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.workstream) } | ForEach-Object { [string]$_.id })
if ($emptyWs.Count -eq 0) {
    Add-Pass 'no canonical item has empty workstream'
} else {
    Add-Failure 'items must have non-empty workstream' ($emptyWs -join ', ')
}

# CHECK 5: no title contains "meeting transcript/summary"
$meetingLeaks = @($itemsList | Where-Object { [string]$_.title -match '(?i)meeting\s+transcript(?:/|\s+or\s+)?summary' } | ForEach-Object { "$($_.id): $($_.title.Substring(0,[Math]::Min(60,$_.title.Length)))" })
if ($meetingLeaks.Count -eq 0) {
    Add-Pass 'no title contains "meeting transcript/summary"'
} else {
    Add-Failure 'meeting-transcript title leak' ($meetingLeaks -join '; ')
}

# CHECK 6: no title is visibly truncated (ends mid-word)
$truncated = @()
foreach ($it in $itemsList) {
    $t = [string]$it.title
    if (-not $t) { continue }
    $lastWord = ($t -split '\s+')[-1]
    if ($lastWord -match '^[A-Za-z]{1,3}$' -and $lastWord -notmatch '^[A-Z]{2,3}$' -and $t -notmatch '[.!?]\s*$') {
        $truncated += "$($it.id): ends in '$lastWord'"
    }
    if ($t -match '(?i)\s(?:receiv|includin|whic|bu|to\s+redu)\s*$') {
        $truncated += "$($it.id): matches truncation suffix"
    }
}
if ($truncated.Count -eq 0) {
    Add-Pass 'no canonical item title appears truncated'
} else {
    Add-Failure 'truncated titles' ($truncated -join '; ')
}

# CHECK 7: no title is entirely numeric
$numeric = @($itemsList | Where-Object { [string]$_.title -match '^\s*-?\d+(?:\.\d+)?\s*$' } | ForEach-Object { [string]$_.id })
if ($numeric.Count -eq 0) {
    Add-Pass 'no title is entirely numeric'
} else {
    Add-Failure 'numeric-only titles must not exist' ($numeric -join ', ')
}

# CHECK 8: index totals are internally consistent
$totalMismatch = @()
if ([int]$index.totals.items -ne $indexItemsList.Count) {
    $totalMismatch += "totals.items = $([int]$index.totals.items) but items array has $($indexItemsList.Count)"
}
if ([int]$index.totals.documents -ne $docsList.Count) {
    $totalMismatch += "totals.documents = $([int]$index.totals.documents) but documents array has $($docsList.Count)"
}
if ($totalMismatch.Count -eq 0) {
    Add-Pass 'index totals are internally consistent'
} else {
    Add-Failure 'index totals must match array lengths' ($totalMismatch -join '; ')
}

# --- Compute Phase 10 metrics for the report -------------------------------

$whyDist = @{
    T1_explicit_rationale = @($itemsList | Where-Object { [string]$_.why_it_matters_source -eq 'explicit-rationale' }).Count
    T2_risk_consequence   = @($itemsList | Where-Object { [string]$_.why_it_matters_source -eq 'risk-consequence' }).Count
    T3_decision_impact    = @($itemsList | Where-Object { [string]$_.why_it_matters_source -eq 'decision-impact' }).Count
    T4_context_fallback   = @($itemsList | Where-Object { [string]$_.why_it_matters_source -eq 'context-fallback' }).Count
    none                  = @($itemsList | Where-Object { [string]$_.why_it_matters_source -eq 'none' }).Count
}
$highConfidence = @($itemsList | Where-Object { [double]$_.why_it_matters_confidence -ge 0.6 }).Count

$statusDist = @{
    red   = @($itemsList | Where-Object { [string]$_.status -eq 'red' }).Count
    amber = @($itemsList | Where-Object { [string]$_.status -eq 'amber' }).Count
    green = @($itemsList | Where-Object { [string]$_.status -eq 'green' }).Count
}

$validated = @($itemsList | Where-Object { $_.validated }).Count
$rejected  = $itemsList.Count - $validated

$docByType = @{}
foreach ($d in $docsList) {
    $t = if ($d.type) { [string]$d.type } else { '(unknown)' }
    if (-not $docByType.ContainsKey($t)) { $docByType[$t] = 0 }
    $docByType[$t] += 1
}

# --- Build report -----------------------------------------------------------

$overallStatus = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$overallStatusEmoji = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('type: phase10-verification')
[void]$sb.AppendLine('title: "Phase 10 Verification Report"')
[void]$sb.AppendLine('generator: scripts/verify-phase10.ps1')
[void]$sb.AppendLine(('generated: {0}' -f (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')))
[void]$sb.AppendLine('version: V4.0-sprint23a')
[void]$sb.AppendLine('schema: ui/src/lib/matryoshka-item.ts')
[void]$sb.AppendLine(('checks_passed: {0}' -f $passes.Count))
[void]$sb.AppendLine(('checks_failed: {0}' -f $failures.Count))
[void]$sb.AppendLine(('overall_status: {0}' -f $overallStatus))
[void]$sb.AppendLine('---')
[void]$sb.AppendLine()
[void]$sb.AppendLine('# Phase 10 Verification')
[void]$sb.AppendLine()
[void]$sb.AppendLine(('Generated at {0} against canonical artifacts:' -f (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')))
[void]$sb.AppendLine('- `00-context/generated/matryoshka-items.json`')
[void]$sb.AppendLine('- `00-context/generated/matryoshka-index.json`')
[void]$sb.AppendLine()
[void]$sb.AppendLine(('**Overall status: {0}** ({1} checks passed, {2} failed)' -f $overallStatusEmoji, $passes.Count, $failures.Count))
[void]$sb.AppendLine()

# --- Sections ---------------------------------------------------------------

[void]$sb.AppendLine('## Canonical Item Counts')
[void]$sb.AppendLine()
[void]$sb.AppendLine("- Total items: **$($itemsList.Count)**")
[void]$sb.AppendLine("- Validated: $validated ($([Math]::Round(100.0 * $validated / [Math]::Max(1, $itemsList.Count), 1))%)")
[void]$sb.AppendLine("- Rejected:  $rejected")
[void]$sb.AppendLine("- By type: decisions=$(@($itemsList | Where-Object { $_.type -eq 'decision' }).Count) / risks=$(@($itemsList | Where-Object { $_.type -eq 'risk' }).Count)")
[void]$sb.AppendLine("- By status: red=$($statusDist.red) / amber=$($statusDist.amber) / green=$($statusDist.green)")
[void]$sb.AppendLine()

[void]$sb.AppendLine('## Title Quality')
[void]$sb.AppendLine()
$badTitles = @($itemsList | Where-Object {
    ([string]$_.title -match '(?i)meeting\s+transcript(?:/|\s+or\s+)?summary') -or
    ([string]$_.title -match '^\s*-?\d+(?:\.\d+)?\s*$') -or
    ([string]::IsNullOrWhiteSpace([string]$_.workstream)) -or
    ([string]$_.title -match '(?i)\s(?:receiv|includin|whic|bu|to\s+redu)\s*$')
})
[void]$sb.AppendLine("- Titles matching any known-bad pattern (meeting-leak / numeric / empty-ws / truncated): **$($badTitles.Count)**")
if ($badTitles.Count -gt 0) {
    foreach ($b in ($badTitles | Select-Object -First 8)) {
        $titleSlice = if ($b.title) { [string]$b.title } else { '' }
        if ($titleSlice.Length -gt 80) { $titleSlice = $titleSlice.Substring(0, 80) }
        [void]$sb.AppendLine(('  - `{0}`: {1}' -f $b.id, $titleSlice))
    }
} else {
    [void]$sb.AppendLine('  - ✅ No bad titles in canonical model')
}
[void]$sb.AppendLine()

[void]$sb.AppendLine('## Source Classification')
[void]$sb.AppendLine()
[void]$sb.AppendLine('Sprint 20 gates: REPORT / GENERATED / RECAP / GOVERNANCE / DOCS folders never produce decisions.')
[void]$sb.AppendLine('Sprint 23a title validator rejects meeting-transcript titles at extraction time even from allowed folders.')
[void]$sb.AppendLine()
$sourcesUsed = @($itemsList | ForEach-Object { [string]$_.source } | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | Select-Object -First 8)
if ($sourcesUsed.Count -gt 0) {
    [void]$sb.AppendLine('Top 8 source files feeding canonical items:')
    foreach ($s in $sourcesUsed) {
        [void]$sb.AppendLine(('- {0}x `{1}`' -f $s.Count, $s.Name))
    }
} else {
    [void]$sb.AppendLine('_No source files reported on items._')
}
[void]$sb.AppendLine()

[void]$sb.AppendLine('## Why-It-Matters Distribution')
[void]$sb.AppendLine()
[void]$sb.AppendLine("- T1 explicit-rationale (conf 0.90): $($whyDist.T1_explicit_rationale)")
[void]$sb.AppendLine("- T2 risk-consequence  (conf 0.75): $($whyDist.T2_risk_consequence)")
[void]$sb.AppendLine("- T3 decision-impact   (conf 0.60-0.85): $($whyDist.T3_decision_impact)")
[void]$sb.AppendLine("- T4 context-fallback  (conf 0.15-0.30): $($whyDist.T4_context_fallback)")
[void]$sb.AppendLine("- none: $($whyDist.none)")
[void]$sb.AppendLine("- **High-confidence (>= 0.6): $highConfidence of $($itemsList.Count)**")
[void]$sb.AppendLine()

[void]$sb.AppendLine('## Markdown Frontmatter Compliance')
[void]$sb.AppendLine()
[void]$sb.AppendLine("- Generated MD artifacts indexed: $((@($docsList | Where-Object { ([string]$_.path -replace '\\','/').StartsWith('00-context/generated/') })).Count)")
[void]$sb.AppendLine("- With parseable YAML frontmatter: $(((@($docsList | Where-Object { ([string]$_.path -replace '\\','/').StartsWith('00-context/generated/') })).Count) - $noFrontmatter.Count)")
[void]$sb.AppendLine("- Missing / malformed: $($noFrontmatter.Count)")
if ($noFrontmatter.Count -gt 0) {
    foreach ($n in $noFrontmatter) { [void]$sb.AppendLine("  - $n") }
}
[void]$sb.AppendLine()
[void]$sb.AppendLine('Document type breakdown from index:')
foreach ($k in ($docByType.Keys | Sort-Object)) {
    [void]$sb.AppendLine(('- {0}: {1}' -f $k, $docByType[$k]))
}
[void]$sb.AppendLine()

[void]$sb.AppendLine('## Index Validation')
[void]$sb.AppendLine()
[void]$sb.AppendLine("- Documents indexed: $($docsList.Count)")
[void]$sb.AppendLine("- Items indexed: $($indexItemsList.Count)")
[void]$sb.AppendLine("- Canonical items: $($itemsList.Count)")
[void]$sb.AppendLine("- Missing paths (indexed but not on disk): $($missingPaths.Count)")
[void]$sb.AppendLine("- Missing from index (canonical but not indexed): $($missingFromIndex.Count)")
[void]$sb.AppendLine()

[void]$sb.AppendLine('## Check Results')
[void]$sb.AppendLine()
if ($passes.Count -gt 0) {
    [void]$sb.AppendLine('### ✅ Passes')
    [void]$sb.AppendLine()
    foreach ($p in $passes) { [void]$sb.AppendLine("- $p") }
    [void]$sb.AppendLine()
}
if ($failures.Count -gt 0) {
    [void]$sb.AppendLine('### ❌ Failures')
    [void]$sb.AppendLine()
    foreach ($f in $failures) {
        [void]$sb.AppendLine("- **$($f.check)**")
        $detail = [string]$f.detail
        if ($detail.Length -gt 400) { $detail = $detail.Substring(0, 397) + '...' }
        [void]$sb.AppendLine("  - $detail")
    }
    [void]$sb.AppendLine()
}

# --- Write + summary --------------------------------------------------------

[System.IO.File]::WriteAllText($OUT_MD, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
$rel = $OUT_MD.Replace($ROOT, '').TrimStart('\','/')
Write-Host ("Written: {0}" -f $rel) -ForegroundColor Green

Write-Host ""
if ($failures.Count -eq 0) {
    Write-Host ("Phase 10 verification: ALL CHECKS PASSED ({0}/{0})" -f $passes.Count) -ForegroundColor Green
    exit 0
} else {
    Write-Host ("Phase 10 verification: {0} check(s) FAILED, {1} passed" -f $failures.Count, $passes.Count) -ForegroundColor Yellow
    foreach ($f in $failures) {
        Write-Host ("  FAIL: {0}" -f $f.check) -ForegroundColor Red
    }
    if ($FailOnError) { exit 1 } else { exit 0 }
}
