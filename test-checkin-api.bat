@echo off
echo Testing Check-in API...
echo.

REM Get today's date in YYYY-MM-DD format
for /f "tokens=1-3 delims=/" %%a in ('date /t') do (
    set TODAY=%%c-%%a-%%b
)

echo Testing: GET http://localhost:8080/api/checkin/arrivals?date=%TODAY%
echo.

curl -X GET "http://localhost:8080/api/checkin/arrivals?date=2025-11-09" ^
  -H "Authorization: Bearer YOUR_TOKEN_HERE" ^
  -H "Content-Type: application/json"

echo.
echo.
echo Done!
pause
