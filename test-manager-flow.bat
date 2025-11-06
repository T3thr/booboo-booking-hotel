@echo off
REM ============================================================================
REM Test Manager Flow - Complete Verification
REM ============================================================================
echo.
echo ============================================================================
echo Testing Manager Flow - Dashboard, Pricing, Inventory, Reports
echo ============================================================================
echo.

REM Set API URL
set API_URL=http://localhost:8080/api

REM ============================================================================
REM Step 1: Login as Manager
REM ============================================================================
echo [1/6] Testing Manager Login...
echo.

curl -X POST "%API_URL%/auth/login" ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" ^
  -c cookies.txt ^
  -s | jq .

echo.
echo Press any key to continue to dashboard stats...
pause > nul

REM Extract token from response (manual step - copy token from above)
echo.
echo Please copy the accessToken from above and paste it here:
set /p TOKEN=Token: 

REM ============================================================================
REM Step 2: Test Dashboard Stats (Revenue)
REM ============================================================================
echo.
echo [2/6] Testing Dashboard - Revenue Report...
echo.

curl -X GET "%API_URL%/reports/revenue?start_date=2025-01-01&end_date=2025-12-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s | jq .

echo.
echo Press any key to continue to occupancy...
pause > nul

REM ============================================================================
REM Step 3: Test Dashboard Stats (Occupancy)
REM ============================================================================
echo.
echo [3/6] Testing Dashboard - Occupancy Report...
echo.

curl -X GET "%API_URL%/reports/occupancy?start_date=2025-01-01&end_date=2025-12-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s | jq .

echo.
echo Press any key to continue to pricing...
pause > nul

REM ============================================================================
REM Step 4: Test Pricing Management
REM ============================================================================
echo.
echo [4/6] Testing Pricing Management...
echo.

echo Getting Rate Tiers:
curl -X GET "%API_URL%/pricing/tiers" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s | jq .

echo.
echo Getting Rate Plans:
curl -X GET "%API_URL%/pricing/plans" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s | jq .

echo.
echo Getting Rate Pricing Matrix:
curl -X GET "%API_URL%/pricing/rates" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s | jq .

echo.
echo Press any key to continue to inventory...
pause > nul

REM ============================================================================
REM Step 5: Test Inventory Management
REM ============================================================================
echo.
echo [5/6] Testing Inventory Management...
echo.

curl -X GET "%API_URL%/inventory?start_date=2025-01-01&end_date=2025-01-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s | jq .

echo.
echo Press any key to continue to reports...
pause > nul

REM ============================================================================
REM Step 6: Test Reports Access
REM ============================================================================
echo.
echo [6/6] Testing Reports Access...
echo.

echo Getting Report Summary:
curl -X GET "%API_URL%/reports/summary?start_date=2025-01-01&end_date=2025-12-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s | jq .

echo.
echo.
echo ============================================================================
echo Manager Flow Test Complete!
echo ============================================================================
echo.
echo If all tests returned data without 403/404 errors, the flow is working!
echo.
pause
