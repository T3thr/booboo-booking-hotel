@echo off
echo ============================================
echo แก้ไขปัญหาห้องเต็ม - รีเซ็ต Inventory
echo ============================================
echo.
echo กรุณาใส่รหัสผ่าน PostgreSQL (postgres)
echo.
psql -U postgres -d hotel_booking -f fix-inventory-reset.sql
echo.
echo ============================================
echo เสร็จสิ้น!
echo.
echo ขั้นตอนต่อไป:
echo 1. ทดสอบ API: curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"
echo 2. เปิดเว็บ: http://localhost:3000/rooms/search
echo 3. ค้นหาห้อง - ควรเห็นปุ่ม "จองห้องนี้"
echo ============================================
pause
