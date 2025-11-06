@echo off
echo ============================================
echo แก้ไขและทดสอบระบบจองห้อง
echo ============================================
echo.

echo [Step 1] แก้ไข Database Inventory...
echo กรุณาใส่รหัสผ่าน PostgreSQL (postgres)
psql -U postgres -d hotel_booking -f fix-room-availability-complete.sql
echo.

echo [Step 2] รอ Backend start (5 วินาที)...
timeout /t 5 /nobreak >nul
echo.

echo [Step 3] ทดสอบ API...
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"
echo.
echo.

echo ============================================
echo เสร็จสิ้น!
echo.
echo ขั้นตอนต่อไป:
echo 1. เปิด browser ไปที่ http://localhost:3000/rooms/search
echo 2. ค้นหาห้อง
echo 3. ควรเห็นปุ่ม "จองห้องนี้" (ไม่ใช่ "เต็ม")
echo ============================================
pause
