@echo off
echo Testing vcvarsall.bat detection...
echo.

echo Checking hardcoded paths in build.bat:
echo ----------------------------------------

if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    echo [FOUND] VS 2022 BuildTools
    set "FOUND=C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
) else (
    echo [NOT FOUND] VS 2022 BuildTools
)

if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    echo [FOUND] VS 2022 Community
    set "FOUND=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
) else (
    echo [NOT FOUND] VS 2022 Community
)

if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
    echo [FOUND] VS 2022 Professional
    set "FOUND=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat"
) else (
    echo [NOT FOUND] VS 2022 Professional
)

if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    echo [FOUND] VS 2019 BuildTools
    set "FOUND=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
) else (
    echo [NOT FOUND] VS 2019 BuildTools
)

if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    echo [FOUND] VS 2019 Community
    set "FOUND=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
) else (
    echo [NOT FOUND] VS 2019 Community
)

echo.
if defined FOUND (
    echo Would use: %FOUND%
) else (
    echo No hardcoded path found. Checking x86 locations...
    echo.
    
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
        echo [FOUND] VS 2022 BuildTools ^(x86^)
        echo Path: C:\Program Files ^(x86^)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat
    )
    
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
        echo [FOUND] VS 2022 Community ^(x86^)
        echo Path: C:\Program Files ^(x86^)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat
    )
    
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
        echo [FOUND] VS 2022 Professional ^(x86^)
        echo Path: C:\Program Files ^(x86^)\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat
    )
)

echo.
echo Current VSCMD_VER: %VSCMD_VER%
if defined VSCMD_VER (
    echo ^(Already in VS Developer environment^)
)
