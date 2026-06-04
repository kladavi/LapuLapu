# Print every #area:* tag with the items carrying it (id + title).
$root = Split-Path -Parent $PSScriptRoot
$files = @(
    (Join-Path $root '02-work\tasks.md'),
    (Join-Path $root '02-work\key-results.md')
)

$areas = [ordered]@{
    '#area:adx-registration' = 'ADX Registration'
    '#area:cmdb-mapping'     = 'CMDB Mapping'
    '#area:employee-xp'      = 'Employee XP Dashboard'
    '#area:dev-xp'           = 'Dev XP Dashboard'
    '#area:gocc-transition'  = 'GOCC Transition'
    '#area:mmm-l2'           = 'MMM L2'
    '#area:patching'         = 'Patching'
    '#area:rapid-recovery'   = 'Rapid Recovery'
}

$bucket = @{}
foreach ($a in $areas.Keys) { $bucket[$a] = New-Object System.Collections.Generic.List[string] }

foreach ($file in $files) {
    $raw = Get-Content -Raw -Path $file
    $parts = [regex]::Split($raw, '(?m)(?=^## )')
    foreach ($b in $parts) {
        $h = [regex]::Match($b, '^##\s+((?:T|KR)\d+)\s+\S+\s+(.+?)\s*$', 'Multiline')
        if (-not $h.Success) { continue }
        $id = $h.Groups[1].Value
        $title = $h.Groups[2].Value.Trim()
        $tagsM = [regex]::Match($b, '(?m)^-\s\*\*Tags:\*\*(.*)$')
        if (-not $tagsM.Success) { continue }
        $tagsLine = $tagsM.Groups[1].Value
        # Look up status
        $statusM = [regex]::Match($b, '(?m)^-\s\*\*Status:\*\*\s*(\S+)')
        $status = if ($statusM.Success) { $statusM.Groups[1].Value } else { '-' }
        foreach ($a in $areas.Keys) {
            if ($tagsLine -match [regex]::Escape($a)) {
                $bucket[$a].Add(("{0,-6} [{1,-12}] {2}" -f $id, $status, $title))
            }
        }
    }
}

foreach ($a in $areas.Keys) {
    Write-Host ""
    Write-Host ("### {0}  ({1})  — {2} items" -f $areas[$a], $a, $bucket[$a].Count) -ForegroundColor Cyan
    foreach ($line in $bucket[$a]) { Write-Host "  $line" }
}
