# 🔧 แก้ไขปัญหา Manager Login - Vercel Redirect Loop

## 🔴 ปัญหา
เมื่อ Manager/Admin login ผ่าน `/auth/admin` แล้ว ระบบ redirect กลับไปที่:
```
/auth/signin?callbackUrl=%2Fadmin%2Fdashboard
```
และหน้าจอค้าง ไม่สามารถเข้าหน้า dashboard ได้

## 🔍 สาเหตุ
1. **Middleware Redirect Loop**: Middleware ตรวจพบว่าผู้ใช้ login แล้วและพยายาม redirect แต่เกิด loop
2. **NextAuth Redirect Callback**: การจัดการ `callbackUrl` ทำให้เกิดการ redirect ซ้ำซ้อน
3. **Next.js 15 Router Issue**: `router.replace()` ไม่ทำงานดีกับ middleware ใน Next.js 15

## ✅ วิธีแก้ไข (แก้ไขแล้ว)

### 1. แก้ไข `frontend/src/app/auth/admin/page.tsx`

**เปลี่ยนการ redirect เป็น hard redirect:**

```typescript
// ❌ เดิม - ใช้ router.replace() ทำให้ค้าง
router.replace(redirectUrl);
router.refresh();

// ✅ ใหม่ - ใช้ window.location.href
window.location.href = redirectUrl;
```

**เพิ่มเวลารอให้ session update:**

```typescript
// รอให้ session ถูกสร้างก่อน redirect (500ms)
await new Promise(resolve => setTimeout(resolve, 500));
```

### 2. แก้ไข `frontend/src/middleware.ts`

**ลบการตรวจสอบ callbackUrl ที่ทำให้เกิด loop:**

```typescript
// ❌ เดิม - ตรวจสอบ callbackUrl ทำให้เกิด loop
if (token && pathname.startsWith('/auth/admin')) {
  const callbackUrl = request.nextUrl.searchParams.get('callbackUrl');
  if (callbackUrl && callbackUrl.startsWith('/')) {
    return NextResponse.redirect(new URL(callbackUrl, request.url));
  }
  // ...
}

// ✅ ใหม่ - redirect ตรงไปที่หน้าหลักของ role
if (token && pathname.startsWith('/auth/admin')) {
  const homeUrl = getRoleHomePage(token.role as string);
  return NextResponse.redirect(new URL(homeUrl, request.url));
}
```

### 3. ตรวจสอบ Environment Variables ใน Vercel

**ไปที่ Vercel Dashboard → Settings → Environment Variables:**

```bash
# ✅ ต้องมีทั้งหมดนี้
NEXTAUTH_URL=https://your-frontend.vercel.app
NEXTAUTH_SECRET=your-secret-at-least-32-chars
NEXT_PUBLIC_API_URL=https://your-backend.onrender.com
BACKEND_URL=https://your-backend.onrender.com
NODE_ENV=production
```

**⚠️ สำคัญมาก:**
- `NEXTAUTH_URL` ต้องเป็น URL ของ **frontend** (Vercel) ไม่ใช่ backend!
- `NEXTAUTH_SECRET` ต้องมีอย่างน้อย 32 ตัวอักษร
- ห้ามมี `/api` ต่อท้าย URL

### 4. Deploy และทดสอบ

```bash
cd frontend
git add .
git commit -m "fix: admin login redirect loop on Vercel"
git push
```

Vercel จะ auto-deploy ให้อัตโนมัติ (ประมาณ 2-3 นาที)

## 🧪 การทดสอบ

### ขั้นตอนการทดสอบ:

1. **เปิด Incognito/Private Window** (เพื่อไม่ให้ cache รบกวน)
2. ไปที่ `https://your-frontend.vercel.app/auth/admin`
3. Login ด้วย Manager account:
   ```
   Email: manager@hotel.com
   Password: manager123
   ```
4. **ผลลัพธ์ที่ถูกต้อง:**
   - ✅ แสดง toast "เข้าสู่ระบบสำเร็จ!"
   - ✅ Redirect ไปที่ `/admin/dashboard` ทันที
   - ✅ แสดงหน้า Manager Dashboard

