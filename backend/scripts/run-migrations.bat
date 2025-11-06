@echo off
REM ============================================================================
REM Script: run-migrations.bat
REM Description: รัน database migrations ทั้งหมดบน production database (Windows)
REM Usage: run-migrations.bat
REM ============================================================================

echo === Starting Database Migrations ===

REM ตรวจสอบว่ามี DATABASE_URL หรือไม่
if "%DATABASE_URL%"=="" (
    echo DATABASE_URL not set in environment, loading from .env file...
    
    REM อ่าน DATABASE_URL จาก .env file
    for /f "tokens=1,* delims==" %%a in ('findstr /r "^DATABASE_URL=" ..\..\.env 2^>nul') do (
        set DATABASE_URL=%%b
    )
    
    if "!DATABASE_URL!"=="" (
        echo ERROR: DATABASE_URL not found in environment or .env file
        echo Please set DATABASE_URL or create backend/.env file
        exit /b 1
    )
    
    echo Loaded DATABASE_URL from .env file
)

REM Enable delayed expansion for variable usage
setlocal enabledelayedexpansion

echo Database URL: %DATABASE_URL:~0,30%...

REM รัน migrations ทีละไฟล์
set MIGRATIONS=001_create_guests_tables.sql 002_create_room_management_tables.sql 003_create_pricing_inventory_tables.sql 004_create_bookings_tables.sql 005_create_booking_hold_function.sql 006_create_confirm_booking_function.sql 007_create_cancel_booking_function.sql 008_create_release_expired_holds_function.sql 009_create_check_in_function.sql 010_create_check_out_function.sql 011_create_move_room_function.sql 012_performance_optimization.sql

for %%m in (%MIGRATIONS%) do (
    echo.
    echo Running migration: %%m
    
    if exist "..\..\database\migrations\%%m" (
        psql "!DATABASE_URL!" -f "..\..\database\migrations\%%m"
        if !ERRORLEVEL! EQU 0 (
            echo ✓ %%m completed successfully
        ) else (
            echo ✗ %%m failed with error code !ERRORLEVEL!
            exit /b !ERRORLEVEL!
        )
    ) else (
        echo ⚠ Warning: Migration file not found: %%m
        echo Looking in: ..\..\database\migrations\%%m
    )
)

echo.
echo === All Migrations Completed Successfully ===

pause
