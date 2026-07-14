#Requires -Version 7.0
# restart-dev.ps1 — Stop services, start Next.js dev server, confirm it's up
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restart-dev.ps1 [-Port 3000]
#        powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restart-dev.ps1 -Port 3000 -ClearCache
#        powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restart-dev.ps1 -Port 3000 -RetryCount 2 -MaxWait 120
#
# Designed for reliable startup after reboot and manual restarts.
# The server is launched as a detached background process so this script
# can return promptly after confirming the server is healthy.

param(
    [int]$Port = 3000,
    [int]$MaxWait = 120,
    [int]$RetryCount = 2,
    [int]$RetryDelaySeconds = 4,
    [switch]$ClearCache
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiDir = (Resolve-Path (Join-Path $scriptDir "..")).Path
$packageJsonPath = Join-Path $uiDir "package.json"
$lockFilePath = Join-Path $uiDir "package-lock.json"
$nodeModulesDir = Join-Path $uiDir "node_modules"
$nextBinCmd = Join-Path $uiDir "node_modules\.bin\next.cmd"
$devLogPath = Join-Path $uiDir ".next-dev.log"
$url = "http://localhost:$Port"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
}

function Test-PortListening {
    param([int]$TargetPort)
    try {
        $listeners = Get-NetTCPConnection -LocalPort $TargetPort -ErrorAction SilentlyContinue |
            Where-Object { $_.State -eq "Listen" }
        return ($listeners -and $listeners.Count -gt 0)
    } catch {
        return $false
    }
}

function Stop-PortProcesses {
    param([int]$TargetPort)
    Write-Host "[1/6] Stopping processes on port $TargetPort..." -ForegroundColor Yellow

    try {
        $portConnections = Get-NetTCPConnection -LocalPort $TargetPort -ErrorAction SilentlyContinue |
            Where-Object { $_.State -eq "Listen" }
        $pids = @($portConnections | Select-Object -ExpandProperty OwningProcess -Unique)

        if ($pids.Count -eq 0) {
            Write-Host "       Port $TargetPort is free."
            return
        }

        foreach ($processId in $pids) {
            try {
                Stop-Process -Id $processId -Force -ErrorAction Stop
                Write-Host "       Stopped PID $processId on port $TargetPort"
            } catch {
                Write-Host "       WARNING: Failed to stop PID ${processId}: $($_.Exception.Message)"
            }
        }

        $deadline = (Get-Date).AddSeconds(10)
        while ((Get-Date) -lt $deadline) {
            if (-not (Test-PortListening -TargetPort $TargetPort)) {
                break
            }
            Start-Sleep -Milliseconds 400
        }
    } catch {
        Write-Host "       Port check unavailable." -ForegroundColor DarkYellow
    }
}

