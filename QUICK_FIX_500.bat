@echo off
echo ========================================
echo Quick Fix for 500 Error
echo ========================================
echo.

echo Problem: GET /api/checkin/arrivals returns 500
echo Cause: Query uses JOIN guests but some bookings have NULL guest_id
echo Fix: Changed to LEFT JOIN and use booking_guests data
echo.
echo ========================================
echo REBUILD BACKEND NOW!
echo ========================================
echo.

echo Step 1: Stop backend (press Ctrl+C in backend terminal)
pause

echo.
echo Step 2: Rebuild backend...
cd backend
go build -o hotel-booking-api.exe ./cmd/server
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build Success!
echo ========================================
echo.
echo Step 3: Run backend...
echo.
echo Run this command in a new terminal:
echo cd backend
echo ./hotel-booking-api.exe
echo.
echo OR
echo.
echo go run cmd/server/main.go
echo.
echo ========================================
echo After backend starts:
echo ========================================
echo.
echo 1. Go to http://localhost:3000/admin/checkin
echo 2. Should work without 500 error
echo 3. Should show bookings correctly
echo 4. Should show payment status badges
echo.
pause
