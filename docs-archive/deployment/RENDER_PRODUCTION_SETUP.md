# 🚀 Render Production Setup Guide

## สถานะปัจจุบัน
✅ Backend (Go) deployed บน Render  
❌ Database migrations ยังไม่ได้รัน  
⏳ Frontend (Next.js) รอ deploy บน Vercel

---

## 🔧 ขั้นตอนที่ 1: แก้ไข Database Migration Issue

### ปัญหาที่พบ
```
ERROR: function release_expired_holds() does not exist (SQLSTATE 42883)
```

**สาเหตุ**: Database migrations ไม่ได้ถูก run บน production database

### วิธีแก้ไข

#### Option A: รัน Migrations จาก Local (แนะนำ)

1. **ติดตั้ง PostgreSQL Client** (ถ้ายังไม่มี)
   ```bash
   # Windows (Chocolatey)
   choco install postgresql
   
   # หรือดาวน์โหลดจาก
   # https://www.postgresql.org/download/windows/
   ```

2. **ดึง DATABASE_URL จาก Render Dashboard**
   - ไปที่ Render Dashboard → Database
   - คัดลอก "External Database URL"
   - Format: `postgresql://user:password@host:port/database`

3. **Set Environment Variable**
   ```cmd
   # Windows CMD
   set DATABASE_URL=postgresql://user:password@host:port/database
   
   # หรือ PowerShell
   $env:DATABASE_URL="postgresql://user:password@host:port/database"
   ```

4. **รัน Migration Script**
   ```bash
   cd backend/scripts
   ./run-migrations.sh    # Linux/Mac
   run-migrations.bat     # Windows
   ```

#### Option B: รัน Migrations ผ่าน Render Shell

1. ไปที่ Render Dashboard → Service → Shell
2. รันคำสั่ง:
   ```bash
   cd /app/backend
   psql $DATABASE_URL -f ../database/migrations/008_create_release_expired_holds_function.sql
   ```

#### Option C: ใช้ Render Build Command (แนะนำสำหรับอนาคต)

แก้ไข `render.yaml`:
```yaml
services:
  - type: web
    name: hotel-booking-backend
    env: go
    buildCommand: |
      cd backend
      # Run migrations first
      for f in ../database/migrations/*.sql; do
        psql $DATABASE_URL -f "$f" || true
      done
      # Then build
      go build -o main ./cmd/server
    startCommand: cd backend && ./main
```

---

## 🔧 ขั้นตอนที่ 2: ตั้งค่า Environment Variables บน Render

### Backend Service Environment Variables

ไปที่ Render Dashboard → Service → Environment:

```env
# Database
DATABASE_URL=<your-neon-database-url>

# Server
PORT=8080
GIN_MODE=release
ENVIRONMENT=production

# Security
JWT_SECRET=<generate-random-string-32-chars>

# CORS (จะอัปเดตหลัง deploy frontend)
ALLOWED_ORIGINS=https://your-frontend.vercel.app

# Redis (Optional - ถ้าไม่มีก็ skip)
REDIS_URL=redis://localhost:6379
REDIS_ENABLED=false

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60

# Session
SESSION_TIMEOUT=3600
```

### วิธีสร้าง JWT_SECRET
```bash
# Linux/Mac
openssl rand -base64 32

# Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))

# หรือใช้ online generator
# https://generate-secret.vercel.app/32
```

---

## 🔧 ขั้นตอนที่ 3: Deploy Frontend บน Vercel

### 3.1 เตรียม Frontend Environment Variables

สร้างไฟล์ `.env.production` ใน `frontend/`:

```env
# API Configuration
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api

# NextAuth Configuration
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=<generate-random-string-32-chars>

# Environment
NODE_ENV=production
```

### 3.2 Deploy ไปยัง Vercel

#### Option A: ผ่าน Vercel CLI (แนะนำ)

1. **ติดตั้ง Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Login**
   ```bash
   vercel login
   ```

3. **Deploy**
   ```bash
   cd frontend
   vercel --prod
   ```

4. **ตั้งค่า Environment Variables**
   ```bash
   vercel env add NEXT_PUBLIC_API_URL production
   # ใส่: https://booboo-booking.onrender.com/api
   
   vercel env add NEXTAUTH_URL production
   # ใส่: https://your-app.vercel.app
   
   vercel env add NEXTAUTH_SECRET production
   # ใส่: <your-generated-secret>
   ```

