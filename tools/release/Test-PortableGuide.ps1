#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixtureRoot = Join-Path $tempBase ('themetoggle-guide-' + [guid]::NewGuid().ToString('N'))

function Write-Success { param([string]$Message) }

try {
    $tokenList = $null
    $parseErrors = $null
    # Decode the repository's UTF-8 source explicitly when extracting the
    # stage; Windows PowerShell otherwise guesses ANSI for a BOM-less file.
    $sourceText = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'build-and-publish.ps1'))
    $ast = [Management.Automation.Language.Parser]::ParseInput(
        $sourceText, [ref]$tokenList, [ref]$parseErrors)
    if ($parseErrors.Count -ne 0) { throw 'Publisher did not parse.' }
    $zipBlocks = @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.IfStatementAst] -and
        $node.Clauses[0].Item1.Extent.Text -eq '$NoZip' -and
        $node.Extent.Text -match 'ThemeToggle-Portable\.zip'
    }, $true))
    if ($zipBlocks.Count -ne 1) { throw 'Expected exactly one portable ZIP stage.' }

    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'docs'),
        (Join-Path $fixtureRoot 'Resources'), (Join-Path $fixtureRoot 'dist/launchers') -Force | Out-Null
    foreach ($name in @('ThemeToggle.exe', 'LICENSE.txt', 'setup.bat', 'uninstall.bat',
            'Resources/ThemeToggle.ico', 'dist/launchers/ThemeToggle.ps1')) {
        Set-Content -LiteralPath (Join-Path $fixtureRoot $name) -Value 'inert packaging fixture' -Encoding ASCII
    }
    $guide = Join-Path $sourceRoot 'docs/USAGE.md'
    $expectedHash = (Get-FileHash -LiteralPath $guide).Hash
    Copy-Item -LiteralPath $guide -Destination (Join-Path $fixtureRoot 'docs/USAGE.md')
    if (Test-Path -LiteralPath (Join-Path $fixtureRoot 'README.md')) { throw 'Fixture must omit the source root guide.' }

    # Execute the actual ZIP stage with inert inputs; do not run release,
    # signing, versioning, WinGet submission or the executable itself.
    $repoRoot = [IO.Path]::GetFullPath($fixtureRoot)
    $expectedDeploy = [IO.Path]::GetFullPath((Join-Path $repoRoot 'deploy/ThemeToggle'))
    if (-not $expectedDeploy.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture deployment path.' }
    $NoZip = $false
    $DryRun = $false
    & ([scriptblock]::Create($zipBlocks[0].Extent.Text))

    $archive = Join-Path $fixtureRoot 'ThemeToggle-Portable.zip'
    $extracted = Join-Path $fixtureRoot 'extracted'
    Expand-Archive -LiteralPath $archive -DestinationPath $extracted
    if ((Get-FileHash -LiteralPath (Join-Path $extracted 'README.md')).Hash -ne $expectedHash) {
        throw 'Portable README does not match the selected operator guide.'
    }
    Write-Output 'PASS: actual portable ZIP stage packages docs/USAGE.md as README.md without a source root README.'
}
finally {
    $resolved = [IO.Path]::GetFullPath($fixtureRoot)
    if (-not $resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($resolved) -notlike 'themetoggle-guide-*') { throw 'Unsafe test cleanup path.' }
    if (Test-Path -LiteralPath $resolved) {
        if (Get-ChildItem -LiteralPath $resolved -Recurse -Force -Attributes ReparsePoint) { throw 'Fixture contains reparse points.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
