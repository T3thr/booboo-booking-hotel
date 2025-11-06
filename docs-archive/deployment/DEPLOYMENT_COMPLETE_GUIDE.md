# 🎯 Complete Deployment Guide - Hotel Booking System

## 📊 Overview

ระบบ Hotel Booking ประกอบด้วย 3 ส่วนหลัก:

```
Frontend (Next.js) → Vercel
    ↓ HTTPS + JWT
Backend (Go) → Render
    ↓ PostgreSQL
Database → Neon
```

---

## 🚀 Quick Start (30 นาที)

### ขั้นตอนที่ 1: แก้ไข Database (5-10 นาที) ⚠️

```bash
# 1. Get DATABASE_URL from Render Dashboard
# 2. Set environment variable
set DATABASE_URL=postgresql://user:password@host:port/database

# 3. Run migrations
cd backend\scripts
run-migrations.bat
```

➡️ **[QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)**

---

### ขั้นตอนที่ 2: Deploy Frontend (10-15 นาที)

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
deploy-vercel.bat     # Windows
deploy-vercel.sh      # Linux/Mac
```

➡️ **[VERCEL_DEPLOYMENT_GUIDE.md](VERCEL_DEPLOYMENT_GUIDE.md)**

---

### ขั้นตอนที่ 3: เชื่อมต่อ (5 นาที)

```bash
# 1. Update NEXTAUTH_URL
vercel env add NEXTAUTH_URL production
# ใส่: https://your-app.vercel.app

# 2. Redeploy
vercel --prod

# 3. Update CORS on Render
# Dashboard → Environment → ALLOWED_ORIGINS
# Add: https://your-app.vercel.app
```

➡️ **[VERCEL_SETUP_CHECKLIST.md](VERCEL_SETUP_CHECKLIST.md)**

---

## 📚 เอกสารทั้งหมด

### 🎯 เริ่มต้นที่นี่
- **[START_DEPLOYMENT.md](START_DEPLOYMENT.md)** - เลือกเอกสารที่เหมาะกับคุณ

### 🚨 แก้ไขปัญหาด่วน
- **[QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)** - แก้ไข database migrations (5 นาที)

### 🚀 Deploy Frontend
- **[VERCEL_DEPLOYMENT_GUIDE.md](VERCEL_DEPLOYMENT_GUIDE.md)** - คู่มือ deploy Vercel
- **[VERCEL_SETUP_CHECKLIST.md](VERCEL_SETUP_CHECKLIST.md)** - Checklist ทีละขั้นตอน
- **[deploy-vercel.bat](deploy-vercel.bat)** / **[deploy-vercel.sh](deploy-vercel.sh)** - Scripts

### 📖 คู่มือฉบับสมบูรณ์
- **[คู่มือ_DEPLOY_PRODUCTION.md](คู่มือ_DEPLOY_PRODUCTION.md)** - คู่มือภาษาไทย
- **[DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md)** - Workflow ทั้งหมด
- **[RENDER_PRODUCTION_SETUP.md](RENDER_PRODUCTION_SETUP.md)** - Setup Render

### 🔗 Integration
- **[FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md)** - Integration guide
- **[FRONTEND_BACKEND_CONNECTION_VERIFIED.md](FRONTEND_BACKEND_CONNECTION_VERIFIED.md)** - Connection verification

### 📋 Summary & Reference
- **[PRODUCTION_DEPLOYMENT_SUMMARY.md](PRODUCTION_DEPLOYMENT_SUMMARY.md)** - สรุปสถานะ
- **[QUICK_REFERENCE_PRODUCTION.md](QUICK_REFERENCE_PRODUCTION.md)** - Quick reference
- **[RENDER_ENVIRONMENT_VARIABLES.md](RENDER_ENVIRONMENT_VARIABLES.md)** - Environment variables

---

## 🔄 Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    START HERE                                │
│              START_DEPLOYMENT.md                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Step 1: Fix Database                            │
│          QUICK_FIX_RENDER.md (5-10 min)                     │
│                                                              │
│  cd backend\scripts                                         │
│  run-migrations.bat                                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Step 2: Deploy Frontend                         │
│       VERCEL_DEPLOYMENT_GUIDE.md (10-15 min)               │
│                                                              │
│  npm install -g vercel                                      │
│  vercel login                                               │
│  deploy-vercel.bat                                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Step 3: Connect & Configure                     │
│        VERCEL_SETUP_CHECKLIST.md (5 min)                   │
│                                                              │
│  1. Update NEXTAUTH_URL                                     │
│  2. Update CORS on Render                                   │
│  3. Test connection                                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Step 4: Test & Verify                           │
│                                                              │
│  ✅ Health check                                            │
│  ✅ Authentication                                          │
│  ✅ Booking flow                                            │
│  ✅ All features                                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    SUCCESS! 🎉                              │
│                                                              │
│  Frontend: https://your-app.vercel.app                      │
│  Backend:  https://booboo-booking.onrender.com             │
│  Status:   Production Ready ✅                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Browser                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Vercel CDN (Global)                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Next.js 14 Frontend                                 │  │
│  │  - Server Components                                 │  │
│  │  - Client Components                                 │  │
│  │  - Static Generation                                 │  │
│  │  - Edge Functions                                    │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS + JWT + CORS
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Render (Singapore)                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Go Backend (Gin)                                    │  │
│  │  - RESTful API                                       │  │
│  │  - JWT Authentication                                │  │
│  │  - Rate Limiting                                     │  │
│  │  - Background Jobs                                   │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ PostgreSQL Protocol
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Neon (Singapore)                                │
│  - PostgreSQL 15+                                           │
│  - Serverless                                                │
│  - Connection Pooling                                        │
│  - Auto-scaling                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Environment Variables

### Frontend (Vercel)

```env
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api
BACKEND_URL=https://booboo-booking.onrender.com
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=<32-char-secret>
NODE_ENV=production
```

### Backend (Render)

```env
DATABASE_URL=postgresql://...
PORT=8080
GIN_MODE=release
JWT_SECRET=<same-as-NEXTAUTH_SECRET>
ALLOWED_ORIGINS=https://your-app.vercel.app
REDIS_ENABLED=false
RATE_LIMIT_ENABLED=true
```

---

## 🧪 Testing Checklist

### Backend
- [ ] Health check: `curl https://booboo-booking.onrender.com/api/health`
- [ ] No errors in logs
- [ ] All migrations executed
- [ ] Database functions exist

