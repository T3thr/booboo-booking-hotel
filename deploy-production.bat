@echo off
echo ========================================
echo 🚀 Production Deployment - Hotel Booking System
echo ========================================
echo.

echo [1/6] ตรวจสอบ Docker...
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Docker ไม่ได้ติดตั้ง! Download: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

where docker-compose >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Docker Compose ไม่ได้ติดตั้ง!
    pause
    exit /b 1
)

echo ✅ Docker และ Docker Compose พร้อมใช้งาน

echo.
echo [2/6] ตรวจสอบ Environment Files...
if not exist .env.production (
    echo ❌ ไม่พบ .env.production
    echo กรุณาสร้างไฟล์ .env.production จาก .env.production.example
    pause
    exit /b 1
)

echo ✅ Environment files พร้อม

echo.
echo [3/6] สร้าง directories สำหรับ logs และ backups...
if not exist logs mkdir logs
if not exist logs\nginx mkdir logs\nginx
if not exist logs\backend mkdir logs\backend
if not exist logs\frontend mkdir logs\frontend
if not exist logs\postgres mkdir logs\postgres
if not exist logs\redis mkdir logs\redis
if not exist backups mkdir backups
if not exist backups\database mkdir backups\database

echo ✅ Directories สร้างเสร็จ

echo.
echo [4/6] หยุด services เก่า (ถ้ามี)...
docker-compose -f docker-compose.prod.yml down

echo.
echo [5/6] Build และ Start Production Services...
docker-compose -f docker-compose.prod.yml up -d --build

echo.
echo [6/6] ตรวจสอบสถานะ services...
timeout /t 10 /nobreak >nul
docker-compose -f docker-compose.prod.yml ps

echo.
echo ========================================
echo ✅ Production Deployment เสร็จสิ้น!
echo ========================================
echo.
echo 🌐 Services:
echo   - Frontend: http://localhost
echo   - Backend API: http://localhost/api
echo   - Grafana: http://localhost:3001
echo   - Prometheus: http://localhost:9091
echo.
echo 📋 ตรวจสอบ logs:
echo   docker-compose -f docker-compose.prod.yml logs -f [service-name]
echo.
echo 🔧 Services ที่รัน:
echo   - nginx (Reverse Proxy)
echo   - frontend (Next.js)
echo   - backend (Go API)
echo   - db (PostgreSQL)
echo   - redis (Cache)
echo   - prometheus (Monitoring)
echo   - grafana (Dashboard)
echo   - db-backup (Auto Backup)
echo.
pause