### ทดสอบ Role อื่นๆ:

**Receptionist:**
```
Email: receptionist@hotel.com
Password: receptionist123
→ ควร redirect ไปที่ /admin/reception
```

**Housekeeper:**
```
Email: housekeeper@hotel.com
Password: housekeeper123
→ ควร redirect ไปที่ /admin/housekeeping
```

## 🔧 หากยังมีปัญหา

### 1. ตรวจสอบ Browser Console (F12)

**Logs ที่ควรเห็น:**
```
[Admin Login] Attempting login for: manager@hotel.com
[Auth] Calling backend: https://your-backend.onrender.com/api/auth/login
[Auth] Backend response: { success: true, data: { role_code: 'MANAGER', ... } }
[Admin Login] Login successful, waiting for session...
[Admin Login] Session data: { user: { role: 'MANAGER', ... } }
[Admin Login] Valid staff role: MANAGER redirecting to: /admin/dashboard
```

**หากเห็น Error:**
- `Failed to fetch` → Backend ไม่ตอบสนอง (ตรวจสอบ CORS)
- `No role in session` → Session ไม่ถูกสร้าง (ตรวจสอบ NEXTAUTH_SECRET)
- `Guest detected` → Login ด้วย Guest account ผิด

### 2. ตรวจสอบ Network Tab

**Request ที่ควรเห็น:**
1. `POST /api/auth/callback/credentials` → Status 200
2. `GET /api/auth/session` → Status 200, Response มี `user.role`
3. Navigation ไปที่ `/admin/dashboard`

### 3. Clear Cache และ Cookies

```
1. เปิด DevTools (F12)
2. ไปที่ Application tab
3. Clear Storage → Clear site data
4. Reload page (Ctrl+Shift+R)
```

### 4. ตรวจสอบ Backend

**ทดสอบ Backend API:**
```bash
curl -X POST https://your-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"manager123"}'
```

**Response ที่ถูกต้อง:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "manager@hotel.com",
    "role_code": "MANAGER",
    "user_type": "STAFF",
    "access_token": "..."
  }
}
```

## 📋 Checklist การแก้ไข

- [x] แก้ไข `frontend/src/app/auth/admin/page.tsx` ใช้ `window.location.href`
- [x] แก้ไข `frontend/src/middleware.ts` ลบ callbackUrl check
- [ ] ตรวจสอบ `NEXTAUTH_URL` ใน Vercel (ต้องเป็น frontend URL)
- [ ] ตรวจสอบ `NEXTAUTH_SECRET` มีอย่างน้อย 32 ตัวอักษร
- [ ] Deploy ใหม่ไปที่ Vercel
- [ ] ทดสอบ login ใน Incognito mode
- [ ] ทดสอบทุก role (Manager, Receptionist, Housekeeper)

## 📝 สรุป

### ปัญหาหลัก:
1. ❌ Middleware redirect loop กับ callbackUrl parameter
2. ❌ `router.replace()` ไม่ทำงานกับ middleware ใน Next.js 15
3. ❌ Session ไม่ได้ update ก่อน redirect

### การแก้ไข:
1. ✅ ใช้ `window.location.href` แทน `router.replace()`
2. ✅ ลบการตรวจสอบ callbackUrl ใน middleware
3. ✅ เพิ่มเวลารอให้ session update (500ms)
4. ✅ ตรวจสอบ NEXTAUTH_URL ใน Vercel

## 📚 เอกสารที่เกี่ยวข้อง

- `frontend/VERCEL_REDIRECT_FIX.md` - รายละเอียดการแก้ไขแบบเต็ม
- `frontend/DEPLOY_CHECKLIST.md` - Checklist การ deploy
- `VERCEL_FIX_SUMMARY.md` - สรุปการแก้ไข Vercel

---

**อัพเดทล่าสุด:** 8 พฤศจิกายน 2025  
**สถานะ:** ✅ แก้ไขโค้ดแล้ว - รอ Deploy และทดสอบ  
**ผู้แก้ไข:** Kiro AI Assistant
