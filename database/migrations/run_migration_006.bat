@echo off
REM ============================================================================
REM Script: run_migration_006.bat (Windows)
REM Description: รัน migration 006 - สร้าง confirm_booking function
REM Task: 12. สร้าง PostgreSQL Function - confirm_booking
REM ============================================================================

echo ========================================
echo Running Migration 006: Confirm Booking Function
echo ========================================
echo.

REM ตรวจสอบว่ามี .env file หรือไม่
if not exist "../../.env" (
    echo Error: .env file not found!
    echo Please create .env file in project root with database credentials.
    echo.
    echo Example:
    echo POSTGRES_HOST=localhost
    echo POSTGRES_PORT=5432
    echo POSTGRES_DB=hotel_booking
    echo POSTGRES_USER=postgres
    echo POSTGRES_PASSWORD=yourpassword
    pause
    exit /b 1
)

REM อ่านค่าจาก .env (simplified version for Windows)
REM Note: ใน production ควรใช้วิธีที่ปลอดภัยกว่า
set POSTGRES_HOST=localhost
set POSTGRES_PORT=5432
set POSTGRES_DB=hotel_booking
set POSTGRES_USER=postgres

REM ถาม password
set /p POSTGRES_PASSWORD=Enter PostgreSQL password: 

echo.
echo Connecting to database: %POSTGRES_DB% at %POSTGRES_HOST%:%POSTGRES_PORT%
echo.

REM รัน migration
echo Running migration file...
psql -h %POSTGRES_HOST% -p %POSTGRES_PORT% -U %POSTGRES_USER% -d %POSTGRES_DB% -f 006_create_confirm_booking_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Migration 006 completed successfully!
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Run tests: run_test_confirm_booking.bat
    echo 2. Verify function: verify_confirm_booking.sql
    echo.
) else (
    echo.
    echo ========================================
    echo Migration 006 failed!
    echo ========================================
    echo Please check the error messages above.
    echo.
)

pause