function Stop-NodeProcesses {
    Write-Host "[2/6] Cleaning up remaining node processes..." -ForegroundColor Yellow
    $running = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($running) {
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    $remaining = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($remaining) {
        Write-Host "       WARNING: $($remaining.Count) node process(es) still running."
    } else {
        Write-Host "       All node processes stopped."
    }
}

function Handle-Cache {
    param([bool]$ForceColdStart)
    Write-Host "[3/6] Cache management..." -ForegroundColor Yellow

    $nextCacheDir = Join-Path $uiDir ".next"
    if ($ForceColdStart) {
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
}

function Ensure-Dependencies {
    param([string]$NpmPath)
    Write-Host "[4/6] Validating dependencies..." -ForegroundColor Yellow
    $requiresInstall = $false

    if (-not (Test-Path $nodeModulesDir)) {
        $requiresInstall = $true
        Write-Host "       node_modules missing; install required."
    }

    if (-not (Test-Path $nextBinCmd)) {
        $requiresInstall = $true
        Write-Host "       next binary missing; install required."
    }

    if ($requiresInstall) {
        Push-Location $uiDir
        try {
            if (Test-Path $lockFilePath) {
                Write-Host "       Running npm ci..." -ForegroundColor Gray
                & $NpmPath ci
            } else {
                Write-Host "       Running npm install..." -ForegroundColor Gray
                & $NpmPath install
            }

            if ($LASTEXITCODE -ne 0) {
                throw "Dependency install failed with exit code $LASTEXITCODE."
            }
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "       Dependencies look good."
    }

    if (-not (Test-Path $nextBinCmd)) {
        throw "next.cmd not found after dependency check."
    }
}

function Start-DevServerProcess {
    param([int]$TargetPort)
    Write-Host "[5/6] Starting Next.js dev server on port $TargetPort..." -ForegroundColor Yellow

    if (Test-Path $devLogPath) {
        Remove-Item $devLogPath -Force -ErrorAction SilentlyContinue
    }

    $cmdArgs = "/c cd /d `"$uiDir`" && npm run dev -- -p $TargetPort > `"$devLogPath`" 2>&1"
    $proc = Start-Process cmd.exe -ArgumentList $cmdArgs -WindowStyle Hidden -PassThru

    Write-Host "       Server process launched (background)."
    Write-Host "       Log file: $devLogPath" -ForegroundColor Gray

    Start-Sleep -Seconds 2
    return $proc
}

function Wait-UntilHealthy {
    param(
        [int]$WaitSeconds,
        [string]$TargetUrl,
        [System.Diagnostics.Process]$Process
    )

    Write-Host "[6/6] Waiting for server to respond (max ${WaitSeconds}s)..." -ForegroundColor Yellow

    $startTime = Get-Date
    while (((Get-Date) - $startTime).TotalSeconds -lt $WaitSeconds) {
        try {
            $response = Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
                return @{
                    Healthy = $true
                    Elapsed = $elapsed
                    Reason = ""
                }
            }
        } catch {
            # Not ready yet
        }

        try {
            if ($Process.HasExited) {
                return @{
                    Healthy = $false
                    Elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
                    Reason = "Server process exited early with code $($Process.ExitCode)."
                }
            }
        } catch {
            return @{
                Healthy = $false
                Elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
                Reason = "Server process terminated before health check completed."
            }
        }

        Start-Sleep -Seconds 2
    }

    return @{
        Healthy = $false
        Elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
        Reason = "Timed out waiting for health response."
    }
}

function Show-RecentLogs {
    if (Test-Path $devLogPath) {
        Write-Host "  Last server log lines:" -ForegroundColor Yellow
        Get-Content $devLogPath -Tail 60
    } else {
        Write-Host "  No dev log file found at $devLogPath" -ForegroundColor DarkYellow
    }
}

Write-Header "=== LapuLapu Dev Server Restart ==="

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

if ($RetryCount -lt 1) {
    Write-Host "       ERROR: RetryCount must be at least 1." -ForegroundColor Red
    exit 1
}

Write-Host "       node: $($nodeCommand.Source)" -ForegroundColor Gray
Write-Host "       npm : $($npmCommand.Source)" -ForegroundColor Gray

for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
    $forceColdStart = $ClearCache.IsPresent -or $attempt -gt 1

    if ($attempt -gt 1) {
        Write-Host ""
        Write-Host "  Retry attempt $attempt/$RetryCount" -ForegroundColor Yellow
        Start-Sleep -Seconds $RetryDelaySeconds
    }

    try {
        Stop-PortProcesses -TargetPort $Port
        Stop-NodeProcesses
        Handle-Cache -ForceColdStart:$forceColdStart
        Ensure-Dependencies -NpmPath $npmCommand.Source

        $process = Start-DevServerProcess -TargetPort $Port
        $health = Wait-UntilHealthy -WaitSeconds $MaxWait -TargetUrl $url -Process $process

        if ($health.Healthy) {
            Write-Host ""
            Write-Host "  Dev server is UP at $url (took $($health.Elapsed)s)" -ForegroundColor Green
            Write-Host ""
            exit 0
        }

        Write-Host ""
        Write-Host "  Attempt $attempt failed: $($health.Reason)" -ForegroundColor Red
        Show-RecentLogs
    } catch {
        Write-Host ""
        Write-Host "  Attempt $attempt failed with error: $($_.Exception.Message)" -ForegroundColor Red
        Show-RecentLogs
    }
}

Write-Host ""
Write-Host "  Dev server failed to start after $RetryCount attempt(s)." -ForegroundColor Red
Write-Host "  Try: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restart-dev.ps1 -Port $Port -ClearCache -MaxWait 180" -ForegroundColor Yellow
Write-Host ""
exit 1
