@echo off
echo ========================================
echo Start Backend Server (Latest Version)
echo ========================================
echo.

REM Kill old processes
taskkill /F /IM server.exe 2>nul
taskkill /F /IM hotel-booking-api.exe 2>nul
timeout /t 2 /nobreak >nul

REM Go to backend directory and build
cd backend

echo Building latest version...
go build -o bin\server.exe cmd\server\main.go
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    cd ..
    pause
    exit /b 1
)

echo.
echo Starting server...
echo Server: http://localhost:8080
echo API Docs: http://localhost:8080/docs
echo.
echo Press Ctrl+C to stop
echo.

REM Run the server
bin\server.exe
