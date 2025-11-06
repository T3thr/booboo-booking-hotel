@echo off
echo ========================================
echo Testing Guest Access to Bookings Page
echo ========================================
echo.

echo Step 1: Checking if backend is running...
curl -s http://localhost:8080/api/health >nul 2>&1
if errorlevel 1 (
    echo WARNING: Backend is not running!
    echo Please start backend first with: start-backend-local.bat
    echo.
    pause
    exit /b 1
)
echo Backend is running ✓
echo.

echo Step 2: Checking if frontend is running...
curl -s http://localhost:3000 >nul 2>&1
if errorlevel 1 (
    echo WARNING: Frontend is not running!
    echo Please start frontend with: cd frontend && npm run dev
    echo.
    pause
    exit /b 1
)
echo Frontend is running ✓
echo.

echo ========================================
echo Manual Testing Steps:
echo ========================================
echo.
echo 1. Open browser: http://localhost:3000
echo.
echo 2. Click "Sign In" or go to: http://localhost:3000/auth/signin
echo.
echo 3. Login with Guest account:
echo    Email: anan.test@example.com
echo    Password: password123
echo.
echo 4. After login, go to: http://localhost:3000/bookings
echo.
echo 5. You should see "My Bookings" page
echo    (NOT the "Unauthorized" page)
echo.
echo ========================================
echo Debugging Tips:
echo ========================================
echo.
echo If you still see "Unauthorized" page:
echo.
echo 1. Open Browser DevTools (F12)
echo 2. Go to Console tab
echo 3. Run: fetch('/api/auth/session').then(r => r.json()).then(console.log)
echo 4. Check if you see: role: "GUEST"
echo.
echo If role is missing or wrong:
echo - Backend needs to be rebuilt
echo - Run: rebuild-backend.bat
echo - Then restart backend
echo.
echo ========================================
pause
