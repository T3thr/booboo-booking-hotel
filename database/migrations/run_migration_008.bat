@echo off
REM ============================================================================
REM Script: run_migration_008.bat
REM Description: Run migration 008 - Create release_expired_holds function
REM Task: 14. สร้าง PostgreSQL Function - release_expired_holds
REM ============================================================================

echo.
echo ========================================
echo Running Migration 008
echo Create release_expired_holds Function
echo ========================================
echo.

REM Load environment variables
if exist "../../.env" (
    for /f "tokens=*" %%a in ('type "../../.env"') do (
        set "%%a"
    )
)

REM Set default values if not in .env
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432
if not defined DB_NAME set DB_NAME=hotel_booking
if not defined DB_USER set DB_USER=postgres
if not defined DB_PASSWORD set DB_PASSWORD=postgres

echo Connecting to: %DB_HOST%:%DB_PORT%/%DB_NAME%
echo.

REM Run migration
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f 008_create_release_expired_holds_function.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Migration 008 completed successfully!
    echo ========================================
    echo.
) else (
    echo.
    echo ========================================
    echo Migration 008 FAILED!
    echo ========================================
    echo.
    exit /b 1
)

pause
