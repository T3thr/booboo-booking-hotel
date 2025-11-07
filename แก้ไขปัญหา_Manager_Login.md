# 🔧 แก้ไขปัญหา Manager Login บน Vercel

## 📌 ปัญหา
เมื่อ Manager login บน Vercel มัน redirect ไป:
```
https://booboo-booking.vercel.app/auth/signin?callbackUrl=%2Fadmin%2Fdashboard
```
และค้างไม่สามารถเข้า dashboard ได้

## ✅ สาเหตุและการแก้ไข

### 1. NEXTAUTH_URL ไม่ถูกต้อง
**ปัญหา:** ใน `.env.production` ยังเป็น placeholder
**แก้ไข:** อัปเดตเป็น `https://booboo-booking.vercel.app`

### 2. Redirect Callback ไม่ทำงาน
**ปัญหา:** NextAuth ไม่ได้จัดการ callbackUrl parameter
**แก้ไข:** ปรับปรุง redirect callback ใน `auth.ts`

### 3. Redirect Loop
**ปัญหา:** Admin layout และ middleware redirect ซ้ำซ้อน
**แก้ไข:** ใช้ `router.replace()` แทน `router.push()`

## 🚀 วิธีแก้ไข (ทำตามขั้นตอน)

### ขั้นตอนที่ 1: ตั้งค่า Environment Variables บน Vercel

1. เข้า **Vercel Dashboard**: https://vercel.com/dashboard
2. เลือก project **booboo-booking**
3. ไปที่ **Settings** → **Environment Variables**
4. เพิ่ม/แก้ไข variables ต่อไปนี้:

```bash
NEXTAUTH_URL=https://booboo-booking.vercel.app
NEXTAUTH_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com
BACKEND_URL=https://booboo-booking.onrender.com
NODE_ENV=production
NEXT_PUBLIC_DEBUG=false
NEXT_PUBLIC_LOG_API=false
```

5. คลิก **Save**

### ขั้นตอนที่ 2: Deploy โค้ดใหม่

```bash
# ใน terminal
git add .
git commit -m "fix: แก้ไขปัญหา manager login redirect"
git push origin main
```

Vercel จะ auto-deploy ภายใน 1-2 นาที

### ขั้นตอนที่ 3: ทดสอบ

1. ไปที่: https://booboo-booking.vercel.app/auth/admin
2. Login ด้วย:
   - Email: `manager@hotel.com`
   - Password: `Manager123!`
3. ควร redirect ไป `/admin/dashboard` ทันที

## 📝 ไฟล์ที่แก้ไข

- ✅ `frontend/src/lib/auth.ts` - NextAuth redirect callback
- ✅ `frontend/src/middleware.ts` - Middleware redirect logic
- ✅ `frontend/src/app/auth/admin/page.tsx` - Admin login page
- ✅ `frontend/src/app/admin/layout.tsx` - Admin layout
- ✅ `frontend/.env.production` - Environment variables

## 🧪 การทดสอบ

### ทดสอบ Manager
```
URL: /auth/admin
Email: manager@hotel.com
Password: Manager123!
Expected: Redirect to /admin/dashboard
```

### ทดสอบ Receptionist
```
URL: /auth/admin
Email: receptionist@hotel.com
Password: Receptionist123!
Expected: Redirect to /admin/reception
```

### ทดสอบ Housekeeper
```
URL: /auth/admin
Email: housekeeper@hotel.com
Password: Housekeeper123!
Expected: Redirect to /admin/housekeeping
```

## 🔍 ตรวจสอบว่าแก้ไขสำเร็จ

เปิด Browser DevTools (F12) → Console tab

ควรเห็น logs:
```
[Admin Login] Valid staff role: MANAGER redirecting to: /admin/dashboard
[Middleware] User role: MANAGER
[Middleware] Access granted
```

## ⚠️ หากยังมีปัญหา

### ลอง Clear Cache
1. กด `Ctrl + Shift + Delete`
2. เลือก "Cached images and files" และ "Cookies"
3. Clear data
4. ลอง login ใหม่

### ลอง Incognito Mode
1. เปิด browser ใน Incognito/Private mode
2. ทดสอบ login อีกครั้ง

### ตรวจสอบ Vercel Logs
1. ไปที่ Vercel Dashboard
2. เลือก **Deployments**
3. คลิกที่ deployment ล่าสุด
4. คลิก **View Function Logs**
5. ดู error messages

## 📚 เอกสารเพิ่มเติม

- `frontend/VERCEL_REDIRECT_FIX.md` - รายละเอียดการแก้ไขแบบเต็ม
- `frontend/DEPLOY_CHECKLIST.md` - Checklist การ deploy
- `VERCEL_FIX_SUMMARY.md` - สรุปแบบสั้น

## 🎯 สรุป

**สิ่งสำคัญที่สุด:**
1. ✅ ตั้งค่า `NEXTAUTH_URL=https://booboo-booking.vercel.app` บน Vercel
2. ✅ Deploy โค้ดใหม่
3. ✅ ทดสอบ login

หลังจากทำตามขั้นตอนนี้ Manager จะสามารถ login และเข้า dashboard ได้ทันทีโดยไม่ค้าง! 🎉
