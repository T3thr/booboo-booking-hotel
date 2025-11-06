# สรุปการตรวจสอบสิทธิ์ตาม Role

## ✅ Middleware ปัจจุบัน (ถูกต้องแล้ว)

Middleware ตรวจสอบสิทธิ์ตามบทบาทอย่างเหมาะสม:

### 🔐 สิทธิ์การเข้าถึงแต่ละหน้า

| Path | Allowed Roles | หมายเหตุ |
|------|---------------|----------|
| `/` | Public | หน้าแรก |
| `/rooms` | Public | ค้นหาห้อง |
| `/bookings` | GUEST, RECEPTIONIST, MANAGER | การจองของฉัน |
| `/reception` | RECEPTIONIST, MANAGER | Reception dashboard |
| `/checkin` | RECEPTIONIST, MANAGER | Check-in |
| `/checkout` | RECEPTIONIST, MANAGER | Check-out |
| `/move-room` | RECEPTIONIST, MANAGER | ย้ายห้อง |
| `/no-show` | RECEPTIONIST, MANAGER | No-show |
| `/housekeeping` | HOUSEKEEPER, MANAGER | งานทำความสะอาด |
| `/dashboard` | MANAGER | Manager dashboard |
| `/pricing` | MANAGER | จัดการราคา |
| `/inventory` | MANAGER | จัดการสต็อก |
| `/reports` | MANAGER | รายงาน |
| `/settings` | MANAGER | ตั้งค่า |

## 🎯 การทำงานของ Middleware

### 1. Public Routes (ไม่ต้อง login)
```typescript
const publicRoutes = [
  '/',
  '/rooms',
  '/auth/signin',
  '/auth/register',
  '/auth/admin',
  '/unauthorized',
];
```

### 2. Protected Routes (ต้อง login)
ทุกหน้าที่ไม่ใช่ public routes ต้อง login ก่อน

### 3. Role-Based Access (ตรวจสอบสิทธิ์)
หลัง login แล้ว จะตรวจสอบว่า role ของ user มีสิทธิ์เข้าหน้านั้นหรือไม่

## 📋 ตัวอย่างการทำงาน

### ✅ กรณีที่ถูกต้อง

#### Manager Login
```
1. Login ที่ /auth/admin
2. Email: manager@hotel.com
3. Password: staff123
4. ✅ Redirect ไป /dashboard (Manager home)
5. ✅ สามารถเข้า /pricing, /inventory, /reports, /settings
6. ✅ สามารถเข้า /reception, /checkin (เพราะ Manager มีสิทธิ์ทุกอย่าง)
7. ✅ สามารถเข้า /housekeeping (เพราะ Manager มีสิทธิ์ทุกอย่าง)
```

#### Receptionist Login
```
1. Login ที่ /auth/admin
2. Email: receptionist1@hotel.com
3. Password: staff123
4. ✅ Redirect ไป /reception (Receptionist home)
5. ✅ สามารถเข้า /checkin, /checkout, /move-room, /no-show
6. ❌ ไม่สามารถเข้า /dashboard (403 - Manager only)
7. ❌ ไม่สามารถเข้า /housekeeping (403 - Housekeeper only)
```

#### Housekeeper Login
```
1. Login ที่ /auth/admin
2. Email: housekeeper1@hotel.com
3. Password: staff123
4. ✅ Redirect ไป /housekeeping (Housekeeper home)
5. ✅ สามารถเข้า /housekeeping/inspection
6. ❌ ไม่สามารถเข้า /dashboard (403 - Manager only)
7. ❌ ไม่สามารถเข้า /reception (403 - Receptionist only)
```

#### Guest Login
```
1. Login ที่ /auth/signin
2. Email: anan.test@example.com
3. Password: password123
4. ✅ Redirect ไป / (Guest home)
5. ✅ สามารถเข้า /rooms, /bookings
6. ❌ ไม่สามารถเข้า /dashboard, /reception, /housekeeping (403)
```

### ❌ กรณีที่ผิดพลาด

#### Manager ไม่สามารถเข้า /dashboard
**สาเหตุที่เป็นไปได้:**
1. Backend ยังไม่ rebuild หลังแก้โค้ด
2. JWT token ยังมี role เป็น "staff" แทน "MANAGER"
3. Browser cache ยังเก็บ token เก่า

**วิธีแก้:**
```bash
# 1. Rebuild backend
cd backend
go build -o server.exe ./cmd/server

# 2. Restart backend
server.exe

# 3. Clear browser
- Logout
- Clear cache (Ctrl+Shift+Delete)
- Login ใหม่
```

## 🔍 วิธีตรวจสอบปัญหา

### 1. ตรวจสอบ JWT Token
```typescript
// เปิด DevTools > Application > Session Storage
// หรือ Console:
import { getSession } from 'next-auth/react';
const session = await getSession();
console.log(session);

// ควรเห็น:
{
  user: {
    id: "6",
    email: "manager@hotel.com",
    role: "MANAGER",  // ✅ ต้องเป็น "MANAGER" ไม่ใช่ "staff"
    userType: "staff"
  }
}
```

