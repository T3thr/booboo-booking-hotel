#!/bin/bash

echo "========================================"
echo "🚀 Production Deployment - Hotel Booking System"
echo "========================================"
echo

echo "[1/6] ตรวจสอบ Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker ไม่ได้ติดตั้ง! Download: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose ไม่ได้ติดตั้ง!"
    exit 1
fi

echo "✅ Docker และ Docker Compose พร้อมใช้งาน"

echo
echo "[2/6] ตรวจสอบ Environment Files..."
if [ ! -f .env.production ]; then
    echo "❌ ไม่พบ .env.production"
    echo "กรุณาสร้างไฟล์ .env.production จาก .env.production.example"
    exit 1
fi

echo "✅ Environment files พร้อม"

echo
echo "[3/6] สร้าง directories สำหรับ logs และ backups..."
mkdir -p logs/{nginx,backend,frontend,postgres,redis}
mkdir -p backups/database

echo "✅ Directories สร้างเสร็จ"

echo
echo "[4/6] หยุด services เก่า (ถ้ามี)..."
docker-compose -f docker-compose.prod.yml down

echo
echo "[5/6] Build และ Start Production Services..."
docker-compose -f docker-compose.prod.yml up -d --build

echo
echo "[6/6] ตรวจสอบสถานะ services..."
sleep 10
docker-compose -f docker-compose.prod.yml ps

echo
echo "========================================"
echo "✅ Production Deployment เสร็จสิ้น!"
echo "========================================"
echo
echo "🌐 Services:"
echo "  - Frontend: http://localhost"
echo "  - Backend API: http://localhost/api"
echo "  - Grafana: http://localhost:3001"
echo "  - Prometheus: http://localhost:9091"
echo
echo "📋 ตรวจสอบ logs:"
echo "  docker-compose -f docker-compose.prod.yml logs -f [service-name]"
echo
echo "🔧 Services ที่รัน:"
echo "  - nginx (Reverse Proxy)"
echo "  - frontend (Next.js)"
echo "  - backend (Go API)"
echo "  - db (PostgreSQL)"
echo "  - redis (Cache)"
echo "  - prometheus (Monitoring)"
echo "  - grafana (Dashboard)"
echo "  - db-backup (Auto Backup)"
echo