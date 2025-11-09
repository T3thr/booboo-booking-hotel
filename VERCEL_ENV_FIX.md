# แก้ไข Vercel Environment Variables

## 🔴 ปัญหา

- **Browser Console**: Error 500
- **Render Logs**: ไม่มี error
- **สาเหตุ**: Frontend (Vercel) ไม่สามารถเชื่อมต่อ Backend (Render) ได้

## 🔍 การวินิจฉัย

Error ใน browser แต่ไม่มีใน backend logs = **Frontend API routes มีปัญหา**

**สาเหตุที่เป็นไปได้:**
1. `BACKEND_URL` ไม่ถูกต้องใน Vercel
2. `BACKEND_URL` ไม่ได้ตั้งค่าใน Vercel
3. CORS ไม่อนุญาต Vercel URL

## ✅ วิธีแก้ไข

### Step 1: ตรวจสอบ Vercel Environment Variables

1. เข้า https://vercel.com/dashboard
2. เลือก project: **booboo-booking**
3. Settings → **Environment Variables**

### Step 2: ตรวจสอบ/เพิ่ม Variables

**ต้องมีทั้งหมดนี้:**

```bash
# Backend URL (สำคัญมาก!)
BACKEND_URL=https://booboo-booking.onrender.com
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com

# NextAuth
NEXTAUTH_URL=https://booboo-booking.vercel.app
NEXTAUTH_SECRET=your-secret-at-least-32-chars

# Node Environment
NODE_ENV=production
```

**⚠️ สำคัญ:**
- ไม่มี `/` ท้าย URL
- ไม่มี `/api` ต่อท้าย
- ใช้ `https://` ไม่ใช่ `http://`
- ไม่มีช่องว่าง

### Step 3: ตั้งค่า Environment Scope

**สำหรับแต่ละ variable:**
- ✅ Production
- ✅ Preview
- ✅ Development

### Step 4: Redeploy

หลังจากเพิ่ม/แก้ไข environment variables:

1. ไปที่ **Deployments** tab
2. เลือก deployment ล่าสุด
3. คลิก **"..."** (three dots)
4. เลือก **"Redeploy"**
5. รอ 1-2 นาที

## 🧪 วิธีทดสอบ

### Test 1: ตรวจสอบ Environment Variables

เปิด browser console และรัน:

```javascript
// ใน production site
fetch('/api/test-env')
  .then(r => r.json())
  .then(console.log)
```

**Expected:**
```json
{
  "BACKEND_URL": "https://booboo-booking.onrender.com",
  "NEXT_PUBLIC_API_URL": "https://booboo-booking.onrender.com"
}
```

### Test 2: ทดสอบ Backend Connection

```javascript
// ทดสอบเชื่อมต่อ backend
fetch('https://booboo-booking.onrender.com/health')
  .then(r => r.json())
  .then(console.log)
```

**Expected:**
```json
{
  "status": "ok"
}
```

### Test 3: ทดสอบ Approve API

1. Login as manager
2. เปิด browser console
3. ทดสอบ approve:

```javascript
fetch('/api/admin/payment-proofs/32/approve', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(r => r.json())
.then(console.log)
```

## 🔧 Common Issues

### Issue 1: BACKEND_URL ไม่ถูกต้อง

**Error**: `fetch failed` หรือ `ENOTFOUND`

**Fix**:
```bash
# ตรวจสอบ URL ถูกต้อง
BACKEND_URL=https://booboo-booking.onrender.com

# ไม่ใช่:
BACKEND_URL=http://booboo-booking.onrender.com  # ❌ http
BACKEND_URL=https://booboo-booking.onrender.com/  # ❌ มี /
BACKEND_URL=https://booboo-booking.onrender.com/api  # ❌ มี /api
```

### Issue 2: Environment Variables ไม่ถูก Load

**Error**: `undefined` หรือ `localhost:8080`

**Fix**:
1. ตรวจสอบ variable name ถูกต้อง
2. ตรวจสอบ scope (Production/Preview/Development)
3. **Redeploy** หลังเพิ่ม variables

### Issue 3: CORS Error

**Error**: `CORS policy blocked`

**Fix**:
1. ตรวจสอบ Backend (Render) มี `ALLOWED_ORIGINS`
2. ต้องมี: `https://booboo-booking.vercel.app`
3. Redeploy backend

## 📋 Checklist

### Vercel Environment Variables
- [ ] `BACKEND_URL` = https://booboo-booking.onrender.com
- [ ] `NEXT_PUBLIC_API_URL` = https://booboo-booking.onrender.com
- [ ] `NEXTAUTH_URL` = https://booboo-booking.vercel.app
- [ ] `NEXTAUTH_SECRET` = (at least 32 chars)
- [ ] `NODE_ENV` = production
- [ ] ทุก variable มี scope: Production ✓

### Render Environment Variables
- [ ] `ALLOWED_ORIGINS` มี Vercel URL
- [ ] `DATABASE_URL` ถูกต้อง
- [ ] `JWT_SECRET` ตั้งค่าแล้ว
- [ ] `PORT` = 8080

### Deployment
- [ ] Vercel redeploy หลังเพิ่ม env vars
- [ ] Render redeploy (ถ้าแก้ ALLOWED_ORIGINS)
- [ ] รอ 2-3 นาที
- [ ] ทดสอบ approve booking
- [ ] ทดสอบ admin/checkin

## 🚨 ถ้ายังไม่ได้

### 1. ตรวจสอบ Vercel Function Logs

1. Vercel Dashboard → Project
2. Deployments → Latest
3. **Function Logs**
4. ดู error messages

### 2. ตรวจสอบ Network Tab

1. เปิด browser DevTools (F12)
2. Network tab
3. ทดสอบ approve booking
4. ดู request/response

**ดูที่:**
- Request URL: ต้องเป็น Render URL
- Request Headers: ต้องมี Authorization
- Response: ดู error message

### 3. สร้าง Test Endpoint

สร้างไฟล์ `frontend/src/app/api/test-env/route.ts`:

```typescript
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    BACKEND_URL: process.env.BACKEND_URL,
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXTAUTH_URL: process.env.NEXTAUTH_URL,
    NODE_ENV: process.env.NODE_ENV,
  });
}
```

Deploy และเข้า: `https://booboo-booking.vercel.app/api/test-env`

## 📝 สรุป

### ปัญหา
- Error ใน browser console
- ไม่มี error ใน Render logs
- = Frontend ไม่เชื่อมต่อ Backend ได้

### สาเหตุ
- `BACKEND_URL` ไม่ถูกต้องใน Vercel

### วิธีแก้
1. ตั้งค่า `BACKEND_URL` ใน Vercel
2. Redeploy Vercel
3. ทดสอบ

---

**สร้างเมื่อ**: 9 พฤศจิกายน 2025  
**สถานะ**: ✅ พร้อมแก้ไข
