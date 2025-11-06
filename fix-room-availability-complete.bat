@echo off
echo ============================================
echo แก้ไขปัญหาห้องเต็ม - สร้าง Inventory
echo ============================================
echo.

echo [1/3] กำลังรัน SQL Script...
psql -U postgres -d hotel_booking -f fix-room-availability-complete.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ สร้าง Inventory สำเร็จ!
    echo.
    echo [2/3] กำลัง Restart Backend...
    taskkill /F /IM main.exe 2>nul
    timeout /t 2 /nobreak >nul
    
    cd backend
    start "Backend Server" cmd /k "go run cmd/server/main.go"
    cd ..
    
    echo.
    echo ✅ Backend กำลังเริ่มต้น...
    echo.
    echo [3/3] รอ Backend พร้อมใช้งาน (10 วินาที)...
    timeout /t 10 /nobreak >nul
    
    echo.
    echo ============================================
    echo ✅ เสร็จสมบูรณ์!
    echo ============================================
    echo.
    echo ตอนนี้ลองค้นหาห้องใหม่ที่:
    echo http://localhost:3000/rooms/search
    echo.
    echo ห้องทุกประเภทควรมีห้องว่างสำหรับ 90 วันข้างหน้า
    echo.
) else (
    echo.
    echo ❌ เกิดข้อผิดพลาด!
    echo กรุณาตรวจสอบว่า PostgreSQL ทำงานอยู่
    echo.
)

pause
