@echo off
echo ========================================
echo Fix Infinite Redirect Loop
echo ========================================
echo.

echo Changes:
echo 1. window.location.href → window.location.replace
echo 2. Add hasRedirected flag
echo 3. Remove unused imports
echo.

echo Why window.location.replace?
echo - No browser history entry
echo - Prevent back button loop
echo - Best practice for auth redirect
echo.

set /p confirm="Deploy? (y/n): "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo Committing...
git add .
git commit -m "fix: แก้ไข infinite redirect loop - ใช้ window.location.replace + flag"
echo.

echo Pushing...
git push
if errorlevel 1 (
    echo ❌ Failed
    pause
    exit /b 1
)
echo.

echo ========================================
echo ✅ Deployed!
echo ========================================
echo.
echo Test:
echo 1. https://booboo-booking.vercel.app/auth/admin
echo 2. Login: manager@hotel.com / Manager123!
echo 3. Should redirect ONCE to /admin/dashboard
echo 4. No infinite loop!
echo.

pause
