# 🚀 Vercel Deployment Guide - Hotel Booking Frontend

## 📋 สถานะปัจจุบัน

```
✅ Backend deployed บน Render → https://booboo-booking.onrender.com
⚠️ Database migrations → ต้องรันก่อน (ดู QUICK_FIX_RENDER.md)
⏳ Frontend → พร้อม deploy บน Vercel
```

---

## 🎯 ขั้นตอนการ Deploy (10 นาที)

### วิธีที่ 1: Vercel CLI (แนะนำ - ง่ายที่สุด)

#### 1. ติดตั้ง Vercel CLI

```bash
npm install -g vercel
```

#### 2. Login

```bash
vercel login
```

#### 3. Deploy

```bash
# Deploy to production
vercel --prod

# ตอบคำถาม:
# ? Set up and deploy "~/hotel-booking"? [Y/n] Y
# ? Which scope? [Your Account]
# ? Link to existing project? [y/N] N
# ? What's your project's name? hotel-booking-frontend
# ? In which directory is your code located? ./frontend
```

#### 4. ตั้งค่า Environment Variables

หลัง deploy สำเร็จ คุณจะได้ URL เช่น: `https://hotel-booking-frontend.vercel.app`

```bash
# Set environment variables
vercel env add NEXT_PUBLIC_API_URL production
# ใส่: https://booboo-booking.onrender.com/api

vercel env add BACKEND_URL production
# ใส่: https://booboo-booking.onrender.com

vercel env add NEXTAUTH_URL production
# ใส่: https://hotel-booking-frontend.vercel.app (URL ที่ได้จาก deploy)

vercel env add NEXTAUTH_SECRET production
# ใส่: IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=
# (หรือสร้างใหม่ด้วย: openssl rand -base64 32)

vercel env add NODE_ENV production
# ใส่: production
```

#### 5. Redeploy เพื่อใช้ Environment Variables

```bash
vercel --prod
```

---

### วิธีที่ 2: Vercel Dashboard (ผ่าน Web UI)

#### 1. เตรียม Repository

```bash
# Commit และ push code ไป GitHub
git add .
git commit -m "Prepare for Vercel deployment"
git push origin main
```

#### 2. Import Project

1. ไปที่ https://vercel.com/new
2. คลิก "Import Git Repository"
3. เลือก repository ของคุณ
4. คลิก "Import"

#### 3. Configure Project

**Framework Preset**: Next.js (auto-detected)

**Root Directory**: `frontend`

**Build Command**: `npm run build`

**Output Directory**: `.next`

**Install Command**: `npm install`

#### 4. Environment Variables

เพิ่ม environment variables ต่อไปนี้:

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_API_URL` | `https://booboo-booking.onrender.com/api` |
| `BACKEND_URL` | `https://booboo-booking.onrender.com` |
| `NEXTAUTH_URL` | `https://your-app.vercel.app` (อัปเดตหลัง deploy) |
| `NEXTAUTH_SECRET` | `IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=` |
| `NODE_ENV` | `production` |

#### 5. Deploy

คลิก "Deploy" และรอ 2-3 นาที

---

## 🔗 เชื่อมต่อ Frontend ↔ Backend

### 1. อัปเดต NEXTAUTH_URL

หลัง deploy สำเร็จ คุณจะได้ URL เช่น: `https://hotel-booking-frontend.vercel.app`

**Vercel CLI**:
```bash
vercel env rm NEXTAUTH_URL production
vercel env add NEXTAUTH_URL production
# ใส่: https://hotel-booking-frontend.vercel.app

vercel --prod
```

**Vercel Dashboard**:
1. ไปที่ Project Settings → Environment Variables
2. แก้ไข `NEXTAUTH_URL` เป็น URL ที่ได้จาก deployment
3. Redeploy

### 2. อัปเดต CORS บน Backend (Render)

1. ไปที่ Render Dashboard: https://dashboard.render.com
2. เลือก Backend Service
3. ไปที่ Environment
4. แก้ไข `ALLOWED_ORIGINS`:
   ```
   https://hotel-booking-frontend.vercel.app,https://hotel-booking-frontend-*.vercel.app
   ```
5. Save Changes (Render จะ redeploy อัตโนมัติ)

---

## 🧪 ทดสอบการเชื่อมต่อ

### 1. ทดสอบ Backend Health

```bash
curl https://booboo-booking.onrender.com/api/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-11-04T..."
}
```

### 2. ทดสอบ Frontend → Backend

เปิด browser console บน frontend URL:

```javascript
fetch('https://booboo-booking.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log)
```

ถ้าเห็น response แสดงว่า CORS ตั้งค่าถูกต้อง ✅

### 3. ทดสอบ Authentication

1. เปิด https://hotel-booking-frontend.vercel.app
2. คลิก "Login"
3. ใส่ credentials:
   - Email: `admin@hotel.com`
   - Password: `admin123`
4. ถ้า login สำเร็จ แสดงว่าระบบทำงานถูกต้อง ✅

### 4. ทดสอบ Booking Flow

1. Search rooms
2. Select room
3. Fill guest info
4. Confirm booking
5. View booking confirmation

---

## 📊 Architecture Overview

```
User Browser
    ↓
Vercel CDN (Global)
    │
    ├─ Static Assets (HTML, CSS, JS)
    ├─ Next.js Server Components
    └─ Edge Functions
    ↓
    HTTPS + JWT + CORS
    ↓
Render (Singapore)
    │
    ├─ Go Backend API
    ├─ JWT Validation
    ├─ Rate Limiting
    └─ Business Logic
    ↓
    PostgreSQL Protocol
    ↓
Neon (Singapore)
    │
    ├─ PostgreSQL Database
    ├─ Connection Pooling
    └─ Serverless Scaling
```

