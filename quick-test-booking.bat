@echo off
echo ============================================
echo ทดสอบระบบจองห้องแบบรวดเร็ว
echo ============================================
echo.

echo [1] ตรวจสอบ PostgreSQL...
psql -U postgres -d hotel_booking -c "SELECT 'PostgreSQL OK' as status;" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ PostgreSQL ไม่ทำงาน
    pause
    exit /b 1
)
echo ✅ PostgreSQL ทำงานปกติ
echo.

echo [2] ตรวจสอบ Inventory...
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) as inventory_count FROM room_inventory WHERE date >= CURRENT_DATE;"
echo.

echo [3] ตรวจสอบห้องว่าง...
psql -U postgres -d hotel_booking -c "SELECT rt.name, SUM(ri.allotment - ri.booked_count - ri.tentative_count) as available FROM room_inventory ri JOIN room_types rt ON ri.room_type_id = rt.room_type_id WHERE ri.date >= CURRENT_DATE GROUP BY rt.name;"
echo.

echo [4] ทดสอบ Backend API...
echo กำลังเรียก: http://localhost:8080/api/rooms/search
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-12&guests=2" | findstr "available_rooms"
echo.
echo.

echo ============================================
echo สรุป:
echo - ถ้าเห็น available_rooms ^> 0 = ✅ ระบบพร้อมใช้งาน
echo - ถ้าเห็น available_rooms = 0 = ❌ ต้องรัน fix-room-availability-complete.bat
echo ============================================
pause
