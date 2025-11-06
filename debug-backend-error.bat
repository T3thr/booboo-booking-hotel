@echo off
echo ============================================================================
echo DEBUG BACKEND ERROR 500
echo ============================================================================
echo.
echo Testing API with verbose output...
echo.
curl -v "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-07&guests=1"
echo.
echo.
echo ============================================================================
echo Check backend terminal for detailed error message!
echo ============================================================================
pause
