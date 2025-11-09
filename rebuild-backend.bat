@echo off
echo ========================================
echo Rebuild Backend Server
echo ========================================
echo.

echo Killing old server processes...
taskkill /F /IM server.exe 2>nul
taskkill /F /IM hotel-booking-system.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Building server...
cd backend
go build -o hotel-booking-system.exe .\cmd\server
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    cd ..
    pause
    exit /b 1
)

echo.
echo Build successful!
echo Starting server...
echo Server at http://localhost:8080
echo Press Ctrl+C to stop
echo.
hotel-booking-system.exe
