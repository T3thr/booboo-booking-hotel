@echo off
REM ============================================================================
REM Verify Manager Access - Automated Test
REM ============================================================================
setlocal enabledelayedexpansion

echo.
echo ============================================================================
echo Verifying Manager Access to All Features
echo ============================================================================
echo.

set API_URL=http://localhost:8080/api
set EMAIL=manager@hotel.com
set PASSWORD=staff123

REM ============================================================================
REM Step 1: Login and Extract Token
REM ============================================================================
echo [Step 1] Logging in as Manager...
echo.

REM Create temp file for response
curl -X POST "%API_URL%/auth/login" ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%EMAIL%\",\"password\":\"%PASSWORD%\"}" ^
  -s -o login_response.json

REM Check if login was successful
findstr /C:"\"success\":true" login_response.json >nul
if errorlevel 1 (
    echo [ERROR] Login failed!
    type login_response.json
    del login_response.json
    pause
    exit /b 1
)

echo [SUCCESS] Login successful!
echo.

REM Extract token using PowerShell
for /f "delims=" %%i in ('powershell -Command "(Get-Content login_response.json | ConvertFrom-Json).data.accessToken"') do set TOKEN=%%i

if "%TOKEN%"=="" (
    echo [ERROR] Could not extract token!
    type login_response.json
    del login_response.json
    pause
    exit /b 1
)

echo Token extracted successfully
echo.

REM ============================================================================
REM Step 2: Test Dashboard Access
REM ============================================================================
echo [Step 2] Testing Dashboard Access...
echo.

set TODAY=2025-11-05

echo Testing Revenue Report...
curl -X GET "%API_URL%/reports/revenue?start_date=%TODAY%&end_date=%TODAY%" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s -o revenue_response.json

findstr /C:"\"error\"" revenue_response.json >nul
if not errorlevel 1 (
    echo [ERROR] Revenue report failed!
    type revenue_response.json
    goto :cleanup
)
echo [SUCCESS] Revenue report accessible

echo.
echo Testing Occupancy Report...
curl -X GET "%API_URL%/reports/occupancy?start_date=%TODAY%&end_date=%TODAY%" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s -o occupancy_response.json

findstr /C:"\"error\"" occupancy_response.json >nul
if not errorlevel 1 (
    echo [ERROR] Occupancy report failed!
    type occupancy_response.json
    goto :cleanup
)
echo [SUCCESS] Occupancy report accessible

echo.

REM ============================================================================
REM Step 3: Test Pricing Management
REM ============================================================================
echo [Step 3] Testing Pricing Management...
echo.

echo Testing Rate Tiers...
curl -X GET "%API_URL%/pricing/tiers" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s -o tiers_response.json

findstr /C:"\"error\"" tiers_response.json >nul
if not errorlevel 1 (
    echo [ERROR] Rate tiers failed!
    type tiers_response.json
    goto :cleanup
)
echo [SUCCESS] Rate tiers accessible

echo.
echo Testing Rate Plans...
curl -X GET "%API_URL%/pricing/plans" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s -o plans_response.json

findstr /C:"\"error\"" plans_response.json >nul
if not errorlevel 1 (
    echo [ERROR] Rate plans failed!
    type plans_response.json
    goto :cleanup
)
echo [SUCCESS] Rate plans accessible

echo.
echo Testing Rate Pricing Matrix...
curl -X GET "%API_URL%/pricing/rates" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s -o rates_response.json

findstr /C:"\"error\"" rates_response.json >nul
if not errorlevel 1 (
    echo [ERROR] Rate pricing failed!
    type rates_response.json
    goto :cleanup
)
echo [SUCCESS] Rate pricing matrix accessible

echo.

REM ============================================================================
REM Step 4: Test Inventory Management
REM ============================================================================
echo [Step 4] Testing Inventory Management...
echo.

curl -X GET "%API_URL%/inventory?start_date=2025-01-01&end_date=2025-01-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s -o inventory_response.json

findstr /C:"\"error\"" inventory_response.json >nul
if not errorlevel 1 (
    echo [ERROR] Inventory access failed!
    type inventory_response.json
    goto :cleanup
)
echo [SUCCESS] Inventory accessible

echo.

REM ============================================================================
REM Step 5: Test Reports
REM ============================================================================
echo [Step 5] Testing Reports...
echo.

curl -X GET "%API_URL%/reports/summary?start_date=2025-01-01&end_date=2025-12-31" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -s -o summary_response.json

findstr /C:"\"error\"" summary_response.json >nul
if not errorlevel 1 (
    echo [ERROR] Report summary failed!
    type summary_response.json
    goto :cleanup
)
echo [SUCCESS] Report summary accessible

echo.

REM ============================================================================
REM Step 6: Verify Role in Token
REM ============================================================================
echo [Step 6] Verifying Role...
echo.

powershell -Command "(Get-Content login_response.json | ConvertFrom-Json).data | Select-Object email, role_code, user_type | Format-List"

echo.

REM ============================================================================
REM Summary
REM ============================================================================
echo ============================================================================
echo VERIFICATION COMPLETE - ALL TESTS PASSED!
echo ============================================================================
echo.
echo Manager can access:
echo   [OK] Dashboard (Revenue + Occupancy)
echo   [OK] Pricing Management (Tiers, Plans, Matrix)
echo   [OK] Inventory Management
echo   [OK] Reports
echo.
echo No 403 or 404 errors detected!
echo.

:cleanup
del login_response.json 2>nul
del revenue_response.json 2>nul
del occupancy_response.json 2>nul
del tiers_response.json 2>nul
del plans_response.json 2>nul
del rates_response.json 2>nul
del inventory_response.json 2>nul
del summary_response.json 2>nul

pause
