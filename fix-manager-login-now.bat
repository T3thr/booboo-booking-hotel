@echo off
echo ========================================
echo Fix Manager Login - Quick Fix
echo ========================================
echo.

echo This script will help you fix the manager login issue.
echo.
echo Changes made:
echo 1. Added logging to auth/admin/page.tsx
echo 2. Added logging to middleware.ts
echo 3. Added logging to lib/auth.ts
echo 4. Fixed redirect logic
echo.
pause

echo.
echo Step 1: Checking if frontend is running...
echo ========================================
curl -s http://localhost:3000 > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Frontend is not running!
    echo.
    echo Please start frontend:
    echo   cd frontend
    echo   npm run dev
    echo.
    goto :error
)
echo ✅ Frontend is running
echo.

echo Step 2: Checking if backend is running...
echo ========================================
curl -s http://localhost:8080/health > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Backend is not running!
    echo.
    echo Please start backend:
    echo   cd backend
    echo   go run ./cmd/server
    echo.
    goto :error
)
echo ✅ Backend is running
echo.

echo Step 3: Testing backend login...
echo ========================================
curl -s -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}" > test-login.json

findstr /C:"MANAGER" test-login.json > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Backend login failed or role not found!
    echo Response:
    type test-login.json
    del test-login.json
    goto :error
)
echo ✅ Backend login successful with MANAGER role
del test-login.json
echo.

echo ========================================
echo ✅ System is ready!
echo ========================================
echo.
echo Next steps:
echo.
echo 1. Open browser in INCOGNITO mode (important!)
echo    - Chrome: Ctrl+Shift+N
echo    - Firefox: Ctrl+Shift+P
echo    - Edge: Ctrl+Shift+N
echo.
echo 2. Open Developer Console (F12)
echo.
echo 3. Go to: http://localhost:3000/auth/admin
echo.
echo 4. Login with:
echo    Email: manager@hotel.com
echo    Password: staff123
echo.
echo 5. Watch the console logs:
echo    You should see:
echo    - [Admin Login] Attempting login for: manager@hotel.com
echo    - [Auth] Backend response: {...}
echo    - [JWT Callback] User data: {...}
echo    - [Session Callback] Token: {...}
echo    - [Middleware] User role: MANAGER
echo    - [Admin Login] Redirecting to: /dashboard
echo.
echo 6. Expected result:
echo    - Redirect to /dashboard
echo    - Dashboard shows data
echo    - No 403/404 errors
echo.
echo ========================================
echo.
echo If you still see errors:
echo 1. Copy ALL console logs
echo 2. Copy frontend terminal logs
echo 3. Copy backend terminal logs
echo 4. Send them for analysis
echo.
echo Read: FIX_MANAGER_LOGIN_COMPLETE.md for details
echo.
goto :end

:error
echo.
echo ========================================
echo ❌ SETUP FAILED
echo ========================================
echo.
echo Please fix the errors above and try again.
echo.

:end
pause
