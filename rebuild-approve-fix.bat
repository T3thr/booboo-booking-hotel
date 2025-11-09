@echo off
echo ========================================
echo REBUILD BACKEND - Fix Approve Error
echo ========================================
echo.
echo Fixed: Changed UPSERT to SELECT then INSERT/UPDATE
echo.
cd backend
echo Building...
go build -o hotel-booking-api.exe ./cmd/server
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo.
echo ========================================
echo Build Success!
echo ========================================
echo.
echo Now run backend:
echo   ./hotel-booking-api.exe
echo.
echo OR
echo.
echo   go run cmd/server/main.go
echo.
pause
