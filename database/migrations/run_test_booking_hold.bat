@echo off
REM ============================================================================
REM Script: run_test_booking_hold.bat
REM Description: ทดสอบ create_booking_hold function (Windows)
REM ============================================================================

echo ============================================================================
echo Testing Booking Hold Function
echo ============================================================================
echo.

REM ตั้งค่า environment variables
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking_db
set PGUSER=postgres
set PGPASSWORD=postgres123

echo Connecting to database: %PGDATABASE%
echo.

REM รัน test script
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f test_booking_hold_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo All tests completed!
    echo ============================================================================
) else (
    echo.
    echo ============================================================================
    echo Tests failed!
    echo ============================================================================
    exit /b 1
)

pause
