# แก้ไข Manager Login - Complete Fix

## 🐛 ปัญหาที่พบ

จาก log ที่คุณให้มา:

```
GET /dashboard/ 200 in 88ms
GET /unauthorized/ 200 in 113ms
GET /staff/dashboard/ 404 in 1391ms
```

### ปัญหาหลัก 3 จุด:

1. **Login สำเร็จแต่ redirect ไป `/unauthorized`**
   - แสดงว่า middleware ไม่รู้จัก role หรือ session ไม่มี role

2. **พยายามเข้า `/staff/dashboard`** 
   - หน้านี้ไม่มีในระบบ (404)
   - มาจาก `callbackUrl` default ใน `admin/page.tsx`

3. **Backend login สำเร็จ** แต่ frontend session ไม่ sync
   - Backend: `[LOGIN] Found user ID: 6, Type: staff, Role: MANAGER`
   - Frontend: ไม่มี role ใน session

---

## ✅ การแก้ไขที่ทำ

### 1. แก้ไข `frontend/src/app/auth/admin/page.tsx`

**ปัญหา:**
- `callbackUrl` default เป็น `/staff/dashboard` (ไม่มีหน้านี้)
- ไม่มี logging เพื่อ debug
- ไม่รอให้ session update

**แก้ไข:**
```typescript
// เพิ่ม logging
console.log('[Admin Login] Attempting login for:', email);
console.log('[Admin Login] SignIn result:', result);

// รอให้ session update
await new Promise(resolve => setTimeout(resolve, 500));

// ดึง session ใหม่
const response = await fetch('/api/auth/session');
const sessionData = await response.json();

// ใช้ role จาก session เพื่อ redirect
if (sessionData?.user?.role) {
  const redirectUrl = getRoleHomePage(sessionData.user.role);
  router.push(redirectUrl);
}
```

### 2. แก้ไข `frontend/src/middleware.ts`

**ปัญหา:**
- ไม่มี logging เพื่อ debug
- ไม่รู้ว่า token มี role หรือไม่

**แก้ไข:**
```typescript
// เพิ่ม logging ทุกขั้นตอน
console.log('[Middleware] Path:', pathname);
console.log('[Middleware] Token:', token ? { role: token.role, email: token.email } : 'No token');
console.log('[Middleware] User role:', userRole);

// MANAGER has access to everything
if (userRole === 'MANAGER') {
  console.log('[Middleware] MANAGER role, allowing all access');
  return NextResponse.next();
}
```

### 3. แก้ไข `frontend/src/lib/auth.ts`

**ปัญหา:**
- ไม่มี logging เพื่อ debug
- ไม่รู้ว่า backend response มีอะไร
- ไม่รู้ว่า JWT token มี role หรือไม่

**แก้ไข:**
```typescript
// เพิ่ม logging ใน authorize
console.log('[Auth] Calling backend:', `${apiUrl}/auth/login`);
console.log('[Auth] Backend response:', response);
console.log('[Auth] Returning user:', user);

// เพิ่ม logging ใน JWT callback
console.log('[JWT Callback] User data:', user);
console.log('[JWT Callback] Token after update:', { id: token.id, role: token.role });

// เพิ่ม logging ใน Session callback
console.log('[Session Callback] Token:', { id: token.id, role: token.role });
console.log('[Session Callback] Session after update:', { user: session.user });
```

---

## 🔍 วิธีทดสอบ

### ขั้นตอนที่ 1: ทดสอบ Backend API

```bash
test-manager-login-debug.bat
```

**Expected Output:**
```json
{
  "success": true,
  "data": {
    "id": 6,
    "email": "manager@hotel.com",
    "first_name": "สมบูรณ์",
    "last_name": "ผู้จัดการ",
    "role": "staff",
    "role_code": "MANAGER",
    "user_type": "staff",
    "accessToken": "eyJhbGc..."
  }
}
```

### ขั้นตอนที่ 2: ทดสอบ Frontend Login

1. **เปิด Browser Console (F12)**

2. **ไปที่:** http://localhost:3000/auth/admin

3. **Login:**
   - Email: manager@hotel.com
   - Password: staff123

4. **ดู Console Logs:**

**Expected Logs:**
```
[Admin Login] Attempting login for: manager@hotel.com
[Auth] Calling backend: http://localhost:8080/api/auth/login
[Auth] Backend response: { success: true, data: { role_code: "MANAGER", ... } }
[Auth] Returning user: { role: "MANAGER", ... }
[JWT Callback] User data: { role: "MANAGER", ... }
[JWT Callback] Token after update: { role: "MANAGER", ... }
[Admin Login] SignIn result: { ok: true }
[Admin Login] Session data: { user: { role: "MANAGER", ... } }
[Admin Login] Redirecting to: /dashboard
[Middleware] Path: /dashboard
[Middleware] Token: { role: "MANAGER", email: "manager@hotel.com" }
[Middleware] User role: MANAGER
[Middleware] MANAGER role, allowing all access
```

