@echo off
echo ========================================
echo Deploy: Ultimate Fix - Admin Login
echo ========================================
echo.
echo Critical Fixes:
echo 1. Fixed build errors - window.location checks
echo 2. Fixed redirect loop - removed middleware redirect from auth pages
echo 3. Fixed production vs local differences
echo.

echo [Step 1/5] Testing build locally...
cd frontend
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed! Please fix errors before deploying.
    echo.
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Build successful!
echo.

echo [Step 2/5] Checking git status...
git status
echo.

echo [Step 3/5] Adding changes...
git add frontend/src/middleware.ts
git add frontend/src/app/(guest)/rooms/search/page.tsx
git add frontend/src/app/(guest)/bookings/page.tsx
git add ULTIMATE_FIX_ADMIN_LOGIN.md
git add deploy-ultimate-fix.bat
echo.

echo [Step 4/5] Committing...
git commit -m "fix: resolve redirect loop and build errors - ultimate fix"
echo.

echo [Step 5/5] Pushing to repository...
git push
echo.

echo ========================================
echo ✅ Deploy Complete!
echo ========================================
echo.
echo What was fixed:
echo ✅ Build errors (location is not defined)
echo ✅ Redirect loop (auth → dashboard → auth)
echo ✅ Production vs Local differences
echo.
echo Next Steps:
echo 1. Wait 2-3 minutes for Vercel to build
echo 2. Check: https://vercel.com/dashboard
echo 3. Look for "Ready" status (green checkmark)
echo 4. Test at: https://booboo-booking.vercel.app/auth/admin
echo.
echo Test Credentials:
echo - Manager: manager@hotel.com / manager123
echo.
echo Expected Behavior:
echo 1. Login → "กำลังเข้าสู่ระบบ..."
echo 2. After 1-2 seconds → "เข้าสู่ระบบสำเร็จ!"
echo 3. Redirect to /admin/dashboard
echo 4. Show Manager Dashboard (NO white screen)
echo 5. NO redirect loop
echo.
echo Important:
echo - Test in Incognito mode
echo - Check Browser Console (F12) for logs
echo - Verify NO redirect back to /auth/signin
echo.
echo If still having issues:
echo - Clear Vercel cache and redeploy
echo - Check Vercel Function Logs
echo - Verify NEXTAUTH_URL in Vercel settings
echo.
pause
