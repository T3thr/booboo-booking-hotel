@echo off
echo ========================================
echo Test Manager Access - All Pages
echo ========================================
echo.

echo Step 1: Login as Manager...
curl -s -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" > temp_token.json

echo.
echo Extracting token...
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content temp_token.json | ConvertFrom-Json).data.accessToken"') do set TOKEN=%%a
echo Token obtained: %TOKEN:~0,50%...
echo.

echo ========================================
echo Testing Manager Access to All Endpoints
echo ========================================
echo.

echo 1. Manager Routes (Should Work)
echo --------------------------------
echo.

echo Testing /api/pricing/tiers...
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8080/api/pricing/tiers | findstr "success"
echo.

echo Testing /api/inventory...
curl -s -H "Authorization: Bearer %TOKEN%" "http://localhost:8080/api/inventory?start_date=2024-12-01&end_date=2024-12-31" | findstr "success"
echo.

echo Testing /api/reports/revenue...
curl -s -H "Authorization: Bearer %TOKEN%" "http://localhost:8080/api/reports/revenue?start_date=2024-12-01&end_date=2024-12-31" | findstr "success"
echo.

echo 2. Receptionist Routes (Manager Should Access)
echo -----------------------------------------------
echo.

echo Testing /api/rooms/status...
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8080/api/rooms/status | findstr "success"
echo.

echo Testing /api/checkin/arrivals...
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8080/api/checkin/arrivals | findstr "success"
echo.

echo 3. Housekeeper Routes (Manager Should Access)
echo ----------------------------------------------
echo.

echo Testing /api/housekeeping/tasks...
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8080/api/housekeeping/tasks | findstr "success"
echo.

echo 4. Guest Routes (Manager Should Access)
echo ----------------------------------------
echo.

echo Testing /api/bookings...
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8080/api/bookings | findstr "success"
echo.

del temp_token.json

echo.
echo ========================================
echo Test Complete!
echo ========================================
echo.
echo If all tests show "success", Manager can access everything!
echo.
echo Next: Test Frontend
echo 1. Open: http://localhost:3000/auth/admin
echo 2. Login: manager@hotel.com / staff123
echo 3. Try accessing:
echo    - /dashboard (Manager)
echo    - /pricing/tiers (Manager)
echo    - /inventory (Manager)
echo    - /reports (Manager)
echo    - /reception (Receptionist - Manager should access)
echo    - /housekeeping (Housekeeper - Manager should access)
echo    - /bookings (Guest - Manager should access)
echo.
echo All should work without 403 errors!
echo.
pause