#### Option B: ผ่าน Vercel Dashboard

1. ไปที่ https://vercel.com/new
2. Import repository จาก GitHub
3. ตั้งค่า:
   - **Framework Preset**: Next.js
   - **Root Directory**: `frontend`
   - **Build Command**: `npm run build`
   - **Output Directory**: `.next`
4. เพิ่ม Environment Variables (ตามด้านบน)
5. คลิก Deploy

---

## 🔧 ขั้นตอนที่ 4: เชื่อมต่อ Frontend ↔ Backend

### 4.1 อัปเดต CORS บน Backend

หลังจาก deploy frontend แล้ว:

1. ไปที่ Render Dashboard → Backend Service → Environment
2. อัปเดต `ALLOWED_ORIGINS`:
   ```
   https://your-app.vercel.app,https://your-app-*.vercel.app
   ```
3. Redeploy backend service

### 4.2 ทดสอบการเชื่อมต่อ

เปิด browser console บน frontend:
```javascript
// ทดสอบ API connection
fetch('https://booboo-booking.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log)
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-11-04T..."
}
```

---

## 📊 Workflow: Frontend ↔ Backend Communication

```
┌─────────────────────────────────────────────────────────────┐
│                    User Browser                              │
│                 (https://your-app.vercel.app)               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ 1. User Action (e.g., Search Rooms)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Next.js Frontend (Vercel)                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  React Component                                      │  │
│  │  - useRooms() hook                                   │  │
│  │  - Calls: api.get('/rooms/available')               │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  API Client (lib/api.ts)                            │  │
│  │  - Base URL: NEXT_PUBLIC_API_URL                    │  │
│  │  - Adds: Authorization header (JWT)                 │  │
│  │  - Handles: Error responses                         │  │
│  └──────────────────┬───────────────────────────────────┘  │
└────────────────────┬┴───────────────────────────────────────┘
                     │
                     │ 2. HTTP Request
                     │    GET https://booboo-booking.onrender.com/api/rooms/available
                     │    Headers: { Authorization: "Bearer <token>" }
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              Go Backend (Render)                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Middleware Chain                                     │  │
│  │  1. CORS Check (ALLOWED_ORIGINS)                    │  │
│  │  2. Rate Limiting                                    │  │
│  │  3. JWT Validation                                   │  │
│  │  4. Security Headers                                 │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  Router (internal/router/router.go)                  │  │
│  │  - Route: GET /api/rooms/available                   │  │
│  │  - Handler: room_handler.GetAvailableRooms()        │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  Handler (internal/handlers/room_handler.go)         │  │
│  │  - Validates request parameters                      │  │
│  │  - Calls: roomService.GetAvailableRooms()           │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  Service (internal/service/room_service.go)          │  │
│  │  - Business logic                                    │  │
│  │  - Calls: roomRepo.FindAvailable()                  │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  Repository (internal/repository/room_repository.go) │  │
│  │  - SQL Query execution                               │  │
│  │  - Database connection pool                          │  │
│  └──────────────────┬───────────────────────────────────┘  │
└────────────────────┬┴───────────────────────────────────────┘
                     │
                     │ 3. Database Query
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL Database (Neon)                      │
│  - Tables: rooms, room_types, room_inventory                │
│  - Functions: create_booking_hold, confirm_booking, etc.    │
│  - Indexes: Optimized for performance                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ 4. Query Results
                     ↓
                  (Response flows back up the chain)
```

### Key Points:

1. **Authentication Flow**:
   - User logs in → Backend returns JWT
   - Frontend stores JWT in memory (useAuthStore)
   - Every API request includes JWT in Authorization header
   - Backend validates JWT on each request

2. **Error Handling**:
   - Backend returns standardized error format
   - Frontend catches and displays user-friendly messages
   - Network errors trigger retry logic

3. **Data Flow**:
   - Frontend → Backend: JSON request body
   - Backend → Frontend: JSON response
   - All dates in ISO 8601 format
   - All amounts in smallest currency unit (satang)

---

## 🧪 ขั้นตอนที่ 5: ทดสอบระบบ

