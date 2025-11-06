@echo off
echo Testing Room Search API
echo.

echo Testing: GET http://localhost:8080/api/rooms/search?checkIn=2025-11-04^&checkOut=2025-11-05^&guests=2
echo.

curl -v "http://localhost:8080/api/rooms/search?checkIn=2025-11-04&checkOut=2025-11-05&guests=2"

echo.
echo.
pause
