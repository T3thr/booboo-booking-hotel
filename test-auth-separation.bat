@echo off
echo ========================================
echo Testing Auth Separation
echo ========================================
echo.

echo [Test Instructions]
echo.
echo 1. Guest Login Test (/auth/signin)
echo    - Try: guest@example.com
echo    - Expected: Login success, redirect to /
echo    - Try: manager@hotel.com
echo    - Expected: Error + auto sign out
echo.
echo 2. Staff Login Test (/auth/admin)
echo    - Try: manager@hotel.com
echo    - Expected: Login success, redirect to /admin/dashboard
echo    - Try: receptionist@hotel.com
echo    - Expected: Login success, redirect to /admin/reception
echo    - Try: housekeeper@hotel.com
echo    - Expected: Login success, redirect to /admin/housekeeping
echo    - Try: guest@example.com
echo    - Expected: Error + auto sign out
echo.
echo 3. Check Links
echo    - /auth/signin should have link to /auth/admin
echo    - /auth/admin should have link to /auth/signin
echo.
echo ========================================
echo.
echo Starting frontend...
cd frontend
start cmd /k "npm run dev"
echo.
echo Frontend starting at http://localhost:3000
echo.
echo Test URLs:
echo - Guest Login: http://localhost:3000/auth/signin
echo - Admin Login: http://localhost:3000/auth/admin
echo.
echo ========================================

pause
