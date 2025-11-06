@echo off
echo ============================================
echo Setting up Staff Authentication System
echo ============================================
echo.

echo Step 1: Running Migration 014...
cd backend\scripts
go run run-migration-014.go
cd ..\..

echo.
echo Step 2: Verifying setup...
cd backend
go run check-view.go
cd ..

echo.
echo ============================================
echo Setup Complete!
echo ============================================
echo.
echo You can now login with:
echo   Manager: manager@hotel.com / staff123
echo   Receptionist: receptionist1@hotel.com / staff123
echo   Housekeeper: housekeeper1@hotel.com / staff123
echo.
pause
