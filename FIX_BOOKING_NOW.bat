@echo off
cls
echo ============================================
echo แก้ไขปัญหาห้องเต็ม - ทันที!
echo ============================================
echo.
echo ขั้นตอนที่ 1: รีเซ็ต Database Inventory
echo กรุณาใส่รหัสผ่าน PostgreSQL (postgres)
echo.
psql -U postgres -d hotel_booking -f fix-inventory-reset.sql
echo.
echo.

echo ============================================
echo ขั้นตอนที่ 2: ทดสอบ API
echo ============================================
timeout /t 2 /nobreak >nul
echo.
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"
echo.
echo.

echo ============================================
echo เสร็จสิ้น!
echo ============================================
echo.
echo ตรวจสอบ:
echo 1. ดู response ด้านบนว่ามี "available_rooms" หรือไม่
echo 2. เปิดเว็บ: http://localhost:3000/rooms/search
echo 3. ค้นหาห้อง - ควรเห็นปุ่ม "จองห้องนี้" (สีเขียว)
echo.
echo หากยังไม่ได้:
echo - ตรวจสอบว่า Backend ทำงานอยู่หรือไม่
echo - ลอง restart Backend: cd backend ^&^& go run cmd/server/main.go
echo - ลอง hard refresh browser: Ctrl+Shift+R
echo ============================================
pause
