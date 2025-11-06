@echo off
echo ============================================================================
echo FIX SQL ERROR AND RESTART BACKEND
echo ============================================================================
echo.
echo Step 1: Kill ALL Go processes...
taskkill /F /IM go.exe 2>nul
timeout /t 3 /nobreak >nul
echo.
echo Step 2: Kill processes on port 8080...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do taskkill /F /PID %%a 2>nul
timeout /t 2 /nobreak >nul
echo.
echo Step 3: Starting backend...
cd backend
start "Hotel Backend - Fixed" cmd /k "go run cmd/server/main.go"
echo.
echo Step 4: Waiting for backend to start (10 seconds)...
timeout /t 10 /nobreak >nul
echo.
echo Step 5: Testing API...
echo ============================================================================
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
echo.
echo.
echo ============================================================================
echo CHECK RESULTS:
echo ============================================================================
echo.
echo If you see "available_rooms" field: SUCCESS! ✓
echo If you see error: Check backend terminal for details
echo.
echo Backend terminal should show:
echo   INFO [SearchRooms]: Request - CheckIn: ..., CheckOut: ..., Guests: ...
echo   INFO [SearchRooms]: Success - Found X room types
echo.
echo ============================================================================
pause