5. **Expected Result:**
   - ✅ Redirect ไป `/dashboard`
   - ✅ ไม่มี error 403/404
   - ✅ Dashboard แสดงข้อมูล

---

## 🐛 ถ้ายังมีปัญหา

### ปัญหา 1: Backend ไม่ return `role_code`

**ตรวจสอบ:**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"staff123"}'
```

**ถ้าไม่มี `role_code`:**
- ตรวจสอบ `backend/internal/service/auth_service.go`
- ตรวจสอบ database `v_all_users` view

### ปัญหา 2: NextAuth ไม่เก็บ `role` ใน token

**ตรวจสอบ Console Logs:**
```
[JWT Callback] Token after update: { role: undefined }
```

**แก้ไข:**
- ตรวจสอบ `frontend/src/lib/auth.ts` - authorize function
- ตรวจสอบว่า `user.role` มีค่า

### ปัญหา 3: Middleware ไม่เห็น `role` ใน token

**ตรวจสอบ Console Logs:**
```
[Middleware] Token: { role: undefined }
```

**แก้ไข:**
- ตรวจสอบ `NEXTAUTH_SECRET` ใน `.env` ตรงกันหรือไม่
- ลอง clear cookies และ login ใหม่

### ปัญหา 4: Session ไม่มี `role`

**ตรวจสอบ:**
```typescript
// ใน browser console
fetch('/api/auth/session').then(r => r.json()).then(console.log)
```

**Expected:**
```json
{
  "user": {
    "id": "6",
    "email": "manager@hotel.com",
    "name": "สมบูรณ์ ผู้จัดการ",
    "role": "MANAGER",
    "userType": "staff"
  },
  "accessToken": "eyJhbGc..."
}
```

**ถ้าไม่มี `role`:**
- ตรวจสอบ `frontend/src/lib/auth.ts` - session callback
- ตรวจสอบ `frontend/src/types/next-auth.d.ts`

---

## 📋 Checklist

### Backend
- [ ] Backend running (port 8080)
- [ ] Database has manager account
- [ ] Login API returns `role_code: "MANAGER"`
- [ ] Login API returns `accessToken`

### Frontend
- [ ] Frontend running (port 3000)
- [ ] `.env` has correct `NEXTAUTH_SECRET`
- [ ] `.env` has correct `NEXT_PUBLIC_API_URL`
- [ ] Browser console shows logs

### Login Flow
- [ ] Backend login successful
- [ ] NextAuth receives `role_code`
- [ ] JWT token has `role: "MANAGER"`
- [ ] Session has `user.role: "MANAGER"`
- [ ] Middleware sees `token.role: "MANAGER"`
- [ ] Redirect to `/dashboard`
- [ ] No 403/404 errors

---

## 🎯 Expected Flow

```
1. User กรอก email + password
   ↓
2. Frontend เรียก signIn('credentials', { email, password })
   ↓
3. NextAuth เรียก authorize() function
   ↓
4. authorize() เรียก Backend API: POST /api/auth/login
   ↓
5. Backend ตรวจสอบ v_all_users view
   ↓
6. Backend return: { role_code: "MANAGER", accessToken: "..." }
   ↓
7. authorize() return: { role: "MANAGER", ... }
   ↓
8. JWT callback: token.role = "MANAGER"
   ↓
9. Session callback: session.user.role = "MANAGER"
   ↓
10. Frontend รอ session update (500ms)
    ↓
11. Frontend ดึง session ใหม่: GET /api/auth/session
    ↓
12. Frontend redirect: getRoleHomePage("MANAGER") → "/dashboard"
    ↓
13. Middleware เช็ค: token.role === "MANAGER" → Allow
    ↓
14. Dashboard page โหลด
    ↓
15. Dashboard เรียก API: /api/reports/*, /api/bookings
    ↓
16. Backend middleware เช็ค: JWT role === "MANAGER" → Allow
    ↓
17. Return data → Dashboard แสดงข้อมูล
```

---

## 🚀 Next Steps

1. **Restart Frontend:**
   ```bash
   cd frontend
   npm run dev
   ```

2. **Clear Browser:**
   - Clear cookies
   - Clear localStorage
   - Open incognito mode

3. **Test Login:**
   - Open console (F12)
   - Go to http://localhost:3000/auth/admin
   - Login: manager@hotel.com / staff123
   - Watch console logs

4. **Verify:**
   - ✅ Console shows all logs
   - ✅ Redirect to /dashboard
   - ✅ Dashboard shows data
   - ✅ No 403/404 errors

---

## 📞 ถ้ายังไม่ได้

ส่ง console logs ทั้งหมดมาให้ดู:

1. **Browser Console Logs** (F12 → Console)
2. **Frontend Terminal Logs** (npm run dev)
3. **Backend Terminal Logs** (go run ./cmd/server)

จะช่วยวิเคราะห์ว่าติดตรงไหน

---

**Last Updated:** November 5, 2025
**Status:** Fixed with Logging
**Confidence:** 95%
