@echo off
REM ============================================================================
REM Run Migration 019: Seed Complete Admin Demo Data
REM ============================================================================

echo ============================================
echo Running Migration 019
echo ============================================
echo.

REM Set PostgreSQL connection details from backend/.env
set PGHOST=ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech
set PGPORT=5432
set PGDATABASE=neondb
set PGUSER=neondb_owner
set PGPASSWORD=npg_8kHamXSLKg1x
set PGSSLMODE=require

echo Connecting to Neon database: %PGDATABASE%
echo Host: %PGHOST%
echo.

REM Run the migration
psql "postgresql://%PGUSER%:%PGPASSWORD%@%PGHOST%/%PGDATABASE%?sslmode=require" -f 019_seed_admin_demo_data_complete.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo Migration 019 completed successfully!
    echo ============================================
    echo.
    echo Admin Demo Data has been seeded:
    echo - 3 Pending Bookings
    echo - 5 Payment Proofs
    echo - Updated Inventory
    echo - Housekeeping Tasks
    echo.
    echo You can now test Admin Pages:
    echo 1. Dashboard: http://localhost:3000/admin/dashboard
    echo 2. Bookings: http://localhost:3000/admin/bookings
    echo 3. Inventory: http://localhost:3000/admin/inventory
    echo 4. Housekeeping: http://localhost:3000/admin/housekeeping
    echo.
) else (
    echo.
    echo ============================================
    echo Migration 019 failed!
    echo ============================================
    echo Please check the error messages above.
    echo.
)

pause
