@echo off
REM ============================================================================
REM Script: run_test_check_out.bat
REM Description: รันการทดสอบ check_out function
REM ============================================================================

echo ========================================
echo Testing Check-out Function
echo ========================================
echo.

REM ตั้งค่า environment variables
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking
set PGUSER=postgres

echo Running test suite...
echo.

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f test_check_out_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo All tests completed!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Tests failed!
    echo ========================================
    exit /b 1
)

pause
