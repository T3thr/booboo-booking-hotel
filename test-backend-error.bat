@echo off
echo Testing Backend Room Search API...
echo.

echo Test 1: Basic search
curl -v "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
echo.
echo.

echo Test 2: Get room types (should work)
curl "http://localhost:8080/api/rooms/types"
echo.
echo.

pause
