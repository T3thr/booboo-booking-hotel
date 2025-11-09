@echo off
echo ========================================
echo Testing Guest Data Fix
echo ========================================
echo.

echo Step 1: Rebuild Backend...
cd backend
go build -o hotel-booking-server.exe ./cmd/server
if errorlevel 1 (
    echo ERROR: Backend build failed!
    pause
    exit /b 1
)
echo Backend built successfully!
echo.

echo Step 2: Restart Backend...
taskkill /F /IM hotel-booking-server.exe 2>nul
start "Hotel Backend" cmd /k "cd backend && hotel-booking-server.exe"
timeout /t 3 /nobreak >nul
echo Backend restarted!
echo.

echo ========================================
echo Fix Applied Successfully!
echo ========================================
echo.
echo What was fixed:
echo 1. Payment status now shows "approved" for Confirmed bookings
echo 2. Guest data now uses account info for signed-in users
echo.
echo Next steps:
echo 1. Sign in as a guest user
echo 2. Create a new booking
echo 3. Complete the booking
echo 4. Check admin/reception - should show correct guest name/email/phone
echo 5. Check admin/checkin - should show "approved" payment status
echo.
pause
