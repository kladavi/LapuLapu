<#
.SYNOPSIS
    V4.0 Sprint 26 - One-command deploy of the Quartz knowledge portal into the
    Next.js dashboard at ui/public/quartz/.

.DESCRIPTION
    Chains the four steps of the local hosting model documented in
    docs/QuartzHostingDecision.md:

      1. prepare-quartz-content.ps1  (regenerate markdown from canonical model)
      2. quartz build                 (emit static HTML into ui/public/quartz)
      3. test-quartz-links.ps1        (integrity gate - 0 broken refs required)
      4. Readiness message with URLs to test

    Aborts (non-zero exit) if any step fails, so a red build is never mistaken
    for a green deploy.

.PARAMETER SkipContentPrep
    Skip step 1 (assume quartz-content is already current). Use when iterating
    on Quartz config or the deploy pipeline itself.

.PARAMETER SkipValidator
    Skip step 3 (integrity gate). NOT RECOMMENDED. Only for debugging.

.EXAMPLE
    pwsh -File .\scripts\deploy-quartz-local.ps1

.EXAMPLE
    pwsh -File .\scripts\deploy-quartz-local.ps1 -SkipContentPrep

.NOTES
    Repo layout assumed:
      <repo-root>/
        scripts/deploy-quartz-local.ps1   (this file)
        scripts/prepare-quartz-content.ps1
        scripts/test-quartz-links.ps1
        quartz-content/                    (input markdown)
        quartz-site/                       (Quartz install, gitignored)
        ui/public/quartz/                  (output, gitignored)
#>

[CmdletBinding()]
param(
    [switch]$SkipContentPrep,
    [switch]$SkipValidator
)

$ErrorActionPreference = 'Stop'
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Resolve repo root as the parent of the scripts/ dir this file lives in.
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot 'quartz-content'))) {
    throw "Cannot locate repo root. Expected quartz-content/ under: $RepoRoot"
}

Write-Host ""
Write-Host "=== V4.0 Sprint 26 - Deploy Quartz to ui/public/quartz/ ===" -ForegroundColor Cyan
Write-Host "Repo root: $RepoRoot"
Write-Host ""

# --- Step 1: content prep ---------------------------------------------------
if ($SkipContentPrep) {
    Write-Host "[1/4] Skipping content prep (per -SkipContentPrep)." -ForegroundColor Yellow
}
else {
    Write-Host "[1/4] Regenerating quartz-content/ from canonical model ..." -ForegroundColor Cyan
    $prepScript = Join-Path $RepoRoot 'scripts\prepare-quartz-content.ps1'
    if (-not (Test-Path $prepScript)) { throw "Missing: $prepScript" }
    & pwsh -NoProfile -File $prepScript -Clean
    if ($LASTEXITCODE -ne 0) { throw "prepare-quartz-content.ps1 failed with exit code $LASTEXITCODE." }
}

# --- Step 2: quartz build ---------------------------------------------------
Write-Host ""
Write-Host "[2/4] Building Quartz into ui/public/quartz/ ..." -ForegroundColor Cyan
$quartzSite = Join-Path $RepoRoot 'quartz-site'
$outDir = Join-Path $RepoRoot 'ui\public\quartz'
if (-not (Test-Path $quartzSite)) {
    throw "quartz-site/ is missing. See quartz-pilot-review.md for install steps."
}

# Fresh output dir so removed pages disappear.
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Path $outDir | Out-Null

Push-Location $quartzSite
try {
    & npx quartz build -d ..\quartz-content -o ..\ui\public\quartz
    if ($LASTEXITCODE -ne 0) { throw "quartz build failed with exit code $LASTEXITCODE." }
}
finally {
    Pop-Location
}

$emittedCount = (Get-ChildItem $outDir -Recurse -File | Measure-Object).Count
Write-Host "      Emitted files: $emittedCount"

# --- Step 3: integrity gate -------------------------------------------------
if ($SkipValidator) {
    Write-Host ""
    Write-Host "[3/4] Skipping validator (per -SkipValidator). NOT RECOMMENDED." -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "[3/4] Running link validator (integrity gate) ..." -ForegroundColor Cyan
    $validator = Join-Path $RepoRoot 'scripts\test-quartz-links.ps1'
    if (-not (Test-Path $validator)) { throw "Missing: $validator" }
    Push-Location $RepoRoot
    try {
        & pwsh -NoProfile -File $validator -SiteDir $outDir
        if ($LASTEXITCODE -ne 0) {
            throw "Link validator FAILED (exit $LASTEXITCODE). Deploy aborted. See quartz-link-validation.md."
        }
    }
    finally {
        Pop-Location
    }
}

# --- Step 4: readiness ------------------------------------------------------
$sw.Stop()
Write-Host ""
Write-Host "[4/4] Done in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s." -ForegroundColor Green
Write-Host ""
Write-Host "Portal is deployed at ui/public/quartz/. To serve it:" -ForegroundColor Green
Write-Host ""
Write-Host "  cd ui"
Write-Host "  npm run dev        # dev mode (recommended for iteration)"
Write-Host "  # or"
Write-Host "  npm run build      # ~10 min cold on OneDrive-synced hosts"
Write-Host "  npm run start      # production mode"
Write-Host ""
Write-Host "Then open:" -ForegroundColor Green
Write-Host "  http://localhost:3000/quartz/                   (portal home)"
Write-Host "  http://localhost:3000/quartz/decisions          (decisions index)"
Write-Host "  http://localhost:3000/quartz/risks              (risks index)"
Write-Host "  http://localhost:3000/quartz/workstreams        (workstreams index)"
Write-Host "  http://localhost:3000/quartz/tags               (tags index)"
Write-Host ""
