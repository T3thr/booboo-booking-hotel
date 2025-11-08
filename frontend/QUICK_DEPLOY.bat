@echo off
echo ========================================
echo Quick Deploy to Vercel
echo ========================================
echo.

cd /d "%~dp0"

echo [Step 1/4] Testing build...
call npm run build

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed! Please fix errors before deploying.
    pause
    exit /b 1
)

echo.
echo ✅ Build successful!
echo.

echo [Step 2/4] Checking git status...
git status

echo.
echo [Step 3/4] Adding changes...
cd ..
git add .

echo.
echo [Step 4/4] Ready to commit and push!
echo.
echo Please run these commands manually:
echo.
echo   git commit -m "fix: resolve admin redirect loop in production"
echo   git push origin main
echo.
echo Vercel will auto-deploy after push.
echo.
pause
