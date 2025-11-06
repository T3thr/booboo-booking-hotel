@echo off
REM ============================================================================
REM Run Migration 018: Seed Admin Demo Data
REM ============================================================================

echo ============================================
echo Running Migration 018: Seed Admin Demo Data
echo ============================================
echo.

REM Check if PostgreSQL is accessible
psql -U postgres -d hotel_booking -c "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Cannot connect to PostgreSQL database
    echo Please ensure:
    echo 1. PostgreSQL is running
    echo 2. Database 'hotel_booking' exists
    echo 3. User 'postgres' has access
    pause
    exit /b 1
)

echo Running migration...
psql -U postgres -d hotel_booking -f 018_seed_admin_demo_data.sql

if errorlevel 1 (
    echo.
    echo ERROR: Migration failed!
    pause
    exit /b 1
)

echo.
echo ============================================
echo Migration 018 completed successfully!
echo ============================================
echo.
echo Next steps:
echo 1. Restart backend: cd ../../backend ^&^& go run cmd/server/main.go
echo 2. Open frontend: http://localhost:3000/admin
echo 3. Login as manager and check all pages
echo.
pause
