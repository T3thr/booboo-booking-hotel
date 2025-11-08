@echo off
echo ========================================
echo Deploy: Admin Login Fix - Final Version
echo ========================================
echo.
echo Fix Summary:
echo - Resolved SSR location error
echo - Fixed loading state hanging
echo - Added browser check for window API
echo.

echo [1/4] Checking current status...
git status
echo.

echo [2/4] Adding changes...
git add frontend/src/app/auth/admin/page.tsx
git add ADMIN_LOGIN_FIX_FINAL.md
git add frontend/deploy-admin-fix-final.bat
echo.

echo [3/4] Committing...
git commit -m "fix: resolve SSR location error and admin login hanging"
echo.

echo [4/4] Pushing to repository...
git push
echo.

echo ========================================
echo ✅ Deploy Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Wait 2-3 minutes for Vercel to build
echo 2. Check Vercel Dashboard: https://vercel.com/dashboard
echo 3. Look for "Ready" status (green checkmark)
echo 4. Test login at: https://booboo-booking.vercel.app/auth/admin
echo.
echo Test Credentials:
echo - Manager: manager@hotel.com / manager123
echo - Receptionist: receptionist@hotel.com / receptionist123
echo - Housekeeper: housekeeper@hotel.com / housekeeper123
echo.
echo Important: Test in Incognito mode to avoid cache issues!
echo.
pause
