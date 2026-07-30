# ============================================================================
# ThemeToggle - Set WinGet Submission Token
# ============================================================================
# Validates a GitHub PAT and stores it as the WINGET_GITHUB_TOKEN repository
# secret used by the "Publish to WinGet" workflow (wingetcreate submit).
# Run this whenever the PAT is rotated or the publish run fails with
# "Token was invalid".
#
# Usage:
#   .\tools\release\set-winget-token.ps1                        # prompt, validate, store
#   .\tools\release\set-winget-token.ps1 -PublishVersion 1.6.0  # ...then re-dispatch publish
# ============================================================================

param(
    [string]$Repo = "espensev/ThemeToggle",
    [string]$PublishVersion = ""
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Fail "gh CLI is not available on PATH."
}

Write-Host "Setting WINGET_GITHUB_TOKEN on $Repo" -ForegroundColor White
Write-Host "The token needs the 'public_repo' scope (classic PAT) so wingetcreate can fork and open PRs on microsoft/winget-pkgs."
Write-Host ""

$secure = Read-Host "Paste the new GitHub PAT" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try     { $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }

if (-not $token -or -not $token.Trim()) {
    Fail "No token entered."
}
$token = $token.Trim()

# Validate the token against the GitHub API before storing anything.
$headers = @{
    Authorization          = "Bearer $token"
    Accept                 = "application/vnd.github+json"
    "User-Agent"           = "ThemeToggle-set-winget-token"
    "X-GitHub-Api-Version" = "2022-11-28"
}

try {
    $resp = Invoke-WebRequest -Uri "https://api.github.com/user" -Headers $headers -UseBasicParsing -ErrorAction Stop
}
catch {
    Fail "Token was rejected by the GitHub API (invalid, expired, or revoked). $($_.Exception.Message)"
}

$login = ($resp.Content | ConvertFrom-Json).login
Ok "Token authenticates as: $login"

$scopes = @($resp.Headers["X-OAuth-Scopes"]) -join ", "
if ($scopes) {
    Write-Host "Token scopes: $scopes"
    if ($scopes -notmatch '\bpublic_repo\b' -and $scopes -notmatch '(^|,\s*)repo(,|$)') {
        Fail "Classic PAT is missing the 'public_repo' (or 'repo') scope required by wingetcreate."
    }
    Ok "Required scope present"
}
else {
    Write-Host "No scopes header (fine-grained PAT). Ensure it can fork and write to your winget-pkgs fork." -ForegroundColor Yellow
}

$expiry = @($resp.Headers["github-authentication-token-expiration"]) -join ""
if ($expiry) {
    Write-Host "Token expires: $expiry" -ForegroundColor Yellow
}
else {
    Write-Host "Token has no advertised expiry."
}

$token | gh secret set WINGET_GITHUB_TOKEN --repo $Repo
if ($LASTEXITCODE -ne 0) {
    Fail "gh secret set failed with exit code $LASTEXITCODE."
}
Ok "WINGET_GITHUB_TOKEN stored on $Repo"

$token = $null

if ($PublishVersion) {
    if ($PublishVersion -notmatch '^\d+\.\d+\.\d+$') {
        Fail "PublishVersion must be in x.y.z format. Got: '$PublishVersion'"
    }
    gh workflow run "Publish to WinGet" --repo $Repo -f version=$PublishVersion
    if ($LASTEXITCODE -ne 0) {
        Fail "Failed to dispatch the Publish to WinGet workflow."
    }
    Ok "Dispatched Publish to WinGet for $PublishVersion"
    Write-Host "Watch it with: gh run list --repo $Repo --workflow `"Publish to WinGet`" --limit 1"
}
else {
    Write-Host ""
    Write-Host "To resubmit a release now:"
    Write-Host "  gh workflow run `"Publish to WinGet`" --repo $Repo -f version=<x.y.z>"
}
