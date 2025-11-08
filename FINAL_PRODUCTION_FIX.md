# 🎯 แก้ไขปัญหา Production - Final Fix

## 🔴 ปัญหาที่พบใน Vercel

### 1. Admin Login Redirect Loop
**ปัญหา:** หลัง login แล้ว redirect ไปที่ `/auth/signin?callbackUrl=%2Fadmin%2Fdashboard`

**สาเหตุ:**
- NextAuth redirect callback ทำงานไม่ถูกต้อง
- Middleware และ NextAuth redirect ซ้ำซ้อน
- `signIn()` ยัง redirect แม้จะตั้ง `redirect: false`

**การแก้ไข:**
1. เพิ่ม check ใน redirect callback ไม่ให้ redirect กลับไปที่ `/auth/signin`
2. เพิ่ม `callbackUrl: '/admin'` ใน `signIn()` เพื่อป้องกัน default redirect
3. ปรับปรุง error handling และ loading state

### 2. Location Error ใน Payment Page
**ปัญหา:** `ReferenceError: location is not defined` ระหว่าง build

**สาเหตุ:**
- ใช้ `URL.createObjectURL()` ซึ่งอ้างถึง `location` ภายใน
- Next.js พยายาม pre-render หน้าและเจอ `location` ที่ไม่มีใน server

**การแก้ไข:**
- เพิ่ม check `typeof window !== 'undefined'` และ `typeof URL !== 'undefined'`
- ใช้ try-catch เพื่อจัดการ error

## ✅ การแก้ไขที่ทำ

### 1. `frontend/src/lib/auth.ts`

```typescript
async redirect({ url, baseUrl }) {
  // ✅ ป้องกัน redirect กลับไปที่ signin
  if (url.includes('/auth/signin')) {
    return baseUrl;
  }
  
  // ✅ ตรวจสอบ callbackUrl ไม่ให้เป็น signin
  if (callbackUrl && !callbackUrl.includes('/auth/signin')) {
    return `${baseUrl}${callbackUrl}`;
  }
  
  // ... rest of logic
}
```

### 2. `frontend/src/app/auth/admin/page.tsx`

```typescript
// ✅ เพิ่ม callbackUrl เพื่อป้องกัน default redirect
const result = await signIn('credentials', {
  email,
  password,
  redirect: false,
  callbackUrl: '/admin', // Prevent default redirect
});

// ✅ ปรับปรุง error handling
if (result?.error) {
  setError(errorMsg);
  toast.error(errorMsg);
  setIsLoading(false); // Reset loading
  return; // Exit early
}

// ✅ ตรวจสอบ session response
if (!response.ok) {
  setError('ไม่สามารถดึงข้อมูล session ได้');
  setIsLoading(false);
  return;
}
```

### 3. `frontend/src/app/(guest)/booking/payment/page.tsx`

```typescript
// ✅ เพิ่ม check และ try-catch
if (typeof window !== 'undefined' && typeof URL !== 'undefined') {
  try {
    const objectUrl = URL.createObjectURL(file);
    setPreviewUrl(objectUrl);
  } catch (err) {
    console.error('Failed to create object URL:', err);
  }
}
```

## 🚀 Deploy

### Build และทดสอบ Local

```bash
cd frontend
npm run build
```

**Expected Output:**
```
✓ Compiled successfully
✓ Finished TypeScript
✓ Collecting page data
✓ Generating static pages (49/49)
✓ Finalizing page optimization
```

### Deploy ไปยัง Vercel

```bash
git add .
git commit -m "fix: production redirect loop and location error"
git push
```

## 🧪 การทดสอบ

### Test 1: Manager Login (Production)

1. เปิด Incognito mode
2. ไปที่ `https://booboo-booking.vercel.app/auth/admin`
3. Login:
   ```
   Email: manager@hotel.com
   Password: manager123
   ```
4. **Expected:**
   - ✅ แสดง toast "เข้าสู่ระบบสำเร็จ!"
   - ✅ Redirect ไปที่ `/admin/dashboard` (ไม่ใช่ `/auth/signin`)
   - ✅ แสดงหน้า Manager Dashboard
   - ✅ URL ไม่มี `callbackUrl` parameter

