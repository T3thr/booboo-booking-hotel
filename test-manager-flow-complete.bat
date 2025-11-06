@echo off
echo ========================================
echo Testing Manager Flow - Complete Check
echo ========================================
echo.

echo Step 1: Testing Manager Login
echo ========================================
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" ^
  -o manager-login-response.json
echo.
echo Login response saved to manager-login-response.json
type manager-login-response.json
echo.
echo.

echo Step 2: Extract Token (Manual - copy from above)
echo ========================================
echo Please copy the accessToken from the response above
echo.
set /p TOKEN="Paste the token here: "
echo.

echo Step 3: Test Dashboard API - Revenue Report
echo ========================================
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-12-01&end_date=2024-12-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json"
echo.
echo.

echo Step 4: Test Dashboard API - Occupancy Report
echo ========================================
curl -X GET "http://localhost:8080/api/reports/occupancy?start_date=2024-12-01&end_date=2024-12-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json"
echo.
echo.

echo Step 5: Test Pricing API - Get Rate Tiers
echo ========================================
curl -X GET "http://localhost:8080/api/pricing/tiers" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json"
echo.
echo.

echo Step 6: Test Inventory API
echo ========================================
curl -X GET "http://localhost:8080/api/inventory?start_date=2024-12-01&end_date=2024-12-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json"
echo.
echo.

echo Step 7: Test Bookings API (Manager can see all)
echo ========================================
curl -X GET "http://localhost:8080/api/bookings?limit=10" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json"
echo.
echo.

echo ========================================
echo Manager Flow Test Complete!
echo ========================================
echo.
echo Check the responses above for:
echo - No 403 Forbidden errors
echo - No 404 Not Found errors
echo - Data is returned successfully
echo.
pause
