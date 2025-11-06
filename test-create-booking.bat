@echo off
echo ========================================
echo Test Create Booking API
echo ========================================
echo.

echo Testing create booking with auth token...
echo.

REM First login to get token
echo Step 1: Login to get token...
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"john.doe@example.com\",\"password\":\"password123\"}" ^
  -c cookies.txt -s > login_response.txt

REM Extract token from response
for /f "tokens=*" %%a in ('type login_response.txt ^| findstr /C:"access_token"') do set TOKEN_LINE=%%a
echo Token line: %TOKEN_LINE%

echo.
echo Step 2: Create booking with token...
curl -X POST http://localhost:8080/api/bookings ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer YOUR_TOKEN_HERE" ^
  -d "{\"details\":[{\"room_type_id\":1,\"rate_plan_id\":1,\"check_in\":\"2025-11-06\",\"check_out\":\"2025-11-07\",\"num_guests\":2,\"guests\":[{\"first_name\":\"John\",\"last_name\":\"Doe\",\"type\":\"Adult\",\"is_primary\":true}]}]}"

echo.
echo.
echo ========================================
echo Test completed!
echo ========================================
echo.
pause
