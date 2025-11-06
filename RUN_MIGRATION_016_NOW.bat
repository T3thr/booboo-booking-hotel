@echo off
cls
echo ============================================
echo แก้ไขปัญหาห้องเต็ม - Migration 016
echo ============================================
echo.
echo Migration นี้จะ:
echo - ลบ inventory เก่าที่มีปัญหา
echo - สร้าง inventory ใหม่ 100 วัน
echo - ตั้งค่าห้องว่างทั้งหมด (available ^> 0)
echo - เพิ่ม sample bookings 10%% เพื่อความสมจริง
echo.
echo กรุณาใส่รหัสผ่าน PostgreSQL (postgres)
echo.
pause
echo.

cd database\migrations
psql -U postgres -d hotel_booking -f 016_seed_available_inventory.sql

echo.
echo.
echo ============================================
echo ทดสอบ API
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
echo 1. ดู response ด้านบนว่ามี "available_rooms" ^> 0 หรือไม่
echo 2. เปิดเว็บ: http://localhost:3000/rooms/search
echo 3. ค้นหาห้อง - ควรเห็นปุ่ม "จองห้องนี้" (สีเขียว)
echo.
echo ผลลัพธ์ที่คาดหวัง:
echo - Standard Room: available_rooms = 9-10
echo - Deluxe Room: available_rooms = 7-8
echo - Suite Room: available_rooms = 5
echo.
echo หากต้องการตรวจสอบเพิ่มเติม:
echo cd database\migrations
echo psql -U postgres -d hotel_booking -f verify_migration_016.sql
echo ============================================
pause
