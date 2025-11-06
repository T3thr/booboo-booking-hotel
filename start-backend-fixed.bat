@echo off
echo ========================================
echo Starting Backend with Fixed Code
echo ========================================
cd backend
echo.
echo Starting hotel-booking-api.exe...
start "Hotel Booking API" hotel-booking-api.exe
echo.
echo Backend started in new window!
echo Wait 3 seconds for it to initialize...
timeout /t 3 /nobreak >nul
echo.
echo Testing API...
cd ..
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=1" > api-result.json
echo.
echo Response saved to api-result.json
type api-result.json
echo.
echo.
echo ========================================
echo Look for "available_rooms" in response
echo ========================================
pause
