@echo off
REM ============================================================================
REM Restart Backend Server
REM ============================================================================

echo ============================================================================
echo Restarting Backend Server...
echo ============================================================================
echo.

REM Kill existing Go processes
echo Stopping existing backend processes...
taskkill /F /IM go.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Starting backend server...
echo.

cd backend
start "Hotel Booking Backend" cmd /k "go run cmd/server/main.go"

echo.
echo ============================================================================
echo Backend server is starting...
echo ============================================================================
echo.
echo Wait for the message: "Server is running on :8080"
echo Then test at: http://localhost:8080/api/rooms/types
echo.
echo Press any key to close this window...
pause >nul
