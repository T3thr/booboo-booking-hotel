@echo off
echo ========================================
echo 🆓 Deploy ฟรี 100%% - Render + Neon
echo ========================================
echo.

echo [1/5] เตรียม Repository...
echo.
echo ✅ ขั้นตอนที่ 1: Push code ไป GitHub
echo    1. สร้าง repository ใหม่บน GitHub
echo    2. Push code ทั้งหมดไป
echo.
echo    git init
echo    git add .
echo    git commit -m "Initial commit"
echo    git remote add origin https://github.com/username/repo-name.git
echo    git push -u origin main
echo.

echo [2/5] สร้าง Database ฟรีบน Neon...
echo.
echo ✅ ขั้นตอนที่ 2: สร้าง Neon Database
echo    1. ไปที่: https://console.neon.tech
echo    2. สร้างบัญชีฟรี
echo    3. สร้าง Project ใหม่
echo    4. คัดลอก "Pooled Connection String"
echo.
echo    ตัวอย่าง:
echo    postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
echo.

echo [3/5] Deploy Backend บน Render...
echo.
echo ✅ ขั้นตอนที่ 3: Deploy Go Backend
echo    1. ไปที่: https://render.com
echo    2. สร้างบัญชีฟรี
echo    3. คลิก "New +" → "Web Service"
echo    4. เชื่อมต่อ GitHub repository
echo    5. ตั้งค่า:
echo       - Name: hotel-booking-backend
echo       - Root Directory: backend
echo       - Build Command: go build -o main ./cmd/server
echo       - Start Command: ./main
echo.
echo    Environment Variables:
echo    DATABASE_URL=postgresql://...
echo    PORT=8080
echo    GIN_MODE=release
echo    JWT_SECRET=your-32-char-secret
echo.

echo [4/5] Deploy Frontend บน Render...
echo.
echo ✅ ขั้นตอนที่ 4: Deploy Next.js Frontend
echo    1. คลิก "New +" → "Static Site"
echo    2. เลือก repository เดียวกัน
echo    3. ตั้งค่า:
echo       - Name: hotel-booking-frontend
echo       - Root Directory: frontend
echo       - Build Command: npm run build
echo       - Publish Directory: out
echo.
echo    Environment Variables:
echo    NEXT_PUBLIC_API_URL=https://hotel-booking-backend.onrender.com/api
echo    NODE_ENV=production
echo.

echo [5/5] ตั้งค่า CORS...
echo.
echo ✅ ขั้นตอนที่ 5: อัพเดท CORS Settings
echo    1. รอ frontend deploy เสร็จ
echo    2. คัดลอก frontend URL
echo    3. อัพเดท backend environment:
echo       ALLOWED_ORIGINS=https://hotel-booking-frontend.onrender.com
echo    4. Redeploy backend
echo.

echo ========================================
echo 🎉 Deploy เสร็จสิ้น!
echo ========================================
echo.
echo 🌐 URLs ที่ได้:
echo   Frontend: https://hotel-booking-frontend.onrender.com
echo   Backend:  https://hotel-booking-backend.onrender.com
echo.
echo 💡 Tips:
echo   - Render ฟรี 750 ชั่วโมง/เดือน
echo   - Auto-deploy เมื่อ push code ใหม่
echo   - HTTPS ฟรีอัตโนมัติ
echo.
pause