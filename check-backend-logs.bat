@echo off
echo ============================================================================
echo Checking Backend Status and Testing API
echo ============================================================================
echo.

echo Test 1: Check if backend is running
curl -s http://localhost:8080/api/rooms/types
echo.
echo.

echo Test 2: Test room search with verbose output
curl -v "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
echo.
echo.

echo ============================================================================
echo Check the backend terminal for detailed error messages
echo ============================================================================
pause
