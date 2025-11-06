@echo off
REM ============================================================================
REM Template for Migration Scripts with Auto PostgreSQL Detection
REM ============================================================================
REM Copy this template for new migration scripts

REM Setup environment (includes PostgreSQL PATH)
call "%~dp0setup-env.bat"

echo =========================================
echo Running Migration: [MIGRATION_NAME]
echo =========================================
echo.

REM Check if .env file exists
if not exist ".env" (
    echo Error: .env file not found!
    echo Please create .env file with database credentials.
    pause
    exit /b 1
)

REM Load environment variables from .env
for /f "tokens=1,2 delims==" %%a in (.env) do (
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
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f [MIGRATION_FILE].sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =========================================
    echo Migration completed successfully!
    echo =========================================
) else (
    echo.
    echo =========================================
    echo Migration failed!
    echo =========================================
    pause
    exit /b 1
)

pause
