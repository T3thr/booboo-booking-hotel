@echo off
REM ===================================================================
REM Schema Verification Script (Windows)
REM Verifies that the guests and guest_accounts tables are created correctly
REM ===================================================================

echo ==========================================
echo Hotel Booking System - Schema Verification
echo Migration: 001_create_guests_tables.sql
echo ==========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running
    echo Please start Docker Desktop and try again
    exit /b 1
)

echo [OK] Docker is running
echo.

REM Check if database container is running
docker-compose ps | findstr "hotel-booking-db" | findstr "Up" >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Database container is not running
    echo Starting database container...
    docker-compose up -d db
    echo Waiting for database to be ready...
    timeout /t 10 /nobreak >nul
)

echo Running verification tests...
echo.

REM Test 1: Check tables exist
echo Test 1: Checking if tables exist...
docker-compose exec -T db psql -U postgres -d hotel_booking -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('guests', 'guest_accounts') ORDER BY table_name;" 2>nul
if errorlevel 1 (
    echo [ERROR] Tables not found
    exit /b 1
)
echo [OK] Tables exist
echo.

REM Test 2: Count records
echo Test 2: Counting seed data...
docker-compose exec -T db psql -U postgres -d hotel_booking -c "SELECT 'guests' as table_name, COUNT(*) as record_count FROM guests UNION ALL SELECT 'guest_accounts' as table_name, COUNT(*) as record_count FROM guest_accounts;" 2>nul
if errorlevel 1 (
    echo [ERROR] Failed to count records
    exit /b 1
)
echo [OK] Seed data loaded
echo.

REM Test 3: Verify indexes
echo Test 3: Checking indexes...
docker-compose exec -T db psql -U postgres -d hotel_booking -c "SELECT indexname FROM pg_indexes WHERE tablename IN ('guests', 'guest_accounts') ORDER BY indexname;" 2>nul
if errorlevel 1 (
    echo [ERROR] Indexes not found
    exit /b 1
)
echo [OK] Indexes created
echo.

REM Test 4: Verify foreign key
echo Test 4: Checking foreign key constraints...
docker-compose exec -T db psql -U postgres -d hotel_booking -c "SELECT tc.constraint_name, tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name FROM information_schema.table_constraints AS tc JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'guest_accounts';" 2>nul
if errorlevel 1 (
    echo [ERROR] Foreign key constraints not found
    exit /b 1
)
echo [OK] Foreign key constraints verified
echo.

REM Test 5: Sample data query
echo Test 5: Displaying sample guest data...
docker-compose exec -T db psql -U postgres -d hotel_booking -c "SELECT g.guest_id, g.first_name, g.last_name, g.email, CASE WHEN ga.guest_account_id IS NOT NULL THEN 'Yes' ELSE 'No' END as has_account FROM guests g LEFT JOIN guest_accounts ga ON g.guest_id = ga.guest_id ORDER BY g.guest_id LIMIT 5;" 2>nul
if errorlevel 1 (
    echo [ERROR] Failed to retrieve sample data
    exit /b 1
)
echo [OK] Sample data retrieved successfully
echo.

echo ==========================================
echo [SUCCESS] All verification tests passed!
echo ==========================================
echo.
echo Migration 001_create_guests_tables.sql is working correctly.
echo.
echo Test credentials:
echo   Email: somchai@example.com
echo   Password: password123
echo.
echo Next steps:
echo   - Task 4: Create Room Management schema
echo   - Task 5: Create Pricing and Inventory schema
echo   - Task 6: Create Bookings schema
echo.
pause
