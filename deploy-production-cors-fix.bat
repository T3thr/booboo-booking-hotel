@echo off
echo ========================================
echo Production CORS and Check-in Fix Deploy
echo ========================================
echo.

echo [1/5] Checking git status...
git status
echo.

echo [2/5] Adding modified files...
git add backend/internal/models/booking.go
git add backend/internal/repository/booking_repository.go
git add backend/pkg/config/config.go
git add CORS_PRODUCTION_FIX.md
git add CHECKIN_DATA_FIX.md
git add PRODUCTION_FIX_COMPLETE.md
git add deploy-production-cors-fix.bat
echo.

echo [3/5] Committing changes...
git commit -m "fix: Add payment proof fields to arrivals API and improve CORS config for production"
echo.

echo [4/5] Pushing to GitHub...
git push origin main
echo.

echo [5/5] Deployment initiated!
echo.
echo ========================================
echo Next Steps:
echo ========================================
echo 1. Go to https://dashboard.render.com
echo 2. Select your backend service (booboo-booking)
echo 3. Go to Environment tab
echo 4. Add/Update ALLOWED_ORIGINS:
echo    ALLOWED_ORIGINS=http://localhost:3000,https://booboo-booking.vercel.app
echo 5. Save Changes (Render will auto-redeploy)
echo 6. Wait 2-5 minutes for deployment
echo 7. Test at https://booboo-booking.vercel.app/admin/reception
echo.
echo See PRODUCTION_FIX_COMPLETE.md for detailed instructions
echo ========================================

pause
