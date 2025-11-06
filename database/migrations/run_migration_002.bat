@echo off
REM ============================================================================
REM Script: run_migration_002.bat
REM Description: รัน migration 002 - Room Management Schema
REM ============================================================================

echo ========================================
echo Running Migration 002: Room Management
echo ========================================
echo.

REM ตรวจสอบว่า Docker container กำลังทำงานหรือไม่
docker ps --filter "name=hotel-booking-db" --format "{{.Names}}" > nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running or container 'hotel-booking-db' is not found
    echo Please start Docker Desktop and run: docker-compose up -d db
    pause
    exit /b 1
)

echo [INFO] Running migration script...
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < 002_create_room_management_tables.sql

if errorlevel 1 (
    echo.
    echo [ERROR] Migration failed!
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Migration completed successfully!
echo.
echo ========================================
echo Running Verification Script...
echo ========================================
echo.

docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < verify_room_management.sql

echo.
echo ========================================
echo Migration 002 Complete!
echo ========================================
pause
