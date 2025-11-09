@echo off
echo ========================================
echo Rebuilding Backend with Payment Fix
echo ========================================

cd backend
echo Building Go backend...
go build -o bin\server.exe .\cmd\server\main.go

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.
echo To start the backend:
echo   cd backend
echo   .\bin\server.exe
echo.
pause
