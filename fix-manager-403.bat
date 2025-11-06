@echo off
echo ========================================
echo Fix Manager 403 Unauthorized Error
echo ========================================
echo.

echo This script will:
echo 1. Rebuild backend with correct role handling
echo 2. Provide instructions for testing
echo.
pause

echo.
echo Step 1: Rebuilding Backend...
echo ========================================
cd backend
go build -o server.exe ./cmd/server

if errorlevel 1 (
    echo.
    echo ERROR: Failed to build backend
    echo Please check the error messages above
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
echo Backend has been rebuilt with correct role handling.
echo.
echo IMPORTANT: Next Steps
echo ========================================
echo.
echo 1. STOP your current backend server
echo    - Go to backend terminal
echo    - Press Ctrl+C
echo.
echo 2. START backend again
echo    - cd backend
echo    - server.exe
echo.
echo 3. CLEAR browser cache
echo    - Open browser
echo    - Press Ctrl+Shift+Delete
echo    - Select "All time"
echo    - Check "Cookies" and "Cached images"
echo    - Click "Clear data"
echo.
echo 4. LOGOUT and LOGIN again
echo    - Go to http://localhost:3000
echo    - Logout (if logged in)
echo    - Go to http://localhost:3000/auth/admin
echo    - Login with:
echo      Email: manager@hotel.com
echo      Password: staff123
echo.
echo 5. TEST access
echo    - Should redirect to /dashboard
echo    - Try accessing:
echo      * /dashboard (should work)
echo      * /pricing (should work)
echo      * /inventory (should work)
echo      * /reports (should work)
echo      * /reception (should work - Manager has all permissions)
echo      * /housekeeping (should work - Manager has all permissions)
echo.
echo ========================================
echo Troubleshooting
echo ========================================
echo.
echo If you still get 403 Unauthorized:
echo.
echo 1. Check JWT token:
echo    - Open DevTools (F12)
echo    - Go to Application tab
echo    - Check Session Storage
echo    - Look for next-auth token
echo    - Decode at jwt.io
echo    - Verify "role" is "MANAGER" (not "staff")
echo.
echo 2. Test backend directly:
echo    - Run: test-housekeeper-login.bat
echo    - Check if role_code is "MANAGER"
echo.
echo 3. Check backend logs:
echo    - Look for [LOGIN] messages
echo    - Should see: Role: MANAGER
echo.
echo 4. If all else fails:
echo    - Restart computer
echo    - Start backend
echo    - Start frontend
echo    - Clear browser completely
echo    - Try again
echo.
echo ========================================
echo.
pause
