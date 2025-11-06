@echo off
echo ========================================
echo Fix Guest Booking - Complete Solution
echo ========================================
echo.

echo This script will:
echo 1. Run database migration (allow NULL guest_id)
echo 2. Rebuild backend with updated code
echo 3. Restart backend
echo.

pause

echo.
echo Step 1: Run Migration 020
echo ----------------------------------------
cd database\migrations
call run_migration_020.bat
cd ..\..

echo.
echo Step 2: Stop Backend
echo ----------------------------------------
taskkill /F /IM main.exe 2>nul
timeout /t 2 >nul

echo.
echo Step 3: Rebuild Backend
echo ----------------------------------------
cd backend
if exist main.exe del main.exe
go build -o main.exe ./cmd/server
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Step 4: Start Backend
echo ----------------------------------------
start "Hotel Backend" cmd /k "main.exe"
cd ..

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Guest bookings (without signin) are now fully supported!
echo.
echo Test with:
echo   1. Go to http://localhost:3000
echo   2. Do NOT sign in
echo   3. Search for rooms
echo   4. Book a room
echo   5. Fill guest info
echo   6. Complete booking
echo.
echo Expected: No errors!
echo.
pause
