@echo off
echo ========================================
echo Fix Hold Ambiguous Error
echo ========================================
echo.

echo Step 1: Run migration via Go script...
cd backend\scripts
go run fix-hold-function.go
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to run migration
    cd ..\..
    pause
    exit /b 1
)
cd ..\..

echo.
echo Step 2: Rebuild backend...
cd backend
go build -o bin/server.exe cmd/server/main.go
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to build backend
    cd ..
    pause
    exit /b 1
)
cd ..

echo.
echo Step 3: Restart backend...
taskkill /F /IM server.exe 2>nul
timeout /t 2 /nobreak >nul
start "Hotel Backend" cmd /k "cd backend && bin\server.exe"

echo.
echo ========================================
echo Fix completed successfully!
echo ========================================
echo.
echo Backend is restarting...
echo Wait 5 seconds then test booking hold
echo.
pause
