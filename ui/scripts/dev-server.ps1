#Requires -Version 7.0
# dev-server.ps1 — Stop, clear cache, start Next.js dev server for LapuLapu UI
# Usage: powershell -NoProfile -File scripts\dev-server.ps1 [-Port 3000]
#
# Steps: kill node → release port → clear .next cache → start dev server
# The server runs in the foreground.  Health-check is handled externally
# (by post-commit hook or by calling health-check.ps1).

param(
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiDir = (Resolve-Path (Join-Path $scriptDir ".." )).Path
$packageJsonPath = Join-Path $uiDir "package.json"
$lockFilePath = Join-Path $uiDir "package-lock.json"
$nodeModulesDir = Join-Path $uiDir "node_modules"
$nextBin = Join-Path $uiDir "node_modules\.bin\next.cmd"

Write-Host "`n=== LapuLapu Dev Server Restart ===" -ForegroundColor Cyan

if (-not (Test-Path $packageJsonPath)) {
    Write-Host "       ERROR: package.json not found at $packageJsonPath" -ForegroundColor Red
    exit 1
}

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$npmCommand = Get-Command npm -ErrorAction SilentlyContinue
if (-not $nodeCommand -or -not $npmCommand) {
    Write-Host "       ERROR: node and npm must be available on PATH." -ForegroundColor Red
    exit 1
}

# ── 1) Kill any existing node processes ──
Write-Host "[1/4] Stopping existing node processes..." -ForegroundColor Yellow
$procs = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($procs) {
    $procs | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "       Killed $($procs.Count) node process(es)."
    Start-Sleep -Seconds 1
} else {
    Write-Host "       No node processes found."
}

# ── 2) Release the port if anything else holds it ──
Write-Host "[2/4] Releasing port $Port..." -ForegroundColor Yellow
try {
    $portHolder = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq "Listen" }
    if ($portHolder) {
        foreach ($conn in $portHolder) {
            Write-Host "       Killing PID $($conn.OwningProcess) on port $Port"
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 500
    } else {
        Write-Host "       Port $Port is free."
    }
} catch {
    Write-Host "       Port check skipped (not elevated)."
}

# ── 3) Clear Next.js cache ──
Write-Host "[3/4] Clearing .next cache..." -ForegroundColor Yellow
$nextCacheDir = Join-Path $uiDir ".next"
if (Test-Path $nextCacheDir) {
    Remove-Item $nextCacheDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "       Removed .next directory."
} else {
    Write-Host "       No .next cache to clear."
}

# ── 4) Start dev server (foreground — blocks until Ctrl+C) ──
Write-Host "[4/4] Starting Next.js dev server on port $Port..." -ForegroundColor Yellow
Write-Host "       Working directory: $uiDir" -ForegroundColor Gray
Write-Host ""

Set-Location $uiDir
if (-not (Test-Path $nodeModulesDir) -or -not (Test-Path $nextBin)) {
    Write-Host "       Dependencies missing; installing..." -ForegroundColor Yellow
    if (Test-Path $lockFilePath) {
        & $npmCommand.Source ci
    } else {
        & $npmCommand.Source install
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "       ERROR: dependency install failed." -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $nextBin)) {
    Write-Host "       ERROR: next.cmd not found after dependency install." -ForegroundColor Red
    exit 1
}

& $nextBin dev -p $Port
