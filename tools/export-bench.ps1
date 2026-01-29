# ============================================================================
# ThemeToggle Bench Export
# ============================================================================
# Packages ThemeToggle.exe + bench script for running on another machine.
# Usage: .\tools\export-bench.ps1 [-OutDir "C:\temp\ThemeToggleBench"] [-Zip]
# ============================================================================

param(
    [string]$OutDir = "",
    [switch]$Zip
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$exePath = Join-Path $repoRoot "ThemeToggle.exe"
$benchPath = Join-Path $repoRoot "tools\\bench.ps1"

if (-not (Test-Path $exePath)) {
    Write-Error "ThemeToggle.exe not found. Build first."
    exit 1
}
if (-not (Test-Path $benchPath)) {
    Write-Error "bench.ps1 not found."
    exit 1
}

if (-not $OutDir) {
    $OutDir = Join-Path $repoRoot "bench-export"
}

if (Test-Path $OutDir) {
    Remove-Item $OutDir -Recurse -Force
}

New-Item -ItemType Directory -Path $OutDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutDir "tools") | Out-Null

Copy-Item -Path $exePath -Destination (Join-Path $OutDir "ThemeToggle.exe")
Copy-Item -Path $benchPath -Destination (Join-Path $OutDir "tools\\bench.ps1")

$readme = @()
$readme += "ThemeToggle Benchmark Export"
$readme += ""
$readme += "Run in PowerShell:"
$readme += "  .\\tools\\bench.ps1 -Iterations 1000"
$readme += ""
$readme += "Suggested throttled run:"
$readme += "  .\\tools\\bench.ps1 -Iterations 1000 -SettleMs 750 -BatchSize 50 -BatchPauseMs 4000 -JitterMs 150"
$readme += ""
$readme += "Output:"
$readme += "  bench.csv in the same folder."

$readme | Set-Content -Path (Join-Path $OutDir "BENCH_README.txt") -Encoding UTF8

if ($Zip) {
    $zipPath = Join-Path $repoRoot "ThemeToggle-BenchExport.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    Compress-Archive -Path "$OutDir\\*" -DestinationPath $zipPath -Force
    Write-Host "Created: $zipPath" -ForegroundColor Cyan
} else {
    Write-Host "Exported to: $OutDir" -ForegroundColor Cyan
}
