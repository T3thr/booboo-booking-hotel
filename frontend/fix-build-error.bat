@echo off
echo ========================================
echo Fix TypeScript Build Error
echo ========================================
echo.

echo [1/5] Removing .next cache...
if exist .next (
    rmdir /s /q .next
    echo ✓ Removed .next directory
) else (
    echo ✓ .next directory not found
)
echo.

echo [2/5] Removing node_modules/.cache...
if exist node_modules\.cache (
    rmdir /s /q node_modules\.cache
    echo ✓ Removed node_modules/.cache
) else (
    echo ✓ node_modules/.cache not found
)
echo.

echo [3/5] Cleaning npm cache...
npm cache clean --force
echo.

echo [4/5] Reinstalling dependencies...
npm install
echo.

echo [5/5] Building...
npm run build
echo.

echo ========================================
if %ERRORLEVEL% EQU 0 (
    echo ✅ Build Successful!
    echo.
    echo You can now:
    echo 1. Test locally: npm run dev
    echo 2. Deploy to Vercel: git push
) else (
    echo ❌ Build Failed!
    echo.
    echo Try these steps:
    echo 1. Close all editors and terminals
    echo 2. Delete .next folder manually
    echo 3. Run this script again
)
echo ========================================
echo.
pause
