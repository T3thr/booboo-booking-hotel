@echo off
echo ============================================================================
echo Fix Room Availability - Running SQL Script
echo ============================================================================
echo.

REM Get database credentials from .env
for /f "tokens=1,2 delims==" %%a in ('type backend\.env ^| findstr /v "^#"') do (
    if "%%a"=="DB_HOST" set DB_HOST=%%b
    if "%%a"=="DB_PORT" set DB_PORT=%%b
    if "%%a"=="DB_NAME" set DB_NAME=%%b
    if "%%a"=="DB_USER" set DB_USER=%%b
    if "%%a"=="DB_PASSWORD" set DB_PASSWORD=%%b
)

REM Set defaults if not found
if "%DB_HOST%"=="" set DB_HOST=localhost
if "%DB_PORT%"=="" set DB_PORT=5432
if "%DB_NAME%"=="" set DB_NAME=hotel_booking
if "%DB_USER%"=="" set DB_USER=postgres
if "%DB_PASSWORD%"=="" set DB_PASSWORD=postgres

echo Database: %DB_NAME%
echo Host: %DB_HOST%:%DB_PORT%
echo User: %DB_USER%
echo.

REM Set PGPASSWORD environment variable
set PGPASSWORD=%DB_PASSWORD%

REM Run the SQL script
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f fix-room-availability.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo SUCCESS: Room availability fixed!
    echo ============================================================================
    echo.
    echo Next steps:
    echo 1. Restart backend: cd backend ^&^& go run cmd/server/main.go
    echo 2. Test room search at: http://localhost:3000/rooms/search
    echo.
) else (
    echo.
    echo ============================================================================
    echo ERROR: Failed to fix room availability
    echo ============================================================================
    echo.
    echo Please check:
    echo 1. PostgreSQL is running
    echo 2. Database credentials in backend/.env are correct
    echo 3. Database exists and migrations are run
    echo.
)

pause
