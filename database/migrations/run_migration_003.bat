@echo off
REM ============================================================================
REM Script: run_migration_003.bat
REM Description: รันไฟล์ migration 003 สำหรับ Windows
REM ============================================================================

echo ========================================
echo Running Migration 003: Pricing and Inventory
echo ========================================
echo.

REM ตรวจสอบว่ามี PostgreSQL client (psql) หรือไม่
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: psql not found in PATH
    echo Please install PostgreSQL client or add it to PATH
    pause
    exit /b 1
)

REM ตั้งค่า environment variables (ปรับตามการตั้งค่าของคุณ)
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_booking
set PGUSER=postgres

REM ถาม password
set /p PGPASSWORD="Enter PostgreSQL password: "

echo.
echo Connecting to database: %PGDATABASE% on %PGHOST%:%PGPORT%
echo.

REM รัน migration
echo Running migration script...
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f 003_create_pricing_inventory_tables.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Migration completed successfully!
    echo ========================================
    echo.
    
    REM ถามว่าต้องการรัน verification หรือไม่
    set /p RUN_VERIFY="Run verification script? (Y/N): "
    if /i "%RUN_VERIFY%"=="Y" (
        echo.
        echo Running verification...
        psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f verify_pricing_inventory.sql
    )
    
    REM ถามว่าต้องการรัน tests หรือไม่
    set /p RUN_TESTS="Run test script? (Y/N): "
    if /i "%RUN_TESTS%"=="Y" (
        echo.
        echo Running tests...
        psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f test_migration_003.sql
    )
) else (
    echo.
    echo ========================================
    echo Migration failed!
    echo ========================================
)

echo.
pause
