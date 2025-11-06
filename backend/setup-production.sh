#!/bin/bash

echo "========================================"
echo "Hotel Booking System - Production Setup"
echo "========================================"
echo

echo "[1/5] ตรวจสอบ Go installation..."
if ! command -v go &> /dev/null; then
    echo "ERROR: Go ไม่ได้ติดตั้ง! กรุณาติดตั้ง Go จาก https://golang.org/dl/"
    exit 1
fi
go version

echo
echo "[2/5] ติดตั้ง dependencies..."
go mod tidy
if [ $? -ne 0 ]; then
    echo "ERROR: ไม่สามารถติดตั้ง dependencies ได้!"
    exit 1
fi

echo
echo "[3/5] สร้าง production .env file..."
if [ ! -f .env.production ]; then
    cp .env.production.example .env.production
    echo "✓ สร้าง .env.production แล้ว"
    echo "⚠️  กรุณาแก้ไขค่าใน .env.production ให้ถูกต้อง!"
else
    echo "✓ .env.production มีอยู่แล้ว"
fi

echo
echo "[4/5] Build application..."
mkdir -p bin
go build -o bin/server cmd/server/main.go
if [ $? -ne 0 ]; then
    echo "ERROR: Build ไม่สำเร็จ!"
    exit 1
fi

echo
echo "[5/5] ทดสอบ configuration..."
go run cmd/server/main.go --test-config 2>/dev/null || echo "WARNING: Configuration อาจมีปัญหา กรุณาตรวจสอบ .env.production"

echo
echo "========================================"
echo "✓ Setup เสร็จสิ้น!"
echo "========================================"
echo
echo "ขั้นตอนต่อไป:"
echo "1. แก้ไข .env.production ให้ถูกต้อง"
echo "2. ตั้งค่า Neon Database"
echo "3. Deploy ไป Vercel ด้วย: vercel --prod"
echo