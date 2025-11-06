@echo off
echo ========================================
echo Clean Old Bookings and Test
echo ========================================
echo.

echo [1/2] Cleaning old test bookings...
echo.

psql -U postgres -d hotel_booking -f clean-old-bookings.sql

if errorlevel 1 (
    echo.
    echo Failed to clean bookings!
    echo.
    echo ถ้าไม่มี psql ติดตั้ง ให้รัน SQL ใน pgAdmin:
    echo 1. เปิดไฟล์ clean-old-bookings.sql
    echo 2. Copy SQL
    echo 3. Paste ใน pgAdmin Query Tool
    echo 4. Run
    echo.
    pause
    exit /b 1
)

echo.
echo [2/2] Bookings cleaned successfully!
echo.
echo ========================================
echo พร้อมทดสอบ!
echo ========================================
echo.
echo ขั้นตอนทดสอบ:
echo 1. ค้นหาห้อง
echo 2. เลือกห้องและกรอกข้อมูล
echo 3. กรอกข้อมูลบัตรเครดิต (mock)
echo 4. กด Complete Booking
echo 5. ควรไปหน้า confirmation สำเร็จ
echo.
pause
