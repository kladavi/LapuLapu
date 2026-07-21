<#
.SYNOPSIS
  V4.0 Sprint 14 (Phase 8b): Copilot 14-day recap fetch — SCAFFOLD.

.DESCRIPTION
  This script is intentionally a *scaffold* — the browser-automation step is
  DEFERRED per docs/matryoshka-v4-spec.md §8b Fix 2, which states:

      "Deferred until confirmed. Requires capturing the M365 Copilot URL +
       the DOM selector for the response text."

  What this script does today:
    1. Determines today's target filename in 01-inbox/copilot-activity/.
    2. If the target file already exists AND is non-empty, exits early.
    3. Otherwise emits a placeholder markdown scaffold with YAML front-matter,
       the prompt reference, and clearly-marked TODO sections so a human can
       paste the Copilot response into the correct slot.
    4. Prints the exact next-step instruction so the operator can complete
       the ~10-minute manual step without any lookup.

  What this script does NOT do yet (Fix 2 automation TODO):
    - Launch Playwright / Puppeteer against copilot.microsoft.com
    - Wait for the response DOM to settle
    - Extract the response markdown from the DOM and paste it in
    - Detect and handle interactive re-auth prompts

  When Fix 2 is unblocked, replace `Invoke-CopilotFetchStub` below with the
  real Playwright driver. The rest of the pipeline (0-byte guard in Phase 8a,
  intake generator, weekly-report generator) already handles the outcome
  gracefully whether the file is populated automatically or manually.

.PARAMETER Today
  Any date within the target day (defaults to today's date). Used only to
  compute the target filename.

.PARAMETER Force
  Overwrite the target file even if it already exists.

.EXAMPLE
  pwsh -File scripts/fetch-copilot-recap.ps1
  # Emits 01-inbox/copilot-activity/2026-07-21-14-day-activity.md as a
  # placeholder if it doesn't already exist.
#>

[CmdletBinding()]
param(
    [datetime] $Today = (Get-Date),
    [switch]   $Force
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent $PSScriptRoot
$OUT_DIR = Join-Path $ROOT '01-inbox\copilot-activity'
$PROMPT_PATH = Join-Path $ROOT '04-prompts\copilot-14-day-activity-assessment.md'

$dateStr  = $Today.ToString('yyyy-MM-dd')
$fileName = "$dateStr-14-day-activity.md"
$outPath  = Join-Path $OUT_DIR $fileName

if (-not (Test-Path $OUT_DIR)) {
    New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null
}

# --- Early exit if a non-empty target already exists ------------------------

if ((Test-Path $outPath) -and -not $Force) {
    $fi = Get-Item -Path $outPath
    if ($fi.Length -gt 0) {
        Write-Host ("Recap already present ({0} bytes): {1}" -f $fi.Length, $fileName) -ForegroundColor Green
        return
    }
    Write-Host ("Found empty recap file ({0} bytes) - will re-scaffold." -f $fi.Length) -ForegroundColor Yellow
}

# --- Fix 2 automation stub -------------------------------------------------
# When Playwright is wired up, replace this with real browser automation.
function Invoke-CopilotFetchStub {
    param([datetime] $Today)

    return @{
        source        = 'manual-scaffold'
        automated     = $false
        instructions  = @(
            "1. Open the Copilot prompt file: $PROMPT_PATH"
            "2. Paste it into M365 Copilot (BizChat with M365 grounding)."
            "3. Wait for the response to complete."
            "4. Select-all + copy the response markdown."
            "5. Paste it into: $outPath"
            "6. Save and re-run scripts/run-matryoshka-pipeline.ps1."
        )
    }
}

$fetch = Invoke-CopilotFetchStub -Today $Today

# --- Write scaffold markdown -----------------------------------------------

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('type: copilot-activity-recap')
[void]$sb.AppendLine(('generated_on: {0}' -f $dateStr))
[void]$sb.AppendLine('window_days: 14')
[void]$sb.AppendLine(('source: {0}' -f $fetch.source))
[void]$sb.AppendLine('status: placeholder')
[void]$sb.AppendLine('---')
[void]$sb.AppendLine()
[void]$sb.AppendLine(('# 14-Day Activity Recap — {0}' -f $dateStr))
[void]$sb.AppendLine()
[void]$sb.AppendLine('> _This file is a placeholder scaffold from `scripts/fetch-copilot-recap.ps1`._')
[void]$sb.AppendLine('> _Playwright-based recap fetch is deferred (spec Phase 8b Fix 2)._')
[void]$sb.AppendLine('> _Complete the manual paste-in below, then remove this block._')
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Next steps')
[void]$sb.AppendLine()
foreach ($step in $fetch.instructions) { [void]$sb.AppendLine(('- {0}' -f $step)) }
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Paste Copilot response below this line')
[void]$sb.AppendLine()
[void]$sb.AppendLine('<!-- BEGIN COPILOT RESPONSE -->')
[void]$sb.AppendLine()
[void]$sb.AppendLine('<!-- END COPILOT RESPONSE -->')
[void]$sb.AppendLine()

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Write-Host ("Scaffold written: 01-inbox/copilot-activity/{0}" -f $fileName) -ForegroundColor Green
Write-Host '' -ForegroundColor Cyan
Write-Host 'Next steps:' -ForegroundColor Cyan
foreach ($step in $fetch.instructions) { Write-Host ('  ' + $step) -ForegroundColor Cyan }
