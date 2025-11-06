@echo off
echo ========================================
echo Fix Manager Pages - Complete Setup
echo ========================================
echo.

echo Step 1: Rebuild Backend...
cd backend
go build -o server.exe ./cmd/server
if errorlevel 1 (
    echo ERROR: Failed to build backend
    pause
    exit /b 1
)
echo Backend built successfully!
echo.

echo Step 2: Test Backend API...
curl -X GET http://localhost:8080/health
echo.

echo Step 3: Test Manager Login...
curl -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"manager@hotel.com\",\"password\":\"staff123\"}"
echo.

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Start backend: cd backend ^&^& server.exe
echo 2. Start frontend: cd frontend ^&^& npm run dev
echo 3. Login as manager: manager@hotel.com / staff123
echo 4. Test all pages:
echo    - /dashboard
echo    - /pricing/tiers
echo    - /inventory
echo    - /reports
echo.
pause
