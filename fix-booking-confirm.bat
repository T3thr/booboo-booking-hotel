@echo off
echo ========================================
echo แก้ไข Booking Confirm - Payment Fields
echo ========================================
echo.

echo ปัญหา: Backend ต้องการ payment_method และ payment_id
echo การแก้ไข: เพิ่ม mock payment data ใน confirm request
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
echo 2. ค้นหาห้องและเลือกห้อง
echo 3. กรอกข้อมูลผู้เข้าพัก
echo 4. กรอกข้อมูลบัตรเครดิต (mock)
echo 5. กด Complete Booking
echo 6. ควรไปหน้า confirmation สำเร็จ
echo.
pause
