@echo off
echo ============================================================================
echo RESTART BACKEND - Fix Available Rooms Field
echo ============================================================================
echo.
echo Step 1: Stopping backend...
taskkill /F /IM go.exe 2>nul
timeout /t 2 /nobreak >nul
echo Backend stopped!
echo.
echo Step 2: Starting backend...
cd backend
start "Hotel Backend" cmd /k "go run cmd/server/main.go"
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
echo CHECK THE RESPONSE ABOVE:
echo ============================================================================
echo.
echo Look for "available_rooms" field in each room type!
echo.
echo Example of CORRECT response:
echo {
echo   "room_type_id": 1,
echo   "name": "Standard Room",
echo   "available_rooms": 10,  ^<-- Must have this field!
echo   "total_price": 4500,
echo   ...
echo }
echo.
echo ============================================================================
echo If you see "available_rooms": SUCCESS! Go test on web!
echo If you don't see it: Check backend terminal for errors
echo ============================================================================
pause
