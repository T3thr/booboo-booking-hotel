@echo off
echo ========================================
echo แก้ไข Production Issues (Complete Fix)
echo ========================================
echo.

echo ปัญหาที่พบ:
echo 1. Admin/Checkin ไม่แสดงข้อมูล (ECONNREFUSED localhost:8080)
echo 2. Approve Booking Error 500 (Inventory constraint violation)
echo.

echo การแก้ไข:
echo 1. แก้ไข BACKEND_URL ใน API routes (5 ไฟล์)
echo 2. แก้ไข confirm_booking function (ตรวจสอบ capacity)
echo 3. Deploy ไป Vercel + Render
echo.

pause

echo.
echo ========================================
echo Step 1: Run Database Migration
echo ========================================
echo.

echo เชื่อมต่อ Render Database...
echo.

set PGPASSWORD=dpg-ct2rvf08fa8c73a0rvog-a
psql -h dpg-ct2rvf08fa8c73a0rvog-a.oregon-postgres.render.com -U booboo_booking_user -d booboo_booking -f database/migrations/006_fix_confirm_booking_inventory_check.sql

if errorlevel 1 (
    echo.
    echo ❌ Migration ล้มเหลว!
    echo กรุณาตรวจสอบ connection string
    pause
    exit /b 1
)

echo.
echo ✅ Migration สำเร็จ!
echo.

pause

echo.
echo ========================================
echo Step 2: Commit Changes
echo ========================================
echo.

git add .
git commit -m "fix: production issues - BACKEND_URL and inventory constraint

- Fix BACKEND_URL in 5 API routes (checkin/checkout)
- Fix confirm_booking function to check inventory capacity
- Prevent constraint violation when approving bookings"

if errorlevel 1 (
    echo.
    echo หมายเหตุ: อาจ commit แล้ว หรือไม่มีการเปลี่ยนแปลง
)

echo.
echo ========================================
echo Step 3: Deploy to Vercel
echo ========================================
echo.

echo กำลัง push ไป GitHub...
git push origin main

if errorlevel 1 (
    echo.
    echo ❌ Push ล้มเหลว!
    pause
    exit /b 1
)

echo.
echo ✅ Push สำเร็จ! Vercel กำลัง deploy...
echo รอ 1-2 นาที...
timeout /t 120 /nobreak

echo.
echo ========================================
echo Step 4: Verify Vercel Environment
echo ========================================
echo.

echo เปิด test endpoint...
start https://booboo-booking.vercel.app/api/test-env

echo.
echo ตรวจสอบว่า BACKEND_URL ถูกต้อง:
echo ✅ ต้องเห็น: "BACKEND_URL": "https://booboo-booking.onrender.com"
echo ❌ ถ้าเห็น: "NOT SET" = ต้องตั้งค่าใน Vercel Dashboard
echo.

pause

echo.
echo ========================================
echo Step 5: Test Admin/Checkin
echo ========================================
echo.

echo เปิด Admin/Checkin...
start https://booboo-booking.vercel.app/admin/checkin

echo.
echo ทดสอบ:
echo 1. Login: receptionist@hotel.com / password123
echo 2. ต้องเห็นรายการแขกที่จะ check-in
echo 3. เปิด F12 → Network tab
echo 4. ต้องเห็น request ไปที่ Render (ไม่ใช่ localhost)
echo.

pause

echo.
echo ========================================
echo Step 6: Test Approve Booking
echo ========================================
echo.

echo เปิด Admin/Reception...
start https://booboo-booking.vercel.app/admin/reception

echo.
echo ทดสอบ:
echo 1. Login: manager@hotel.com / password123
echo 2. แท็บ "จัดการการจอง"
echo 3. คลิก "อนุมัติ" booking
echo 4. ต้องสำเร็จ (ไม่มี Error 500)
echo 5. เปิด F12 → Network tab
echo 6. ต้องเห็น POST request ไปที่ Render
echo.

pause

echo.
echo ========================================
echo Step 7: Check Render Logs
echo ========================================
echo.

echo เปิด Render Dashboard...
start https://dashboard.render.com

echo.
echo ตรวจสอบ:
echo 1. เลือก service: booboo-booking
echo 2. Logs tab
echo 3. ต้องเห็น requests:
echo    - [GET] /api/checkin/arrivals
echo    - [POST] /api/payment-proofs/32/approve
echo 4. ต้องเห็น status 200 (ไม่ใช่ 401 หรือ 404)
echo.

pause

echo.
echo ========================================
echo ผลลัพธ์ที่คาดหวัง
echo ========================================
echo.

echo ✅ Admin/Checkin แสดงข้อมูลแขก
echo ✅ Approve Booking ทำงานได้
echo ✅ Render logs มี requests
echo ✅ ไม่มี ECONNREFUSED error
echo ✅ ไม่มี constraint violation error
echo.

echo ถ้ายังมีปัญหา:
echo 1. ตรวจสอบ Vercel Environment Variables
echo 2. ตรวจสอบ Render Database connection
echo 3. ตรวจสอบ Network Tab (F12)
echo 4. อ่าน PRODUCTION_FIX_COMPLETE.md
echo.

pause
