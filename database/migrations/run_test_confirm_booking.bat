@echo off
REM ============================================================================
REM Script: run_test_confirm_booking.bat (Windows)
REM Description: รัน test suite สำหรับ confirm_booking function
REM Task: 12. สร้าง PostgreSQL Function - confirm_booking
REM ============================================================================

echo ========================================
echo Testing Confirm Booking Function
echo ========================================
echo.

REM ตรวจสอบว่ามี .env file หรือไม่
if not exist "../../.env" (
    echo Error: .env file not found!
    pause
    exit /b 1
)

REM อ่านค่าจาก .env
set POSTGRES_HOST=localhost
set POSTGRES_PORT=5432
set POSTGRES_DB=hotel_booking
set POSTGRES_USER=postgres

REM ถาม password
set /p POSTGRES_PASSWORD=Enter PostgreSQL password: 

echo.
echo Running test suite...
echo.

REM รัน tests
psql -h %POSTGRES_HOST% -p %POSTGRES_PORT% -U %POSTGRES_USER% -d %POSTGRES_DB% -f test_confirm_booking_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo All tests completed!
    echo ========================================
    echo.
    echo Check the output above for test results.
    echo All tests should show: ✓ TEST X PASSED
    echo.
) else (
    echo.
    echo ========================================
    echo Tests failed!
    echo ========================================
    echo Please check the error messages above.
    echo.
)

pause
