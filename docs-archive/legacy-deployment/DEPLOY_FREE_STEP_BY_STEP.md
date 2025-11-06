# 🆓 Deploy ฟรี 100% - Step by Step Guide

## 🎯 ภาพรวม
- **Frontend**: Render Static Site (ฟรี)
- **Backend**: Render Web Service (ฟรี 750 ชม./เดือน)
- **Database**: Neon PostgreSQL (ฟรี 512MB)
- **ค่าใช้จ่าย**: **$0** 🎉

---

## 📋 ขั้นตอนที่ 1: เตรียม GitHub Repository

### 1.1 Push Code ไป GitHub
```bash
# รันคำสั่งนี้
prepare-github.bat

# หรือทำเอง:
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/hotel-booking-system.git
git push -u origin main
```

### 1.2 ตรวจสอบ Repository
- ✅ Code ทั้งหมดอยู่บน GitHub
- ✅ มี folder `backend/` และ `frontend/`
- ✅ มีไฟล์ `render.yaml`

---

## 📋 ขั้นตอนที่ 2: สร้าง Database ฟรีบน Neon

### 2.1 สร้างบัญชี Neon
1. ไปที่ [console.neon.tech](https://console.neon.tech)
2. คลิก **Sign Up** (ใช้ GitHub account)
3. ยืนยัน email

### 2.2 สร้าง Database
1. คลิก **Create Project**
2. ตั้งชื่อ: `hotel-booking-db`
3. เลือก Region ใกล้ที่สุด
4. คลิก **Create Project**

### 2.3 คัดลอก Connection String
1. ไปที่ **Dashboard**
2. คลิก **Connection Details**
3. เลือก **Pooled connection**
4. คัดลอก URL ทั้งหมด:
   ```
   postgresql://username:password@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
   ```

---

## 📋 ขั้นตอนที่ 3: Deploy Backend บน Render

### 3.1 สร้างบัญชี Render
1. ไปที่ [render.com](https://render.com)
2. คลิก **Get Started for Free**
3. เชื่อมต่อ GitHub account

### 3.2 Deploy Backend
1. คลิก **New +** → **Web Service**
2. เลือก GitHub repository ที่สร้าง
3. ตั้งค่า:
   - **Name**: `hotel-booking-backend`
   - **Root Directory**: `backend`
   - **Environment**: `Go`
   - **Build Command**: `go build -o main ./cmd/server`
   - **Start Command**: `./main`

### 3.3 ตั้งค่า Environment Variables
คลิก **Advanced** → **Add Environment Variable**:

```bash
DATABASE_URL=postgresql://username:password@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
PORT=8080
GIN_MODE=release
ENVIRONMENT=production
JWT_SECRET=your-32-character-secret-key-here
```

### 3.4 สร้าง JWT Secret
```bash
# Windows PowerShell
$bytes = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes); [Convert]::ToBase64String($bytes)

# หรือใช้เว็บ: https://generate-secret.vercel.app/32
```

### 3.5 Deploy
1. คลิก **Create Web Service**
2. รอ 5-10 นาที
3. คัดลอก URL: `https://hotel-booking-backend.onrender.com`

---

## 📋 ขั้นตอนที่ 4: Deploy Frontend บน Render

### 4.1 Deploy Frontend
1. คลิก **New +** → **Static Site**
2. เลือก repository เดียวกัน
3. ตั้งค่า:
   - **Name**: `hotel-booking-frontend`
   - **Root Directory**: `frontend`
   - **Build Command**: `npm ci && npm run build && npm run export`
   - **Publish Directory**: `out`

### 4.2 ตั้งค่า Environment Variables
```bash
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://hotel-booking-backend.onrender.com/api
NEXTAUTH_SECRET=your-nextauth-secret-here
NEXTAUTH_URL=https://hotel-booking-frontend.onrender.com
```

### 4.3 Deploy
1. คลิก **Create Static Site**
2. รอ 3-5 นาที
3. คัดลอก URL: `https://hotel-booking-frontend.onrender.com`

---

## 📋 ขั้นตอนที่ 5: ตั้งค่า CORS

### 5.1 อัพเดท Backend Environment
1. ไปที่ Backend service ใน Render
2. คลิก **Environment**
3. เพิ่ม/แก้ไข:
   ```bash
   ALLOWED_ORIGINS=https://hotel-booking-frontend.onrender.com
   FRONTEND_URL=https://hotel-booking-frontend.onrender.com
   ```

### 5.2 Redeploy Backend
1. คลิก **Manual Deploy** → **Deploy latest commit**
2. รอ 3-5 นาที

---

## 📋 ขั้นตอนที่ 6: Setup Database Schema

### 6.1 Push Database Schema
```bash
cd frontend

# สร้าง .env.local
echo "DATABASE_URL=postgresql://username:password@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require" > .env.local

# Push schema
npm run db:push

# Seed data (optional)
npm run db:seed
```

---

## ✅ ทดสอบการทำงาน

### 6.1 ทดสอบ Backend
```bash
# Health check
curl https://hotel-booking-backend.onrender.com/health

# API endpoint
curl https://hotel-booking-backend.onrender.com/api/auth/health
```

### 6.2 ทดสอบ Frontend
1. เปิด `https://hotel-booking-frontend.onrender.com`
2. ตรวจสอบ:
   - ✅ หน้าเว็บโหลดได้
   - ✅ ไม่มี CORS error ใน Console
   - ✅ API calls ทำงาน

---

## 🎉 เสร็จสิ้น!

### URLs ที่ได้:
- 🌐 **Frontend**: https://hotel-booking-frontend.onrender.com
- 🔧 **Backend**: https://hotel-booking-backend.onrender.com
- 🗄️ **Database**: Neon Console

### ข้อมูลสำคัญ:
- ✅ **ฟรี 100%** - ไม่เสียเงินเลย
- ✅ **Auto-deploy** - Push code ใหม่จะ deploy อัตโนมัติ
- ✅ **HTTPS** - SSL ฟรีอัตโนมัติ
- ✅ **Custom Domain** - ตั้งได้ฟรี

---

## 🔧 การจัดการหลัง Deploy

### Auto-Deploy
- Push ไปยัง `main` branch → Auto deploy
- ดู deployment logs ใน Render dashboard

### Monitoring
- **Render**: Dashboard → Services → Logs
- **Neon**: Console → Monitoring

### Scaling
- **Render Free**: 750 ชั่วโมง/เดือน
- **Neon Free**: 512MB storage
- **Upgrade**: เมื่อต้องการ performance มากขึ้น

---

## 🚨 Troubleshooting

### ❌ Backend Build Failed
```bash
# ตรวจสอบ Go version
go version

# ทดสอบ build local
cd backend
go mod tidy
go build ./cmd/server
```

### ❌ Frontend Build Failed
```bash
# ตรวจสอบ dependencies
cd frontend
npm ci
npm run build
```

### ❌ Database Connection Failed
- ตรวจสอบ `DATABASE_URL` ใน Environment Variables
- ใช้ **Pooled connection** จาก Neon
- ตรวจสอบว่ามี `?sslmode=require`

### ❌ CORS Error
- ตรวจสอบ `ALLOWED_ORIGINS` ใน Backend
- ตรวจสอบ `NEXT_PUBLIC_API_URL` ใน Frontend
- Redeploy Backend หลังแก้ไข

---

## 💡 Tips สำหรับ Production

### Performance
- Render free tier มี cold start ~30 วินาที
- ใช้ health check endpoint เพื่อ keep warm
- Optimize bundle size

### Security
- ใช้ strong JWT secrets
- Enable rate limiting
- Monitor access logs

### Backup
- Neon มี auto backup
- Export data เป็นประจำ
- Test restore procedures

---

**🎯 ตอนนี้คุณมี Hotel Booking System ที่ deploy แล้วและใช้งานได้ฟรี!**