@echo off
REM ========================================
REM Deploy Guest Booking Fix
REM ========================================

echo ========================================
echo Guest Booking System Fix Deployment
echo ========================================
echo.
echo This script will:
echo 1. Run database migration 021
echo 2. Rebuild backend
echo 3. Restart services
echo.
pause

REM Step 1: Run Database Migration
echo.
echo ========================================
echo Step 1: Running Database Migration 021
echo ========================================
cd database\migrations
call run_migration_021.bat
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Database migration failed!
    pause
    exit /b 1
)
cd ..\..

REM Step 2: Rebuild Backend
echo.
echo ========================================
echo Step 2: Rebuilding Backend
echo ========================================
cd backend
echo Building Go backend...
go build -o hotel-booking-api.exe ./cmd/server
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Backend build failed!
    cd ..
    pause
    exit /b 1
)
echo Backend built successfully!
cd ..

REM Step 3: Instructions for restart
echo.
echo ========================================
echo Step 3: Restart Services
echo ========================================
echo.
echo Please restart your services manually:
echo.
echo Backend:
echo   cd backend
echo   hotel-booking-api.exe
echo.
echo Frontend (if using dev mode):
echo   cd frontend
echo   npm run dev
echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Restart backend service
echo 2. Restart frontend service (if needed)
echo 3. Test the booking flow
echo.
echo See GUEST_BOOKING_FIX_SUMMARY.md for testing instructions
echo.
pause