### 2. ตรวจสอบ Backend Response
```bash
# Test login API
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"staff123"}'

# ควรได้:
{
  "success": true,
  "data": {
    "role_code": "MANAGER",  // ✅ ต้องเป็น "MANAGER"
    "user_type": "staff",
    "accessToken": "..."
  }
}
```

### 3. ตรวจสอบ Middleware
```typescript
// ดู middleware logs (ถ้ามี)
// หรือเพิ่ม console.log ใน middleware:

export async function middleware(request: NextRequest) {
  const token = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
  console.log('Path:', request.nextUrl.pathname);
  console.log('User Role:', token?.role);
  console.log('Allowed:', roleAccess[request.nextUrl.pathname]);
  // ...
}
```

## 🛠️ การแก้ไขปัญหา 403 Unauthorized

### ปัญหา: Manager login แล้วเข้า /dashboard ได้ 403

#### สาเหตุที่ 1: Backend ส่ง role ผิด
```typescript
// ❌ ผิด (เก่า)
token, err := utils.GenerateToken(user.UserID, user.Email, user.UserType, s.jwtSecret)
// user.UserType = "staff" ❌

// ✅ ถูก (ใหม่)
token, err := utils.GenerateToken(user.UserID, user.Email, user.RoleCode, s.jwtSecret)
// user.RoleCode = "MANAGER" ✅
```

**วิธีแก้:**
1. ✅ แก้ไขแล้วใน `backend/internal/service/auth_service.go`
2. ⚠️ ต้อง rebuild backend
3. ⚠️ ต้อง restart backend
4. ⚠️ ต้อง logout และ login ใหม่

#### สาเหตุที่ 2: Frontend redirect ผิด
```typescript
// ❌ ผิด (เก่า)
case 'MANAGER':
  return '/manager/dashboard';  // ❌ ไม่มีหน้านี้

// ✅ ถูก (ใหม่)
case 'MANAGER':
  return '/dashboard';  // ✅ ถูกต้อง
```

**วิธีแก้:**
1. ✅ แก้ไขแล้วใน `frontend/src/utils/role-redirect.ts`
2. ✅ แก้ไขแล้วใน `frontend/src/middleware.ts`
3. ✅ แก้ไขแล้วใน `frontend/src/lib/auth.ts`

#### สาเหตุที่ 3: Browser cache token เก่า
**วิธีแก้:**
1. Logout
2. Clear browser cache (Ctrl+Shift+Delete)
3. Close browser
4. Open browser ใหม่
5. Login ใหม่

## 📝 Checklist การแก้ปัญหา

เมื่อเจอ 403 Unauthorized ให้ทำตามนี้:

- [ ] 1. Rebuild backend
  ```bash
  cd backend
  go build -o server.exe ./cmd/server
  ```

- [ ] 2. Restart backend
  ```bash
  cd backend
  server.exe
  ```

- [ ] 3. Test backend API
  ```bash
  curl -X POST http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"manager@hotel.com","password":"staff123"}'
  ```
  ตรวจสอบว่า `role_code` เป็น "MANAGER"

- [ ] 4. Clear browser cache
  - Logout
  - Ctrl+Shift+Delete
  - Clear all

- [ ] 5. Login ใหม่
  - ไปที่ `/auth/admin`
  - Login ด้วย manager@hotel.com
  - ควร redirect ไป `/dashboard`

- [ ] 6. ตรวจสอบ JWT token
  - เปิด DevTools > Application > Session Storage
  - ดู token
  - Decode ที่ jwt.io
  - ตรวจสอบว่า `role` เป็น "MANAGER"

- [ ] 7. ทดสอบเข้าหน้าต่างๆ
  - ✅ `/dashboard` - ควรเข้าได้
  - ✅ `/pricing` - ควรเข้าได้
  - ✅ `/inventory` - ควรเข้าได้
  - ✅ `/reports` - ควรเข้าได้
  - ✅ `/reception` - ควรเข้าได้ (Manager มีสิทธิ์ทุกอย่าง)
  - ✅ `/housekeeping` - ควรเข้าได้ (Manager มีสิทธิ์ทุกอย่าง)

## 🎉 สรุป

**Middleware ทำงานถูกต้องแล้ว:**
- ✅ ตรวจสอบ authentication (ต้อง login)
- ✅ ตรวจสอบ authorization (ต้องมีสิทธิ์)
- ✅ Redirect ตาม role ที่ถูกต้อง

**ปัญหาที่เจอ:**
- ⚠️ Backend ส่ง role ผิด (แก้แล้ว แต่ต้อง rebuild)
- ⚠️ Browser cache token เก่า (ต้อง clear cache)

**วิธีแก้:**
1. Rebuild backend
2. Restart backend
3. Clear browser cache
4. Login ใหม่

**ผลลัพธ์ที่คาดหวัง:**
- ✅ Manager เข้า `/dashboard` ได้
- ✅ Receptionist เข้า `/reception` ได้
- ✅ Housekeeper เข้า `/housekeeping` ได้
- ✅ Guest เข้า `/` และ `/bookings` ได้
- ✅ ไม่มี 403 Unauthorized เมื่อเข้าหน้าที่มีสิทธิ์
- ✅ มี 403 Unauthorized เมื่อเข้าหน้าที่ไม่มีสิทธิ์ (ถูกต้อง)
