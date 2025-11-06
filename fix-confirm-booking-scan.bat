@echo off
echo ========================================
echo แก้ไข Confirm Booking - Scan Error
echo ========================================
echo.

echo ปัญหา: Database function return 3 columns แต่ scan แค่ 2
echo การแก้ไข: เพิ่ม scan column ที่ 3 (booking_id)
echo.

echo [1/2] Stopping backend...
taskkill /F /IM main.exe 2>nul
taskkill /F /IM go.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/2] Rebuilding and starting backend...
cd backend
go build -o main.exe ./cmd/server
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

start cmd /k "main.exe"

echo.
echo ========================================
echo เสร็จสิ้น!
echo ========================================
echo.
echo Backend กำลังเริ่มต้น...
echo รอสักครู่แล้วลองจองอีกครั้ง
echo.
pause
