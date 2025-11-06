@echo off
echo ============================================================================
echo FIX EVERYTHING - Complete System Check and Repair
echo ============================================================================
echo.

echo Step 1: Checking Database...
echo ============================================================================
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) as room_types FROM room_types;" 2>nul
if errorlevel 1 (
    echo ERROR: Cannot connect to database!
    echo Please make sure PostgreSQL is running
    pause
    exit /b 1
)

echo.
echo Step 2: Checking if we have data...
echo ============================================================================
psql -U postgres -d hotel_booking -c "SELECT (SELECT COUNT(*) FROM room_types) as room_types, (SELECT COUNT(*) FROM rate_plans) as rate_plans, (SELECT COUNT(*) FROM pricing_calendar WHERE date >= CURRENT_DATE) as pricing_calendar;"

echo.
echo Step 3: If no data, run seed script...
echo ============================================================================
set /p SEED="Do you want to run seed data? (y/n): "
if /i "%SEED%"=="y" (
    cd database\migrations
    psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
    cd ..\..
    echo Seed data completed!
)

echo.
echo Step 4: Testing Backend API...
echo ============================================================================
curl -s "http://localhost:8080/api/rooms/types" > nul 2>&1
if errorlevel 1 (
    echo ERROR: Backend is not running!
    echo.
    echo Please restart backend:
    echo   1. Go to backend terminal
    echo   2. Press Ctrl+C to stop
    echo   3. Run: go run cmd/server/main.go
    echo.
    pause
    exit /b 1
)

echo Backend is running!
echo.

echo Step 5: Testing Room Search...
echo ============================================================================
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
echo.
echo.

echo ============================================================================
echo DONE! Check the response above.
echo ============================================================================
echo.
echo If you see "success":true and "room_types" - IT WORKS! ✓
echo If you see "error" - Backend needs restart!
echo.
echo Next steps:
echo 1. If backend needs restart: Stop it (Ctrl+C) and run: go run cmd/server/main.go
echo 2. Test on web: http://localhost:3000/rooms/search
echo ============================================================================
pause
