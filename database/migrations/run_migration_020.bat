@echo off
REM Run Migration 020: Seed Check-in/Check-out Test Data

echo ============================================
echo Running Migration 020
echo ============================================
echo.

REM Load environment variables from backend/.env
if exist "..\..\backend\.env" (
    for /f "tokens=1,2 delims==" %%a in (..\..\backend\.env) do (
        if "%%a"=="DB_HOST" set DB_HOST=%%b
        if "%%a"=="DB_PORT" set DB_PORT=%%b
        if "%%a"=="DB_USER" set DB_USER=%%b
        if "%%a"=="DB_PASSWORD" set DB_PASSWORD=%%b
        if "%%a"=="DB_NAME" set DB_NAME=%%b
    )
)

REM Set default values if not found
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432
if not defined DB_USER set DB_USER=postgres
if not defined DB_PASSWORD set DB_PASSWORD=postgres
if not defined DB_NAME set DB_NAME=hotel_booking

echo Database Configuration:
echo - Host: %DB_HOST%
echo - Port: %DB_PORT%
echo - Database: %DB_NAME%
echo - User: %DB_USER%
echo.

REM Set PGPASSWORD for authentication
set PGPASSWORD=%DB_PASSWORD%

echo Running migration 020...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f 020_seed_checkin_test_data.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo Migration 020 completed successfully!
    echo ============================================
) else (
    echo.
    echo ============================================
    echo Migration 020 failed!
    echo ============================================
    exit /b 1
)

pause
