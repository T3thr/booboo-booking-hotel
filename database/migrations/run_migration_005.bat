@echo off
REM ============================================================================
REM Script: run_migration_005.bat
REM Description: รัน migration 005 - create_booking_hold function (Windows)
REM ============================================================================

echo ============================================================================
echo Running Migration 005: Create Booking Hold Function
echo ============================================================================
echo.

REM ตั้งค่า environment variables (ปรับตามการตั้งค่าของคุณ)
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking_db
set PGUSER=postgres
set PGPASSWORD=postgres123

echo Connecting to database: %PGDATABASE%
echo.

REM รัน migration
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f 005_create_booking_hold_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo Migration 005 completed successfully!
    echo ============================================================================
    echo.
    echo You can now run tests with: run_test_booking_hold.bat
) else (
    echo.
    echo ============================================================================
    echo Migration 005 failed!
    echo ============================================================================
    exit /b 1
)

pause