### 5.1 ทดสอบ Backend

```bash
# Health Check
curl https://booboo-booking.onrender.com/api/health

# Test Room Search
curl "https://booboo-booking.onrender.com/api/rooms/available?check_in=2025-11-10&check_out=2025-11-12"

# Test Login
curl -X POST https://booboo-booking.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 5.2 ทดสอบ Frontend

1. เปิด https://your-app.vercel.app
2. ทดสอบ features:
   - ✅ Search rooms
   - ✅ Login/Register
   - ✅ Create booking
   - ✅ View bookings

### 5.3 ทดสอบ Integration

```bash
# ใช้ script ที่เตรียมไว้
cd scripts
./test-production.sh    # Linux/Mac
test-production.bat     # Windows
```

---

## 📝 Checklist: Production Readiness

### Backend (Render)
- [ ] Database migrations รันสำเร็จ
- [ ] Environment variables ตั้งค่าครบ
- [ ] Health check endpoint ทำงาน
- [ ] CORS ตั้งค่าถูกต้อง
- [ ] JWT authentication ทำงาน
- [ ] Rate limiting เปิดใช้งาน
- [ ] Logs ไม่มี errors

### Frontend (Vercel)
- [ ] Build สำเร็จ
- [ ] Environment variables ตั้งค่าครบ
- [ ] API connection ทำงาน
- [ ] Authentication flow ทำงาน
- [ ] All pages load correctly
- [ ] No console errors

### Database (Neon)
- [ ] All tables created
- [ ] All functions created
- [ ] Indexes created
- [ ] Sample data inserted (optional)
- [ ] Backup configured

### Integration
- [ ] Frontend → Backend communication ทำงาน
- [ ] CORS ไม่มีปัญหา
- [ ] Authentication ทำงานข้ามระบบ
- [ ] Error handling ทำงานถูกต้อง

---

## 🚨 Troubleshooting

### ปัญหา: CORS Error
```
Access to fetch at 'https://booboo-booking.onrender.com' from origin 'https://your-app.vercel.app' has been blocked by CORS policy
```

**แก้ไข**:
1. ตรวจสอบ `ALLOWED_ORIGINS` บน Render
2. ต้องมี frontend URL ใน list
3. Redeploy backend

### ปัญหา: 401 Unauthorized
```
{"error": "unauthorized"}
```

**แก้ไข**:
1. ตรวจสอบ JWT token ใน request header
2. ตรวจสอบ `JWT_SECRET` ตรงกันทั้ง 2 ฝั่ง
3. ตรวจสอบ token expiry

### ปัญหา: Database Connection Failed
```
failed to connect to database
```

**แก้ไข**:
1. ตรวจสอบ `DATABASE_URL` format
2. ตรวจสอบ Neon database status
3. ตรวจสอบ IP whitelist (ถ้ามี)

### ปัญหา: Function Does Not Exist
```
ERROR: function release_expired_holds() does not exist
```

**แก้ไข**:
1. รัน migrations ตาม Option A ด้านบน
2. ตรวจสอบว่า migration file ถูก execute

---

## 📚 เอกสารเพิ่มเติม

- [Backend API Documentation](backend/docs/swagger.yaml)
- [Frontend Setup Guide](frontend/SETUP.md)
- [Database Schema](database/migrations/SCHEMA_DIAGRAM.md)
- [Deployment Checklist](DEPLOYMENT_CHECKLIST_FINAL.md)

---

## 🎯 Next Steps

1. **แก้ไข Migration Issue** (ด่วน!)
   ```bash
   cd backend/scripts
   run-migrations.bat
   ```

2. **Deploy Frontend**
   ```bash
   cd frontend
   vercel --prod
   ```

3. **อัปเดต CORS**
   - เพิ่ม Vercel URL ใน `ALLOWED_ORIGINS`

4. **ทดสอบระบบ**
   - ทดสอบทุก features
   - ตรวจสอบ logs

5. **Monitor**
   - ดู Render logs
   - ดู Vercel analytics
   - ตรวจสอบ database performance

---

**สร้างเมื่อ**: 2025-11-04  
**อัปเดตล่าสุด**: 2025-11-04  
**Status**: 🟡 In Progress (Backend deployed, migrations pending)
