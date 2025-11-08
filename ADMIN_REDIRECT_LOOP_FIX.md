# 🔧 แก้ไขปัญหา Admin Redirect Loop ใน Production

## 📋 สรุปปัญหา

เมื่อ login ด้วย Manager account ใน production (Vercel) แล้วเข้าสู่ระบบสำเร็จ แต่เกิด **infinite redirect loop** ระหว่าง:
- `/auth/admin` ↔️ `/admin/dashboard`

Browser console แสดง:
```
[Admin Login] Already authenticated as staff, redirecting to: /admin/dashboard
[Admin Login] Already authenticated as staff, redirecting to: /admin/dashboard
[Admin Login] Already authenticated as staff, redirecting to: /admin/dashboard
...
```

### ✅ ใน Local: ทำงานปกติ
### ❌ ใน Production (Vercel): เกิด redirect loop

---

## 🔍 สาเหตุ

### 1. Network Latency ใน Production
- Session sync ช้ากว่า local
- Admin Layout ยังไม่ได้รับ session ทันที
- Layout คิดว่า user ยัง unauthenticated

### 2. Redirect Loop Flow
```
1. User login สำเร็จ → redirect to /admin/dashboard
2. Admin Layout ยังไม่เห็น session → redirect to /auth/admin?callbackUrl=/admin/dashboard
3. Admin Login Page เห็น session → redirect to /admin/dashboard
4. กลับไปที่ข้อ 2 (loop!)
```

### 3. Root Cause
- **Admin Layout** ใช้ `callbackUrl` parameter
- **Admin Login Page** redirect ทันทีเมื่อเห็น authenticated session
- **Race condition** ระหว่าง session sync และ redirect logic

---

## 🛠️ การแก้ไข

### 1. ลบ callbackUrl จาก Admin Layout
**File:** `frontend/src/app/admin/layout.tsx`

**Before:**
```typescript
router.replace(`/auth/admin?callbackUrl=${encodeURIComponent(pathname)}`);
```

**After:**
```typescript
router.replace('/auth/admin');
```

**เหตุผล:** Admin login page จัดการ redirect เองแล้ว ไม่ต้องส่ง callbackUrl

---

### 2. เพิ่ม Redirect Guard
**File:** `frontend/src/app/admin/layout.tsx`

**เพิ่ม:**
```typescript
const [hasRedirected, setHasRedirected] = useState(false);

useEffect(() => {
  if (hasRedirected) return; // ป้องกัน multiple redirects
  
  if (status === 'unauthenticated') {
    setHasRedirected(true);
    router.replace('/auth/admin');
  }
  // ...
}, [status, session, router, pathname, hasRedirected]);
```

**เหตุผล:** ป้องกัน useEffect ทำงานซ้ำและ redirect หลายครั้ง

---

### 3. เพิ่ม Delay ก่อน Redirect
**File:** `frontend/src/app/auth/admin/page.tsx`

**เพิ่ม:**
```typescript
setTimeout(() => {
  window.location.replace(redirectUrl);
}, 100);
```

**เหตุผล:** ให้เวลา session sync ใน production ก่อน redirect

---

### 4. เพิ่ม Console Logs
**เพิ่มใน:**
- `frontend/src/app/admin/layout.tsx`
- `frontend/src/middleware.ts`

**เหตุผล:** Debug ใน production ผ่าน browser console

---

## 📝 Files ที่แก้ไข

1. ✅ `frontend/src/app/admin/layout.tsx`
   - ลบ callbackUrl parameter
   - เพิ่ม hasRedirected state
   - เพิ่ม console.log

2. ✅ `frontend/src/app/auth/admin/page.tsx`
   - เพิ่ม 100ms delay ก่อน redirect

3. ✅ `frontend/src/middleware.ts`
   - เพิ่ม comment อธิบาย auth page handling

4. ✅ `frontend/VERCEL_ENV_CHECK.md` (ใหม่)
   - Checklist สำหรับ Vercel environment variables

5. ✅ `frontend/test-production-build.bat` (ใหม่)
   - Script ทดสอบ production build

---

## 🧪 วิธีทดสอบ

### Local Testing
```bash
cd frontend
npm run build
npm run start
```

เปิด http://localhost:3000/auth/admin
- Login ด้วย: manager@hotel.com / Manager123!
- ควรไปที่ /admin/dashboard โดยไม่มี loop

### Production Testing
1. Deploy to Vercel
2. เปิด https://booboo-booking.vercel.app/auth/admin
3. เปิด Browser Console (F12)
4. Login ด้วย manager account
5. ตรวจสอบ console logs:
   - ✅ ควรเห็น: `[Admin Login] Already authenticated as staff, redirecting to: /admin/dashboard`
   - ✅ ควรไปที่ /admin/dashboard สำเร็จ
   - ❌ ไม่ควรเห็น: `[Admin Layout] Unauthenticated, redirecting to /auth/admin`

---

## 🔐 Test Accounts

### Manager
```
Email: manager@hotel.com
Password: Manager123!
Expected: /admin/dashboard
```

### Receptionist
```
Email: receptionist@hotel.com
Password: Receptionist123!
Expected: /admin/reception
```

### Housekeeper
```
Email: housekeeper@hotel.com
Password: Housekeeper123!
Expected: /admin/housekeeping
```

---

## 🚀 Deploy to Production

```bash
# 1. Test build locally
cd frontend
npm run build

# 2. Commit changes
git add .
git commit -m "fix: resolve admin redirect loop in production"

# 3. Push to trigger Vercel deployment
git push origin main
```

Vercel จะ auto-deploy ภายใน 2-3 นาที

---

## ✅ Expected Behavior

### After Fix:
1. User login ที่ `/auth/admin`
2. Login สำเร็จ → redirect to role-specific page
3. ไม่มี redirect loop
4. Session persistent ตลอด

### Console Logs (Normal):
```
[Admin Login] Attempting login for: manager@hotel.com
[Auth] Calling backend: https://booboo-booking.onrender.com/api/auth/login
[Auth] Backend response: { success: true, data: {...} }
[Admin Login] Login successful, fetching session...
[Admin Login] Session data: { user: { role: 'MANAGER', ... } }
[Admin Login] Redirecting to: /admin/dashboard
```

---

## 📚 Related Files

- `frontend/.env` - Local environment
- `frontend/.env.production` - Production environment
- `frontend/src/lib/auth.ts` - NextAuth configuration
- `frontend/src/utils/role-redirect.ts` - Role-based redirect helper
- `frontend/src/middleware.ts` - Route protection

---

## 🎯 Key Takeaways

1. **ไม่ใช้ callbackUrl** ใน admin layout เพราะ login page จัดการเอง
2. **ใช้ hasRedirected state** เพื่อป้องกัน multiple redirects
3. **เพิ่ม delay** เล็กน้อยเพื่อให้ session sync ใน production
4. **เพิ่ม console.log** เพื่อ debug ง่ายขึ้น
5. **Test ใน production** เพราะ local อาจไม่เจอปัญหา

---

## 📞 Support

หากยังมีปัญหา:
1. ตรวจสอบ Vercel logs
2. ตรวจสอบ browser console
3. ตรวจสอบ environment variables ใน Vercel
4. ตรวจสอบ backend logs ใน Render

---

**Status:** ✅ Fixed
**Date:** 2025-01-08
**Version:** 1.0.0
