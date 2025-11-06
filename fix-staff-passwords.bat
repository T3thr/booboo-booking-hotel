@echo off
echo ============================================
echo Fixing Staff Password Hashes
echo ============================================
echo.

cd backend
go run fix-staff-passwords.go
cd ..

echo.
pause
