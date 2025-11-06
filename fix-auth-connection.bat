@echo off
echo ========================================
echo Fixing Auth Connection Issue
echo ========================================
echo.

echo Step 1: Stopping frontend...
taskkill /F /IM node.exe 2>nul
timeout /t 2 >nul

echo Step 2: Clearing Next.js cache...
cd frontend
if exist .next rmdir /s /q .next
echo Cache cleared!
echo.

echo Step 3: Checking backend...
curl -s http://localhost:8080/api/rooms/types >nul 2>&1
if %errorlevel% equ 0 (
    echo Backend is running ✓
) else (
    echo Backend is NOT running ✗
    echo Please start backend first:
    echo   cd backend
    echo   go run cmd/server/main.go
    pause
    exit /b 1
)
echo.

echo Step 4: Starting frontend...
start cmd /k "npm run dev"
echo.

echo ========================================
echo Done! Frontend is starting...
echo ========================================
echo.
echo Please wait for frontend to start, then:
echo 1. Open http://localhost:3000
echo 2. Try to login
echo 3. Check console for errors
echo.
pause
