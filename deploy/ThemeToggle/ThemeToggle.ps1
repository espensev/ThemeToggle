# ============================================================================
# ThemeToggle Silent Launcher (PowerShell)
# ============================================================================
# Purpose: Launch ThemeToggle.exe silently without showing console
# Advantages over VBS:
#   - Better error handling
#   - Can capture exit codes
#   - More flexible argument passing
# ============================================================================

param(
    [switch]$Light,
    [switch]$Dark,
    [switch]$Toggle,
    [switch]$ShowWindow
)

# Get script directory and exe path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptDir "ThemeToggle.exe"

# Verify executable exists
if (-not (Test-Path $exePath)) {
    if ($ShowWindow) {
        Write-Error "ThemeToggle.exe not found in: $scriptDir"
    }
    exit 1
}

# Build arguments
$args = @("/quiet")
if ($Light) { $args += "/light" }
elseif ($Dark) { $args += "/dark" }
else { $args += "/toggle" }

# Create process start info for hidden window
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exePath
$psi.Arguments = $args -join " "
$psi.WindowStyle = if ($ShowWindow) { "Normal" } else { "Hidden" }
$psi.CreateNoWindow = -not $ShowWindow
$psi.UseShellExecute = $false

# Start process
try {
    $process = [System.Diagnostics.Process]::Start($psi)
    
    # Don't wait - instant return for maximum responsiveness
    # $process.WaitForExit()
    # exit $process.ExitCode
    
    exit 0
}
catch {
    if ($ShowWindow) {
        Write-Error "Failed to launch ThemeToggle: $_"
    }
    exit 1
}
