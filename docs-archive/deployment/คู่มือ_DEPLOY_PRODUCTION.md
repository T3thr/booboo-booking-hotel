# 🚀 คู่มือ Deploy Production (ฉบับย่อ)

## 📍 สถานะปัจจุบัน

```
✅ Backend (Go)     → Render      → https://booboo-booking.onrender.com
⚠️ Database         → ยังไม่รัน migrations (ต้องแก้ไขก่อน!)
⏳ Frontend (Next)  → Vercel      → รอ deploy
```

---

## 🚨 ปัญหาที่พบ

**Error Log**:
```
ERROR: function release_expired_holds() does not exist
```

**สาเหตุ**: Database functions ยังไม่ถูกสร้าง

**ผลกระทบ**: Hold cleanup job ไม่ทำงาน

---

## ✅ วิธีแก้ไข (3 ขั้นตอน)

### ขั้นตอนที่ 1: แก้ไข Database (5-10 นาที)

```bash
# 1. ดึง DATABASE_URL จาก Render Dashboard
#    Dashboard → Database → External Database URL

# 2. Set environment variable (CMD)
set DATABASE_URL=postgresql://user:password@host:port/database

# 3. รัน migrations
cd backend\scripts
run-migrations.bat

# 4. ตรวจสอบว่าสำเร็จ
# ควรเห็น: "All Migrations Completed Successfully"
```

### ขั้นตอนที่ 2: Deploy Frontend (5-10 นาที)

```bash
# 1. ติดตั้ง Vercel CLI
npm install -g vercel

# 2. Login
vercel login

# 3. Deploy
cd frontend
vercel --prod

# 4. ตั้งค่า environment variables
vercel env add NEXT_PUBLIC_API_URL production
# ใส่: https://booboo-booking.onrender.com/api

vercel env add NEXTAUTH_URL production  
# ใส่: https://your-app.vercel.app (URL ที่ได้จาก deploy)

vercel env add NEXTAUTH_SECRET production
# ใส่: <สร้าง random string 32 ตัว>
```

**สร้าง Secret**:
```powershell
# PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

### ขั้นตอนที่ 3: เชื่อมต่อ Frontend ↔ Backend (2-3 นาที)

```bash
# 1. ไปที่ Render Dashboard
#    → Backend Service → Environment

# 2. แก้ไข ALLOWED_ORIGINS
#    ใส่: https://your-app.vercel.app,https://your-app-*.vercel.app

# 3. Save (Render จะ redeploy อัตโนมัติ)

# 4. ทดสอบ
curl https://booboo-booking.onrender.com/api/health
```

---

## 🧪 ทดสอบระบบ

### ทดสอบ Backend

```bash
# Health check
curl https://booboo-booking.onrender.com/api/health

# Search rooms
curl "https://booboo-booking.onrender.com/api/rooms/available?check_in=2025-11-10&check_out=2025-11-12"
```

### ทดสอบ Frontend

1. เปิด https://your-app.vercel.app
2. ทดสอบ features:
   - ✅ Search rooms
   - ✅ Login/Register
   - ✅ Create booking
   - ✅ View bookings

---

## 📊 Architecture

```
User Browser
    ↓
Vercel (Frontend - Next.js)
    ↓ HTTPS + JWT
Render (Backend - Go)
    ↓ PostgreSQL
Neon (Database)
```

---

## 🔐 Environment Variables

### Backend (Render Dashboard)

```env
DATABASE_URL=postgresql://...
PORT=8080
GIN_MODE=release
JWT_SECRET=<32-char-secret>
ALLOWED_ORIGINS=https://your-app.vercel.app
```

### Frontend (Vercel Dashboard)

```env
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=<32-char-secret>
```

---

## 🔄 Workflow: Frontend ↔ Backend

### ตัวอย่าง: User ค้นหาห้อง

```
1. User กรอกฟอร์ม (Browser)
   - Check-in: 2025-11-10
   - Check-out: 2025-11-12
   ↓
2. Frontend ส่ง request (Vercel)
   GET /api/rooms/available
   Header: Authorization: Bearer <token>
   ↓
3. Backend ตรวจสอบ (Render)
   - CORS check ✓
   - JWT validation ✓
   - Query database
   ↓
4. Database ค้นหา (Neon)
   SELECT rooms WHERE available
   ↓
5. Response กลับไป
   JSON: [{ room_number, type, price }]
   ↓
6. Frontend แสดงผล
   User เห็นห้องว่าง
```

---

## 🚨 ปัญหาที่พบบ่อย

### 1. Function Not Found
**Error**: `function release_expired_holds() does not exist`  
**แก้ไข**: รัน migrations (ขั้นตอนที่ 1)

### 2. CORS Error
**Error**: `blocked by CORS policy`  
**แก้ไข**: อัปเดต `ALLOWED_ORIGINS` บน Render

### 3. 401 Unauthorized
**Error**: `{"error": "unauthorized"}`  
**แก้ไข**: Login ใหม่, ตรวจสอบ JWT_SECRET

---

## 📚 เอกสารเพิ่มเติม

### ภาษาไทย
- 🚨 [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) - แก้ไขปัญหาด่วน
- 📋 [PRODUCTION_DEPLOYMENT_SUMMARY.md](PRODUCTION_DEPLOYMENT_SUMMARY.md) - สรุปการ deploy

### ภาษาอังกฤษ (รายละเอียดเพิ่มเติม)
- 📖 [RENDER_PRODUCTION_SETUP.md](RENDER_PRODUCTION_SETUP.md) - Setup ครบถ้วน
- 🚀 [DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md) - Workflow ทั้งหมด
- 🔗 [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) - Integration

---

## ✅ Checklist

### ก่อน Deploy
- [ ] Backend migrations รันสำเร็จ
- [ ] Environment variables ตั้งค่าครบ
- [ ] JWT secrets สร้างแล้ว

### หลัง Deploy
- [ ] Health check ทำงาน
- [ ] Authentication ทำงาน
- [ ] Booking flow ทำงาน
- [ ] Logs ไม่มี errors

---

## 🎯 เวลาที่ใช้

```
ขั้นตอนที่ 1: แก้ไข Database    → 5-10 นาที
ขั้นตอนที่ 2: Deploy Frontend   → 5-10 นาที
ขั้นตอนที่ 3: เชื่อมต่อ          → 2-3 นาที
ทดสอบระบบ                       → 10-15 นาที
────────────────────────────────────────────
รวม                              → ~30 นาที
```

---

## 🎉 หลัง Deploy สำเร็จ

1. **Monitor**
   - ดู Render logs
   - ดู Vercel analytics
   - ตรวจสอบ database metrics

2. **Test**
   - ทดสอบทุก features
   - ทดสอบ performance
   - ทดสอบ error handling

3. **Document**
   - เขียน user guide
   - อัปเดต API docs
   - สร้าง admin manual

---

**สร้างเมื่อ**: 2025-11-04  
**สถานะ**: 🟡 Backend deployed, รอแก้ไข migrations  
**ความสำคัญ**: 🚨 แก้ไข migrations ก่อน!
