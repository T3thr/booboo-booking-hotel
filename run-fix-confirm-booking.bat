@echo off
echo ========================================
echo Fix Confirm Booking Function
echo ========================================
echo.

echo Running SQL fix using Neon connection...
echo.

REM Read connection details from backend/.env
set DB_USER=neondb_owner
set DB_PASSWORD=npg_8kHamXSLKg1x
set DB_HOST=ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech
set DB_NAME=neondb

REM Set PGPASSWORD environment variable to avoid password prompt
set PGPASSWORD=%DB_PASSWORD%

psql -h %DB_HOST% -U %DB_USER% -d %DB_NAME% -f database/migrations/006_fix_confirm_booking_duplicate.sql

if errorlevel 1 (
    echo.
    echo ========================================
    echo Failed to run SQL via psql!
    echo ========================================
    echo.
    echo วิธีแก้: ใช้ Neon Console หรือ pgAdmin
    echo.
    echo วิธีที่ 1: Neon Console (แนะนำ)
    echo 1. ไปที่ https://console.neon.tech
    echo 2. เลือก project ของคุณ
    echo 3. คลิก "SQL Editor"
    echo 4. Copy SQL จาก database/migrations/006_fix_confirm_booking_duplicate.sql
    echo 5. Paste และ Run
    echo.
    echo วิธีที่ 2: pgAdmin
    echo 1. เปิด pgAdmin
    echo 2. เชื่อมต่อกับ Neon database:
    echo    Host: %DB_HOST%
    echo    Database: %DB_NAME%
    echo    User: %DB_USER%
    echo    Password: %DB_PASSWORD%
    echo 3. Query Tool → Copy SQL → Run
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Function updated successfully!
echo ========================================
echo.
echo ตอนนี้สามารถทดสอบ confirm booking ได้แล้ว
echo (แม้ว่า booking จะมี nightly log อยู่แล้วก็ตาม)
echo.
pause
