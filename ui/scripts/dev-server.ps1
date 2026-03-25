# dev-server.ps1 — Start or restart the Next.js dev server for LapuLapu UI
# Usage: powershell -NoProfile -File scripts\dev-server.ps1 [-Port 3000]

param(
    [int]$Port = 3000
)

$uiDir = "c:\Users\kladavi\Projects\LapuLapu\ui"

# Kill any existing node processes
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# Start dev server from the correct working directory
Set-Location $uiDir
npx next dev -p $Port
