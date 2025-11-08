@echo off
echo ========================================
echo Clean Build - Remove Cache
echo ========================================
echo.

echo [1/3] Removing .next folder...
if exist .next (
    rmdir /s /q .next
    echo ✅ .next folder removed
) else (
    echo ℹ️  .next folder not found
)
echo.

echo [2/3] Removing node_modules/.cache...
if exist node_modules\.cache (
    rmdir /s /q node_modules\.cache
    echo ✅ node_modules/.cache removed
) else (
    echo ℹ️  node_modules/.cache not found
)
echo.

echo [3/3] Running build...
call npm run build
echo.

if %ERRORLEVEL% EQU 0 (
    echo ========================================
    echo ✅ Build Successful!
    echo ========================================
) else (
    echo ========================================
    echo ❌ Build Failed!
    echo ========================================
)
echo.
pause
