# 🚀 Deployment Workflow: Render + Vercel

## สถานะปัจจุบัน

```
✅ Backend (Go)     → Render      → https://booboo-booking.onrender.com
⚠️ Migrations       → ยังไม่รัน   → ต้องแก้ไขก่อน!
⏳ Frontend (Next)  → Vercel      → รอ deploy
⏳ Integration      → รอเชื่อมต่อ
```

---

## 🎯 ขั้นตอนการทำงาน (Step-by-Step)

### Step 1: แก้ไข Backend Migration Issue ⚠️ (ด่วน!)

**ปัญหา**: Database functions ยังไม่ถูกสร้าง

**วิธีแก้ไข**:

```bash
# 1. ดึง DATABASE_URL จาก Render Dashboard
# Dashboard → Database → External Database URL

# 2. Set environment variable
set DATABASE_URL=postgresql://user:password@host:port/database

# 3. รัน migrations
cd backend\scripts
run-migrations.bat

# 4. ตรวจสอบว่าสำเร็จ
# ควรเห็น: "All Migrations Completed Successfully"
```

**เวลาที่ใช้**: 5-10 นาที

**อ่านเพิ่มเติม**: [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)

---

### Step 2: ตรวจสอบ Backend Environment Variables

ไปที่ Render Dashboard → Service → Environment:

```env
✅ DATABASE_URL=postgresql://...
✅ PORT=8080
✅ GIN_MODE=release
✅ ENVIRONMENT=production
✅ JWT_SECRET=<32-char-random-string>
⏳ ALLOWED_ORIGINS=<จะอัปเดตหลัง deploy frontend>
✅ REDIS_ENABLED=false
✅ RATE_LIMIT_ENABLED=true
```

**สร้าง JWT_SECRET**:
```powershell
# PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

---

### Step 3: Deploy Frontend บน Vercel

#### 3.1 เตรียม Environment Variables

สร้างไฟล์ `frontend/.env.production`:

```env
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=<32-char-random-string>
NODE_ENV=production
```

#### 3.2 Deploy

**Option A: Vercel CLI** (แนะนำ)

```bash
# ติดตั้ง Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd frontend
vercel --prod

# ตั้งค่า environment variables
vercel env add NEXT_PUBLIC_API_URL production
# ใส่: https://booboo-booking.onrender.com/api

vercel env add NEXTAUTH_URL production
# ใส่: https://your-app.vercel.app (URL ที่ได้จาก deploy)

vercel env add NEXTAUTH_SECRET production
# ใส่: <your-secret>
```

**Option B: Vercel Dashboard**

1. ไปที่ https://vercel.com/new
2. Import repository
3. ตั้งค่า:
   - Framework: Next.js
   - Root Directory: `frontend`
   - Build Command: `npm run build`
4. เพิ่ม Environment Variables
5. Deploy

**เวลาที่ใช้**: 5-10 นาที

---

### Step 4: เชื่อมต่อ Frontend ↔ Backend

#### 4.1 อัปเดต CORS บน Backend

1. ไปที่ Render Dashboard → Backend Service → Environment
2. แก้ไข `ALLOWED_ORIGINS`:
   ```
   https://your-app.vercel.app,https://your-app-*.vercel.app
   ```
3. คลิก "Save Changes"
4. Render จะ redeploy อัตโนมัติ

#### 4.2 ทดสอบการเชื่อมต่อ

```bash
# Test backend health
curl https://booboo-booking.onrender.com/api/health

# Test from frontend (browser console)
fetch('https://booboo-booking.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log)
```

**Expected Response**:
```json
{
  "status": "ok",
  "timestamp": "2025-11-04T..."
}
```

---

### Step 5: ทดสอบ End-to-End

#### 5.1 ทดสอบ Authentication

```bash
# 1. Register user
curl -X POST https://booboo-booking.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User"
  }'

