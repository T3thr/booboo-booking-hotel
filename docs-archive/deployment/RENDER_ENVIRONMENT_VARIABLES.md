# 🔧 Render Environment Variables Setup

> **ตั้งค่า Environment Variables ใน Render Dashboard**

## 📋 Required Environment Variables

ไปที่ Render Dashboard → Your Service → Environment → Add Environment Variable

### 1. Database Configuration
```bash
DATABASE_URL=postgresql://your_neon_connection_string_here
```
**ตัวอย่าง:**
```bash
DATABASE_URL=postgresql://neondb_owner:npg_xxx@ep-xxx-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
```

### 2. Server Configuration
```bash
PORT=8080
GIN_MODE=release
```

### 3. JWT Security
```bash
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-min-32-chars
```

### 4. CORS Configuration
```bash
FRONTEND_URL=https://your-frontend.vercel.app
ALLOWED_ORIGINS=https://your-frontend.vercel.app
```

### 5. Redis (Optional - ปิดไว้ก่อน)
```bash
# REDIS_URL=  # ปล่อยว่างหรือไม่ต้องใส่
```

## 🚀 Quick Setup Commands

### Copy ค่าเหล่านี้ไปใส่ใน Render:

```bash
# Database (แทนที่ด้วย Neon connection string จริง)
DATABASE_URL=postgresql://neondb_owner:npg_xxx@ep-xxx-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require

# Server
PORT=8080
GIN_MODE=release

# Security (สร้าง JWT secret ใหม่)
JWT_SECRET=hotel-booking-system-super-secret-jwt-key-2025-production-min-32-characters

# CORS (จะอัปเดตหลัง deploy frontend)
FRONTEND_URL=https://your-frontend.vercel.app
ALLOWED_ORIGINS=https://your-frontend.vercel.app
```

## 📝 Steps to Apply

1. **ไปที่ Render Dashboard**
   - https://dashboard.render.com
   - เลือก service ของคุณ

2. **ไปที่ Environment tab**
   - คลิก "Environment" ในเมนูซ้าย

3. **เพิ่ม Environment Variables**
   - คลิก "Add Environment Variable"
   - ใส่ Key และ Value ตามด้านบน
   - คลิก "Save Changes"

4. **Redeploy Service**
   - คลิก "Manual Deploy" → "Deploy latest commit"
   - รอ 2-3 นาที

## ✅ Verification

หลัง redeploy ให้ตรวจสอบ logs:

```bash
# ควรเห็น logs แบบนี้:
✅ Configuration loaded successfully
✅ Database connection established  
✅ Night audit scheduler started successfully
✅ Hold cleanup scheduler started successfully
✅ Starting server on 0.0.0.0:8080 (mode: release)
```

## 🔗 Next Steps

1. **รัน Database Migrations**
   - เปิด Neon Console: https://console.neon.tech
   - ไปที่ SQL Editor
   - รันไฟล์ `fix-production-database.sql`

2. **Test API Endpoints**
   ```bash
   curl https://booboo-booking.onrender.com/health
   curl https://booboo-booking.onrender.com/api/health
   ```

3. **Deploy Frontend**
   - Deploy ไปยัง Vercel
   - อัปเดต CORS settings ใน Render