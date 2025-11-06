# ⚡ Commands Quick Reference

## 🚨 แก้ไข Database Migrations (ด่วน!)

```bash
# Windows
set DATABASE_URL=postgresql://user:password@host:port/database
cd backend\scripts
run-migrations.bat

# Linux/Mac
export DATABASE_URL=postgresql://user:password@host:port/database
cd backend/scripts
./run-migrations.sh
```

---

## 🚀 Deploy Frontend บน Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy (Option 1: Use script)
deploy-vercel.bat     # Windows
./deploy-vercel.sh    # Linux/Mac

# Deploy (Option 2: Manual)
cd frontend
vercel --prod
```

---

## 🔧 ตั้งค่า Environment Variables

```bash
# NEXT_PUBLIC_API_URL
vercel env add NEXT_PUBLIC_API_URL production
# ใส่: https://booboo-booking.onrender.com/api

# BACKEND_URL
vercel env add BACKEND_URL production
# ใส่: https://booboo-booking.onrender.com

# NEXTAUTH_URL
vercel env add NEXTAUTH_URL production
# ใส่: https://your-app.vercel.app

# NEXTAUTH_SECRET
vercel env add NEXTAUTH_SECRET production
# ใส่: IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=

# NODE_ENV
vercel env add NODE_ENV production
# ใส่: production

# Redeploy
vercel --prod
```

---

## 🧪 ทดสอบ Backend

```bash
# Health check
curl https://booboo-booking.onrender.com/api/health

# Search rooms
curl "https://booboo-booking.onrender.com/api/rooms/available?check_in=2025-11-10&check_out=2025-11-12"

# Login
curl -X POST https://booboo-booking.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hotel.com","password":"admin123"}'
```

---

## 🧪 ทดสอบ Frontend → Backend

```javascript
// Browser console บน frontend URL
fetch('https://booboo-booking.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log)

// Expected: { status: "ok", timestamp: "..." }
```

---

## 🔄 อัปเดต CORS บน Render

```
1. ไปที่: https://dashboard.render.com
2. เลือก: Backend Service
3. ไปที่: Environment
4. แก้ไข: ALLOWED_ORIGINS
5. ใส่: https://your-app.vercel.app,https://your-app-*.vercel.app
6. Save Changes
```

---

## 📊 ตรวจสอบสถานะ

```bash
# Vercel
vercel ls                    # List deployments
vercel env ls                # List environment variables
vercel logs                  # View logs

# Render (ผ่าน Dashboard)
# https://dashboard.render.com → Service → Logs
```

---

## 🔐 สร้าง Secrets

```bash
# Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))

# Linux/Mac
openssl rand -base64 32

# Online
# https://generate-secret.vercel.app/32
```

---

## 🗑️ ลบและสร้างใหม่

```bash
# Remove environment variable
vercel env rm NEXTAUTH_URL production

# Add new value
vercel env add NEXTAUTH_URL production

# Redeploy
vercel --prod
```

---

## 📝 Git Commands

```bash
# Commit changes
git add .
git commit -m "Deploy to production"
git push origin main

# Vercel auto-deploys on push (if configured)
```

---

## 🔗 URLs

```
Frontend:  https://your-app.vercel.app
Backend:   https://booboo-booking.onrender.com
API:       https://booboo-booking.onrender.com/api
Health:    https://booboo-booking.onrender.com/api/health

Dashboards:
- Vercel:  https://vercel.com/dashboard
- Render:  https://dashboard.render.com
- Neon:    https://console.neon.tech
```

---

## 📚 Documentation

```
START_DEPLOYMENT.md              - เริ่มต้นที่นี่
QUICK_FIX_RENDER.md             - แก้ไขปัญหาด่วน
VERCEL_DEPLOYMENT_GUIDE.md      - Deploy frontend
VERCEL_SETUP_CHECKLIST.md       - Checklist
DEPLOYMENT_COMPLETE_GUIDE.md    - คู่มือรวม
```

---

**Last Updated**: 2025-11-04
