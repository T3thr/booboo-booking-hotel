@echo off
echo ========================================
echo Manager Login Debug Test
echo ========================================
echo.

echo Step 1: Testing Backend Login API
echo ========================================
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" ^
  -o backend-login-response.json

echo.
echo Backend Response:
type backend-login-response.json
echo.
echo.

echo Step 2: Check Response Fields
echo ========================================
findstr /C:"role_code" backend-login-response.json
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ERROR: role_code not found in response!
    goto :error
)

findstr /C:"MANAGER" backend-login-response.json
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ERROR: MANAGER role not found!
    goto :error
)

findstr /C:"accessToken" backend-login-response.json
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ERROR: accessToken not found!
    goto :error
)

echo ✅ All required fields present
echo.

echo Step 3: Instructions for Frontend Testing
echo ========================================
echo.
echo Now test the frontend:
echo 1. Open browser console (F12)
echo 2. Go to: http://localhost:3000/auth/admin
echo 3. Login with: manager@hotel.com / staff123
echo 4. Watch console logs for:
echo    - [Auth] Backend response
echo    - [JWT Callback] User data
echo    - [Session Callback] Token
echo    - [Middleware] User role
echo.
echo Expected flow:
echo 1. Backend returns role_code: MANAGER
echo 2. NextAuth stores role in JWT token
echo 3. Session has user.role = MANAGER
echo 4. Middleware allows access to /dashboard
echo 5. Redirect to /dashboard (not /unauthorized)
echo.

del backend-login-response.json
goto :end

:error
echo.
echo ========================================
echo ❌ TEST FAILED
echo ========================================
echo.
echo Please check:
echo 1. Backend is running: cd backend ^&^& go run ./cmd/server
echo 2. Database has manager account
echo 3. Backend returns correct role_code
echo.
del backend-login-response.json

:end
pause
