@echo off
REM Run Migration 021: Add Email and Phone to Booking Guests

echo ========================================
echo Running Migration 021
echo Add Email and Phone to Booking Guests
echo ========================================

REM Load environment variables
if exist .env (
    for /f "tokens=*" %%a in ('type .env ^| findstr /v "^#"') do set %%a
)

REM Set default values if not in .env
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432
if not defined DB_NAME set DB_NAME=hotel_db
if not defined DB_USER set DB_USER=hotel_admin
if not defined DB_PASSWORD set DB_PASSWORD=hotel_password_123

echo.
echo Database: %DB_NAME%
echo Host: %DB_HOST%:%DB_PORT%
echo User: %DB_USER%
echo.

REM Run migration
echo Running migration...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f database/migrations/021_add_email_phone_to_booking_guests.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Migration 021 completed successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Migration 021 failed!
    echo ========================================
    exit /b 1
)

pause
