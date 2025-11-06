@echo off
REM ============================================================================
REM Run Migration 004: Create Bookings Tables
REM ============================================================================

echo =========================================
echo Running Migration 004: Bookings Tables
echo =========================================
echo.

REM Check if .env file exists
if not exist "..\..\env" (
    echo Error: .env file not found!
    echo Please create .env file with database credentials.
    pause
    exit /b 1
)

REM Load environment variables from .env
for /f "tokens=1,2 delims==" %%a in (..\..\env) do (
    set %%a=%%b
)

REM Set default values if not provided
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432
if not defined DB_NAME set DB_NAME=hotel_booking
if not defined DB_USER set DB_USER=postgres

echo Database: %DB_NAME%
echo Host: %DB_HOST%:%DB_PORT%
echo User: %DB_USER%
echo.

REM Run migration
echo Running migration...
set PGPASSWORD=%DB_PASSWORD%
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f 004_create_bookings_tables.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =========================================
    echo Migration 004 completed successfully!
    echo =========================================
    echo.
    
    REM Ask if user wants to verify
    set /p verify="Do you want to run verification? (y/n) "
    if /i "%verify%"=="y" (
        echo.
        echo Running verification...
        psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f verify_bookings.sql
    )
    
    REM Ask if user wants to run tests
    echo.
    set /p test="Do you want to run tests? (y/n) "
    if /i "%test%"=="y" (
        echo.
        echo Running tests...
        psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f test_migration_004.sql
    )
) else (
    echo.
    echo =========================================
    echo Migration 004 failed!
    echo =========================================
    pause
    exit /b 1
)

pause
