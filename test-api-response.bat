@echo off
echo ============================================
echo ทดสอบ API Room Search
echo ============================================
echo.
echo [1] ทดสอบ Backend Health
curl -s http://localhost:8080/health
echo.
echo.

echo [2] ทดสอบ Room Search API
echo URL: /api/rooms/search?checkIn=2025-11-06^&checkOut=2025-11-08^&guests=2
echo.
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2" | jq .
echo.
echo.

echo [3] ตรวจสอบ available_rooms field
echo.
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2" | jq ".data.room_types[] | {name: .name, available_rooms: .available_rooms, total_price: .total_price}"
echo.
echo.

echo ============================================
echo หมายเหตุ:
echo - ถ้า available_rooms = null หรือ 0 แสดงว่า database ไม่มี inventory
echo - ถ้า available_rooms ^> 0 แสดงว่าระบบทำงานถูกต้อง
echo ============================================
pause
