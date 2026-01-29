<#
.SYNOPSIS
    Exports source code into readable text documents for review.

.DESCRIPTION
    Collects C++ headers and source files into formatted text documents
    with file separators, line numbers, and a table of contents.

.PARAMETER OutDir
    Output directory for generated files. Default: repo root.

.PARAMETER Split
    Split into two files (headers + sources). Default: single file.

.PARAMETER LineNumbers
    Include line numbers. Default: true.

.PARAMETER Patterns
    File glob patterns to include. Default: *.h, *.cpp

.EXAMPLE
    .\tools\export-source.ps1
    .\tools\export-source.ps1 -Split
    .\tools\export-source.ps1 -OutDir "C:\temp" -LineNumbers:$false
#>

param(
    [string]$OutDir = "",
    [switch]$Split,
    [bool]$LineNumbers = $true,
    [string[]]$Patterns = @("*.h", "*.cpp", "*.rc", "*.bat"),
    [string[]]$SearchDirs = @("include", "src", ".")
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

if (-not $OutDir) { $OutDir = $repoRoot }

# --- Collect files ---

function Get-SourceFiles {
    param([string]$BaseDir, [string[]]$Dirs, [string[]]$Globs)

    $files = @()
    foreach ($dir in $Dirs) {
        $fullDir = Join-Path $BaseDir $dir
        if (-not (Test-Path $fullDir)) { continue }
        
        # Root dir: no recursion (avoid picking up unrelated files)
        $recurse = ($dir -ne ".")
        
        foreach ($glob in $Globs) {
            if ($recurse) {
                $found = Get-ChildItem -Path $fullDir -Filter $glob -File -Recurse
            } else {
                $found = Get-ChildItem -Path $fullDir -Filter $glob -File
            }
            $files += $found
        }
    }
    return $files | Sort-Object { $_.Extension -eq ".cpp" }, FullName
}

# --- Formatting ---

$separator = "=" * 80
$thinSep   = "-" * 80

function Format-FileBlock {
    param([System.IO.FileInfo]$File, [string]$BaseDir, [bool]$ShowLineNums)

    $relativePath = $File.FullName.Substring($BaseDir.Length + 1) -replace '\\', '/'
    $lines = Get-FileLines -Path $File.FullName

    $block = @()
    $block += ""
    $block += $separator
    $block += "  File: $relativePath"
    $block += "  Lines: $($lines.Count)"
    $block += $separator
    $block += ""

    if ($ShowLineNums) {
        $pad = "$($lines.Count)".Length
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $num = ($i + 1).ToString().PadLeft($pad)
            $block += "$num | $($lines[$i])"
        }
    } else {
        $block += $lines
    }

    $block += ""
    return $block
}

function Format-Header {
    param([string]$Title, [System.IO.FileInfo[]]$Files, [string]$BaseDir)

    $header = @()
    $header += $separator
    $header += "  $Title"
    $header += "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    $header += "  Repository: ThemeToggle"
    $header += $separator
    $header += ""
    $header += "  TABLE OF CONTENTS"
    $header += $thinSep

    $totalLines = 0
    $idx = 1
    foreach ($f in $Files) {
        $rel = $f.FullName.Substring($BaseDir.Length + 1) -replace '\\', '/'
        $lineCount = (Get-FileLines -Path $f.FullName).Count
        $totalLines += $lineCount
        $header += "  $($idx.ToString().PadLeft(2)). $rel ($lineCount lines)"
        $idx++
    }

    $header += $thinSep
    $header += "  Total: $($Files.Count) files, $totalLines lines"
    $header += ""
    return $header
}

function Write-Doc {
    param([string]$Path, [string]$Title, [System.IO.FileInfo[]]$Files, [string]$BaseDir, [bool]$ShowLineNums)

    $doc = @()
    $doc += Format-Header -Title $Title -Files $Files -BaseDir $BaseDir

    foreach ($f in $Files) {
        $doc += Format-FileBlock -File $f -BaseDir $BaseDir -ShowLineNums $ShowLineNums
    }

    $doc += $separator
    $doc += "  END OF DOCUMENT"
    $doc += $separator

    $doc | Out-File -FilePath $Path -Encoding utf8
    return $Path
}

function Get-FileLines {
    param([string]$Path)

    $content = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrEmpty($content)) {
        return @()
    }

    $lines = $content -split "`r?`n"
    if ($lines.Count -gt 0 -and $lines[-1] -eq "" -and $content.EndsWith("`n")) {
        if ($lines.Count -eq 1) {
            $lines = @()
        } else {
            $lines = $lines[0..($lines.Count - 2)]
        }
    }
    return $lines
}

# --- Main ---

$allFiles = Get-SourceFiles -BaseDir $repoRoot -Dirs $SearchDirs -Globs $Patterns

if ($allFiles.Count -eq 0) {
    Write-Host "No source files found." -ForegroundColor Yellow
    exit 0
}

$outputs = @()

if ($Split) {
    $headers = $allFiles | Where-Object { $_.Extension -eq ".h" }
    $sources = $allFiles | Where-Object { $_.Extension -eq ".cpp" }

    if ($headers.Count -gt 0) {
        $path = Join-Path $OutDir "ThemeToggle-Headers.txt"
        Write-Doc -Path $path -Title "ThemeToggle - Header Files" -Files $headers -BaseDir $repoRoot -ShowLineNums $LineNumbers
        $outputs += $path
    }
    if ($sources.Count -gt 0) {
        $path = Join-Path $OutDir "ThemeToggle-Sources.txt"
        Write-Doc -Path $path -Title "ThemeToggle - Source Files" -Files $sources -BaseDir $repoRoot -ShowLineNums $LineNumbers
        $outputs += $path
    }
} else {
    $path = Join-Path $OutDir "ThemeToggle-SourceReview.txt"
    Write-Doc -Path $path -Title "ThemeToggle - Complete Source Review" -Files $allFiles -BaseDir $repoRoot -ShowLineNums $LineNumbers
    $outputs += $path
}

Write-Host ""
Write-Host "Exported $($allFiles.Count) files:" -ForegroundColor Green
foreach ($o in $outputs) {
    $size = [math]::Round((Get-Item $o).Length / 1KB, 1)
    Write-Host "  -> $o ($size KB)" -ForegroundColor Cyan
}
Write-Host ""
