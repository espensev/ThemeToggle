# ============================================================================
# ThemeToggle Silent Launcher (PowerShell)
# ============================================================================
# Purpose: Launch ThemeToggle.exe silently without showing console
# Advantages over VBS:
#   - Better error handling
#   - Can capture exit codes (use -Wait)
#   - More flexible argument passing
# ============================================================================

param(
    [switch]$Light,
    [switch]$Dark,
    [switch]$Toggle,
    [switch]$ShowWindow,
    [switch]$Wait
)

# Get script directory and resolve the exe path for both:
#   - portable zip layout: dist\launchers\ThemeToggle.ps1 -> ..\..\ThemeToggle.exe
#   - same-folder layout:  ThemeToggle.ps1 next to ThemeToggle.exe
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-ExePath {
    param([string]$BaseDir)

    $candidates = @(
        (Join-Path $BaseDir "ThemeToggle.exe"),
        (Join-Path (Split-Path -Parent $BaseDir) "ThemeToggle.exe"),
        (Join-Path (Split-Path -Parent (Split-Path -Parent $BaseDir)) "ThemeToggle.exe")
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    return $null
}

$exePath = Resolve-ExePath -BaseDir $scriptDir

# Verify executable exists
if (-not (Test-Path $exePath)) {
    if ($ShowWindow) {
        Write-Error "ThemeToggle.exe not found relative to: $scriptDir"
    }
    exit 1
}

# Build arguments
$ttArgs = @("/quiet")
if ($Light) { $ttArgs += "/light" }
elseif ($Dark) { $ttArgs += "/dark" }
else { $ttArgs += "/toggle" }
if ($Wait) { $ttArgs += "/exitcode" }

# Create process start info for hidden window
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exePath
$psi.Arguments = $ttArgs -join " "
$psi.WindowStyle = if ($ShowWindow) { "Normal" } else { "Hidden" }
$psi.CreateNoWindow = -not $ShowWindow
$psi.UseShellExecute = $false

# Start process
try {
    $process = [System.Diagnostics.Process]::Start($psi)
    
    if ($Wait) {
        $process.WaitForExit()
        exit $process.ExitCode
    }

    # Default: don't wait (instant return for maximum responsiveness)
    exit 0
}
catch {
    if ($ShowWindow) {
        Write-Error "Failed to launch ThemeToggle: $_"
    }
    exit 1
}
