@echo off
echo ========================================
echo แก้ไขปัญหาห้องเต็ม - สร้าง Room Inventory
echo ========================================
echo.

set PGPASSWORD=npg_8kHamXSLKg1x

psql "postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require" -f fix-room-inventory.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo สำเร็จ! ห้องพักพร้อมจองแล้ว
    echo ========================================
) else (
    echo.
    echo ========================================
    echo เกิดข้อผิดพลาด!
    echo ========================================
)

set PGPASSWORD=
pause
