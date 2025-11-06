@echo off
REM ============================================================================
REM Script: run_migration_010.bat
REM Description: รัน migration 010 - สร้าง check_out function
REM ============================================================================

echo ========================================
echo Running Migration 010: Check-out Function
echo ========================================
echo.

REM ตั้งค่า environment variables (ปรับตามการตั้งค่าของคุณ)
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking
set PGUSER=postgres

REM รัน migration
echo Running migration...
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f 010_create_check_out_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Migration completed successfully!
    echo ========================================
    echo.
    echo Running verification...
    psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f verify_check_out.sql
) else (
    echo.
    echo ========================================
    echo Migration failed!
    echo ========================================
    exit /b 1
)

echo.
echo ========================================
echo Next Steps:
echo ========================================
echo 1. Run tests: run_test_check_out.bat
echo 2. Review function: CHECK_OUT_REFERENCE.md
echo ========================================

pause