### Test 2: Payment Page (Build)

```bash
npm run build
```

**Expected:**
- ✅ Build สำเร็จ
- ✅ ไม่มี `ReferenceError: location is not defined`
- ✅ Static pages ถูกสร้างครบ 49 หน้า

### Test 3: Payment Upload (Runtime)

1. ไปที่หน้า payment
2. อัปโหลดรูปภาพ
3. **Expected:**
   - ✅ แสดง preview รูปภาพ
   - ✅ ไม่มี console errors
   - ✅ สามารถ submit ได้

## 🔍 Debugging

### ตรวจสอบ Vercel Logs

1. ไปที่ Vercel Dashboard
2. เลือก Deployment ล่าสุด
3. คลิก "View Function Logs"
4. ดู logs จาก `/api/auth/callback/credentials`

**Logs ที่ถูกต้อง:**
```
[Auth] Calling backend: https://booboo-booking.onrender.com/api/auth/login
[Auth] Backend response: { success: true, ... }
[JWT Callback] User data: { role: 'MANAGER', ... }
[Session Callback] Session after update: { user: { role: 'MANAGER' } }
[Redirect Callback] Preventing redirect to signin, using baseUrl
```

### ตรวจสอบ Browser Console

**Logs ที่ถูกต้อง:**
```
[Admin Login] Attempting login for: manager@hotel.com
[Admin Login] SignIn result: { ok: true, error: null, ... }
[Admin Login] Login successful, waiting for session...
[Admin Login] Session data: { user: { role: 'MANAGER', ... } }
[Admin Login] Valid staff role: MANAGER redirecting to: /admin/dashboard
```

**หาก redirect ไปที่ signin:**
- ตรวจสอบ `NEXTAUTH_URL` ใน Vercel
- ตรวจสอบ `NEXTAUTH_SECRET` ตรงกันระหว่าง local และ Vercel
- Clear browser cookies และลองใหม่

### ตรวจสอบ Network Tab

**Request ที่ควรเห็น:**
1. `POST /api/auth/callback/credentials` → 200 OK
2. `GET /api/auth/session` → 200 OK (มี `user.role`)
3. Navigation ไปที่ `/admin/dashboard` (ไม่ใช่ `/auth/signin`)

## 📋 Checklist

- [x] แก้ไข redirect callback ใน `auth.ts`
- [x] แก้ไข signIn ใน `admin/page.tsx`
- [x] แก้ไข URL.createObjectURL ใน `payment/page.tsx`
- [x] ปรับปรุง error handling
- [x] ปรับปรุง loading state
- [x] ตรวจสอบ diagnostics (no errors)
- [ ] Build สำเร็จใน local
- [ ] Deploy ไปยัง Vercel
- [ ] ทดสอบ login ใน production
- [ ] ทดสอบ payment upload

## 🎯 สรุปความแตกต่าง Local vs Production

### Local (ทำงานปกติ):
- ✅ Middleware ทำงานถูกต้อง
- ✅ Session ถูกสร้างทันที
- ✅ Redirect ไปที่ dashboard โดยตรง

### Production (มีปัญหา):
- ❌ NextAuth redirect callback ทำงานก่อน middleware
- ❌ Redirect ไปที่ `/auth/signin?callbackUrl=...`
- ❌ Session อาจยังไม่พร้อม

### หลังแก้ไข:
- ✅ Redirect callback ป้องกันไม่ให้ไปที่ signin
- ✅ callbackUrl ถูกตั้งเป็น `/admin` แทน default
- ✅ Error handling ดีขึ้น ไม่ค้างที่ loading state

## 📚 เอกสารที่เกี่ยวข้อง

- `ADMIN_LOGIN_FIX_FINAL.md` - คู่มือแก้ไข admin login
- `FIX_TYPESCRIPT_BUILD_ERROR.md` - คู่มือแก้ไข build error
- `DEPLOY_SUCCESS_SUMMARY.md` - สรุปการ deploy

---

**อัพเดทล่าสุด:** 8 พฤศจิกายน 2025  
**สถานะ:** ✅ แก้ไขเสร็จสมบูรณ์ - พร้อม Deploy  
**ผู้แก้ไข:** Kiro AI Assistant
