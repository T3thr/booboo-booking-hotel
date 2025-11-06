@echo off
echo ========================================
echo 📁 เตรียม Code สำหรับ Deploy
echo ========================================
echo.

echo [1/3] ตรวจสอบ Git...
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Git ไม่ได้ติดตั้ง! Download: https://git-scm.com/
    pause
    exit /b 1
)
echo ✅ Git พร้อมใช้งาน

echo.
echo [2/3] เตรียม Repository...
if not exist .git (
    echo สร้าง Git repository...
    git init
    git add .
    git commit -m "Initial commit for deployment"
) else (
    echo อัพเดท repository...
    git add .
    git commit -m "Prepare for deployment"
)

echo.
echo [3/3] ขั้นตอนต่อไป...
echo.
echo ========================================
echo 📋 ทำตามขั้นตอนนี้:
echo ========================================
echo.
echo 1. สร้าง GitHub Repository:
echo    - ไปที่ https://github.com/new
echo    - ตั้งชื่อ: hotel-booking-system
echo    - เลือก Public
echo    - คลิก "Create repository"
echo.
echo 2. Push code ไป GitHub:
echo    git remote add origin https://github.com/YOUR_USERNAME/hotel-booking-system.git
echo    git branch -M main
echo    git push -u origin main
echo.
echo 3. หลังจากนั้นรัน:
echo    deploy-render-free.bat
echo.
pause