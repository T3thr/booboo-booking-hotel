@echo off
REM ============================================================================
REM Run Demo Data Seed Script (Windows)
REM ============================================================================

echo ============================================================================
echo Hotel Reservation System - Demo Data Seed
echo ============================================================================
echo.

REM Check if PostgreSQL is accessible
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: psql command not found. Please install PostgreSQL or add it to PATH.
    pause
    exit /b 1
)

REM Set database connection parameters
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking
set PGUSER=postgres

echo Database: %PGDATABASE%
echo Host: %PGHOST%
echo Port: %PGPORT%
echo User: %PGUSER%
echo.

REM Prompt for password
echo Please enter PostgreSQL password:
set /p PGPASSWORD=

echo.
echo Running demo data seed script...
echo.

REM Run the seed script
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f 013_seed_demo_data.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================================
    echo Demo data seeded successfully!
    echo ============================================================================
    echo.
    echo You can now use the following credentials to test the system:
    echo.
    echo Guest Account:
    echo   Email: somchai@example.com
    echo   Password: password123
    echo.
    echo ============================================================================
) else (
    echo.
    echo ERROR: Failed to seed demo data.
    echo Please check the error messages above.
    echo.
)

pause
