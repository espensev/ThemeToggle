# ============================================================================
# ThemeToggle Benchmark & Verification
# ============================================================================
# Runs repeated toggles, validates registry state, and records timing/results.
# Usage: .\tools\bench.ps1 -Iterations 1000
# ============================================================================

param(
    [int]$Iterations = 1000,
    [string]$OutPath = "",
    [string]$ExePath = "",
    [string[]]$ExtraArgs = @(),
    [int]$SettleMs = 250,
    [int]$BatchSize = 0,
    [int]$BatchPauseMs = 0,
    [int]$JitterMs = 0,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if (-not $OutPath) {
    $OutPath = Join-Path $repoRoot "bench.csv"
}
if (-not $ExePath) {
    $ExePath = Join-Path $repoRoot "ThemeToggle.exe"
}
if (-not (Test-Path $ExePath)) {
    Write-Error "ThemeToggle.exe not found: $ExePath"
    exit 1
}

$regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"

function Get-ThemeValues {
    $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
    $hasSystem = $false
    $hasApps = $false
    $system = $null
    $apps = $null

    if ($props -and ($props.PSObject.Properties.Name -contains "SystemUsesLightTheme")) {
        $hasSystem = $true
        $system = [int]$props.SystemUsesLightTheme
    }
    if ($props -and ($props.PSObject.Properties.Name -contains "AppsUseLightTheme")) {
        $hasApps = $true
        $apps = [int]$props.AppsUseLightTheme
    }
    return @{
        HasSystem = $hasSystem
        HasApps = $hasApps
        System = $system
        Apps = $apps
    }
}

$initial = Get-ThemeValues
$initialValue = if ($initial.HasSystem) { $initial.System } elseif ($initial.HasApps) { $initial.Apps } else { 0 }
$initialMismatch = $initial.HasSystem -and $initial.HasApps -and ($initial.System -ne $initial.Apps)

Write-Host "Benchmarking $Iterations toggles..." -ForegroundColor Cyan
if ($initialMismatch) {
    Write-Host "Warning: initial SystemUsesLightTheme and AppsUseLightTheme differ." -ForegroundColor Yellow
}

$runArgs = @("/toggle", "/exitcode")
if ($Verbose) {
    # Note: passthru output may not capture correctly for Windows subsystem apps
    $runArgs += "/passthru"
} else {
    $runArgs += "/quiet"
}
if ($ExtraArgs.Count -gt 0) {
    $runArgs += $ExtraArgs
}

$csv = @()
$csv += "Iteration,DurationMs,SettleMs,TotalMs,ExitCode,Changed,BroadcastOk,Theme,OldSystemValue,OldAppsValue,NewValue,RegSystem,RegApps,RegMismatch"

$sw = [System.Diagnostics.Stopwatch]::new()
$failures = 0
$mismatches = 0

for ($i = 1; $i -le $Iterations; $i++) {
    $sw.Restart()
    $iterationStart = $sw.ElapsedMilliseconds
    $before = Get-ThemeValues
    & $ExePath @runArgs | Out-Null
    $exitCode = $LASTEXITCODE
    $sw.Stop()

    if ($SettleMs -gt 0) {
        Start-Sleep -Milliseconds $SettleMs
    }
    if ($JitterMs -gt 0) {
        Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum ($JitterMs + 1))
    }
    $totalMs = $sw.ElapsedMilliseconds - $iterationStart

    $reg = Get-ThemeValues
    $regSystem = if ($reg.HasSystem) { $reg.System } else { "" }
    $regApps = if ($reg.HasApps) { $reg.Apps } else { "" }
    $regMismatch = $false
    if ($reg.HasSystem -and $reg.HasApps -and ($reg.System -ne $reg.Apps)) {
        $regMismatch = $true
    }
    if ($regMismatch) { $mismatches++ }

    # Derive values from exit code
    $changed = $exitCode -in 1,2
    $theme = if ($exitCode -eq 1) { "Light" } elseif ($exitCode -eq 2) { "Dark" } else { "" }
    $broadcastOk = if ($exitCode -eq 20) { "false" } elseif ($exitCode -in 0,1,2) { "true" } else { "" }
    
    # Exit codes: 0=no change, 1=light, 2=dark, 10-12=reg errors, 20=broadcast fail, 30=already running
    if ($exitCode -ge 10 -and $exitCode -lt 20) { $failures++ }

    $oldSystem = if ($before.HasSystem) { $before.System } else { "" }
    $oldApps = if ($before.HasApps) { $before.Apps } else { "" }
    $newValue = if ($reg.HasSystem) { $reg.System } elseif ($reg.HasApps) { $reg.Apps } else { "" }

    $csv += "$i,$($sw.ElapsedMilliseconds),$SettleMs,$totalMs,$exitCode,$changed,$broadcastOk,$theme,$oldSystem,$oldApps,$newValue,$regSystem,$regApps,$regMismatch"

    if ($i % 100 -eq 0) {
        Write-Host "  $i/$Iterations" -ForegroundColor DarkGray
    }

    if ($BatchSize -gt 0 -and $BatchPauseMs -gt 0 -and ($i % $BatchSize -eq 0)) {
        Start-Sleep -Milliseconds $BatchPauseMs
    }
}

$csv | Set-Content -Path $OutPath -Encoding UTF8

Write-Host ""
Write-Host "Done. Failures: $failures  Registry mismatches: $mismatches" -ForegroundColor Green
Write-Host "CSV: $OutPath" -ForegroundColor Cyan

Write-Host ""
Write-Host "Restoring initial theme..." -ForegroundColor Cyan
if ($initialValue -eq 1) {
    & $ExePath "/light" "/quiet" | Out-Null
} else {
    & $ExePath "/dark" "/quiet" | Out-Null
}
