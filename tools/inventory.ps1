<#
.SYNOPSIS
  Generates a repository inventory report (structure + per-folder stats).

.DESCRIPTION
  By default, inventories tracked files only (via `git ls-files`) and writes
  a Markdown report with:
    - A file tree (tracked files)
    - Per-folder file counts (recursive) and word counts

  Word counts are computed by whitespace tokenization on "text-like" file
  extensions; binary files are excluded from word totals.

.PARAMETER OutPath
  Output Markdown path (relative to repo root). Default: docs/INVENTORY.md

.PARAMETER MaxTreeDepth
  Maximum depth for the rendered tree. Default: 10

.PARAMETER TrackedOnly
  When set (default), uses `git ls-files`. When not set, inventories the
  working directory (excluding common junk folders).
#>

param(
    [string]$OutPath = "docs/INVENTORY.md",
    [int]$MaxTreeDepth = 10,
    [switch]$TrackedOnly = $true,
    [string[]]$WordCountExtensions = @(
        ".md", ".txt",
        ".ps1", ".bat", ".cmd",
        ".cpp", ".c", ".h", ".hpp",
        ".rc", ".nsi",
        ".yml", ".yaml", ".json",
        ".xml", ".manifest",
        ".props", ".targets", ".sln"
    )
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Get-RelativeDir {
    param([string]$Path)

    if (-not $Path.Contains("/")) { return "." }
    return $Path.Substring(0, $Path.LastIndexOf("/"))
}

function Get-DirPrefixes {
    param([string]$Dir)

    $prefixes = @(".")
    if ($Dir -eq "." -or -not $Dir) { return $prefixes }

    $parts = $Dir.Split("/")
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $prefixes += ($parts[0..$i] -join "/")
    }
    return $prefixes
}

function Get-WordCount {
    param([string]$RelativePath, [string[]]$AllowedExtensions)

    $ext = [System.IO.Path]::GetExtension($RelativePath)
    if (-not $ext) { return 0 }
    if (-not ($AllowedExtensions -contains $ext.ToLowerInvariant())) { return 0 }

    try {
        $text = Get-Content -LiteralPath $RelativePath -Raw -ErrorAction Stop
        if ([string]::IsNullOrEmpty($text)) { return 0 }
        return [regex]::Matches($text, "\S+").Count
    }
    catch {
        # Treat unreadable/binary files as 0 words (still counted as a file).
        return 0
    }
}

function New-TreeNode {
    return @{
        Dirs  = @{}
        Files = New-Object System.Collections.Generic.List[string]
    }
}

function Add-ToTree {
    param(
        [hashtable]$RootNode,
        [string]$RelativePath
    )

    $parts = $RelativePath.Split("/")
    $node = $RootNode

    for ($i = 0; $i -lt $parts.Length; $i++) {
        $part = $parts[$i]
        $isLeaf = ($i -eq ($parts.Length - 1))

        if ($isLeaf) {
            $node.Files.Add($part)
            return
        }

        if (-not $node.Dirs.ContainsKey($part)) {
            $node.Dirs[$part] = New-TreeNode
        }
        $node = $node.Dirs[$part]
    }
}

function Render-Tree {
    param(
        [hashtable]$Node,
        [string]$Prefix,
        [int]$Depth,
        [int]$MaxDepth,
        [System.Collections.Generic.List[string]]$OutLines
    )

    $dirNames = @($Node.Dirs.Keys | Sort-Object)
    $fileNames = @($Node.Files | Sort-Object)

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($d in $dirNames) { $items.Add([pscustomobject]@{ Name = $d; IsDir = $true }) }
    foreach ($f in $fileNames) { $items.Add([pscustomobject]@{ Name = $f; IsDir = $false }) }

    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $isLast = ($i -eq ($items.Count - 1))

        $connector = $(if ($isLast) { "\--" } else { "|--" })
        $label = $(if ($item.IsDir) { "$($item.Name)/" } else { $item.Name })
        $OutLines.Add("$Prefix$connector $label")

        if ($item.IsDir) {
            $nextPrefix = $Prefix + $(if ($isLast) { "    " } else { "|   " })

            if ($Depth + 1 -ge $MaxDepth) {
                # If we would recurse further, indicate truncation.
                $child = $Node.Dirs[$item.Name]
                if ($child.Dirs.Count -gt 0 -or $child.Files.Count -gt 0) {
                    $OutLines.Add("$nextPrefix\-- ...")
                }
            }
            else {
                Render-Tree -Node $Node.Dirs[$item.Name] -Prefix $nextPrefix -Depth ($Depth + 1) -MaxDepth $MaxDepth -OutLines $OutLines
            }
        }
    }
}