---

## 🔐 Environment Variables Summary

### Frontend (Vercel)

```env
# API
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api
BACKEND_URL=https://booboo-booking.onrender.com

# Auth
NEXTAUTH_URL=https://hotel-booking-frontend.vercel.app
NEXTAUTH_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=

# Environment
NODE_ENV=production
NEXT_PUBLIC_DEBUG=false
```

### Backend (Render)

```env
# Database
DATABASE_URL=postgresql://...

# Server
PORT=8080
GIN_MODE=release
ENVIRONMENT=production

# Security
JWT_SECRET=<same-as-NEXTAUTH_SECRET>

# CORS (อัปเดตหลัง deploy frontend)
ALLOWED_ORIGINS=https://hotel-booking-frontend.vercel.app,https://hotel-booking-frontend-*.vercel.app

# Features
REDIS_ENABLED=false
RATE_LIMIT_ENABLED=true
```

---

## 🔄 Request Flow Example

### User searches for rooms

```
1. User Input (Browser)
   - Check-in: 2025-11-10
   - Check-out: 2025-11-12
   ↓
2. Frontend (Vercel)
   Component: SearchForm.tsx
   Hook: useRooms()
   API Call: api.get('/rooms/search', { params })
   ↓
3. Network Request
   GET https://booboo-booking.onrender.com/api/rooms/search
   Headers: {
     Authorization: "Bearer <jwt-token>",
     Origin: "https://hotel-booking-frontend.vercel.app"
   }
   ↓
4. Backend (Render)
   Middleware:
   - CORS check ✓ (origin allowed)
   - Rate limit ✓
   - JWT validation ✓
   
   Handler: room_handler.SearchRooms()
   Service: roomService.SearchAvailable()
   Repository: roomRepo.FindAvailable()
   ↓
5. Database (Neon)
   Query: SELECT rooms WHERE available
   ↓
6. Response
   JSON: [{ id, room_number, type, price }]
   ↓
7. Frontend Display
   Render room cards
```

---

## 🚨 Common Issues

### Issue 1: CORS Error

**Error**:
```
Access to fetch at 'https://booboo-booking.onrender.com' from origin 'https://hotel-booking-frontend.vercel.app' has been blocked by CORS policy
```

**Solution**:
1. ตรวจสอบ `ALLOWED_ORIGINS` บน Render
2. ต้องมี Vercel URL
3. Format: `https://hotel-booking-frontend.vercel.app,https://hotel-booking-frontend-*.vercel.app`
4. Redeploy backend

### Issue 2: 401 Unauthorized

**Error**:
```json
{"error": "unauthorized"}
```

**Solution**:
1. ตรวจสอบ `JWT_SECRET` ตรงกันทั้ง 2 ฝั่ง
2. ตรวจสอบ `NEXTAUTH_SECRET` ตรงกับ `JWT_SECRET`
3. Login ใหม่
4. Clear browser cache

### Issue 3: Build Failed

**Error**:
```
Error: Cannot find module 'next'
```

**Solution**:
1. ตรวจสอบ `package.json` มี dependencies ครบ
2. ตรวจสอบ Root Directory = `frontend`
3. ลอง redeploy

### Issue 4: Environment Variables Not Working

**Error**:
```
NEXT_PUBLIC_API_URL is undefined
```

**Solution**:
1. ตรวจสอบว่าตั้งค่าใน Vercel Dashboard แล้ว
2. Redeploy หลังเพิ่ม env vars
3. ตรวจสอบชื่อตัวแปรถูกต้อง (case-sensitive)

---

## 📝 Deployment Checklist

### Pre-Deployment
- [x] Backend deployed บน Render
- [ ] Database migrations รันสำเร็จ (ดู QUICK_FIX_RENDER.md)
- [x] Frontend code พร้อม
- [x] Environment variables เตรียมไว้แล้ว

### Deployment
- [ ] Deploy frontend บน Vercel
- [ ] ตั้งค่า environment variables
- [ ] อัปเดต NEXTAUTH_URL
- [ ] อัปเดต CORS บน backend

### Post-Deployment
- [ ] Health check ทำงาน
- [ ] CORS ไม่มี errors
- [ ] Authentication ทำงาน
- [ ] Booking flow ทำงาน
- [ ] All pages load correctly

---

## 🎯 Next Steps

### Immediate (หลัง deploy)
1. ทดสอบทุก features
2. ตรวจสอบ logs (Vercel + Render)
3. ทดสอบ performance

### Short-term (1-2 วัน)
1. Setup custom domain (optional)
2. Configure analytics
3. Setup error tracking (Sentry)
4. Performance optimization

### Long-term (1-2 สัปดาห์)
1. Setup CI/CD pipeline
2. Automated testing
3. Monitoring & alerts
4. Backup strategy

---

## 📚 Related Documentation

- [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) - แก้ไข database migrations
- [DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md) - Complete workflow
- [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) - Integration guide
- [คู่มือ_DEPLOY_PRODUCTION.md](คู่มือ_DEPLOY_PRODUCTION.md) - คู่มือภาษาไทย

---

## 🔗 Useful Links

- **Vercel Dashboard**: https://vercel.com/dashboard
- **Render Dashboard**: https://dashboard.render.com
- **Neon Dashboard**: https://console.neon.tech
- **Frontend URL**: https://hotel-booking-frontend.vercel.app (หลัง deploy)
- **Backend URL**: https://booboo-booking.onrender.com

---

**Created**: 2025-11-04  
**Status**: 🟡 Ready to deploy  
**Estimated Time**: 10-15 minutes
