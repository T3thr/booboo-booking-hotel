# Vercel Environment Variables Checklist

## ✅ Required Environment Variables for Vercel

ตรวจสอบว่าใน Vercel Dashboard → Settings → Environment Variables มีค่าเหล่านี้:

### 1. API Configuration
```
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com
BACKEND_URL=https://booboo-booking.onrender.com
```

### 2. NextAuth Configuration
```
NEXTAUTH_URL=https://booboo-booking.vercel.app
NEXTAUTH_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=
AUTH_TRUST_HOST=true
```

### 3. Environment
```
NODE_ENV=production
```

### 4. Optional Debug (ปิดใน production)
```
NEXT_PUBLIC_DEBUG=false
NEXT_PUBLIC_LOG_API=false
```

## 🔧 สาเหตุของ Redirect Loop

### ปัญหาที่พบ:
1. **Admin Layout** redirect ไปที่ `/auth/admin?callbackUrl=/admin/dashboard`
2. **Admin Login Page** detect ว่า user authenticated แล้ว redirect กลับไปที่ `/admin/dashboard`
3. **Session ยังไม่ sync** ใน production (network latency) ทำให้ layout คิดว่า unauthenticated
4. **Loop เกิดขึ้น** เพราะ redirect ไปมาระหว่าง 2 หน้า

### การแก้ไข:
1. ✅ **ลบ callbackUrl** ออกจาก admin layout redirect
2. ✅ **เพิ่ม hasRedirected state** เพื่อป้องกัน multiple redirects
3. ✅ **เพิ่ม delay 100ms** ก่อน redirect เพื่อให้ session sync
4. ✅ **เพิ่ม console.log** เพื่อ debug ใน production

## 🧪 วิธีทดสอบ

### Local Testing:
```bash
cd frontend
npm run build
npm run start
```

### Production Testing:
1. Deploy to Vercel
2. เปิด Browser Console (F12)
3. ลอง login ด้วย manager account
4. ดู console logs:
   - `[Admin Login] Already authenticated as staff, redirecting to: /admin/dashboard`
   - `[Admin Layout] Unauthenticated, redirecting to /auth/admin` (ไม่ควรเห็น)

## 📝 Manager Test Account
```
Email: manager@hotel.com
Password: Manager123!
```

## 🚀 Deploy Command
```bash
cd frontend
npm run build
# ถ้า build สำเร็จ ให้ push to git
git add .
git commit -m "fix: resolve admin redirect loop in production"
git push
```

Vercel จะ auto-deploy เมื่อ push to main branch
