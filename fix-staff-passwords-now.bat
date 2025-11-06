@echo off
echo ============================================
echo Fixing Staff Passwords NOW
echo ============================================
echo.

cd backend
go run run-fix-staff-pwd.go

echo.
echo ============================================
echo Done! Press any key to exit...
pause
