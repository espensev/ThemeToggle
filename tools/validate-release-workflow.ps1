# ============================================================================
# Release / WinGet Workflow Validator
# ============================================================================
# Enforces the canonical CI release flow for this repo:
#   - Release publishes ThemeToggle.exe + ThemeToggle-Portable.zip only
#   - Release uploads the generated winget-manifests snapshot
#   - Publish to WinGet restores and trusts that manifest snapshot
#   - Asset verification stays manifest-driven (InstallerUrl), not filename-driven
#   - Local validation and CI both execute this validator
# ============================================================================

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

function Assert-ContainsLiteral {
    param(
        [string]$Content,
        [string]$Needle,
        [string]$Description
    )

    if (-not $Content.Contains($Needle)) {
        Fail $Description
    }
}

function Assert-NotContainsLiteral {
    param(
        [string]$Content,
        [string]$Needle,
        [string]$Description
    )

    if ($Content.Contains($Needle)) {
        Fail $Description
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$releaseWorkflowPath = Join-Path $repoRoot ".github\workflows\release.yml"
$wingetPublishWorkflowPath = Join-Path $repoRoot ".github\workflows\winget-publish.yml"
$validateWingetWorkflowPath = Join-Path $repoRoot ".github\workflows\validate-winget.yml"
$validateBatPath = Join-Path $repoRoot "tools\validate.bat"
$validateWingetPath = Join-Path $repoRoot "tools\validate-winget.ps1"
$releaseDocsPath = Join-Path $repoRoot "docs\RELEASE.md"
$developmentDocsPath = Join-Path $repoRoot "docs\DEVELOPMENT.md"
$releaseTemplatePath = Join-Path $repoRoot ".github\RELEASE_TEMPLATE.md"

foreach ($path in @(
    $releaseWorkflowPath,
    $wingetPublishWorkflowPath,
    $validateWingetWorkflowPath,
    $validateBatPath,
    $validateWingetPath,
    $releaseDocsPath,
    $developmentDocsPath,
    $releaseTemplatePath
)) {
    if (-not (Test-Path $path)) {
        Fail "Required file not found: $path"
    }
}

$releaseWorkflow = Get-Content $releaseWorkflowPath -Raw
$wingetPublishWorkflow = Get-Content $wingetPublishWorkflowPath -Raw
$validateWingetWorkflow = Get-Content $validateWingetWorkflowPath -Raw
$validateBat = Get-Content $validateBatPath -Raw
$validateWinget = Get-Content $validateWingetPath -Raw
$releaseDocs = Get-Content $releaseDocsPath -Raw
$developmentDocs = Get-Content $developmentDocsPath -Raw
$releaseTemplate = Get-Content $releaseTemplatePath -Raw

Assert-ContainsLiteral $releaseWorkflow '.\tools\release\build-and-publish.ps1 -NoInstaller' "Release workflow must build artifacts with build-and-publish.ps1 -NoInstaller."
Assert-ContainsLiteral $releaseWorkflow 'name: winget-manifests' "Release workflow must upload the winget-manifests artifact."
Assert-ContainsLiteral $releaseWorkflow 'release-inputs/VERSION' "Release workflow must stage VERSION in the winget-manifests artifact."
Assert-ContainsLiteral $releaseWorkflow 'release-inputs/winget/*.yaml' "Release workflow must stage winget YAML files in the winget-manifests artifact."
Assert-ContainsLiteral $releaseWorkflow '-VerifyLocalArtifacts' "Release workflow must validate manifests against the CI-built local artifact hashes."
Assert-ContainsLiteral $releaseWorkflow 'ThemeToggle.exe' "Release workflow must publish ThemeToggle.exe."
Assert-ContainsLiteral $releaseWorkflow 'ThemeToggle-Portable.zip' "Release workflow must publish ThemeToggle-Portable.zip."
Assert-NotContainsLiteral $releaseWorkflow 'ThemeToggle-Setup-' "Release workflow must not publish the legacy ThemeToggle-Setup-* asset in CI."
Ok "Release workflow matches the canonical CI artifact flow"

Assert-ContainsLiteral $wingetPublishWorkflow 'name: winget-manifests' "Publish to WinGet workflow must download the winget-manifests artifact."
Assert-ContainsLiteral $wingetPublishWorkflow 'Copy-Item "generated-release\VERSION" "VERSION" -Force' "Publish to WinGet workflow must restore VERSION from the manifest snapshot."
Assert-ContainsLiteral $wingetPublishWorkflow 'Copy-Item "generated-release\winget\*.yaml" "winget\" -Force' "Publish to WinGet workflow must restore winget manifests from the manifest snapshot."
Assert-ContainsLiteral $wingetPublishWorkflow 'InstallerUrl:\s*(\S+)\s*$' "Publish to WinGet workflow must read InstallerUrl values from the restored installer manifest."
Assert-ContainsLiteral $wingetPublishWorkflow '-VerifyGitHubReleaseDigests' "Publish to WinGet workflow must validate restored manifests against published release digests."
Assert-ContainsLiteral $wingetPublishWorkflow '.\wingetcreate.exe submit' "Publish to WinGet workflow must submit curated local manifests with wingetcreate submit."
Assert-NotContainsLiteral $wingetPublishWorkflow 'wingetcreate update' "Publish to WinGet workflow must not use wingetcreate update for this package."
Assert-NotContainsLiteral $wingetPublishWorkflow 'ThemeToggle-Setup-' "Publish to WinGet workflow must not hard-code the legacy ThemeToggle-Setup-* asset name."
Ok "Publish to WinGet workflow remains manifest-driven"

Assert-ContainsLiteral $validateWingetWorkflow '.\tools\validate-winget.ps1' "Validate WinGet workflow must run the manifest validator."
Assert-ContainsLiteral $validateWingetWorkflow '.\tools\validate-release-workflow.ps1' "Validate WinGet workflow must run the release workflow validator."
Assert-ContainsLiteral $validateWingetWorkflow 'tools/validate-release-workflow.ps1' "Validate WinGet workflow must trigger on changes to the release workflow validator."
Assert-ContainsLiteral $validateWingetWorkflow '.github/RELEASE_TEMPLATE.md' "Validate WinGet workflow must trigger on release template changes."
Assert-ContainsLiteral $validateWingetWorkflow 'docs/RELEASE.md' "Validate WinGet workflow must trigger on release documentation changes."
Ok "CI validation covers workflow and release-note drift"

Assert-ContainsLiteral $validateBat 'tools\validate-release-workflow.ps1' "tools\\validate.bat must run the release workflow validator."
Ok "Local validation covers the canonical workflow"

Assert-ContainsLiteral $validateWinget 'ThemeToggle-Portable.zip' "WinGet validator must validate the portable ZIP release asset."
Assert-ContainsLiteral $validateWinget 'VerifyGitHubReleaseDigests' "WinGet validator must support GitHub release digest verification."
Assert-ContainsLiteral $validateWinget 'PortableCommandAlias' "WinGet validator must enforce the portable command alias entry."
Ok "Manifest validator matches the portable-only WinGet package shape"

Assert-ContainsLiteral $releaseDocs 'winget-manifests' "docs/RELEASE.md must describe the winget-manifests artifact flow."
Assert-ContainsLiteral $releaseDocs 'InstallerUrl' "docs/RELEASE.md must state that WinGet validation reads InstallerUrl values from the manifest."
Assert-ContainsLiteral $releaseDocs 'ThemeToggle.exe' "docs/RELEASE.md must describe ThemeToggle.exe as a release artifact."
Assert-ContainsLiteral $releaseDocs 'ThemeToggle-Portable.zip' "docs/RELEASE.md must describe ThemeToggle-Portable.zip as a release artifact."
Assert-ContainsLiteral $releaseDocs 'tools\validate-release-workflow.ps1' "docs/RELEASE.md must point contributors to the workflow validator."
Ok "Release docs describe the canonical workflow"

Assert-ContainsLiteral $developmentDocs 'tools\validate-release-workflow.ps1' "docs/DEVELOPMENT.md must list the release workflow validator."
Ok "Development docs mention the workflow validator"

Assert-ContainsLiteral $releaseTemplate 'ThemeToggle.exe' "Release template must link ThemeToggle.exe."
Assert-ContainsLiteral $releaseTemplate 'ThemeToggle-Portable.zip' "Release template must link ThemeToggle-Portable.zip."
Assert-NotContainsLiteral $releaseTemplate 'ThemeToggle-Setup-X.Y.Z.exe' "Release template must not advertise the legacy ThemeToggle-Setup-X.Y.Z.exe asset."
Ok "Release template matches the current CI release shape"

Write-Host "[PASS] Release / WinGet workflow invariants validated successfully." -ForegroundColor Green
