@echo off
echo ========================================
echo Running Migration 020: Allow NULL guest_id
echo ========================================
echo.

echo This migration allows guest bookings without user accounts
echo by making guest_id nullable in the bookings table.
echo.

set PGPASSWORD=postgres
psql -U postgres -d hotel_booking -f 020_allow_null_guest_id.sql

if errorlevel 1 (
    echo.
    echo Migration failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Migration completed successfully!
echo ========================================
echo.
echo Guest bookings (without signin) are now supported.
echo.
pause
