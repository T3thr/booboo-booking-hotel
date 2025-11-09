@echo off
echo ========================================
echo Start Complete System
echo ========================================
echo.

echo IMPORTANT: You MUST rebuild backend first!
echo.
echo Step 1: Rebuild Backend
echo ------------------------
echo cd backend
echo go build -o hotel-booking-api.exe ./cmd/server
echo.
pause

echo.
echo Step 2: Start Backend
echo ---------------------
echo Starting backend...
start cmd /k "cd backend && hotel-booking-api.exe"
timeout /t 3

echo.
echo Step 3: Start Frontend
echo ----------------------
echo Starting frontend...
start cmd /k "cd frontend && npm run dev"
timeout /t 3

echo.
echo ========================================
echo System Started!
echo ========================================
echo.
echo Backend: http://localhost:8080
echo Frontend: http://localhost:3000
echo.
echo Test URLs:
echo - Reception: http://localhost:3000/admin/reception
echo - Check-in: http://localhost:3000/admin/checkin
echo.
echo ========================================
echo What to test:
echo ========================================
echo.
echo 1. Go to /admin/reception
echo 2. Tab "รอตรวจสอบการชำระเงิน"
echo 3. Click "อนุมัติ" on a booking
echo 4. Go to /admin/checkin
echo 5. Check that it shows "💰 ชำระเงินแล้ว"
echo 6. Click "ไปที่หน้า Reception" button
echo.
pause
