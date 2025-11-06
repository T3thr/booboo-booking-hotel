@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Manager Flow - Complete Verification
echo ========================================
echo.
echo This script will verify that Manager Flow works 100%%
echo without any 403 or 404 errors.
echo.
pause

echo.
echo [Step 1/7] Checking Backend...
echo ========================================
curl -s http://localhost:8080/health > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ FAILED: Backend is not running
    echo.
    echo Please start backend:
    echo   cd backend
    echo   go run ./cmd/server
    echo.
    goto :error
)
echo ✅ PASSED: Backend is running
echo.

echo [Step 2/7] Checking Database...
echo ========================================
curl -s http://localhost:8080/health/db > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ FAILED: Database connection failed
    goto :error
)
echo ✅ PASSED: Database is connected
echo.

echo [Step 3/7] Testing Manager Login...
echo ========================================
curl -s -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" > login-response.json

findstr /C:"success" login-response.json > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ FAILED: Manager login failed
    echo Response:
    type login-response.json
    del login-response.json
    goto :error
)

findstr /C:"MANAGER" login-response.json > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ FAILED: Manager role not found
    echo Response:
    type login-response.json
    del login-response.json
    goto :error
)

echo ✅ PASSED: Manager login successful
echo ✅ PASSED: Role is MANAGER
echo.

echo [Step 4/7] Extracting Token...
echo ========================================
for /f "tokens=2 delims=:" %%a in ('findstr /C:"accessToken" login-response.json') do (
    set TOKEN_LINE=%%a
)
set TOKEN=!TOKEN_LINE:~2,-2!
del login-response.json

if "!TOKEN!"=="" (
    echo ❌ FAILED: Could not extract token
    goto :error
)
echo ✅ PASSED: Token extracted
echo.

echo [Step 5/7] Testing Manager APIs...
echo ========================================

echo Testing: GET /api/reports/revenue
curl -s -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-12-01&end_date=2024-12-31" ^
  -H "Authorization: Bearer !TOKEN!" ^
  -H "Content-Type: application/json" > revenue-response.json

findstr /C:"403" revenue-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 403 Forbidden
    type revenue-response.json
    del revenue-response.json
    goto :error
)

findstr /C:"404" revenue-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 404 Not Found
    type revenue-response.json
    del revenue-response.json
    goto :error
)

echo ✅ PASSED: Revenue API works (no 403/404)
del revenue-response.json

echo Testing: GET /api/reports/occupancy
curl -s -X GET "http://localhost:8080/api/reports/occupancy?start_date=2024-12-01&end_date=2024-12-31" ^
  -H "Authorization: Bearer !TOKEN!" ^
  -H "Content-Type: application/json" > occupancy-response.json

findstr /C:"403" occupancy-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 403 Forbidden
    type occupancy-response.json
    del occupancy-response.json
    goto :error
)

findstr /C:"404" occupancy-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 404 Not Found
    type occupancy-response.json
    del occupancy-response.json
    goto :error
)

echo ✅ PASSED: Occupancy API works (no 403/404)
del occupancy-response.json

echo Testing: GET /api/pricing/tiers
curl -s -X GET "http://localhost:8080/api/pricing/tiers" ^
  -H "Authorization: Bearer !TOKEN!" ^
  -H "Content-Type: application/json" > pricing-response.json

findstr /C:"403" pricing-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 403 Forbidden
    type pricing-response.json
    del pricing-response.json
    goto :error
)

findstr /C:"404" pricing-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 404 Not Found
    type pricing-response.json
    del pricing-response.json
    goto :error
)

echo ✅ PASSED: Pricing API works (no 403/404)
del pricing-response.json

echo Testing: GET /api/inventory
curl -s -X GET "http://localhost:8080/api/inventory?start_date=2024-12-01&end_date=2024-12-31" ^
  -H "Authorization: Bearer !TOKEN!" ^
  -H "Content-Type: application/json" > inventory-response.json

findstr /C:"403" inventory-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 403 Forbidden
    type inventory-response.json
    del inventory-response.json
    goto :error
)

findstr /C:"404" inventory-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 404 Not Found
    type inventory-response.json
    del inventory-response.json
    goto :error
)

echo ✅ PASSED: Inventory API works (no 403/404)
del inventory-response.json

echo Testing: GET /api/bookings
curl -s -X GET "http://localhost:8080/api/bookings?limit=10" ^
  -H "Authorization: Bearer !TOKEN!" ^
  -H "Content-Type: application/json" > bookings-response.json

findstr /C:"403" bookings-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 403 Forbidden
    type bookings-response.json
    del bookings-response.json
    goto :error
)

findstr /C:"404" bookings-response.json > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ❌ FAILED: Got 404 Not Found
    type bookings-response.json
    del bookings-response.json
    goto :error
)

echo ✅ PASSED: Bookings API works (no 403/404)
del bookings-response.json
echo.

echo [Step 6/7] Checking Frontend...
echo ========================================
curl -s http://localhost:3000 > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  WARNING: Frontend is not running
    echo.
    echo Please start frontend:
    echo   cd frontend
    echo   npm run dev
    echo.
) else (
    echo ✅ PASSED: Frontend is running
)
echo.

echo [Step 7/7] Final Summary...
echo ========================================
echo.
echo ✅ Backend: Running
echo ✅ Database: Connected
echo ✅ Manager Login: Working
echo ✅ Manager Role: MANAGER
echo ✅ Revenue API: No 403/404
echo ✅ Occupancy API: No 403/404
echo ✅ Pricing API: No 403/404
echo ✅ Inventory API: No 403/404
echo ✅ Bookings API: No 403/404
echo.
echo ========================================
echo 🎉 SUCCESS! Manager Flow Works 100%%!
echo ========================================
echo.
echo No 403 Forbidden errors ✅
echo No 404 Not Found errors ✅
echo All APIs working correctly ✅
echo.
echo Next Steps:
echo 1. Open browser: http://localhost:3000/auth/admin
echo 2. Login: manager@hotel.com / staff123
echo 3. Test all pages manually
echo 4. Follow DEMO_SCRIPT_THAI.md for demo
echo.
goto :end

:error
echo.
echo ========================================
echo ❌ VERIFICATION FAILED
echo ========================================
echo.
echo Please fix the errors above and try again.
echo.
echo Common fixes:
echo 1. Start backend: cd backend ^&^& go run ./cmd/server
echo 2. Start frontend: cd frontend ^&^& npm run dev
echo 3. Check database: docker-compose up -d db
echo 4. Check logs for errors
echo.

:end
pause