# 2. Login
curl -X POST https://booboo-booking.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Response: { "token": "eyJ...", "user": {...} }
```

#### 5.2 ทดสอบ Booking Flow

1. เปิด frontend: https://your-app.vercel.app
2. ทดสอบ features:
   - ✅ Search rooms
   - ✅ Login/Register
   - ✅ Create booking hold
   - ✅ Confirm booking
   - ✅ View bookings
   - ✅ Cancel booking

#### 5.3 ตรวจสอบ Logs

**Backend Logs** (Render):
```
2025/11/04 06:43:42 Starting server on 0.0.0.0:8080
2025/11/04 06:43:42 Night audit job scheduled
2025/11/04 06:43:42 Hold cleanup job scheduled
✓ ไม่มี errors
```

**Frontend Logs** (Vercel):
```
Build successful
Deployment ready
✓ ไม่มี errors
```

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User Browser                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Vercel (Frontend)                               │
│  - Next.js 14 App Router                                    │
│  - Server Components                                         │
│  - Static Generation                                         │
│  - Edge Functions                                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS + JWT
                         │ CORS: Allowed
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Render (Backend)                                │
│  - Go (Gin framework)                                       │
│  - RESTful API                                              │
│  - JWT Authentication                                        │
│  - Rate Limiting                                             │
│  - Background Jobs                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ PostgreSQL Protocol
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Neon (Database)                                 │
│  - PostgreSQL 15+                                           │
│  - Serverless                                                │
│  - Connection Pooling                                        │
│  - Auto-scaling                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Request Flow Example

### Scenario: User searches for available rooms

```
1. User Input
   ↓
   User fills form:
   - Check-in: 2025-11-10
   - Check-out: 2025-11-12
   - Guests: 2
   
2. Frontend (Vercel)
   ↓
   Component: SearchForm.tsx
   Hook: useRooms()
   API Call: GET /api/rooms/available?check_in=2025-11-10&check_out=2025-11-12&guests=2
   
3. Network
   ↓
   HTTPS Request
   URL: https://booboo-booking.onrender.com/api/rooms/available
   Headers: { Authorization: "Bearer <token>" }
   
4. Backend (Render)
   ↓
   Middleware Chain:
   - CORS Check ✓
   - Rate Limit ✓
   - JWT Validation ✓
   
   Handler: room_handler.GetAvailableRooms()
   Service: roomService.GetAvailableRooms()
   Repository: roomRepo.FindAvailable()
   
5. Database (Neon)
   ↓
   Query:
   SELECT r.*, rt.name, ri.available_count
   FROM rooms r
   JOIN room_types rt ON r.room_type_id = rt.id
   JOIN room_inventory ri ON rt.id = ri.room_type_id
   WHERE ri.date BETWEEN '2025-11-10' AND '2025-11-12'
     AND ri.available_count >= 2
   
6. Response
   ↓
   JSON:
   [
     {
       "id": 1,
       "room_number": "101",
       "room_type": "Deluxe",
       "price": 2500,
       "available": true
     }
   ]
   
7. Frontend Display
   ↓
   Component renders room cards
   User sees available rooms
