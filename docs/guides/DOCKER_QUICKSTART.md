# 🚀 Docker Quick Start - Hotel Booking System

## เริ่มต้นใช้งานภายใน 5 นาที

### ขั้นตอนที่ 1: ติดตั้ง Docker Desktop

1. ดาวน์โหลดจาก: https://www.docker.com/products/docker-desktop/
2. ติดตั้งและรีสตาร์ทเครื่อง
3. เปิด Docker Desktop และรอให้ไฟเขียว

### ขั้นตอนที่ 2: ตรวจสอบการติดตั้ง

```powershell
# เปิด PowerShell หรือ Git Bash
docker --version
docker compose version

# ทดสอบ
docker run hello-world
```

### ขั้นตอนที่ 3: เตรียม Environment

```powershell
# สร้าง .env file (ถ้ายังไม่มี)
copy .env.example .env

# แก้ไขค่าใน .env ตามต้องการ
```

### ขั้นตอนที่ 4: เริ่ม Project

```powershell
# เริ่ม services ทั้งหมด
docker compose up -d

# ดู logs
docker compose logs -f

# ตรวจสอบ status
docker compose ps
```

### ขั้นตอนที่ 5: ทดสอบ

```powershell
# ทดสอบ Backend
curl http://localhost:8080/health

# ทดสอบ Frontend
# เปิดเบราว์เซอร์: http://localhost:3000

# ทดสอบ Database
docker compose exec postgres psql -U hotel_user -d hotel_db
```

## 🎮 Commands ที่ใช้บ่อย

```powershell
# เริ่ม
docker compose up -d

# หยุด
docker compose down

# รีสตาร์ท
docker compose restart

# ดู logs
docker compose logs -f backend

# Build ใหม่
docker compose up --build -d

# ทำความสะอาด
docker compose down -v
docker system prune -a
```

## 🔧 Troubleshooting

### Docker Desktop ไม่เปิด
```powershell
wsl --shutdown
# เปิด Docker Desktop ใหม่
```

### Port ถูกใช้แล้ว
```powershell
# ดู process ที่ใช้ port
netstat -ano | findstr :3000

# Kill process
taskkill /PID <PID> /F
```

### Container ไม่ start
```powershell
# ดู logs
docker compose logs backend

# ลบและสร้างใหม่
docker compose down
docker compose up -d
```

## 📚 เอกสารเพิ่มเติม

- คู่มือฉบับสมบูรณ์: `DOCKER_COMPLETE_GUIDE_2025.md`
- แก้ปัญหา Windows: `WINDOWS_PATH_FIX_GUIDE.md`
- Docker Setup: `DOCKER_SETUP.md`

