@echo off
echo ========================================
echo Manager System Diagnostic Check
echo ========================================
echo.

echo [1/5] Checking Backend Status...
echo ========================================
curl -s http://localhost:8080/health
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Backend is not running!
    echo Please start backend: cd backend ^&^& go run ./cmd/server
    goto :end
)
echo Backend: OK
echo.

echo [2/5] Checking Database Connection...
echo ========================================
curl -s http://localhost:8080/health/db
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Database connection failed!
    goto :end
)
echo Database: OK
echo.

echo [3/5] Checking Manager Account...
echo ========================================
echo Testing login for manager@hotel.com...
curl -s -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" > temp-login.json

findstr /C:"success" temp-login.json >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Manager login failed!
    echo Response:
    type temp-login.json
    del temp-login.json
    goto :end
)

findstr /C:"MANAGER" temp-login.json >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Manager role not found in response!
    echo Response:
    type temp-login.json
    del temp-login.json
    goto :end
)

echo Manager Account: OK
echo Role: MANAGER
del temp-login.json
echo.

echo [4/5] Checking Frontend Status...
echo ========================================
curl -s http://localhost:3000 >nul
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Frontend is not running!
    echo Please start frontend: cd frontend ^&^& npm run dev
) else (
    echo Frontend: OK
)
echo.

echo [5/5] Checking API Endpoints...
echo ========================================
echo Testing public endpoints...

curl -s http://localhost:8080/api/rooms/types >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Rooms API not working!
) else (
    echo - Rooms API: OK
)

echo.
echo ========================================
echo System Check Complete!
echo ========================================
echo.
echo Summary:
echo - Backend: Running
echo - Database: Connected
echo - Manager Account: Valid (role: MANAGER)
echo - Frontend: Check above
echo - API Endpoints: Check above
echo.
echo Next Steps:
echo 1. If backend not running: cd backend ^&^& go run ./cmd/server
echo 2. If frontend not running: cd frontend ^&^& npm run dev
echo 3. Test manager flow: test-manager-flow-complete.bat
echo 4. Open browser: http://localhost:3000/auth/admin
echo.

:end
pause
