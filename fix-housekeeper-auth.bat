@echo off
echo ========================================
echo Fix Housekeeper Authentication
echo ========================================
echo.

echo Step 1: Rebuilding Backend...
echo.
cd backend
go build -o server.exe ./cmd/server
if errorlevel 1 (
    echo ERROR: Failed to build backend
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo ========================================
echo Build SUCCESS!
echo ========================================
echo.
echo Next Steps:
echo 1. Stop your current backend server (Ctrl+C in backend terminal)
echo 2. Start backend again with: cd backend ^&^& server.exe
echo 3. Test login at: http://localhost:3000/auth/admin
echo.
echo Test Credentials:
echo   Housekeeper: housekeeper1@hotel.com / staff123
echo   Receptionist: receptionist1@hotel.com / staff123
echo   Manager: manager@hotel.com / staff123
echo.
echo The fix includes:
echo - Backend now sends role_code (HOUSEKEEPER) instead of user_type (staff) in JWT
echo - Frontend redirects to /housekeeping instead of /staff/housekeeping
echo.
pause
