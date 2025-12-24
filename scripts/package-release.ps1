param(
    [string]$VersionTag,
    [switch]$Rebuild
)

$ErrorActionPreference = 'Stop'

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

if ($Rebuild) {
    & "$repoRoot\build.bat"
    if ($LASTEXITCODE -ne 0) {
        throw "build.bat failed (exit code $LASTEXITCODE). Run inside a VS Developer Command Prompt or rebuild manually."
    }
}

$payloadDir = Join-Path $repoRoot 'deploy\ThemeToggle'
if (-not (Test-Path $payloadDir)) {
    throw "Payload folder '$payloadDir' not found. Run build.bat first."
}

if (-not $VersionTag) {
    $VersionTag = Get-Date -Format 'yyyyMMdd-HHmmss'
}

$zipName = "ThemeToggle-$VersionTag.zip"
$zipPath = Join-Path (Join-Path $repoRoot 'deploy') $zipName

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path (Join-Path $payloadDir '*') -DestinationPath $zipPath -Force

Write-Host "Release archive created at $zipPath"
