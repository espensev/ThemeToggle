# Repository Inventory

Generated: 2026-02-07

This report inventories **tracked (git) files only**.

## Totals

- Files: 50
- Words (text files only): 18308

Word counting is whitespace-based and only includes these extensions:

`.md, .txt, .ps1, .bat, .cmd, .cpp, .c, .h, .hpp, .rc, .nsi, .yml, .yaml, .json, .xml, .manifest, .props, .targets, .sln`

## Structure

```text
.
|-- .github/
|   |-- workflows/
|   |   |-- build.yml
|   |   |-- release.yml
|   |   |-- validate-winget.yml
|   |   \-- winget-publish.yml
|   \-- RELEASE_TEMPLATE.md
|-- dist/
|   |-- launchers/
|   |   |-- ThemeToggle.ps1
|   |   |-- ThemeToggle.vbs
|   |   |-- ThemeToggle-Dark.vbs
|   |   \-- ThemeToggle-Light.vbs
|   |-- build-release.bat
|   \-- update-winget.ps1
|-- docs/
|   |-- DEVELOPMENT.md
|   |-- README.md
|   |-- RELEASE.md
|   |-- RELEASE_NOTES.md
|   \-- TECHNICAL.md
|-- include/
|   |-- BroadcastManager.h
|   |-- RegistryManager.h
|   |-- StringUtils.h
|   |-- Types.h
|   \-- UxThemeHelper.h
|-- Resources/
|   |-- ThemeToggle.ico
|   \-- ThemeToggle.manifest
|-- src/
|   |-- BroadcastManager.cpp
|   |-- main.cpp
|   |-- RegistryManager.cpp
|   \-- UxThemeHelper.cpp
|-- tools/
|   |-- signing/
|   |   |-- README.md
|   |   \-- sign-release.ps1
|   |-- bench.ps1
|   |-- bump-version.ps1
|   |-- cleanup.bat
|   |-- export-bench.ps1
|   |-- export-source.ps1
|   |-- release.ps1
|   |-- test_vcvars.bat
|   \-- validate.bat
|-- winget/
|   |-- SevIQ.ThemeToggle.installer.yaml
|   |-- SevIQ.ThemeToggle.locale.en-US.yaml
|   \-- SevIQ.ThemeToggle.yaml
|-- .gitattributes
|-- .gitignore
|-- build.bat
|-- LICENSE.txt
|-- README.md
|-- setup.bat
|-- setup.nsi
|-- ThemeToggle.rc
|-- uninstall.bat
\-- VERSION
```

## Folder Stats (Recursive)

| Folder | Files | Words |
|--------|------:|------:|
| (repo root) | 50 | 18308 |
| .github | 5 | 2263 |
| .github/workflows | 4 | 1975 |
| dist | 6 | 1904 |
| dist/launchers | 4 | 190 |
| docs | 5 | 2548 |
| include | 5 | 956 |
| Resources | 2 | 93 |
| src | 4 | 2913 |
| tools | 10 | 4346 |
| tools/signing | 2 | 685 |
| winget | 3 | 285 |
