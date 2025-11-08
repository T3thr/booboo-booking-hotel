@echo off
echo ========================================
echo Deploy Final Admin Redirect Fix
echo ========================================
echo.

echo This will:
echo 1. Test build locally
echo 2. Commit changes
echo 3. Push to Vercel
echo.

set /p confirm="Continue? (y/n): "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo [1/3] Testing build...
cd frontend
call npm run build
if errorlevel 1 (
    echo.
    echo ❌ Build failed! Fix errors before deploying.
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Build successful!
echo.

echo [2/3] Committing changes...
git add .
git commit -m "fix: แก้ไข admin redirect loop ครั้งสุดท้าย - ใช้ backend API validation"
if errorlevel 1 (
    echo No changes to commit or commit failed
)
echo.

echo [3/3] Pushing to Vercel...
git push
if errorlevel 1 (
    echo ❌ Failed to push
    pause
    exit /b 1
)
echo.

echo ========================================
echo ✅ Deployment triggered!
echo ========================================
echo.
echo Check Vercel dashboard: https://vercel.com/dashboard
echo.
echo After deployment, test:
echo 1. Go to: https://booboo-booking.vercel.app/auth/admin
echo 2. Login: manager@hotel.com / Manager123!
echo 3. Should redirect to: /admin/dashboard
echo.
echo If still stuck:
echo - Clear browser cookies
echo - Check Vercel logs
echo - Check NEXT_PUBLIC_API_URL in Vercel env vars
echo.

pause
