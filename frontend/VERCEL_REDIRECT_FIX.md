# แก้ไขปัญหา Manager Login Redirect บน Vercel

## ปัญหาที่พบ
เมื่อ Manager login บน Vercel มัน redirect ไป `/auth/signin?callbackUrl=%2Fadmin%2Fdashboard` และค้างไม่สามารถเข้า dashboard ได้

## สาเหตุ
1. **NEXTAUTH_URL ไม่ถูกต้อง**: ใน `.env.production` ยังเป็น placeholder `https://your-app.vercel.app`
2. **Redirect Loop**: Admin layout และ middleware ทำการ redirect ซ้ำซ้อน
3. **Callback URL ไม่ทำงาน**: NextAuth redirect callback ไม่ได้จัดการ callbackUrl parameter อย่างถูกต้อง

## การแก้ไขที่ทำแล้ว

### 1. ปรับปรุง NextAuth Redirect Callback (`frontend/src/lib/auth.ts`)
```typescript
async redirect({ url, baseUrl }) {
  // Parse URL เพื่อดึง callbackUrl parameter
  const urlObj = new URL(url, baseUrl);
  const callbackUrl = urlObj.searchParams.get('callbackUrl');
  
  // ถ้ามี callbackUrl ที่ valid ให้ใช้มัน
  if (callbackUrl && callbackUrl.startsWith('/')) {
    return `${baseUrl}${callbackUrl}`;
  }
  
  // จัดการ URL ที่เป็น absolute หรือ relative
  if (url.startsWith(baseUrl)) return url;
  if (url.startsWith('/')) return `${baseUrl}${url}`;
  
  return baseUrl;
}
```

### 2. ปรับปรุง Middleware (`frontend/src/middleware.ts`)
```typescript
// ตรวจสอบ callbackUrl parameter เมื่อ user login แล้ว
if (token && pathname.startsWith('/auth/signin')) {
  const callbackUrl = request.nextUrl.searchParams.get('callbackUrl');
  if (callbackUrl && callbackUrl.startsWith('/')) {
    return NextResponse.redirect(new URL(callbackUrl, request.url));
  }
  
  const homeUrl = getRoleHomePage(token.role as string);
  return NextResponse.redirect(new URL(homeUrl, request.url));
}
```

### 3. แก้ไข Admin Login Page (`frontend/src/app/auth/admin/page.tsx`)
```typescript
// Redirect ตรงไปยังหน้าที่ถูกต้องตาม role ทันที
if (role === 'MANAGER' || role === 'RECEPTIONIST' || role === 'HOUSEKEEPER') {
  const redirectUrl = getRoleHomePage(role);
  router.replace(redirectUrl); // ใช้ replace แทน push
  router.refresh();
}
```

### 4. ปรับปรุง Admin Layout (`frontend/src/app/admin/layout.tsx`)
```typescript
// Redirect ไปที่ admin login พร้อม callback URL
if (status === 'unauthenticated') {
  router.replace(`/auth/admin?callbackUrl=${encodeURIComponent(pathname)}`);
}
```

## ขั้นตอนการแก้ไขบน Vercel

### ⚠️ สำคัญมาก: ตั้งค่า Environment Variables บน Vercel

1. **ไปที่ Vercel Dashboard** → เลือก project `booboo-booking`
2. **Settings** → **Environment Variables**
3. **เพิ่ม/แก้ไข variables ต่อไปนี้**:

```bash
# NextAuth URL - ต้องเป็น URL ของ Vercel ที่ถูกต้อง
NEXTAUTH_URL=https://booboo-booking.vercel.app

# NextAuth Secret - ใช้ค่าเดิมหรือสร้างใหม่
NEXTAUTH_SECRET=IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=

# Backend API URL
NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com
BACKEND_URL=https://booboo-booking.onrender.com

# Environment
NODE_ENV=production
NEXT_PUBLIC_DEBUG=false
NEXT_PUBLIC_LOG_API=false
```

4. **Save** และ **Redeploy** project

### วิธีการ Deploy ใหม่

#### Option 1: ผ่าน Vercel Dashboard
1. ไปที่ **Deployments** tab
2. คลิก **...** (three dots) ที่ deployment ล่าสุด
3. เลือก **Redeploy**
4. เลือก **Use existing Build Cache** (ถ้าต้องการเร็ว) หรือไม่เลือก (ถ้าต้องการ build ใหม่)
5. คลิก **Redeploy**

#### Option 2: ผ่าน Git
```bash
# Commit การเปลี่ยนแปลง
git add .
git commit -m "fix: แก้ไขปัญหา manager login redirect บน Vercel"
git push origin main

# Vercel จะ auto-deploy
```

## การทดสอบหลัง Deploy

1. **ทดสอบ Manager Login**:
   - ไปที่ `https://booboo-booking.vercel.app/auth/admin`
   - Login ด้วย manager account
   - ควร redirect ไป `/admin/dashboard` ทันที

2. **ทดสอบ Receptionist Login**:
   - Login ด้วย receptionist account
   - ควร redirect ไป `/admin/reception`

3. **ทดสอบ Housekeeper Login**:
   - Login ด้วย housekeeper account
   - ควร redirect ไป `/admin/housekeeping`

4. **ตรวจสอบ Console Logs**:
   - เปิด Browser DevTools (F12)
   - ดู Console tab
   - ควรเห็น logs:
     ```
     [Admin Login] Valid staff role: MANAGER redirecting to: /admin/dashboard
     [Middleware] User role: MANAGER
     [Middleware] Access granted
     ```

## หากยังมีปัญหา

### ตรวจสอบ Environment Variables
```bash
# ใน Vercel Dashboard → Settings → Environment Variables
# ตรวจสอบว่า NEXTAUTH_URL ถูกต้อง
```

### ตรวจสอบ Logs
```bash
# ใน Vercel Dashboard → Deployments → คลิกที่ deployment → View Function Logs
# ดู logs เพื่อหาข้อผิดพลาด
```

### Clear Browser Cache
```bash
# Chrome/Edge: Ctrl + Shift + Delete
# เลือก "Cached images and files" และ "Cookies and other site data"
# Clear data
```

### ลอง Incognito/Private Mode
- เปิด browser ใน Incognito/Private mode
- ทดสอบ login อีกครั้ง

## สรุป
การแก้ไขนี้จะทำให้:
- ✅ Manager login แล้ว redirect ไป `/admin/dashboard` ทันที
- ✅ ไม่มี redirect loop
- ✅ Callback URL ทำงานถูกต้อง
- ✅ ไม่ค้างที่หน้า signin

**สิ่งสำคัญที่สุด**: ต้องตั้งค่า `NEXTAUTH_URL=https://booboo-booking.vercel.app` บน Vercel Dashboard!
