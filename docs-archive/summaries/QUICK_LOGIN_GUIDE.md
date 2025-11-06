# 🔐 คู่มือเข้าสู่ระบบด่วน (Quick Login Guide)

## 🎯 วิธีเริ่มต้นใช้งาน

### ขั้นตอนที่ 1: เริ่มระบบ

เลือก 1 ใน 3 วิธี:

#### วิธีที่ 1: Docker (แนะนำ - ง่ายที่สุด)
```bash
# Windows
docker-compose up -d

# หรือใช้ start script
start.bat
```

#### วิธีที่ 2: รันแยกส่วน (สำหรับ Development)
```bash
# Terminal 1: เริ่ม Database
docker-compose up db redis -d

# Terminal 2: เริ่ม Backend
cd backend
go run cmd/server/main.go

# Terminal 3: เริ่ม Frontend
cd frontend
npm run dev
```

#### วิธีที่ 3: ใช้ Neon PostgreSQL
1. แก้ไฟล์ `backend/.env` ให้ชี้ไปที่ Neon
2. รัน Backend และ Frontend แยกกัน

---

## 🗄️ ขั้นตอนที่ 2: สร้างฐานข้อมูลและข้อมูลทดสอบ

### ตรวจสอบว่า Database พร้อมใช้งาน
```bash
# Windows PowerShell
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "\dt"
```

### Run Migrations (สร้างตาราง)
```bash
cd database/migrations

# Windows
run_migration_001.bat
run_migration_002.bat
run_migration_003.bat
run_migration_004.bat
```

หรือรันทีเดียว:
```bash
# Windows PowerShell
Get-ChildItem database\migrations\*.sql | Where-Object { $_.Name -match '^\d{3}_' } | Sort-Object Name | ForEach-Object {
    Write-Host "Running migration: $($_.Name)"
    Get-Content $_.FullName | docker exec -i hotel-booking-db psql -U postgres -d hotel_booking
}
```

---

## 👤 ข้อมูล Login สำหรับทดสอบ

### สำหรับ E2E Testing (ต้องสร้างผ่าน API หรือ Seed Script)

**Guest (ผู้เข้าพัก):**
- Email: `test.guest@example.com`
- Password: `TestPassword123!`

**Receptionist (พนักงานต้อนรับ):**
- Email: `receptionist@hotel.com`
- Password: `ReceptionistPass123!`

**Housekeeper (แม่บ้าน):**
- Email: `housekeeper@hotel.com`
- Password: `HousekeeperPass123!`

**Manager (ผู้จัดการ):**
- Email: `manager@hotel.com`
- Password: `ManagerPass123!`

### สำหรับ Database Seed Data (จาก Migration 001)

**Password เดียวกันทั้งหมด:** `password123`

**Test Users:**
- `somchai@example.com`
- `somying@example.com`
- `prayut@example.com`
- `nattaya@example.com`
- `wichai@example.com`
- `suda@example.com`
- `anan@example.com`
- `pensri@example.com`
- `chaiyong@example.com`
- `malee@example.com`

---

## 🔧 การสร้าง Test Users ด้วย API

หากยังไม่มี users ในระบบ สามารถสร้างผ่าน API:

### 1. สร้าง Guest User
```bash
curl -X POST http://localhost:8080/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@example.com\",\"password\":\"Test123456!\",\"firstName\":\"Test\",\"lastName\":\"User\",\"phoneNumber\":\"0812345678\"}"
```

### 2. Login
```bash
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@example.com\",\"password\":\"Test123456!\"}"
```

---

## 🌐 URLs สำหรับเข้าถึงระบบ

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080
- **API Docs:** http://localhost:8080/swagger/index.html
- **Database:** localhost:5432
- **Redis:** localhost:6379

---

## ❌ แก้ปัญหาที่พบบ่อย

### ปัญหา: "เข้าสู่ระบบไม่สำเร็จ"

**สาเหตุ:**
1. Backend ยังไม่ได้รัน
2. Database ยังไม่มีข้อมูล users
3. Connection string ผิด

**วิธีแก้:**
```bash
# 1. ตรวจสอบ Backend ทำงานหรือไม่
curl http://localhost:8080/health

# 2. ตรวจสอบ Database
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "SELECT email FROM guests LIMIT 5;"

# 3. ดู Backend logs
docker logs hotel-booking-backend

# 4. ดู Frontend logs
docker logs hotel-booking-frontend
```

### ปัญหา: "Cannot connect to database"

**วิธีแก้:**
```bash
# ตรวจสอบ Database container
docker ps | findstr hotel-booking-db

# Restart Database
docker-compose restart db

# ตรวจสอบ connection
docker exec -it hotel-booking-db psql -U postgres -c "\l"
```

### ปัญหา: "Port already in use"

**วิธีแก้:**
```bash
# หา process ที่ใช้ port
netstat -ano | findstr :3000
netstat -ano | findstr :8080
netstat -ano | findstr :5432

# Kill process (แทน PID ด้วยเลขที่ได้)
taskkill /PID <PID> /F
```

---

## 📝 ขั้นตอนแนะนำสำหรับครั้งแรก

1. **เริ่มระบบ:**
   ```bash
   docker-compose up -d
   ```

2. **รอให้ services พร้อม (ประมาณ 30 วินาที)**

3. **Run migrations:**
   ```bash
   cd database/migrations
   run_migration_001.bat
   ```

4. **ทดสอบ login:**
   - เปิด http://localhost:3000
   - ใช้: `somchai@example.com` / `password123`

5. **หากไม่ได้ผล:**
   - ตรวจสอบ logs: `docker logs hotel-booking-backend`
   - ตรวจสอบ database: `docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "SELECT * FROM guests;"`

---

## 🎓 เรียนรู้เพิ่มเติม

- **Backend API:** `backend/docs/README.md`
- **Frontend Setup:** `frontend/SETUP.md`
- **Database Migrations:** `database/migrations/README.md`
- **Testing Guide:** `backend/docs/TESTING_GUIDE.md`

---

**หมายเหตุ:** ข้อมูล test users เหล่านี้ใช้สำหรับ development เท่านั้น อย่าใช้ใน production!
