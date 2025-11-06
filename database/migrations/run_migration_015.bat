@echo off
REM ============================================================================
REM Run Migration 015: Create Payment Proof Table
REM ============================================================================

echo ============================================================================
echo Running Migration 015: Create Payment Proof Table
echo ============================================================================
echo.

REM Check if PostgreSQL is accessible
psql --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: PostgreSQL is not installed or not in PATH
    echo Please install PostgreSQL or add it to your PATH
    pause
    exit /b 1
)

REM Set database connection parameters
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking
set PGUSER=postgres

echo Connecting to database: %PGDATABASE%
echo.

REM Run the migration
psql -U %PGUSER% -d %PGDATABASE% -f 015_create_payment_proof_table.sql

if errorlevel 1 (
    echo.
    echo ============================================================================
    echo ERROR: Migration failed!
    echo ============================================================================
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo Migration 015 completed successfully!
echo ============================================================================
echo.
echo Next steps:
echo 1. Restart your backend server
echo 2. Test payment proof upload functionality
echo 3. Test admin payment verification
echo ============================================================================
pause