### Frontend
- [ ] Homepage loads
- [ ] No console errors
- [ ] All pages accessible
- [ ] Build successful

### Integration
- [ ] CORS no errors
- [ ] Authentication works
- [ ] API calls successful
- [ ] Booking flow works

---

## 🚨 Troubleshooting

### CORS Error
```
Access blocked by CORS policy
```
**Fix**: Update `ALLOWED_ORIGINS` on Render

### 401 Unauthorized
```
{"error": "unauthorized"}
```
**Fix**: Check `JWT_SECRET` matches `NEXTAUTH_SECRET`

### Function Not Found
```
function release_expired_holds() does not exist
```
**Fix**: Run migrations ([QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md))

### Build Failed
```
Error: Cannot find module
```
**Fix**: Check `package.json` and dependencies

---

## 📈 Timeline

```
Total Time: ~30 minutes

Step 1: Fix Database        → 5-10 min
Step 2: Deploy Frontend     → 10-15 min
Step 3: Connect & Configure → 5 min
Step 4: Test & Verify       → 5-10 min
```

---

## 🎯 Success Criteria

เมื่อ deployment สำเร็จ:

### ✅ Backend (Render)
- Service running
- No errors in logs
- Health check returns 200
- All migrations executed

### ✅ Frontend (Vercel)
- Build successful
- All pages load
- API connection works
- No console errors

### ✅ Integration
- CORS configured
- Authentication works
- Booking flow works
- All features functional

---

## 📞 Support

### ปัญหาเกี่ยวกับ Backend
- ดู [backend/README.md](backend/README.md)
- ตรวจสอบ Render logs
- อ่าน [RENDER_PRODUCTION_SETUP.md](RENDER_PRODUCTION_SETUP.md)

### ปัญหาเกี่ยวกับ Frontend
- ดู [frontend/README.md](frontend/README.md)
- ตรวจสอบ Vercel logs
- อ่าน [VERCEL_DEPLOYMENT_GUIDE.md](VERCEL_DEPLOYMENT_GUIDE.md)

### ปัญหาเกี่ยวกับ Integration
- อ่าน [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md)
- ตรวจสอบ CORS configuration
- ตรวจสอบ environment variables

---

## 🔗 Useful Links

- **Vercel Dashboard**: https://vercel.com/dashboard
- **Render Dashboard**: https://dashboard.render.com
- **Neon Dashboard**: https://console.neon.tech
- **Frontend URL**: https://your-app.vercel.app (หลัง deploy)
- **Backend URL**: https://booboo-booking.onrender.com
- **API Docs**: [backend/docs/swagger.yaml](backend/docs/swagger.yaml)

---

**Created**: 2025-11-04  
**Last Updated**: 2025-11-04  
**Status**: 🟡 Ready to deploy  
**Estimated Time**: 30 minutes
