@echo off
echo ========================================
echo Testing Guest Bookings Access Fix
echo ========================================
echo.

echo Step 1: Rebuilding backend...
cd backend
go build -o ../bin/server.exe ./cmd/server
if errorlevel 1 (
    echo ERROR: Failed to build backend
    pause
    exit /b 1
)
cd ..

echo.
echo Step 2: Backend built successfully!
echo.
echo Step 3: Please restart your backend server manually
echo         Run: start-backend-local.bat
echo.
echo Step 4: Test login with guest account:
echo         Email: anan.test@example.com
echo         Password: password123
echo.
echo Step 5: After login, navigate to /bookings page
echo         It should now work correctly!
echo.
echo ========================================
echo Fix Applied:
echo - Added role_code and role_name to Guest model
echo - Updated auth repository to use v_all_users view
echo - Updated auth service to return role_code in login response
echo - Updated middleware to allow GUEST role access to /bookings
echo ========================================
echo.
pause
