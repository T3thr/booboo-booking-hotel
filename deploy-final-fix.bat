@echo off
echo ========================================
echo Deploy: Final Fix - Admin Login
echo ========================================
echo.
echo Changes:
echo 1. Fixed payment page - URL.createObjectURL with window check
echo 2. Fixed admin login - proper error handling with early returns
echo 3. Fixed loading state - removed finally block
echo 4. Added response.ok checks
echo.

echo [Step 1/5] Testing build locally...
cd frontend
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed! Please fix errors before deploying.
    echo.
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
git add frontend/src/app/auth/admin/page.tsx
git add frontend/src/app/(guest)/booking/payment/page.tsx
git add FINAL_FIX_ADMIN_LOGIN.md
git add frontend/test-build-local.bat
git add deploy-final-fix.bat
echo.

echo [Step 4/5] Committing...
git commit -m "fix: resolve loading hang and SSR errors - final fix"
echo.

echo [Step 5/5] Pushing to repository...
git push
echo.

echo ========================================
echo ✅ Deploy Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Wait 2-3 minutes for Vercel to build
echo 2. Check: https://vercel.com/dashboard
echo 3. Look for "Ready" status (green checkmark)
echo 4. Test at: https://booboo-booking.vercel.app/auth/admin
echo.
echo Test Credentials:
echo - Manager: manager@hotel.com / manager123
echo - Receptionist: receptionist@hotel.com / receptionist123
echo.
echo Important:
echo - Test in Incognito mode
echo - Check Browser Console (F12) for logs
echo - Verify redirect happens within 1-2 seconds
echo.
echo If still having issues:
echo - Check Vercel Function Logs
echo - Verify Backend (Render) is running
echo - Check NEXTAUTH_URL in Vercel settings
echo.
pause
