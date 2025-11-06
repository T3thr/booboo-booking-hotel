@echo off
echo ============================================
echo ทดสอบห้องว่าง - Room Availability Test
echo ============================================
echo.

echo [Step 1] ตรวจสอบ Database...
psql -U postgres -d hotel_booking -c "SELECT rt.name, COUNT(*) as inventory_days, SUM(ri.allotment - ri.booked_count - ri.tentative_count) as total_available FROM room_inventory ri JOIN room_types rt ON ri.room_type_id = rt.room_type_id WHERE ri.date >= CURRENT_DATE GROUP BY rt.name ORDER BY rt.name;"

echo.
echo [Step 2] ทดสอบ Backend API...
curl -X GET "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-12&guests=2"

echo.
echo.
echo ============================================
echo หากเห็นข้อมูลด้านบน แสดงว่าระบบทำงาน
echo ============================================
pause
