@echo off
echo ========================================
echo Rebuilding Backend with Guest Role Fix
echo ========================================
echo.

cd backend
echo Building backend...
go build -o server.exe ./cmd/server

if errorlevel 1 (
    echo.
    echo ERROR: Failed to build backend
    echo Please check the error messages above
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build SUCCESS!
echo ========================================
echo.
echo Backend executable: backend\server.exe
echo.
echo Next Steps:
echo 1. Stop your current backend server (Ctrl+C)
echo 2. Run: cd backend
echo 3. Run: server.exe
echo.
echo Or use: start-backend-local.bat
echo.
echo Then test with:
echo   Email: anan.test@example.com
echo   Password: password123
echo.
pause
