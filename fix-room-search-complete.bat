@echo off
echo ============================================================================
echo FIX ROOM SEARCH - Complete Solution
echo ============================================================================
echo.
echo Step 1: Stopping backend...
taskkill /F /IM go.exe 2>nul
timeout /t 2 /nobreak >nul
echo.
echo Step 2: Starting backend with detailed logging...
cd backend
start "Hotel Backend" cmd /k "echo Starting backend with logging... && go run cmd/server/main.go"
echo.
echo Step 3: Waiting for backend to start (10 seconds)...
timeout /t 10 /nobreak >nul
echo.
echo Step 4: Testing API...
echo ============================================================================
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
echo.
echo.
echo ============================================================================
echo CHECK RESULTS:
echo ============================================================================
echo.
echo 1. Check backend terminal for detailed error logs
echo 2. Look for lines starting with "ERROR [SearchRooms]:"
echo 3. If you see "available_rooms" in response above: SUCCESS!
echo.
echo Common errors and solutions:
echo - "failed to ensure inventory": Run seed data
echo - "database query failed": Check database connection
echo - "failed to scan": Check database schema
echo.
echo ============================================================================
echo Next: Check backend terminal for error details!
echo ============================================================================
pause
