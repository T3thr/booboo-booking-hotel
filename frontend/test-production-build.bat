@echo off
echo ========================================
echo Testing Production Build
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] Cleaning previous build...
if exist .next rmdir /s /q .next
if exist out rmdir /s /q out

echo.
echo [2/3] Building for production...
call npm run build

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo.
echo [3/3] Starting production server...
echo.
echo ✅ Build successful!
echo.
echo Testing at: http://localhost:3000
echo Press Ctrl+C to stop
echo.

call npm run start
