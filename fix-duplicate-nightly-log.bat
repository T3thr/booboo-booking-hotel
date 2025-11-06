@echo off
echo ========================================
echo แก้ไข Duplicate Nightly Log Error
echo ========================================
echo.

echo ปัญหา: CreateBooking และ confirm_booking สร้าง nightly log ซ้ำกัน
echo การแก้ไข: ลบการสร้าง nightly log ออกจาก CreateBooking
echo           ให้ confirm_booking เป็นคนสร้างเพียงอย่างเดียว
echo.

echo [1/3] Stopping backend...
taskkill /F /IM main.exe 2>nul
taskkill /F /IM go.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/3] Cleaning old nightly logs from test bookings...
echo (Optional - ถ้าต้องการลบข้อมูลทดสอบเก่า)
echo.

echo [3/3] Rebuilding and starting backend...
cd backend
go build -o main.exe ./cmd/server
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

start cmd /k "main.exe"

echo.
echo ========================================
echo เสร็จสิ้น!
echo ========================================
echo.
echo Backend กำลังเริ่มต้น...
echo.
echo ขั้นตอนทดสอบ:
echo 1. รอ backend เริ่มต้นเสร็จ (5-10 วินาที)
echo 2. ลองจองห้องใหม่
echo 3. กรอกข้อมูลบัตรเครดิต
echo 4. กด Complete Booking
echo 5. ควรไปหน้า confirmation สำเร็จ
echo.
pause
