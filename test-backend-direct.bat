@echo off
echo ========================================
echo Testing Backend API Directly
echo ========================================
echo.

echo Test 1: Health Check
curl -s http://localhost:8080/health
echo.
echo.

echo Test 2: Room Types
curl -s http://localhost:8080/api/rooms/types
echo.
echo.

echo Test 3: Room Search
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-05&checkOut=2025-11-06&guests=2"
echo.
echo.

pause
