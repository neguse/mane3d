@echo off
setlocal enabledelayedexpansion

REM Find Visual Studio and setup environment
set VSWHERE="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`%VSWHERE% -latest -property installationPath`) do set VS_PATH=%%i

if not defined VS_PATH (
    echo Visual Studio not found
    exit /b 1
)

call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Configure if needed
if not exist "%~dp0..\build\dummy-debug\build.ninja" (
    cmake --preset win-dummy-debug
)

REM Build
cmake --build --preset win-dummy-debug
if errorlevel 1 (
    echo Build failed
    exit /b 1
)

set EXE="%~dp0..\build\dummy-debug\mane3d-test.exe"
set TEST_DIR=%~dp0..\examples\b2d

REM If argument provided, run that single test
if not "%~1"=="" (
    echo Running: %~1
    %EXE% %*
    exit /b !errorlevel!
)

REM Run all test_*.lua files in examples/b2d/
echo.
echo ========================================
echo Running all Box2D tests
echo ========================================
echo.

set PASSED=0
set FAILED=0
set FAILED_TESTS=

for %%f in ("%TEST_DIR%\test_*.lua") do (
    echo [TEST] %%~nxf
    %EXE% "%%f"
    if errorlevel 1 (
        echo [FAIL] %%~nxf
        set /a FAILED+=1
        set FAILED_TESTS=!FAILED_TESTS! %%~nxf
    ) else (
        echo [PASS] %%~nxf
        set /a PASSED+=1
    )
    echo.
)

echo ========================================
echo Results: !PASSED! passed, !FAILED! failed
echo ========================================

if !FAILED! gtr 0 (
    echo Failed tests:!FAILED_TESTS!
    exit /b 1
)

echo All tests passed!
exit /b 0
