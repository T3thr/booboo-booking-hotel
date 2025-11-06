@echo off
echo ========================================
echo แก้ไขปัญหาห้องเต็ม - สร้าง Room Inventory
echo ========================================
echo.

REM อ่านค่า environment variables
for /f "tokens=1,2 delims==" %%a in ('type backend\.env ^| findstr /v "^#"') do (
    set %%a=%%b
)

echo กำลังเชื่อมต่อ PostgreSQL...
echo Database: %DB_NAME%
echo Host: %DB_HOST%
echo.

REM รัน SQL script (ใช้ PGPASSWORD environment variable)
set PGPASSWORD=%DB_PASSWORD%
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f fix-room-inventory.sql
set PGPASSWORD=

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo สำเร็จ! ห้องพักพร้อมจองแล้ว
    echo ========================================
    echo.
    echo ลองค้นหาห้องใหม่ที่ frontend
) else (
    echo.
    echo ========================================
    echo เกิดข้อผิดพลาด!
    echo ========================================
    echo กรุณาตรวจสอบการเชื่อมต่อ database
)

pause
