@echo off
REM ============================================================================
REM Run Migration 007: Create Cancel Booking Function
REM ============================================================================

echo.
echo ========================================
echo Running Migration 007
echo ========================================
echo.

REM Check if PostgreSQL is accessible
psql -U postgres -d hotel_booking -c "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo Error: Cannot connect to PostgreSQL database
    echo Please ensure:
    echo   1. PostgreSQL is running
    echo   2. Database 'hotel_booking' exists
    echo   3. User 'postgres' has access
    pause
    exit /b 1
)

echo Running migration script...
psql -U postgres -d hotel_booking -f 007_create_cancel_booking_function.sql

if errorlevel 1 (
    echo.
    echo ========================================
    echo Migration 007 FAILED
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo Migration 007 Completed Successfully
echo ========================================
echo.
echo Next steps:
echo   1. Run tests: run_test_cancel_booking.bat
echo   2. Verify function: verify_cancel_booking.sql
echo.
pause
