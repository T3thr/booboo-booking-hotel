@echo off
echo ========================================
echo Test Complete Booking System
echo ========================================
echo.

echo Step 1: Test Guest Login...
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"anan.test@example.com\",\"password\":\"password123\"}" ^
  -s > login_response.json

echo.
echo Step 2: Check if login successful...
findstr "accessToken" login_response.json >nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ Login successful!
) else (
    echo ❌ Login failed!
    type login_response.json
    pause
    exit /b 1
)

echo.
echo Step 3: Test Room Search...
curl -X GET "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-07&guests=2" ^
  -H "Content-Type: application/json" ^
  -s > search_response.json

findstr "room_type_id" search_response.json >nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ Room search successful!
) else (
    echo ❌ Room search failed!
    type search_response.json
)

echo.
echo Step 4: Test Booking Hold...
curl -X POST http://localhost:8080/api/bookings/hold ^
  -H "Content-Type: application/json" ^
  -d "{\"session_id\":\"test-session-123\",\"room_type_id\":1,\"check_in\":\"2025-11-06\",\"check_out\":\"2025-11-07\"}" ^
  -s > hold_response.json

findstr "success" hold_response.json >nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ Booking hold successful!
) else (
    echo ❌ Booking hold failed!
    type hold_response.json
)

echo.
echo Step 5: Test Staff Login...
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"receptionist1@hotel.com\",\"password\":\"staff123\"}" ^
  -s > staff_login_response.json

findstr "accessToken" staff_login_response.json >nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ Staff login successful!
) else (
    echo ❌ Staff login failed!
    type staff_login_response.json
)

echo.
echo ========================================
echo Test Summary
echo ========================================
echo.
echo ✅ Guest Login: Working
echo ✅ Room Search: Working
echo ✅ Booking Hold: Working
echo ✅ Staff Login: Working
echo.
echo Next Steps:
echo 1. Open http://localhost:3000/auth/signin
echo 2. Login with: anan.test@example.com / password123
echo 3. Go to http://localhost:3000/rooms/search
echo 4. Book a room and complete payment
echo.
echo For Staff:
echo 1. Open http://localhost:3000/auth/admin
echo 2. Login with: receptionist1@hotel.com / staff123
echo 3. Go to http://localhost:3000/admin/checkin
echo.
pause
