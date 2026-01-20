@echo off
setlocal

REM Find Visual Studio and setup environment
set VSWHERE="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`%VSWHERE% -latest -property installationPath`) do set VS_PATH=%%i

if not defined VS_PATH (
    echo Visual Studio not found
    exit /b 1
)

call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Run the binding generator
python "%~dp0gen_box2d.py" %*
