@echo off
echo ========================================
echo Deploy to Vercel with Fixes
echo ========================================
echo.

echo This script will:
echo 1. Test build locally
echo 2. Commit changes
echo 3. Push to trigger Vercel deployment
echo.

set /p confirm="Continue? (y/n): "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo [1/3] Testing build locally...
call npm run build
if errorlevel 1 (
    echo ERROR: Build failed! Fix errors before deploying.
    pause
    exit /b 1
)
echo Build successful!
echo.

echo [2/3] Committing changes...
cd ..
git add .
git commit -m "fix: แก้ไข admin redirect loop และ SSR build error"
if errorlevel 1 (
    echo No changes to commit or commit failed
)
echo.

echo [3/3] Pushing to trigger Vercel deployment...
git push
if errorlevel 1 (
    echo ERROR: Failed to push
    pause
    exit /b 1
)
echo.

echo ========================================
echo Deployment triggered!
echo ========================================
echo.
echo Check Vercel dashboard for deployment status:
echo https://vercel.com/dashboard
echo.
echo After deployment completes, test:
echo 1. Go to your production URL
echo 2. Navigate to /auth/admin
echo 3. Login with: manager@hotel.com / Manager123!
echo 4. Verify redirect to /admin/dashboard works
echo.

pause
