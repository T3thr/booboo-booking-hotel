@echo off
echo ========================================
echo Test Manager Pages - Complete
echo ========================================
echo.

echo Testing Backend API...
echo.

echo 1. Health Check...
curl -s http://localhost:8080/health
echo.
echo.

echo 2. Manager Login...
curl -s -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" > temp_token.json
echo.
echo.

echo 3. Extract Token...
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content temp_token.json | ConvertFrom-Json).data.accessToken"') do set TOKEN=%%a
echo Token: %TOKEN:~0,50%...
echo.

echo 4. Test Pricing Tiers API...
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8080/api/pricing/tiers
echo.
echo.

echo 5. Test Inventory API...
curl -s -H "Authorization: Bearer %TOKEN%" "http://localhost:8080/api/inventory?start_date=2024-12-01&end_date=2024-12-31"
echo.
echo.

echo 6. Test Reports API...
curl -s -H "Authorization: Bearer %TOKEN%" "http://localhost:8080/api/reports/revenue?start_date=2024-12-01&end_date=2024-12-31"
echo.
echo.

del temp_token.json

echo ========================================
echo Test Complete!
echo ========================================
echo.
echo If all tests passed, Manager pages should work!
echo.
echo Next: Open browser and test:
echo 1. http://localhost:3000/auth/admin
echo 2. Login: manager@hotel.com / staff123
echo 3. Test pages:
echo    - /dashboard
echo    - /pricing/tiers
echo    - /inventory
echo    - /reports
echo.
pause
