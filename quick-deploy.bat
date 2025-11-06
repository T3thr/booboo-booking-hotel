@echo off
echo ========================================
echo 🚀 Hotel Booking System - Quick Deploy
echo ========================================
echo.

echo [1/4] ตรวจสอบ dependencies...
where go >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Go ไม่ได้ติดตั้ง! Download: https://golang.org/dl/
    pause
    exit /b 1
)

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js ไม่ได้ติดตั้ง! Download: https://nodejs.org/
    pause
    exit /b 1
)

where npx >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ NPX ไม่พร้อมใช้งาน!
    pause
    exit /b 1
)

echo ✅ Go, Node.js, NPX พร้อมใช้งาน

echo.
echo [2/4] Setup Backend...
cd backend
go mod tidy
if not exist .env.production (
    copy .env.production.example .env.production
    echo ✅ สร้าง .env.production
)
cd ..

echo.
echo [3/4] Setup Frontend...
cd frontend
if not exist .env.production (
    copy .env.example .env.production
    echo ✅ สร้าง .env.production
)
cd ..

echo.
echo [4/4] ขั้นตอนสุดท้าย...
echo.
echo ========================================
echo ✅ Setup เสร็จสิ้น!
echo ========================================
echo.
echo 📋 ขั้นตอนต่อไป:
echo.
echo 1. ตั้งค่า Neon Database:
echo    - ไป https://console.neon.tech
echo    - สร้าง project ใหม่
echo    - Copy "Pooled connection" string
echo.
echo 2. แก้ไข backend/.env.production:
echo    - DATABASE_URL=postgresql://...
echo    - JWT_SECRET=your-32-char-secret
echo.
echo 3. แก้ไข frontend/.env.production:
echo    - NEXT_PUBLIC_API_URL=https://your-backend.vercel.app/api
echo    - NEXTAUTH_SECRET=your-secret
echo.
echo 4. Deploy Backend:
echo    cd backend
echo    npx vercel --prod
echo.
echo 5. Deploy Frontend:
echo    cd frontend  
echo    npx vercel --prod
echo.
echo 6. อัพเดท CORS ใน backend/.env.production:
echo    - FRONTEND_URL=https://your-frontend.vercel.app
echo    - Redeploy backend
echo.
echo 📖 ดูรายละเอียดเพิ่มเติม: VERCEL_DEPLOYMENT_COMPLETE.md
echo.
pause