@echo off
REM ============================================================================
REM Run Demo Data Seed Script via Docker (Windows)
REM ============================================================================

echo ============================================================================
echo Hotel Reservation System - Demo Data Seed (Docker)
echo ============================================================================
echo.

REM Check if Docker is running
docker ps >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker is not running or not installed.
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo Checking if database container is running...
docker ps --filter "name=hotel-booking-db" --format "{{.Names}}" | findstr "hotel-booking-db" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PostgreSQL container is not running.
    echo Please start the database with: docker-compose up -d db
    pause
    exit /b 1
)

echo.
echo Running demo data seed script via Docker...
echo.

REM Run the seed script through Docker
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < 013_seed_demo_data.sql

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
    echo Staff Account:
    echo   Email: staff@hotel.com
    echo   Password: staff123
    echo.
    echo Housekeeper Account:
    echo   Email: housekeeper@hotel.com
    echo   Password: housekeeper123
    echo.
    echo Manager Account:
    echo   Email: manager@hotel.com
    echo   Password: manager123
    echo.
    echo ============================================================================
) else (
    echo.
    echo ERROR: Failed to seed demo data.
    echo.
    echo Troubleshooting:
    echo 1. Make sure PostgreSQL container is running: docker ps
    echo 2. Check container name: docker ps --filter "name=postgres"
    echo 3. Try: docker exec -it hotel-booking-db psql -U postgres -d hotel_booking_booking
    echo.
)

pause
