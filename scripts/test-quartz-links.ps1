<#
.SYNOPSIS
V4.0 Sprint 25b — Quartz link + backlink + graph integrity validator.

.DESCRIPTION
Scans the emitted Quartz site under quartz-site/public/ and asserts:

  1. Every href to /decisions|risks|workstreams|reports/... resolves to an
     emitted HTML file.
  2. Every backlink target listed inside <div class="backlinks"> resolves.
  3. Every graph edge target (derived from href data feeding the graph
     plugin) resolves. In Quartz v5 the graph is built from the same page
     links, so a broken link is also a ghost edge.
  4. No emitted page references a draft-filtered item (any target in
     matryoshka-items.json where validated == false).

Writes quartz-link-validation.md with:
  - counts of pass / fail per check
  - list of every broken reference (if any)
  - final PASS/FAIL verdict

Exit code:
  0  = all checks pass
  1  = any check fails

.PARAMETER SiteDir
Path to the built Quartz site (default: quartz-site/public).

.PARAMETER OutFile
Path to the markdown report (default: quartz-link-validation.md at repo root).

.PARAMETER CanonicalItems
Path to matryoshka-items.json used to distinguish draft-filtered targets.
#>
[CmdletBinding()]
param(
    [string] $SiteDir = (Join-Path $PSScriptRoot '..\quartz-site\public'),
    [string] $OutFile = (Join-Path $PSScriptRoot '..\quartz-link-validation.md'),
    [string] $CanonicalItems = (Join-Path $PSScriptRoot '..\00-context\generated\matryoshka-items.json')
)

$ErrorActionPreference = 'Stop'

$SiteDir = (Resolve-Path -LiteralPath $SiteDir).Path
if (-not (Test-Path -LiteralPath $SiteDir)) {
    Write-Error "Site directory not found: $SiteDir"
    exit 2
}

Write-Host "Scanning $SiteDir ..." -ForegroundColor Cyan

# --- Enumerate emitted pages -------------------------------------------------

$allHtml = @(Get-ChildItem -LiteralPath $SiteDir -Filter *.html -Recurse -File)
$emittedSet = @{}
foreach ($f in $allHtml) {
    $rel = ($f.FullName.Substring($SiteDir.Length + 1) -replace '\\', '/').ToLower()
    $emittedSet[$rel] = $true
}
Write-Host ("  emitted html files: {0}" -f $allHtml.Count)

# --- Load canonical model for draft-target detection -------------------------

$draftIds = @{}
$publishedIds = @{}
if (Test-Path -LiteralPath $CanonicalItems) {
    $json = Get-Content -LiteralPath $CanonicalItems -Raw | ConvertFrom-Json
    foreach ($it in @($json.items)) {
        $id = [string]$it.id
        if ($it.validated) { $publishedIds[$id.ToLower()] = $true }
        else               { $draftIds[$id.ToLower()]     = $true }
    }
}
Write-Host ("  canonical items: {0} published, {1} draft" -f $publishedIds.Count, $draftIds.Count)

# --- Scan every HTML for cross-references -----------------------------------

# Pattern captures any href pointing at our four content sections.
$hrefPattern = 'href="((?:\.\./)*(?:decisions|risks|workstreams|reports)/[^"#?]+?)(?:"|#|\?)'
$backlinksPattern = '(?s)<div class="backlinks">(.*?)</div>'

$brokenLinks    = New-Object System.Collections.Generic.List[object]
$brokenBacklinks = New-Object System.Collections.Generic.List[object]
$draftRefs      = New-Object System.Collections.Generic.List[object]
$totalRefs      = 0
$totalBacklinkRefs = 0

