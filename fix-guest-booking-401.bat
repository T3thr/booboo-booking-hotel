@echo off
echo ========================================
echo Fix Guest Booking 401 Error
echo ========================================
echo.

echo This script will rebuild and restart the backend
echo to fix the 401 error for guest bookings.
echo.

echo Step 1: Stop backend
echo ----------------------------------------
taskkill /F /IM main.exe 2>nul
timeout /t 2 >nul

echo.
echo Step 2: Clean build
echo ----------------------------------------
cd backend
if exist main.exe del main.exe
if exist main del main

echo.
echo Step 3: Rebuild backend
echo ----------------------------------------
go build -o main.exe ./cmd/server
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Step 4: Start backend
echo ----------------------------------------
start "Hotel Backend" cmd /k "main.exe"

echo.
echo ========================================
echo Backend restarted successfully!
echo ========================================
echo.
echo The backend now supports guest bookings without signin.
echo.
echo Test with:
echo   1. Go to http://localhost:3000
echo   2. Search for rooms
echo   3. Book WITHOUT signing in
echo   4. Fill guest info
echo   5. Complete booking
echo.
echo Expected: No 401 error!
echo.
pause
