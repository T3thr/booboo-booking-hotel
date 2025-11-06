@echo off
echo Debugging API Response...
echo.
curl -s "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=1" > api-response.json
echo Response saved to api-response.json
echo.
type api-response.json
echo.
pause
