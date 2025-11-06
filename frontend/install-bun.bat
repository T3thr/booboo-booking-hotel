@echo off
echo Installing Bun for Windows...
echo.

:: Download Bun (disable progress to prevent hanging)
echo Downloading Bun... (this may take a minute)
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/oven-sh/bun/releases/latest/download/bun-windows-x64.zip' -OutFile \"$env:TEMP\bun.zip\""

if not exist "%TEMP%\bun.zip" (
    echo Download failed!
    pause
    exit /b 1
)

echo Download complete!
echo.

:: Create directory
if not exist "%USERPROFILE%\.bun\bin" mkdir "%USERPROFILE%\.bun\bin"

:: Extract using Shell.Application COM object (works on all Windows versions)
echo Extracting...
powershell -Command "$shell = New-Object -ComObject Shell.Application; $zip = $shell.NameSpace(\"%TEMP%\bun.zip\"); $dest = $shell.NameSpace(\"%USERPROFILE%\.bun\bin\"); $dest.CopyHere($zip.Items(), 16)"

:: Clean up
del "%TEMP%\bun.zip"

:: Check if bun.exe exists
if exist "%USERPROFILE%\.bun\bin\bun-windows-x64\bun.exe" (
    echo Moving bun.exe to correct location...
    move "%USERPROFILE%\.bun\bin\bun-windows-x64\bun.exe" "%USERPROFILE%\.bun\bin\bun.exe"
    rmdir "%USERPROFILE%\.bun\bin\bun-windows-x64"
)

:: Add to PATH (for current session)
set "PATH=%USERPROFILE%\.bun\bin;%PATH%"

echo.
echo ========================================
echo Bun installed successfully!
echo ========================================
echo.
echo Testing installation...
bun --version
echo.
echo To use bun in OTHER terminals, restart them or add to PATH:
echo   set "PATH=%USERPROFILE%\.bun\bin;%%PATH%%"
echo.
echo To permanently add to PATH (run as Administrator):
echo   setx PATH "%%USERPROFILE%%\.bun\bin;%%PATH%%" /M
echo.

pause
