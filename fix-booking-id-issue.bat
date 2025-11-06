@echo off
echo ========================================
echo แก้ไข Booking ID Issue
echo ========================================
echo.

echo [1/2] Stopping frontend...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/2] Starting frontend...
cd frontend
start cmd /k "npm run dev"

echo.
echo ========================================
echo เสร็จสิ้น!
echo ========================================
echo.
echo Frontend กำลังเริ่มต้น...
echo.
echo ขั้นตอนทดสอบ:
echo 1. รอ frontend เริ่มต้นเสร็จ (10-20 วินาที)
echo 2. เปิด Browser Console (F12)
echo 3. ลองค้นหาห้องและจองใหม่
echo 4. ดู log ใน console ว่า booking_id ถูกส่งกลับมาหรือไม่
echo.
pause
