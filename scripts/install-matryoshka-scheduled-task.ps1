#Requires -Version 7.0
<#
.SYNOPSIS
    Register (or remove) the Project Matryoshka daily intake pipeline as a
    Windows Scheduled Task under the current user.

.DESCRIPTION
    Registers a daily task named "Project Matryoshka Automated Intake Pipeline"
    that runs scripts/run-matryoshka-pipeline.ps1 via pwsh 7. The task uses the
    interactive user's context and does NOT require administrator rights.

    Timing: 06:10 local time.
    Rationale: 14-day activity recap is weekly; generated dashboards refresh
    daily; the morning briefing should be available before the work day starts.
    Note on JST: -At is a local-time value. If this machine is set to JST the
    task fires at 06:10 JST. Adjust with -At if you run on a different tz.

.PARAMETER At
    Time-of-day the task should fire. Default 06:10.

.PARAMETER DryRun
    Print what would be registered without changing Task Scheduler.

.PARAMETER Uninstall
    Remove the scheduled task instead of installing it.

.EXAMPLE
    pwsh -File .\scripts\install-matryoshka-scheduled-task.ps1

.EXAMPLE
    pwsh -File .\scripts\install-matryoshka-scheduled-task.ps1 -At "07:00"

.EXAMPLE
    pwsh -File .\scripts\install-matryoshka-scheduled-task.ps1 -Uninstall

.NOTES
    Target shell: PowerShell 7.6.3+ (pwsh).
    Path: C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.3.0_x64__8wekyb3d8bbwe\pwsh.exe
#>

[CmdletBinding()]
param(
    [string] $At        = '06:10',
    [switch] $DryRun,
    [switch] $Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$TaskName   = 'Project Matryoshka Automated Intake Pipeline'
$RepoRoot   = 'C:\Users\kladavi\OneDrive - Manulife\Projects\LapuLapu'
$ScriptPath = Join-Path $RepoRoot 'scripts\run-matryoshka-pipeline.ps1'
$LogDir     = Join-Path $RepoRoot 'logs'

function Get-PwshPath {
    $preferred = 'C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.3.0_x64__8wekyb3d8bbwe\pwsh.exe'
    if (Test-Path -LiteralPath $preferred) { return $preferred }
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'pwsh (PowerShell 7+) not found. Install PowerShell 7 or update this script.'
}

# --- Uninstall ------------------------------------------------------------

if ($Uninstall) {
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $existing) {
        Write-Host "Task '$TaskName' is not registered. Nothing to do."
        return
    }
    if ($DryRun) {
        Write-Host "[DryRun] Would unregister task: $TaskName"
        return
    }
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Unregistered task: $TaskName"
    return
}

# --- Preflight ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Pipeline script not found at: $ScriptPath"
}
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$pwshPath = Get-PwshPath

$argumentString = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

$Action = New-ScheduledTaskAction `
    -Execute $pwshPath `
    -Argument $argumentString `
    -WorkingDirectory $RepoRoot

$Trigger = New-ScheduledTaskTrigger `
    -Daily `
    -At $At

# Task settings tuned for a laptop that may sleep/hibernate.
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -RunOnlyIfNetworkAvailable:$false

# Run in interactive user context (no admin required, no stored credential).
$Principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

Write-Host "Task registration plan:"
Write-Host "  TaskName : $TaskName"
Write-Host "  Execute  : $pwshPath"
Write-Host "  Argument : $argumentString"
Write-Host "  Working  : $RepoRoot"
Write-Host "  Trigger  : Daily at $At (local time)"
Write-Host "  Principal: $env:USERNAME (Interactive, Limited)"
Write-Host "  Logs     : $LogDir\matryoshka-pipeline-YYYY-MM-DD.log"

if ($DryRun) {
    Write-Host "`n[DryRun] Nothing was written to Task Scheduler."
    return
}

# --- Register (idempotent via -Force) -------------------------------------

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description 'Runs Project Matryoshka automated intake and generated dashboard pipeline.' `
    -Force | Out-Null

$task = Get-ScheduledTask -TaskName $TaskName
Write-Host "`nRegistered task: $($task.TaskName)"
Write-Host "State           : $($task.State)"
Write-Host "Next run time   : $((Get-ScheduledTaskInfo -TaskName $TaskName).NextRunTime)"
Write-Host "`nTo run once manually now:"
Write-Host "  Start-ScheduledTask -TaskName `"$TaskName`""
Write-Host "To uninstall:"
Write-Host "  pwsh -File .\scripts\install-matryoshka-scheduled-task.ps1 -Uninstall"
