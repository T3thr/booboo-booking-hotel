@echo off
echo ========================================
echo Deploy CORS Fix - Use NextAuth Server-Side
echo ========================================
echo.

echo Changes:
echo - Use NextAuth signIn (server-side call)
echo - No direct backend API call (avoid CORS)
echo - Check role after session created
echo - Redirect with window.location.href
echo.

set /p confirm="Deploy now? (y/n): "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo [1/2] Committing changes...
git add .
git commit -m "fix: แก้ไข CORS error - ใช้ NextAuth server-side call"
if errorlevel 1 (
    echo No changes to commit or commit failed
)
echo.

echo [2/2] Pushing to Vercel...
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
echo Check: https://vercel.com/dashboard
echo.
echo Test after deployment:
echo 1. Go to: https://booboo-booking.vercel.app/auth/admin
echo 2. Login: manager@hotel.com / Manager123!
echo 3. Should redirect to: /admin/dashboard ✅
echo.
echo No CORS error should appear!
echo.

pause
