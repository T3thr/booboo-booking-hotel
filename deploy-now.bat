@echo off
echo ========================================
echo Deploy to Vercel - Final Version
echo ========================================
echo.
echo ✅ Build สำเร็จแล้ว!
echo.
echo กำลัง deploy...
echo.

echo [1/3] Adding all changes...
git add .
echo.

echo [2/3] Committing...
git commit -m "fix: admin login redirect and build issues"
echo.

echo [3/3] Pushing to repository...
git push
echo.

echo ========================================
echo ✅ Deploy Complete!
echo ========================================
echo.
echo Vercel กำลัง build อัตโนมัติ...
echo.
echo ขั้นตอนต่อไป:
echo 1. ไปที่ https://vercel.com/dashboard
echo 2. รอ build สำเร็จ (2-3 นาที)
echo 3. ดู status เป็น "Ready" (สีเขียว)
echo 4. ทดสอบที่ https://booboo-booking.vercel.app/auth/admin
echo.
echo Test Login:
echo - Manager: manager@hotel.com / manager123
echo - Receptionist: receptionist@hotel.com / receptionist123
echo - Housekeeper: housekeeper@hotel.com / housekeeper123
echo.
echo 💡 Tips: ทดสอบใน Incognito mode เพื่อหลีกเลี่ยง cache!
echo.
pause
