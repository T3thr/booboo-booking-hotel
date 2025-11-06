@echo off
REM ============================================================================
REM Test Script: Cancel Booking Function
REM ============================================================================

echo.
echo ========================================
echo Testing cancel_booking Function
echo ========================================
echo.

REM Check if PostgreSQL is accessible
psql -U postgres -d hotel_booking -c "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo Error: Cannot connect to PostgreSQL database
    pause
    exit /b 1
)

echo Running comprehensive tests...
echo.
psql -U postgres -d hotel_booking -f test_cancel_booking_function.sql

if errorlevel 1 (
    echo.
    echo ========================================
    echo Tests FAILED
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo All Tests Passed!
echo ========================================
echo.
pause
