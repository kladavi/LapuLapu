# restart-dev.ps1 — Stop services, start Next.js dev server, confirm it's up
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restart-dev.ps1 [-Port 3000]
#        powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restart-dev.ps1 -Port 3000 -ClearCache
#
# Designed to be called from git post-commit hook or manually.
# The server is launched as a detached background process so this script
# can return promptly after confirming the server is healthy.
#
# By default the .next cache is preserved (warm restart ~15s).
# Pass -ClearCache to force a cold restart (~60-90s) when troubleshooting.

param(
    [int]$Port = 3000,
    [int]$MaxWait = 60,
    [switch]$ClearCache
)

$ErrorActionPreference = "Continue"
$uiDir = "c:\Users\kladavi\Projects\LapuLapu\ui"
$url   = "http://localhost:$Port/api/load-local"

Write-Host ""
Write-Host "=== LapuLapu Dev Server Restart ===" -ForegroundColor Cyan

# ── 1) Stop any processes holding the port ──
Write-Host "[1/5] Stopping processes on port $Port..." -ForegroundColor Yellow
try {
    $listeners = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq "Listen" }
    if ($listeners) {
        foreach ($conn in $listeners) {
            Write-Host "       Killing PID $($conn.OwningProcess)"
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "       Port $Port is free."
    }
} catch {
    Write-Host "       Port check unavailable."
}

# ── 2) Kill all remaining node processes ──
Write-Host "[2/5] Cleaning up remaining node processes..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$remaining = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($remaining) {
    Write-Host "       WARNING: $($remaining.Count) node process(es) still running."
} else {
    Write-Host "       All node processes stopped."
}

# ── 3) Optionally clear Next.js cache ──
Write-Host "[3/5] Cache management..." -ForegroundColor Yellow
$nextCacheDir = Join-Path $uiDir ".next"
if ($ClearCache) {
    if (Test-Path $nextCacheDir) {
        Remove-Item $nextCacheDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "       Removed .next directory (cold restart)."
    } else {
        Write-Host "       No .next cache to clear."
    }
} else {
    if (Test-Path $nextCacheDir) {
        Write-Host "       Keeping .next cache (warm restart)."
    } else {
        Write-Host "       No .next cache present (will be cold start)."
    }
}

# ── 4) Start dev server as a detached background process ──
Write-Host "[4/5] Starting Next.js dev server on port $Port..." -ForegroundColor Yellow

# cmd /c launches npx in a hidden window. The process tree survives after
# this script exits. cmd handles PATH resolution for npx reliably.
Start-Process cmd.exe `
    -ArgumentList "/c", "cd /d `"$uiDir`" && npx next dev -p $Port" `
    -WindowStyle Hidden `
    -PassThru | Out-Null

Write-Host "       Server process launched (background)."

# ── 5) Health check: poll until the API responds ──
Write-Host "[5/5] Waiting for server to respond (max ${MaxWait}s)..." -ForegroundColor Yellow

$startTime = Get-Date
$healthy = $false

while (((Get-Date) - $startTime).TotalSeconds -lt $MaxWait) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            $healthy = $true
            break
        }
    } catch {
        # Not ready yet
    }
    Start-Sleep -Seconds 3
}

if ($healthy) {
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    Write-Host ""
    Write-Host "  Dev server is UP at http://localhost:$Port (took ${elapsed}s)" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host ""
    Write-Host "  Dev server did not respond within ${MaxWait}s" -ForegroundColor Red
    Write-Host ""
    exit 1
}
