# health-check.ps1 — Poll the dev server until it responds or times out
# Usage: powershell -NoProfile -File scripts\health-check.ps1 [-Port 3000] [-MaxWait 30]

param(
    [int]$Port = 3000,
    [int]$MaxWait = 30
)

$ErrorActionPreference = "Continue"
$url = "http://localhost:$Port"

Write-Host "Waiting for $url to respond (max ${MaxWait}s)..." -ForegroundColor Yellow

$startTime = Get-Date
$healthy = $false

while (((Get-Date) - $startTime).TotalSeconds -lt $MaxWait) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            $healthy = $true
            break
        }
    } catch {
        # Not ready yet
    }
    Start-Sleep -Seconds 2
}

if ($healthy) {
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    Write-Host "`n`u{2705} Dashboard is UP at $url (took ${elapsed}s)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n`u{274C} Dashboard did not respond within ${MaxWait}s at $url" -ForegroundColor Red
    exit 1
}
