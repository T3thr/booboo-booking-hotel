@echo off
echo ========================================
echo Restarting Backend for Guest Booking Fix
echo ========================================
echo.
echo Migration 020 has been applied to allow NULL guest_id
echo Now restarting backend to use the updated schema...
echo.

cd backend

echo Stopping any running backend processes...
taskkill /F /IM main.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Starting backend...
go run cmd/server/main.go

pause
