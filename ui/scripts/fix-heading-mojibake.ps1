# Repairs mojibake'd markdown heading separators.
# Pattern observed: " <U+2001>E" replaced original " <U+2014> " (space + em-dash + space).
# Also normalizes KR question-mark separator and the "<U+2181>E" arrow mojibake.

param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$em      = [char]0x2014   # —
$emQuad  = [char]0x2001
$arrow   = [char]0x2192   # →
$badArrow = [char]0x2181  # ↁ (preceded an 'E' in mojibake'd arrows)

$files = @(
    '02-work\tasks.md',
    '02-work\key-results.md',
    '02-work\decisions.md',
    '00-context\projects.md'
)

foreach ($rel in $files) {
    $path = Join-Path $Root $rel
    if (-not (Test-Path $path)) { Write-Host "skip (missing): $rel"; continue }

    $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $orig = $text

    # 1. Heading mojibake: "## ID  <U+2001>E" -> "## ID — "
    $text = $text -replace (" " + $emQuad + "E"), (" " + $em + " ")

    # 2. KR placeholder "## KR### ? Title" -> "## KR### — Title"
    $text = $text -replace '(?m)^(## KR\d+) \? ', ('$1 ' + $em + ' ')

    # 3. Arrow mojibake "<U+2181>E" -> "→ "
    $text = $text -replace ([string]$badArrow + 'E'), ([string]$arrow + ' ')

    if ($text -ne $orig) {
        [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding $false))
        Write-Host ("fixed: {0} (delta {1} chars)" -f $rel, ($text.Length - $orig.Length))
    } else {
        Write-Host "clean: $rel"
    }
}
