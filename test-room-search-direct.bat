@echo off
echo ============================================================================
echo Test Room Search API Directly
echo ============================================================================
echo.

REM Calculate dates
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do (
    set TODAY=%%c-%%a-%%b
)

REM Test parameters
set CHECK_IN=%TODAY%
set CHECK_OUT=%TODAY%
set GUESTS=2

echo Testing room search with:
echo - Check-in: %CHECK_IN%
echo - Check-out: (tomorrow)
echo - Guests: %GUESTS%
echo.

REM Test backend API directly
echo Testing Backend API (http://localhost:8080/api/rooms/search)...
echo.
curl -X GET "http://localhost:8080/api/rooms/search?checkIn=%CHECK_IN%&checkOut=%CHECK_OUT%&guests=%GUESTS%" -H "Content-Type: application/json"

echo.
echo.
echo ============================================================================
echo.

REM Test frontend API proxy
echo Testing Frontend API Proxy (http://localhost:3000/api/rooms/search)...
echo.
curl -X GET "http://localhost:3000/api/rooms/search?checkIn=%CHECK_IN%&checkOut=%CHECK_OUT%&guests=%GUESTS%" -H "Content-Type: application/json"

echo.
echo.
echo ============================================================================
echo Test completed!
echo ============================================================================
echo.
echo If you see "available_rooms" with values greater than 0, the system works!
echo If all rooms show 0 available, run: fix-room-availability.bat
echo.
pause