```

---

## 🔐 Security Checklist

### Backend (Render)

- [x] HTTPS enabled (automatic)
- [x] JWT authentication
- [x] Rate limiting
- [x] CORS configured
- [x] SQL injection prevention (parameterized queries)
- [x] Password hashing (bcrypt)
- [x] Security headers
- [ ] Redis caching (optional)

### Frontend (Vercel)

- [x] HTTPS enabled (automatic)
- [x] Environment variables secured
- [x] No sensitive data in client
- [x] JWT stored in memory only
- [x] CSRF protection (NextAuth)
- [x] XSS prevention (React)

### Database (Neon)

- [x] SSL/TLS connection
- [x] Connection pooling
- [x] Prepared statements
- [x] Role-based access
- [x] Backup enabled

---

## 📝 Deployment Checklist

### Pre-Deployment

- [ ] Backend migrations รันสำเร็จ
- [ ] Environment variables ตั้งค่าครบ (ทั้ง 2 ฝั่ง)
- [ ] JWT secrets สร้างแล้ว
- [ ] Database connection ทดสอบแล้ว
- [ ] API endpoints ทดสอบแล้ว

### Deployment

- [ ] Backend deployed บน Render
- [ ] Frontend deployed บน Vercel
- [ ] CORS configured
- [ ] Environment variables synced

### Post-Deployment

- [ ] Health check ทำงาน
- [ ] Authentication flow ทำงาน
- [ ] Booking flow ทำงาน end-to-end
- [ ] Logs ไม่มี errors
- [ ] Performance acceptable

---

## 🚨 Troubleshooting

### ปัญหา: Backend ไม่ตอบสนอง

**อาการ**: `Failed to fetch` หรือ timeout

**แก้ไข**:
1. ตรวจสอบ Render service status
2. ดู logs: Render Dashboard → Logs
3. ตรวจสอบ DATABASE_URL
4. Restart service

### ปัญหา: CORS Error

**อาการ**: `blocked by CORS policy`

**แก้ไข**:
1. ตรวจสอบ `ALLOWED_ORIGINS` บน Render
2. ต้องมี Vercel URL
3. Format: `https://your-app.vercel.app,https://your-app-*.vercel.app`
4. Redeploy backend

### ปัญหา: 401 Unauthorized

**อาการ**: `{"error": "unauthorized"}`

**แก้ไข**:
1. ตรวจสอบ JWT token ใน request
2. Login ใหม่
3. ตรวจสอบ `JWT_SECRET` ตรงกันทั้ง 2 ฝั่ง
4. ตรวจสอบ token expiry (default: 24h)

### ปัญหา: Database Function Not Found

**อาการ**: `function release_expired_holds() does not exist`

**แก้ไข**:
อ่าน [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)

---

## 📊 Monitoring

### Backend (Render)

```bash
# View logs
# Render Dashboard → Service → Logs

# Key metrics:
- Response time
- Error rate
- Memory usage
- CPU usage
```

### Frontend (Vercel)

```bash
# View analytics
# Vercel Dashboard → Analytics

# Key metrics:
- Page load time
- Core Web Vitals
- Error rate
- Traffic
```

### Database (Neon)

```bash
# View metrics
# Neon Dashboard → Metrics

# Key metrics:
- Connection count
- Query performance
- Storage usage
- Backup status
```

---

## 🎯 Next Steps

### Immediate (ด่วน!)

1. **แก้ไข Migration Issue**
   ```bash
   cd backend\scripts
   run-migrations.bat
   ```

2. **Deploy Frontend**
   ```bash
   cd frontend
   vercel --prod
   ```

3. **อัปเดต CORS**
   - เพิ่ม Vercel URL ใน `ALLOWED_ORIGINS`

### Short-term (1-2 วัน)

1. ทดสอบทุก features
2. ตรวจสอบ performance
3. Setup monitoring/alerts
4. เขียน user documentation

### Long-term (1-2 สัปดาห์)

1. Setup CI/CD pipeline
2. Add automated tests
3. Implement Redis caching
4. Setup backup strategy
5. Performance optimization

---

## 📚 Documentation

- [RENDER_PRODUCTION_SETUP.md](RENDER_PRODUCTION_SETUP.md) - Complete setup
- [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) - Fix migrations
- [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) - Integration guide
- [RENDER_ENVIRONMENT_VARIABLES.md](RENDER_ENVIRONMENT_VARIABLES.md) - All env vars
- [backend/docs/swagger.yaml](backend/docs/swagger.yaml) - API docs

---

**Created**: 2025-11-04  
**Last Updated**: 2025-11-04  
**Status**: 🟡 Backend deployed, migrations pending, frontend ready