foreach ($f in $allHtml) {
    $sourceRel = ($f.FullName.Substring($SiteDir.Length + 1) -replace '\\', '/')
    $content = Get-Content -LiteralPath $f.FullName -Raw

    # (1) all cross-refs
    foreach ($m in [regex]::Matches($content, $hrefPattern)) {
        $target = $m.Groups[1].Value -replace '^(\.\./)+', ''
        if (-not $target.EndsWith('.html')) { $target = $target + '.html' }
        $key = $target.ToLower()
        $totalRefs++
        if (-not $emittedSet.ContainsKey($key)) {
            $brokenLinks.Add([pscustomobject]@{
                Source = $sourceRel
                Target = $target
            }) | Out-Null
            # extract bare id from target for draft attribution
            $bareId = ([IO.Path]::GetFileNameWithoutExtension($target)).ToLower()
            if ($draftIds.ContainsKey($bareId)) {
                $draftRefs.Add([pscustomobject]@{
                    Source = $sourceRel
                    Target = $target
                    Reason = 'target is draft-filtered (validated:false)'
                }) | Out-Null
            }
        }
    }

    # (2) backlinks section only
    foreach ($bm in [regex]::Matches($content, $backlinksPattern)) {
        $blHtml = $bm.Groups[1].Value
        foreach ($bh in [regex]::Matches($blHtml, $hrefPattern)) {
            $target = $bh.Groups[1].Value -replace '^(\.\./)+', ''
            if (-not $target.EndsWith('.html')) { $target = $target + '.html' }
            $key = $target.ToLower()
            $totalBacklinkRefs++
            if (-not $emittedSet.ContainsKey($key)) {
                $brokenBacklinks.Add([pscustomobject]@{
                    Source = $sourceRel
                    Target = $target
                }) | Out-Null
            }
        }
    }
}

# --- Results -----------------------------------------------------------------

$brokenLinkCount     = $brokenLinks.Count
$brokenBacklinkCount = $brokenBacklinks.Count
$draftRefCount       = $draftRefs.Count
# Graph edges in Quartz v5 are derived from the same cross-refs. So a broken
# link is also a ghost edge. Report the same count under graph-cleanliness.
$ghostEdgeCount      = $brokenLinkCount

$overall = ($brokenLinkCount -eq 0 -and $brokenBacklinkCount -eq 0 -and $ghostEdgeCount -eq 0)

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host ("  cross-refs scanned:      {0}" -f $totalRefs)
Write-Host ("  broken href refs:        {0}" -f $brokenLinkCount)
Write-Host ("  backlink refs scanned:   {0}" -f $totalBacklinkRefs)
Write-Host ("  broken backlink refs:    {0}" -f $brokenBacklinkCount)
Write-Host ("  refs to draft targets:   {0}" -f $draftRefCount)
Write-Host ("  ghost graph edges:       {0}" -f $ghostEdgeCount)
Write-Host ""
if ($overall) {
    Write-Host "OVERALL: PASS" -ForegroundColor Green
} else {
    Write-Host "OVERALL: FAIL" -ForegroundColor Red
}

# --- Emit markdown report ----------------------------------------------------

