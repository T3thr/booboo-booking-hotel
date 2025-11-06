@echo off
REM ============================================================================
REM Integration Tests Runner for PostgreSQL Functions (Windows)
REM ============================================================================

echo ============================================================
echo Running Integration Tests for PostgreSQL Functions
echo ============================================================
echo.

REM Check if PostgreSQL is accessible
psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PostgreSQL is not installed or not in PATH
    exit /b 1
)

REM Set database connection parameters
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking
set PGUSER=postgres

echo Connecting to database: %PGDATABASE%
echo.

REM Run integration tests
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f integration_tests.sql

if %errorlevel% equ 0 (
    echo.
    echo ============================================================
    echo Integration tests completed successfully!
    echo ============================================================
) else (
    echo.
    echo ============================================================
    echo Integration tests failed!
    echo ============================================================
    exit /b 1
)

pause
