@echo off
echo ========================================
echo Rebuild and Run Backend Server
echo ========================================
echo.

echo Step 1: Kill old server processes...
taskkill /F /IM server.exe 2>nul
taskkill /F /IM hotel-booking-api.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Step 2: Clean old binaries...
if exist bin\server.exe del /F /Q bin\server.exe
if exist server.exe del /F /Q server.exe

echo.
echo Step 3: Build new server...
go build -o bin\server.exe .\cmd\server
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo Step 4: Run server...
echo Server starting at http://localhost:8080
echo Press Ctrl+C to stop
echo.
bin\server.exe
