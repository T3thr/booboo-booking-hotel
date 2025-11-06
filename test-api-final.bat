@echo off
echo ========================================
echo Testing API After Fix
echo ========================================
echo.
echo Waiting for backend to restart...
timeout /t 5 /nobreak >nul
echo.
echo Testing API...
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=1" > api-test-result.json
echo.
echo Response:
type api-test-result.json
echo.
echo.
echo ========================================
echo Check if "available_rooms" appears above
echo ========================================
pause
