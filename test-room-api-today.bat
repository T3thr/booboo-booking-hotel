@echo off
echo Testing Room Search API with dates from migration 016
echo.
echo Testing: 2025-11-06 to 2025-11-08 (2 nights)
echo.
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"
echo.
echo.
pause
