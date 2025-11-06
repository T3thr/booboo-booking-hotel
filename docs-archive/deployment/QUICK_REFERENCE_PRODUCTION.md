# ⚡ Quick Reference - Production

## 🔗 URLs

```
Backend:  https://booboo-booking.onrender.com
Frontend: https://your-app.vercel.app (หลัง deploy)
Database: Neon PostgreSQL (External)
```

---

## 🚨 แก้ไขปัญหาด่วน (5 นาที)

```bash
# 1. Get DATABASE_URL from Render Dashboard
# 2. Set env var
set DATABASE_URL=postgresql://user:password@host:port/database

# 3. Run migrations
cd backend\scripts
run-migrations.bat
```

**อ่านเพิ่ม**: [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md)

---

## 🚀 Deploy Frontend (5 นาที)

```bash
npm install -g vercel
vercel login
cd frontend
vercel --prod

# Set env vars
vercel env add NEXT_PUBLIC_API_URL production
# → https://booboo-booking.onrender.com/api

vercel env add NEXTAUTH_URL production
# → https://your-app.vercel.app

vercel env add NEXTAUTH_SECRET production
# → <random-32-chars>
```

---

## 🔧 Environment Variables

### Backend (Render)
```env
DATABASE_URL=postgresql://...
PORT=8080
GIN_MODE=release
JWT_SECRET=<secret>
ALLOWED_ORIGINS=https://your-app.vercel.app
```

### Frontend (Vercel)
```env
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com/api
NEXTAUTH_URL=https://your-app.vercel.app
NEXTAUTH_SECRET=<secret>
```

---

## 🧪 Test Commands

```bash
# Backend health
curl https://booboo-booking.onrender.com/api/health

# Search rooms
curl "https://booboo-booking.onrender.com/api/rooms/available?check_in=2025-11-10&check_out=2025-11-12"

# Login
curl -X POST https://booboo-booking.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## 📊 API Endpoints

### Public
```
GET  /api/health
GET  /api/rooms/types
GET  /api/rooms/available
POST /api/auth/login
POST /api/auth/register
```

### Protected (+ JWT)
```
POST   /api/bookings/hold
POST   /api/bookings/confirm
GET    /api/bookings
DELETE /api/bookings/:id
```

---

## 🚨 Common Errors

| Error | Solution |
|-------|----------|
| `function does not exist` | Run migrations |
| `blocked by CORS` | Update ALLOWED_ORIGINS |
| `unauthorized` | Check JWT token |
| `connection refused` | Check service status |

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [QUICK_FIX_RENDER.md](QUICK_FIX_RENDER.md) | Fix migrations (5 min) |
| [คู่มือ_DEPLOY_PRODUCTION.md](คู่มือ_DEPLOY_PRODUCTION.md) | คู่มือภาษาไทย |
| [DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md) | Complete workflow |
| [FRONTEND_BACKEND_INTEGRATION.md](FRONTEND_BACKEND_INTEGRATION.md) | Integration guide |

---

## ⏱️ Timeline

```
Now:     Fix migrations (5 min)
+10 min: Deploy frontend (5 min)
+15 min: Connect & test (5 min)
+30 min: Done! ✅
```

---

## 🎯 Checklist

```
[ ] Migrations รันสำเร็จ
[ ] Frontend deployed
[ ] CORS configured
[ ] Health check OK
[ ] Auth works
[ ] Booking works
```

---

**Status**: 🟡 Backend OK, Migrations pending  
**Priority**: 🚨 Fix migrations first!
