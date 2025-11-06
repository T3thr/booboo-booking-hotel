# คู่มือการรัน Backend Server

## ปัญหาที่พบ

เมื่อรัน `server.exe` โดยตรง อาจได้เวอร์ชันเก่าที่ยังไม่ได้ build ใหม่

## วิธีรัน Backend ที่ถูกต้อง

### 1. รัน Backend (แนะนำ)

```bash
# จาก root directory
start-backend.bat
```

หรือ

```bash
# จาก backend directory
cd backend
rebuild-and-run.bat
```

**สิ่งที่ script ทำ:**
- Kill process เก่า
- Build เวอร์ชันใหม่
- รัน server จาก `bin\server.exe`

### 2. รัน Backend แบบ Background

```bash
# จาก root directory
cd backend
start "Hotel Backend" cmd /k bin\server.exe
```

### 3. รัน Backend ด้วย Go โดยตรง (สำหรับ Development)

```bash
cd backend
go run cmd/server/main.go
```

**ข้อดี:**
- ไม่ต้อง build
- เห็น error ทันที
- Hot reload (ถ้าใช้ air)

**ข้อเสีย:**
- ช้ากว่า compiled binary

## คำสั่งที่ใช้บ่อย

### Build เท่านั้น (ไม่รัน)

```bash
cd backend
go build -o bin\server.exe cmd\server\main.go
```

### Kill Server

```bash
taskkill /F /IM server.exe
taskkill /F /IM hotel-booking-api.exe
```

### ตรวจสอบว่า Server รันอยู่หรือไม่

```bash
curl http://localhost:8080/health
```

หรือ

```bash
netstat -ano | findstr :8080
```

## โครงสร้าง Binary Files

```
backend/
├── bin/
│   └── server.exe          ← ใช้ตัวนี้ (เวอร์ชันล่าสุด)
├── server.exe              ← อย่าใช้ (อาจเป็นเวอร์ชันเก่า)
└── hotel-booking-api.exe   ← อย่าใช้ (อาจเป็นเวอร์ชันเก่า)
```

## Scripts ที่มี

### 1. `start-backend.bat` (Root directory)
- Build และรัน backend
- แนะนำสำหรับการใช้งานทั่วไป

### 2. `backend/rebuild-and-run.bat`
- Clean, build, และรัน
- แนะนำเมื่อมีปัญหา

### 3. `backend/quick-restart.bat`
- Restart โดยไม่ build ใหม่
- ใช้เมื่อแน่ใจว่า code ไม่เปลี่ยน

## Environment Variables

Backend อ่าน config จาก `backend/.env`:

```env
PORT=8080
DATABASE_URL=postgresql://...
JWT_SECRET=...
```

## Troubleshooting

### ปัญหา: Server ยังใช้ code เก่า

**วิธีแก้:**
```bash
cd backend
del /F /Q bin\server.exe server.exe hotel-booking-api.exe
go build -o bin\server.exe cmd\server\main.go
bin\server.exe
```

### ปัญหา: Port 8080 ถูกใช้งานอยู่

**วิธีแก้:**
```bash
# หา process ที่ใช้ port 8080
netstat -ano | findstr :8080

# Kill process (แทน PID ด้วยเลขที่ได้)
taskkill /F /PID <PID>
```

### ปัญหา: Database connection failed

**วิธีแก้:**
1. ตรวจสอบ `backend/.env`
2. ตรวจสอบว่า database online
3. ตรวจสอบ credentials

### ปัญหา: Build error

**วิธีแก้:**
```bash
cd backend
go mod tidy
go mod download
go build -o bin\server.exe cmd\server\main.go
```

## Best Practices

### Development
```bash
# ใช้ go run สำหรับ development
cd backend
go run cmd/server/main.go
```

### Testing
```bash
# Build และรัน
cd backend
go build -o bin\server.exe cmd\server\main.go
bin\server.exe
```

### Production
```bash
# Build with optimizations
cd backend
go build -ldflags="-s -w" -o bin\server.exe cmd\server\main.go
```

## Quick Reference

| คำสั่ง | จุดประสงค์ |
|--------|-----------|
| `start-backend.bat` | รัน backend (แนะนำ) |
| `backend/rebuild-and-run.bat` | Build ใหม่และรัน |
| `go run cmd/server/main.go` | รันโดยไม่ build |
| `go build -o bin\server.exe cmd\server\main.go` | Build เท่านั้น |
| `bin\server.exe` | รัน binary ที่ build แล้ว |
| `taskkill /F /IM server.exe` | หยุด server |

## ตัวอย่างการใช้งาน

### Scenario 1: เริ่มต้นใช้งาน
```bash
start-backend.bat
```

### Scenario 2: แก้ code แล้วต้องการ restart
```bash
cd backend
rebuild-and-run.bat
```

### Scenario 3: Development (แก้ code บ่อย)
```bash
cd backend
go run cmd/server/main.go
```

### Scenario 4: มีปัญหา server ไม่ update
```bash
cd backend
taskkill /F /IM server.exe
del /F /Q bin\server.exe
go build -o bin\server.exe cmd\server\main.go
bin\server.exe
```

## สรุป

✅ **ใช้:** `start-backend.bat` หรือ `backend/rebuild-and-run.bat`  
✅ **ใช้:** `bin\server.exe` (ใน backend directory)  
❌ **อย่าใช้:** `server.exe` ที่ root ของ backend  
❌ **อย่าใช้:** `hotel-booking-api.exe`  

---

**หมายเหตุ:** ทุกครั้งที่แก้ code ต้อง build ใหม่ หรือใช้ `go run` แทน
