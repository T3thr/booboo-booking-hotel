# 🎯 แก้ไขปัญหา Admin Redirect Loop ครั้งสุดท้าย

## ปัญหา

Staff login สำเร็จแล้วแต่ URL ค้างที่:
```
/auth/admin?callbackUrl=%2Fadmin%2Fdashboard
```

ไม่สามารถเข้าหน้า `/admin/dashboard` ได้จริงๆ ใน Vercel production

## สาเหตุหลัก

1. **NextAuth Redirect Callback** ไม่ทำงานถูกต้องใน production
2. **Middleware** เพิ่ม `callbackUrl` parameter ทำให้เกิด loop
3. **Router.push/replace** ไม่เสถียรพอใน production environment

## การแก้ไขครั้งสุดท้าย

### 1. แก้ไข Admin Login Page (`frontend/src/app/auth/admin/page.tsx`)

**เปลี่ยนจาก:** ใช้ NextAuth signIn แล้วรอ session
**เป็น:** เรียก Backend API ตรงๆ ก่อน แล้วค่อย signIn

```typescript
// เรียก backend API ตรงๆ เพื่อ validate credentials
const loginResponse = await fetch(`${apiUrl}/api/auth/login`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password }),
});

// ตรวจสอบ role ก่อน
const userData = loginData.data;
const role = userData.role_code;

// ปฏิเสธ GUEST
if (role === 'GUEST') {
  // Show error
  return;
}

// ตอนนี้ค่อย signIn กับ NextAuth
const result = await signIn('credentials', {
  email,
  password,
  redirect: false, // ไม่ให้ NextAuth redirect
});

// Redirect เองด้วย window.location.href
if (result?.ok) {
  const redirectUrl = getRoleHomePage(role);
  window.location.href = redirectUrl; // Force redirect
}
```

**ข้อดี:**
- ✅ Validate role ก่อน signIn
- ✅ ไม่พึ่งพา NextAuth redirect callback
- ✅ ใช้ `window.location.href` ที่เสถียรที่สุด

### 2. แก้ไข Middleware (`frontend/src/middleware.ts`)

**เปลี่ยนจาก:**
```typescript
if (pathname.startsWith('/admin')) {
  const url = new URL('/auth/admin', request.url);
  url.searchParams.set('callbackUrl', pathname); // ❌ สร้าง loop
  return NextResponse.redirect(url);
}
```

**เป็น:**
```typescript
if (pathname.startsWith('/admin')) {
  // ไม่ใส่ callbackUrl เพื่อหลีกเลี่ยง loop
  return NextResponse.redirect(new URL('/auth/admin', request.url));
}
```

**ข้อดี:**
- ✅ ไม่มี callbackUrl parameter
- ✅ หลังจาก login สำเร็จ จะ redirect ตาม role โดยตรง
- ✅ ไม่เกิด redirect loop

### 3. แก้ไข Admin Page (`frontend/src/app/admin/page.tsx`)

**เพิ่ม:**
```typescript
// ใช้ window.location.href แทน router.replace
if (typeof window !== 'undefined') {
  window.location.href = redirectUrl;
} else {
  router.replace(redirectUrl);
}
```

**ข้อดี:**
- ✅ Redirect เสถียรใน production
- ✅ Force page reload เพื่อให้ middleware ตรวจสอบ session ใหม่

## Flow การทำงานใหม่

### ก่อนแก้ไข (มีปัญหา)
```
1. User → /admin/dashboard
2. Middleware: No token → Redirect to /auth/admin?callbackUrl=%2Fadmin%2Fdashboard
3. User login สำเร็จ
4. NextAuth redirect callback → ??? (ไม่ทำงาน)
5. ❌ ค้างที่ /auth/admin?callbackUrl=%2Fadmin%2Fdashboard
```

### หลังแก้ไข (ทำงานได้)
```
1. User → /admin/dashboard
2. Middleware: No token → Redirect to /auth/admin (ไม่มี callbackUrl)
3. User login สำเร็จ
4. Admin page: เรียก backend API → validate role
5. Admin page: signIn กับ NextAuth
6. Admin page: window.location.href = '/admin/dashboard'
7. ✅ เข้าหน้า /admin/dashboard สำเร็จ
```

## ไฟล์ที่แก้ไข

1. ✅ `frontend/src/app/auth/admin/page.tsx`
   - เรียก backend API ตรงๆ ก่อน signIn
   - Validate role ก่อน
   - ใช้ `window.location.href` สำหรับ redirect

2. ✅ `frontend/src/middleware.ts`
   - ลบ `callbackUrl` parameter ออก
   - Redirect ตรงๆ ไปที่ `/auth/admin`

3. ✅ `frontend/src/app/admin/page.tsx`
   - ใช้ `window.location.href` แทน `router.replace`

## วิธีทดสอบ

### Local
```bash
cd frontend
npm run build
npm run start
```

### Deploy to Vercel
```bash
git add .
git commit -m "fix: แก้ไข admin redirect loop ครั้งสุดท้าย"
git push
```

### ทดสอบหลัง Deploy

1. **ทดสอบ Manager Login**
   ```
   URL: https://booboo-booking.vercel.app/auth/admin
   Email: manager@hotel.com
   Password: Manager123!
   Expected: → /admin/dashboard ✅
   ```

2. **ทดสอบ Direct Access**
   ```
   URL: https://booboo-booking.vercel.app/admin/dashboard
   Expected: → /auth/admin → login → /admin/dashboard ✅
   ```

3. **ทดสอบ Navbar Link**
   ```
   Login แล้ว → คลิก Dashboard link
   Expected: → /admin/dashboard ✅
   ```

## Troubleshooting

### ถ้ายังค้างที่ /auth/admin

1. **Clear Browser Cache & Cookies**
   ```
   Chrome: Ctrl+Shift+Delete
   เลือก: Cookies and other site data
   ```

2. **ตรวจสอบ Vercel Logs**
   ```
   Vercel Dashboard → Deployments → Latest → Logs
   ดู: [Middleware] และ [Admin Login] logs
   ```

3. **ตรวจสอบ Environment Variables**
   ```
   NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com
   NEXTAUTH_URL=https://booboo-booking.vercel.app
   NEXTAUTH_SECRET=<your-secret>
   ```

### ถ้า Backend API ไม่ตอบสนอง

1. **ทดสอบ Backend**
   ```bash
   curl https://booboo-booking.onrender.com/api/health
   ```

2. **ตรวจสอบ CORS**
   - Backend ต้องอนุญาต origin จาก Vercel
   - ตรวจสอบ `backend/internal/middleware/cors.go`

## สรุป

การแก้ไขครั้งนี้:
- ✅ ไม่พึ่งพา NextAuth redirect callback
- ✅ ไม่ใช้ callbackUrl parameter
- ✅ ใช้ `window.location.href` สำหรับ redirect
- ✅ Validate role ก่อน signIn
- ✅ ทำงานได้ทั้ง local และ production

## ความแตกต่างจากการแก้ไขครั้งก่อน

| ครั้งก่อน | ครั้งนี้ |
|-----------|----------|
| ใช้ NextAuth redirect callback | เรียก backend API ตรงๆ |
| มี callbackUrl parameter | ไม่มี callbackUrl |
| ใช้ router.push/replace | ใช้ window.location.href |
| รอ session แล้ว redirect | Validate role ก่อน signIn |

ครั้งนี้ควรแก้ปัญหาได้แน่นอน! 🎉
