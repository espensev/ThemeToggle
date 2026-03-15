# ============================================================================
# Set GitHub Signing Secrets
# ============================================================================
# Reads your local PFX certificate and pushes the three signing secrets
# to your GitHub repository so the release workflow can sign builds.
#
# Secrets set:
#   THEMETOGGLE_SIGN_PFX_BASE64      — base64-encoded .pfx file
#   THEMETOGGLE_SIGN_PFX_PASSWORD    — PFX password
#   THEMETOGGLE_SIGN_CERT_THUMBPRINT — certificate thumbprint
#
# Usage:
#   .\tools\signing\set-github-secrets.ps1                         # reads from env vars
#   .\tools\signing\set-github-secrets.ps1 -PfxPath "C:\cert.pfx" # explicit path
#   .\tools\signing\set-github-secrets.ps1 -DryRun                # show what would happen
#
# Credential resolution order:
#   PFX path:     -PfxPath param  →  $env:THEMETOGGLE_SIGN_PFX_PATH  →  $env:PFX_PATH  →  prompt
#   PFX password: -PfxPassword    →  $env:THEMETOGGLE_SIGN_PFX_PASSWORD  →  $env:PFX_PASS  →  prompt
#
# Prerequisites:
#   - GitHub CLI (gh) authenticated with repo scope
#   - PowerShell 5.1+ (ships with Windows 10/11)
# ============================================================================

param(
    [string]$PfxPath,
    [string]$PfxPassword,
    [string]$Repo,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Resolve PFX path
# ============================================================================
if (-not $PfxPath) { $PfxPath = $env:THEMETOGGLE_SIGN_PFX_PATH }
if (-not $PfxPath) { $PfxPath = $env:PFX_PATH }

if (-not $PfxPath) {
    $PfxPath = Read-Host "Enter path to .pfx file"
}

if (-not $PfxPath -or -not (Test-Path $PfxPath)) {
    Write-Error "PFX file not found: $PfxPath"
    exit 1
}

$PfxPath = (Resolve-Path $PfxPath).Path
Write-Host "PFX file : $PfxPath" -ForegroundColor Cyan

# ============================================================================
# Resolve PFX password
# ============================================================================
if (-not $PfxPassword) { $PfxPassword = $env:THEMETOGGLE_SIGN_PFX_PASSWORD }
if (-not $PfxPassword) { $PfxPassword = $env:PFX_PASS }

if (-not $PfxPassword) {
    $secure = Read-Host "Enter PFX password" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try   { $PfxPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

if (-not $PfxPassword) {
    Write-Error "PFX password is required."
    exit 1
}

Write-Host "Password : ****" -ForegroundColor Cyan

# ============================================================================
# Base64-encode PFX
# ============================================================================
Write-Host ""
Write-Host "Encoding PFX to base64..." -ForegroundColor White
$pfxBytes = [System.IO.File]::ReadAllBytes($PfxPath)
$pfxBase64 = [System.Convert]::ToBase64String($pfxBytes)
Write-Host "  Base64 length: $($pfxBase64.Length) chars" -ForegroundColor DarkGray

# ============================================================================
# Extract thumbprint
# ============================================================================
Write-Host "Extracting certificate thumbprint..." -ForegroundColor White

try {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
        $PfxPath, $PfxPassword,
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet
    )
    $thumbprint = $cert.Thumbprint
    $subject = $cert.Subject
    $expiry = $cert.NotAfter
    $cert.Dispose()
}
catch {
    Write-Error "Failed to read certificate: $($_.Exception.Message)"
    Write-Error "Check that the PFX password is correct."
    exit 1
}

Write-Host "  Subject    : $subject" -ForegroundColor DarkGray
Write-Host "  Thumbprint : $thumbprint" -ForegroundColor DarkGray
Write-Host "  Expires    : $expiry" -ForegroundColor DarkGray

if ($expiry -lt (Get-Date)) {
    Write-Warning "Certificate has expired! Signatures may not be trusted."
} elseif ($expiry -lt (Get-Date).AddDays(30)) {
    Write-Warning "Certificate expires within 30 days."
}

# ============================================================================
# Resolve target repository
# ============================================================================
if (-not $Repo) {
    # Try to detect from git remote
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl -match 'github\.com[:/](.+?)(?:\.git)?$') {
        $Repo = $Matches[1]
    }
}

if (-not $Repo) {
    Write-Error "Could not detect GitHub repository. Pass -Repo owner/name."
    exit 1
}

Write-Host ""
Write-Host "Target repo: $Repo" -ForegroundColor Cyan

# ============================================================================
# Verify gh CLI
# ============================================================================
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) not found. Install from https://cli.github.com/"
    exit 1
}

$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "GitHub CLI is not authenticated. Run: gh auth login"
    exit 1
}

# ============================================================================
# Summary & confirmation
# ============================================================================
Write-Host ""
Write-Host "Will set the following secrets on $Repo :" -ForegroundColor Yellow
Write-Host "  THEMETOGGLE_SIGN_PFX_BASE64      ($($pfxBase64.Length) chars)" -ForegroundColor White
Write-Host "  THEMETOGGLE_SIGN_PFX_PASSWORD     (****)" -ForegroundColor White
Write-Host "  THEMETOGGLE_SIGN_CERT_THUMBPRINT  ($thumbprint)" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] No secrets were set." -ForegroundColor Yellow
    exit 0
}

$confirm = Read-Host "Proceed? (y/N)"
if ($confirm -notin @("y", "Y", "yes")) {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

# ============================================================================
# Push secrets
# ============================================================================
Write-Host ""

Write-Host "Setting THEMETOGGLE_SIGN_PFX_BASE64..." -ForegroundColor White
$pfxBase64 | gh secret set THEMETOGGLE_SIGN_PFX_BASE64 --repo $Repo
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set THEMETOGGLE_SIGN_PFX_BASE64"; exit 1 }
Write-Host "  [OK]" -ForegroundColor Green

Write-Host "Setting THEMETOGGLE_SIGN_PFX_PASSWORD..." -ForegroundColor White
$PfxPassword | gh secret set THEMETOGGLE_SIGN_PFX_PASSWORD --repo $Repo
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set THEMETOGGLE_SIGN_PFX_PASSWORD"; exit 1 }
Write-Host "  [OK]" -ForegroundColor Green

Write-Host "Setting THEMETOGGLE_SIGN_CERT_THUMBPRINT..." -ForegroundColor White
$thumbprint | gh secret set THEMETOGGLE_SIGN_CERT_THUMBPRINT --repo $Repo
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set THEMETOGGLE_SIGN_CERT_THUMBPRINT"; exit 1 }
Write-Host "  [OK]" -ForegroundColor Green

# ============================================================================
# Done
# ============================================================================
Write-Host ""
Write-Host "All signing secrets set on $Repo" -ForegroundColor Green
Write-Host ""
Write-Host "Verify at: https://github.com/$Repo/settings/secrets/actions" -ForegroundColor DarkGray
Write-Host ""
