@echo off
echo ========================================
echo Test Build Locally Before Deploy
echo ========================================
echo.

echo [1/3] Cleaning previous build...
if exist .next rmdir /s /q .next
echo.

echo [2/3] Running build...
npm run build
echo.

if %ERRORLEVEL% EQU 0 (
    echo ========================================
    echo ✅ Build Successful!
    echo ========================================
    echo.
    echo You can now deploy to Vercel safely.
    echo Run: git push
    echo.
) else (
    echo ========================================
    echo ❌ Build Failed!
    echo ========================================
    echo.
    echo Please fix the errors above before deploying.
    echo.
)

pause
