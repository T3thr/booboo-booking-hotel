@echo off
echo ========================================
echo Quick Build Test
echo ========================================
echo.

echo Testing TypeScript compilation...
call npx tsc --noEmit
if errorlevel 1 (
    echo.
    echo ❌ TypeScript errors found!
    echo Fix errors before deploying.
    pause
    exit /b 1
)
echo ✅ TypeScript OK
echo.

echo Testing Next.js build...
call npm run build
if errorlevel 1 (
    echo.
    echo ❌ Build failed!
    pause
    exit /b 1
)
echo ✅ Build OK
echo.

echo ========================================
echo ✅ All tests passed!
echo ========================================
echo.
echo Ready to deploy to Vercel!
echo.

pause