function Get-TrackedFiles {
    param([switch]$UseTrackedOnly)

    if ($UseTrackedOnly) {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if (-not $git) { throw "git not found; run without -TrackedOnly for filesystem inventory." }

        $files = & git ls-files
        return @($files | Where-Object { $_ -and $_.Trim() })
    }

    # Filesystem fallback (best-effort). Avoid typical junk.
    $excludeDirs = @(".git", ".vs", ".tmp", "deploy", "bench-export")
    $all = Get-ChildItem -Path $repoRoot -Recurse -File -Force | Where-Object {
        $rel = $_.FullName.Substring($repoRoot.Path.Length).TrimStart("\\") -replace "\\\\", "/"
        foreach ($x in $excludeDirs) {
            if ($rel -like "$x/*") { return $false }
        }
        return $true
    }

    return @($all | ForEach-Object { $_.FullName.Substring($repoRoot.Path.Length).TrimStart("\\") -replace "\\\\", "/" } | Sort-Object)
}

function Ensure-ParentDir {
    param([string]$Path)

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

# --- Main ---

$files = Get-TrackedFiles -UseTrackedOnly:$TrackedOnly
$files = @($files | Sort-Object)

$treeRoot = New-TreeNode
$dirStats = @{} # dir -> @{ Files=int; Words=int }

$totalFiles = 0
$totalWords = 0

foreach ($f in $files) {
    $totalFiles++

    Add-ToTree -RootNode $treeRoot -RelativePath $f

    $words = Get-WordCount -RelativePath $f -AllowedExtensions $WordCountExtensions
    $totalWords += $words

    $dir = Get-RelativeDir -Path $f
    $prefixes = Get-DirPrefixes -Dir $dir

    foreach ($p in $prefixes) {
        if (-not $dirStats.ContainsKey($p)) {
            $dirStats[$p] = @{ Files = 0; Words = 0 }
        }
        $dirStats[$p].Files++
        $dirStats[$p].Words += $words
    }
}

$treeLines = New-Object System.Collections.Generic.List[string]
$treeLines.Add(".")
Render-Tree -Node $treeRoot -Prefix "" -Depth 0 -MaxDepth $MaxTreeDepth -OutLines $treeLines

$reportLines = New-Object System.Collections.Generic.List[string]
$reportLines.Add("# Repository Inventory")
$reportLines.Add("")
$reportLines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd')")
$reportLines.Add("")
$reportLines.Add("This report inventories **$(if ($TrackedOnly) { 'tracked (git) files only' } else { 'working directory files (filesystem)' })**.")
$reportLines.Add("")
$reportLines.Add("## Totals")
$reportLines.Add("")
$reportLines.Add("- Files: $totalFiles")
$reportLines.Add("- Words (text files only): $totalWords")
$reportLines.Add("")
$reportLines.Add("Word counting is whitespace-based and only includes these extensions:")
$reportLines.Add("")
$reportLines.Add('`' + ($WordCountExtensions -join ', ') + '`')
$reportLines.Add("")
$reportLines.Add("## Structure")
$reportLines.Add("")
$reportLines.Add('```text')
foreach ($l in $treeLines) { $reportLines.Add($l) }
$reportLines.Add('```')
$reportLines.Add("")
$reportLines.Add("## Folder Stats (Recursive)")
$reportLines.Add("")
$reportLines.Add("| Folder | Files | Words |")
$reportLines.Add("|--------|------:|------:|")

$sortedDirs = @($dirStats.Keys | Sort-Object { if ($_ -eq ".") { "" } else { $_ } })
foreach ($d in $sortedDirs) {
    $label = $(if ($d -eq ".") { "(repo root)" } else { $d })
    $filesCount = $dirStats[$d].Files
    $wordCount = $dirStats[$d].Words
    $reportLines.Add("| $label | $filesCount | $wordCount |")
}

$outFull = Join-Path $repoRoot $OutPath
Ensure-ParentDir -Path $outFull
$reportLines | Set-Content -LiteralPath $outFull -Encoding UTF8

Write-Host "[OK] Wrote inventory: $outFull" -ForegroundColor Green
