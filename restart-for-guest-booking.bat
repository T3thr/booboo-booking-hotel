@echo off
echo ========================================
echo Restarting Backend for Guest Booking
echo ========================================
echo.

echo Stopping backend...
taskkill /F /IM main.exe 2>nul
timeout /t 2 >nul

echo.
echo Building backend...
cd backend
go build -o main.exe ./cmd/server
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Starting backend...
start "Hotel Backend" cmd /k "main.exe"

echo.
echo ========================================
echo Backend restarted successfully!
echo ========================================
echo.
echo Guest booking is now enabled!
echo Users can book without signing in.
echo.
echo Test with:
echo   1. Go to http://localhost:3000
echo   2. Search for rooms
echo   3. Book without signing in
echo   4. Use phone number to track booking
echo.
pause
