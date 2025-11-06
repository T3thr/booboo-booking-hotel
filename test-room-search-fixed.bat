@echo off
REM ============================================================================
REM Test Room Search API (After Fix)
REM ============================================================================

echo ============================================================================
echo Testing Room Search API...
echo ============================================================================
echo.

echo Test 1: Search for rooms (Nov 10-13, 2025, 2 guests)
echo.
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
echo.
echo.

echo ============================================================================
echo.
echo Check the response above:
echo - Should see "available_rooms" field for each room type
echo - Should see room types with prices
echo - Should NOT see empty room_types array
echo.
echo If you see available_rooms: Backend is FIXED! ✅
echo If you don't see available_rooms: Backend needs restart! ❌
echo.
echo ============================================================================
pause
