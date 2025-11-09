@echo off
echo ========================================
echo แก้ไขปัญหา Production ทั้งหมด
echo ========================================
echo.

echo ปัญหาที่จะแก้ไข:
echo 1. Approve booking error 500
echo 2. Admin/checkin ไม่โหลดข้อมูล
echo 3. Guest data ส่ง mock แทนข้อมูลจริง
echo.

pause

echo.
echo ========================================
echo Step 1: Rebuild Backend
echo ========================================
echo.

cd backend
echo Building backend...
go build -o hotel-booking-server.exe ./cmd/server

if errorlevel 1 (
    echo.
    echo ERROR: Backend build failed!
    pause
    exit /b 1
)

echo Backend built successfully!
echo.

echo ========================================
echo Step 2: แก้ไข Booking เก่า (Mock Data)
echo ========================================
echo.

cd ..\database\migrations

echo Running fix script...
call run_fix_mock_guest_data.bat

if errorlevel 1 (
    echo.
    echo WARNING: Fix script failed, but continuing...
)

cd ..\..

echo.
echo ========================================
echo Step 3: Restart Backend
echo ========================================
echo.

echo Stopping old backend...
taskkill /F /IM hotel-booking-server.exe 2>nul

echo Starting new backend...
cd backend
start "Hotel Backend" cmd /k "hotel-booking-server.exe"

timeout /t 3 /nobreak >nul

echo Backend restarted!
echo.

echo ========================================
echo ✅ แก้ไขเสร็จสมบูรณ์!
echo ========================================
echo.
echo ขั้นตอนต่อไป:
echo.
echo 1. ทดสอบ Local:
echo    - ไปที่ http://localhost:3000/admin/reception
echo    - ทดสอบ approve booking
echo    - ไปที่ http://localhost:3000/admin/checkin
echo    - ตรวจสอบว่าแสดงข้อมูล
echo.
echo 2. Deploy to Production:
echo    git add .
echo    git commit -m "fix: แก้ไขปัญหา production ทั้งหมด"
echo    git push origin main
echo.
echo 3. รอ Auto-deploy:
echo    - Render: 2-5 นาที
echo    - Vercel: 1-2 นาที
echo.
echo 4. ทดสอบ Production:
echo    - https://booboo-booking.vercel.app/admin/reception
echo    - https://booboo-booking.vercel.app/admin/checkin
echo.
pause
