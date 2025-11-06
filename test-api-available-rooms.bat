@echo off
echo Testing API for available_rooms field...
echo.
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"
echo.
echo.
echo Look for "available_rooms" in the response above
pause
