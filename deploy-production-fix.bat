@echo off
echo ========================================
echo Deploy Production Fix - Final Version
echo ========================================
echo.
echo Fixes Applied:
echo 1. Admin login redirect loop (Vercel)
echo 2. Location error in payment page (Build)
echo 3. Improved error handling
echo.

echo [1/4] Testing build locally...
cd frontend
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed! Please fix errors first.
    pause
    exit /b 1
)
cd ..
echo.

echo [2/4] Adding changes...
git add frontend/src/lib/auth.ts
git add frontend/src/app/auth/admin/page.tsx
git add "frontend/src/app/(guest)/booking/payment/page.tsx"
git add FINAL_PRODUCTION_FIX.md
git add deploy-production-fix.bat
echo.

echo [3/4] Committing...
git commit -m "fix: production redirect loop and location error"
echo.

echo [4/4] Pushing to repository...
git push
echo.

echo ========================================
echo ✅ Deploy Complete!
========================================
echo.
echo Vercel is building automatically...
echo.
echo Next Steps:
echo 1. Go to https://vercel.com/dashboard
echo 2. Wait for build to complete (2-3 minutes)
echo 3. Check status is "Ready" (green)
echo 4. Test at https://booboo-booking.vercel.app/auth/admin
echo.
echo Test Credentials:
echo - Manager: manager@hotel.com / manager123
echo - Should redirect to /admin/dashboard (NOT /auth/signin)
echo.
echo 💡 Important: Test in Incognito mode!
echo.
pause
