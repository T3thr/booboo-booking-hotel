@echo off
echo ========================================
echo Deploy to Production - Render + Vercel
echo ========================================
echo.

echo ปัญหา:
echo - Localhost ทำงานได้ ✅
echo - Production error 500 ❌
echo.
echo สาเหตุ: Backend บน Render ยังไม่ได้ deploy code ใหม่
echo.

pause

echo.
echo ========================================
echo Step 1: Commit Code
echo ========================================
echo.

git add .
git status

echo.
echo กำลัง commit...
git commit -m "fix: แก้ไขปัญหา production - approve, checkin, guest data"

if errorlevel 1 (
    echo.
    echo หมายเหตุ: ไม่มีการเปลี่ยนแปลง หรือ commit แล้ว
)

echo.
echo ========================================
echo Step 2: Push to GitHub
echo ========================================
echo.

echo กำลัง push...
git push origin main

if errorlevel 1 (
    echo.
    echo ERROR: Push failed!
    echo กรุณาตรวจสอบ:
    echo 1. Internet connection
    echo 2. GitHub credentials
    echo 3. Branch name (main/master)
    pause
    exit /b 1
)

echo.
echo Push สำเร็จ! ✅
echo.

echo ========================================
echo Step 3: รอ Auto-Deploy
echo ========================================
echo.

echo Backend (Render):
echo - URL: https://dashboard.render.com
echo - เวลา: 2-5 นาที
echo - ตรวจสอบ: Logs tab
echo.

echo Frontend (Vercel):
echo - URL: https://vercel.com/dashboard
echo - เวลา: 1-2 นาที
echo - ตรวจสอบ: Deployments tab
echo.

echo รอ 3 นาที...
timeout /t 180 /nobreak

echo.
echo ========================================
echo Step 4: ทดสอบ Production
echo ========================================
echo.

echo กำลังเปิด browser...
start https://booboo-booking.vercel.app/admin/reception
timeout /t 2 /nobreak >nul
start https://booboo-booking.vercel.app/admin/checkin

echo.
echo ทดสอบ:
echo.
echo 1. Admin/Reception:
echo    - Login: manager@hotel.com / Manager123!
echo    - ไปแท็บ "จัดการการจอง"
echo    - คลิก "อนุมัติ" booking
echo    Expected: ✅ อนุมัติสำเร็จ
echo.
echo 2. Admin/Checkin:
echo    - Login: receptionist@hotel.com / Receptionist123!
echo    - เลือกวันที่วันนี้
echo    Expected: ✅ แสดงรายการแขก
echo.
echo 3. Guest Booking:
echo    - Login: john.doe@example.com / password123
echo    - สร้าง booking ใหม่
echo    - ตรวจสอบใน admin/reception
echo    Expected: ✅ แสดงชื่อ John Doe
echo.

echo ========================================
echo ถ้ายังไม่ได้ (Troubleshooting)
echo ========================================
echo.
echo 1. ตรวจสอบ Render Logs:
echo    https://dashboard.render.com
echo    → เลือก service: booboo-booking
echo    → Logs tab
echo    → ดู error messages
echo.
echo 2. ตรวจสอบ Vercel Logs:
echo    https://vercel.com/dashboard
echo    → เลือก project: booboo-booking
echo    → Deployments → Latest
echo    → Function Logs
echo.
echo 3. Manual Redeploy (ถ้าจำเป็น):
echo    Render: คลิก "Manual Deploy" → "Deploy latest commit"
echo    Vercel: คลิก "Redeploy"
echo.

pause
