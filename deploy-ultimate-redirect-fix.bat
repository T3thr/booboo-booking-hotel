@echo off
echo ========================================
echo ULTIMATE REDIRECT FIX - Deploy
echo ========================================
echo.

echo Fix: ใช้ window.location.href แทน router.push()
echo.
echo Changes:
echo - useEffect: router.push() → window.location.href
echo - handleSubmit: already using window.location.href ✓
echo.

set /p confirm="Deploy now? (y/n): "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo [1/2] Committing...
git add .
git commit -m "fix: ใช้ window.location.href แทน router.push ใน admin login useEffect"
echo.

echo [2/2] Pushing...
git push
if errorlevel 1 (
    echo ❌ Failed to push
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
echo 3. Should redirect to /admin/dashboard ✅
echo.
echo No more stuck at /auth/admin!
echo.

pause