$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$verdict = if ($overall) { 'PASS' } else { 'FAIL' }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('type: "quartz-link-validation"')
[void]$sb.AppendLine('title: "Quartz Link Validation Report"')
[void]$sb.AppendLine('generator: "scripts/test-quartz-links.ps1"')
[void]$sb.AppendLine(('generated: "' + $now + '"'))
[void]$sb.AppendLine('version: "V4.0-sprint25b"')
[void]$sb.AppendLine('schema: "quartz-link-validation/v1"')
[void]$sb.AppendLine(('verdict: "' + $verdict + '"'))
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('# Quartz Link Validation Report')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Sprint 25b Deliverable 25b.1 + 25b.3. Emitted by [scripts/test-quartz-links.ps1](scripts/test-quartz-links.ps1) against the built Quartz site.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Summary')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Check | Count | Target | Result |')
[void]$sb.AppendLine('|---|---:|---:|:---:|')
[void]$sb.AppendLine(('| Emitted HTML files | ' + $allHtml.Count + ' | - | - |'))
[void]$sb.AppendLine(('| Cross-refs scanned | ' + $totalRefs + ' | - | - |'))
[void]$sb.AppendLine(('| Backlink refs scanned | ' + $totalBacklinkRefs + ' | - | - |'))
[void]$sb.AppendLine(('| Broken href refs | ' + $brokenLinkCount + ' | 0 | ' + $(if ($brokenLinkCount -eq 0) { '**PASS**' } else { '**FAIL**' }) + ' |'))
[void]$sb.AppendLine(('| Broken backlink refs | ' + $brokenBacklinkCount + ' | 0 | ' + $(if ($brokenBacklinkCount -eq 0) { '**PASS**' } else { '**FAIL**' }) + ' |'))
[void]$sb.AppendLine(('| Ghost graph edges | ' + $ghostEdgeCount + ' | 0 | ' + $(if ($ghostEdgeCount -eq 0) { '**PASS**' } else { '**FAIL**' }) + ' |'))
[void]$sb.AppendLine(('| Refs pointing at draft-filtered items | ' + $draftRefCount + ' | 0 | ' + $(if ($draftRefCount -eq 0) { '**PASS**' } else { '**FAIL**' }) + ' |'))
[void]$sb.AppendLine('')
[void]$sb.AppendLine(('**Overall verdict: ' + $verdict + '**'))
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Canonical model context')
[void]$sb.AppendLine('')
[void]$sb.AppendLine(('- Published (link-eligible) items: **' + $publishedIds.Count + '**'))
[void]$sb.AppendLine(('- Draft (link-excluded) items: **' + $draftIds.Count + '**'))
[void]$sb.AppendLine('- Source: `00-context/generated/matryoshka-items.json`')
[void]$sb.AppendLine('')

if ($brokenLinks.Count -gt 0) {
    [void]$sb.AppendLine('## Broken href references')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Source page | Target |')
    [void]$sb.AppendLine('|---|---|')
    foreach ($b in ($brokenLinks | Sort-Object Source, Target)) {
        [void]$sb.AppendLine(('| `' + $b.Source + '` | `' + $b.Target + '` |'))
    }
    [void]$sb.AppendLine('')
}

if ($brokenBacklinks.Count -gt 0) {
    [void]$sb.AppendLine('## Broken backlink references')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Source page | Target |')
    [void]$sb.AppendLine('|---|---|')
    foreach ($b in ($brokenBacklinks | Sort-Object Source, Target)) {
        [void]$sb.AppendLine(('| `' + $b.Source + '` | `' + $b.Target + '` |'))
    }
    [void]$sb.AppendLine('')
}

if ($draftRefs.Count -gt 0) {
    [void]$sb.AppendLine('## References to draft-filtered items')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Each row is a page that references an item whose `validated == false` in `matryoshka-items.json`. These would render as dead links because Quartz''s `remove-draft` plugin filters draft items from output.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Source page | Target | Reason |')
    [void]$sb.AppendLine('|---|---|---|')
    foreach ($d in ($draftRefs | Sort-Object Source, Target)) {
        [void]$sb.AppendLine(('| `' + $d.Source + '` | `' + $d.Target + '` | ' + $d.Reason + ' |'))
    }
    [void]$sb.AppendLine('')
}

if ($overall) {
    [void]$sb.AppendLine('## Notes')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('All navigation surfaces (href, backlinks, graph) resolve to emitted pages. The Sprint 25b draft-aware navigation logic in `scripts/prepare-quartz-content.ps1` (Sprint 25b) is validated: no page references a draft-filtered target.')
    [void]$sb.AppendLine('')
}

$OutFile = [IO.Path]::GetFullPath($OutFile)
Set-Content -LiteralPath $OutFile -Value ($sb.ToString()) -Encoding utf8
Write-Host ("Report written: " + $OutFile) -ForegroundColor Green

if (-not $overall) { exit 1 }
exit 0
