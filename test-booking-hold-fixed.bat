@echo off
echo ========================================
echo Test Booking Hold (Fixed)
echo ========================================
echo.

echo Testing booking hold API...
echo.

curl -X POST http://localhost:8080/api/bookings/hold ^
  -H "Content-Type: application/json" ^
  -d "{\"session_id\":\"test-session-123\",\"room_type_id\":1,\"check_in\":\"2025-11-06\",\"check_out\":\"2025-11-07\"}"

echo.
echo.
echo ========================================
echo Test completed!
echo ========================================
echo.
echo If you see success=true and expiry time, the fix works!
echo.
pause
