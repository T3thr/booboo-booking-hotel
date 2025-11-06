@echo off
REM ============================================================================
REM Script: run_migration_011.bat
REM Description: รัน migration 011 - สร้าง move_room function (Windows)
REM ============================================================================

echo ============================================================================
echo Running Migration 011: Create Move Room Function
echo ============================================================================
echo.

REM ตรวจสอบว่ามี environment variables หรือไม่
if "%DB_HOST%"=="" set DB_HOST=localhost
if "%DB_PORT%"=="" set DB_PORT=5432
if "%DB_NAME%"=="" set DB_NAME=hotel_booking
if "%DB_USER%"=="" set DB_USER=postgres

echo Database Configuration:
echo   Host: %DB_HOST%
echo   Port: %DB_PORT%
echo   Database: %DB_NAME%
echo   User: %DB_USER%
echo.

REM รัน migration
echo Running migration script...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f 011_create_move_room_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo Migration 011 completed successfully!
    echo ============================================================================
    echo.
    echo Next steps:
    echo   1. Run verification: run_migration_011.bat verify
    echo   2. Run tests: run_test_move_room.bat
    echo.
) else (
    echo.
    echo ============================================================================
    echo Migration 011 failed!
    echo ============================================================================
    echo Please check the error messages above.
    echo.
    exit /b 1
)

REM ถ้ามี argument "verify" ให้รัน verification
if "%1"=="verify" (
    echo.
    echo Running verification...
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f verify_move_room.sql
)

pause
