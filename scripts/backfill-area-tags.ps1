#Requires -Version 7.0
# Backfill #area:* tags on tasks.md and key-results.md based on keyword rules.
# See 00-context/pack-config.md "Delivery Area Taxonomy" for the canonical mapping.
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$files = @(
    (Join-Path $root '02-work\tasks.md'),
    (Join-Path $root '02-work\key-results.md')
)

# Classification rules. Order matters only for reporting; all matching tags are added.
# Each rule is a regex evaluated case-insensitively against the full item block
# (heading + body), EXCLUDING the existing Tags line so we don't double-match
# on tags we just added on a prior run.
$rules = @(
    @{ Tag = '#area:adx-registration'; Pattern = '\bADX\b|Azure Data Explorer' },
    @{ Tag = '#area:cmdb-mapping';     Pattern = '\bCMDB\b' },
    @{ Tag = '#area:employee-xp';      Pattern = 'Employee Experience|Employee XP' },
    @{ Tag = '#area:dev-xp';           Pattern = 'Developer Experience|Dev XP|non[- ]?prod(uction)? monitoring|non[- ]?prod(uction)? alert|non[- ]?prod(uction)? environment|nonprod' },
    @{ Tag = '#area:gocc-transition';  Pattern = 'PS[- ]to[- ]GOCC|GOCC handover|GOCC onboarding|GOCC transition|scaffolding pack|reverse[- ]?shadow|shadow session|\bKT\b|knowledge[- ]transfer|handover to GOCC|transition to GOCC|onboard(ed|ing)? to GOCC|GOCC ORR|gocc-handover' },
    @{ Tag = '#area:mmm-l2';           Pattern = '\bMMM\b|\bOMM\b|Observability Maturity' },
    @{ Tag = '#area:patching';         Pattern = '\bpatching\b|patch cycle|patch window|weekday patching' },
    @{ Tag = '#area:rapid-recovery';   Pattern = 'Rapid Recovery|\bRRP\b|\bR2R\b|recovery plan|rapid[- ]?response' }
)

$summary = @{}
foreach ($r in $rules) { $summary[$r.Tag] = New-Object System.Collections.Generic.List[string] }

foreach ($file in $files) {
    if (-not (Test-Path $file)) { continue }
    $raw = Get-Content -Raw -Path $file
    # Split into blocks at "## " headings, preserving the heading on each block.
    $parts = [regex]::Split($raw, '(?m)(?=^## )')
    $modified = $false
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $block = $parts[$i]
        if ($block -notmatch '^##\s+(T\d+|KR\d+)\b') { continue }
        $idMatch = [regex]::Match($block, '^##\s+(T\d+|KR\d+)\b')
        $itemId = $idMatch.Groups[1].Value

        # Find the Tags line.
        $tagsLineMatch = [regex]::Match($block, '(?m)^(- \*\*Tags:\*\*)(.*)$')
        if (-not $tagsLineMatch.Success) { continue }
        $existingTags = $tagsLineMatch.Groups[2].Value.Trim()

        # Body for matching = block minus the Tags line (so we don't re-match on tags).
        $bodyForMatching = $block.Remove($tagsLineMatch.Index, $tagsLineMatch.Length)

        $tagsToAdd = @()
        foreach ($r in $rules) {
            if ($existingTags -match [regex]::Escape($r.Tag)) { continue }
            if ([regex]::IsMatch($bodyForMatching, $r.Pattern, 'IgnoreCase')) {
                $tagsToAdd += $r.Tag
                $summary[$r.Tag].Add($itemId)
            }
        }

        if ($tagsToAdd.Count -gt 0) {
            $combined = if ([string]::IsNullOrWhiteSpace($existingTags)) {
                ($tagsToAdd -join ' ')
            } else {
                ($existingTags + ' ' + ($tagsToAdd -join ' '))
            }
            $newLine = "- **Tags:** $combined"
            $parts[$i] = $block.Substring(0, $tagsLineMatch.Index) + $newLine + $block.Substring($tagsLineMatch.Index + $tagsLineMatch.Length)
            $modified = $true
        }
    }
    if ($modified -and -not $DryRun) {
        $out = ($parts -join '')
        Set-Content -Path $file -Value $out -NoNewline
    }
}

# Print summary
Write-Host ""
Write-Host "=== Backfill Summary ==="
foreach ($r in $rules) {
    $ids = $summary[$r.Tag]
    Write-Host ("{0,-28} ({1,3}) {2}" -f $r.Tag, $ids.Count, ($ids -join ', '))
}
if ($DryRun) { Write-Host "`n(dry-run: no files written)" }
