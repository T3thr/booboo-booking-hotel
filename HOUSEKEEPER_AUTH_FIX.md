# แก้ไขปัญหา Housekeeper Authentication (403 Forbidden)

## ปัญหาที่พบ

เมื่อ housekeeper login ที่ `/auth/admin` สำเร็จแล้ว แต่เมื่อเข้าหน้า `/housekeeping` จะได้ error 403 Forbidden เมื่อเรียก API `/api/housekeeping/tasks`

### Log ที่เห็น:
```
[LOGIN] Attempting login for email: housekeeper1@hotel.com
[LOGIN] Found user ID: 3, Type: staff, Role: HOUSEKEEPER
[LOGIN] Password check SUCCESS
```

แต่ API response:
```
2025/11/05 08:35:20 [GET] 403 | 511.4µs | ::1 | /api/housekeeping/tasks
```

## สาเหตุ

### 1. Backend JWT Token ผิด
ใน `backend/internal/service/auth_service.go` บรรทัด 95:
```go
// ❌ ผิด - ส่ง user_type ("staff") แทน role_code ("HOUSEKEEPER")
token, err := utils.GenerateToken(user.UserID, user.Email, user.UserType, s.jwtSecret)
```

ทำให้ JWT token มี `role: "staff"` แทนที่จะเป็น `role: "HOUSEKEEPER"`

### 2. Middleware ตรวจสอบ Role
ใน `backend/internal/middleware/role.go`:
```go
func RequireHousekeeper() gin.HandlerFunc {
    return RequireRole("HOUSEKEEPER", "MANAGER")
}
```

Middleware ต้องการ role เป็น "HOUSEKEEPER" หรือ "MANAGER" แต่ได้รับ "staff" จึงส่ง 403 Forbidden

### 3. Frontend Redirect Path
ใน `frontend/src/utils/role-redirect.ts`:
```typescript
// ❌ ผิด - redirect ไป /staff/housekeeping (ไม่มีหน้านี้)
case 'HOUSEKEEPER':
  return '/staff/housekeeping';
```

แต่จริงๆ หน้า housekeeping อยู่ที่ `frontend/src/app/(staff)/housekeeping/page.tsx` ซึ่ง route คือ `/housekeeping`

## การแก้ไข

### 1. แก้ Backend - ส่ง role_code แทน user_type

**File: `backend/internal/service/auth_service.go`**

```go
// ✅ ถูกต้อง - ส่ง role_code (HOUSEKEEPER, RECEPTIONIST, MANAGER, GUEST)
token, err := utils.GenerateToken(user.UserID, user.Email, user.RoleCode, s.jwtSecret)
```

แก้ทั้ง 2 จุด:
- บรรทัด 95: ใน Login function
- บรรทัด 67: ใน Register function (เปลี่ยนจาก "guest" เป็น "GUEST")

### 2. แก้ Frontend - Redirect Path

**File: `frontend/src/utils/role-redirect.ts`**

```typescript
export function getRoleHomePage(role: UserRole | string): string {
  switch (role) {
    case 'GUEST':
      return '/';
    case 'RECEPTIONIST':
      return '/reception';  // ✅ แก้จาก /staff/dashboard
    case 'HOUSEKEEPER':
      return '/housekeeping';  // ✅ แก้จาก /staff/housekeeping
    case 'MANAGER':
      return '/dashboard';  // ✅ แก้จาก /manager/dashboard
    default:
      return '/';
  }
}
```

## วิธี Deploy การแก้ไข

### ขั้นตอนที่ 1: Rebuild Backend

```bash
# Windows
fix-housekeeper-auth.bat

# หรือ manual
cd backend
go build -o server.exe ./cmd/server
cd ..
```

### ขั้นตอนที่ 2: Restart Backend

1. หยุด backend server ปัจจุบัน (Ctrl+C)
2. Start ใหม่:
```bash
cd backend
server.exe
```

### ขั้นตอนที่ 3: Restart Frontend (ถ้าจำเป็น)

Frontend จะ hot-reload อัตโนมัติ แต่ถ้าไม่ reload ให้:
```bash
cd frontend
npm run dev
# หรือ
bun dev
```

### ขั้นตอนที่ 4: Clear Browser Cache

1. เปิด DevTools (F12)
2. Right-click บน Refresh button
3. เลือก "Empty Cache and Hard Reload"
4. หรือ Logout แล้ว Login ใหม่

## การทดสอบ

### 1. ทดสอบ Login

ไปที่: `http://localhost:3000/auth/admin`

**Housekeeper:**
- Email: `housekeeper1@hotel.com`
- Password: `staff123`

**Receptionist:**
- Email: `receptionist1@hotel.com`
- Password: `staff123`

**Manager:**
- Email: `manager@hotel.com`
- Password: `staff123`

### 2. ตรวจสอบ JWT Token

เปิด DevTools > Application > Session Storage > ดู token

Decode JWT ที่ [jwt.io](https://jwt.io) ควรเห็น:
```json
{
  "user_id": 3,
  "email": "housekeeper1@hotel.com",
  "role": "HOUSEKEEPER",  // ✅ ต้องเป็น "HOUSEKEEPER" ไม่ใช่ "staff"
  "user_type": "staff"
}
```

### 3. ตรวจสอบ Redirect

หลัง login สำเร็จ:
- Housekeeper → `/housekeeping` ✅
- Receptionist → `/reception` ✅
- Manager → `/dashboard` ✅

### 4. ทดสอบ API Call

เปิด DevTools > Network > ดู request ไป `/api/housekeeping/tasks`

**ควรเห็น:**
```
Status: 200 OK  ✅
```

**ไม่ควรเห็น:**
```
Status: 403 Forbidden  ❌
```

## Database Schema (ตรวจสอบความถูกต้อง)

### Roles Table
```sql
SELECT * FROM roles;
```

ควรมี:
| role_id | role_name | role_code | description |
|---------|-----------|-----------|-------------|
| 1 | Guest | GUEST | ผู้เข้าพัก |
| 2 | Receptionist | RECEPTIONIST | พนักงานต้อนรับ |
| 3 | Housekeeper | HOUSEKEEPER | แม่บ้าน |
| 4 | Manager | MANAGER | ผู้จัดการ |

### Staff Table
```sql
SELECT s.staff_id, s.email, s.first_name, s.last_name, r.role_code, r.role_name
FROM staff s
JOIN roles r ON s.role_id = r.role_id
WHERE s.email = 'housekeeper1@hotel.com';
```

ควรได้:
| staff_id | email | first_name | last_name | role_code | role_name |
|----------|-------|------------|-----------|-----------|-----------|
| 3 | housekeeper1@hotel.com | สมศรี | แม่บ้าน | HOUSEKEEPER | Housekeeper |

### Unified View
```sql
SELECT * FROM v_all_users WHERE email = 'housekeeper1@hotel.com';
```

ควรเห็น `role_code = 'HOUSEKEEPER'`

## URL Structure ที่ถูกต้อง

### Frontend Routes (Next.js App Router)

```
frontend/src/app/
├── (guest)/              → Routes สำหรับ Guest
│   ├── page.tsx         → / (homepage)
│   ├── rooms/           → /rooms
│   └── bookings/        → /bookings
│
├── (staff)/             → Routes สำหรับ Staff (Receptionist + Housekeeper)
│   ├── reception/       → /reception (Receptionist)
│   ├── checkin/         → /checkin (Receptionist)
│   ├── checkout/        → /checkout (Receptionist)
│   ├── housekeeping/    → /housekeeping (Housekeeper)
│   │   ├── page.tsx     → /housekeeping
│   │   └── inspection/  → /housekeeping/inspection
│   └── layout.tsx
│
└── (manager)/           → Routes สำหรับ Manager
    ├── dashboard/       → /dashboard
    ├── pricing/         → /pricing
    ├── inventory/       → /inventory
    └── reports/         → /reports
```

### Backend API Routes

```
/api/housekeeping/tasks              → GET (HOUSEKEEPER, MANAGER)
/api/housekeeping/rooms/:id/status   → PUT (HOUSEKEEPER, MANAGER)
/api/housekeeping/rooms/:id/inspect  → POST (HOUSEKEEPER, MANAGER)
/api/housekeeping/inspection         → GET (HOUSEKEEPER, MANAGER)
```

## สรุป

การแก้ไขนี้แก้ปัญหา 3 จุด:

1. ✅ **Backend JWT** - ส่ง `role_code` ("HOUSEKEEPER") แทน `user_type` ("staff")
2. ✅ **Frontend Redirect** - ไปที่ `/housekeeping` แทน `/staff/housekeeping`
3. ✅ **Middleware** - ตรวจสอบ role ได้ถูกต้อง

หลังจาก rebuild backend และ restart server แล้ว housekeeper จะสามารถ login และเข้าถึง housekeeping tasks ได้ปกติ

## Troubleshooting

### ถ้ายังได้ 403 Forbidden

1. **ตรวจสอบว่า rebuild backend แล้ว:**
   ```bash
   cd backend
   dir server.exe  # ดูวันที่ modified ต้องเป็นวันนี้
   ```

2. **ตรวจสอบว่า restart backend แล้ว:**
   - หยุด process เก่า (Ctrl+C)
   - Start ใหม่ `server.exe`

3. **Clear browser cache และ logout/login ใหม่**

4. **ตรวจสอบ JWT token ใน DevTools:**
   - ต้องมี `"role": "HOUSEKEEPER"` ไม่ใช่ `"role": "staff"`

5. **ตรวจสอบ backend logs:**
   - ดูว่า middleware log อะไร
   - ควรเห็น role เป็น "HOUSEKEEPER"

### ถ้า Frontend ยัง redirect ผิด

1. **Hard refresh browser:** Ctrl+Shift+R
2. **Clear Next.js cache:**
   ```bash
   cd frontend
   rm -rf .next
   npm run dev
   ```

3. **ตรวจสอบ middleware.ts:**
   - ดูว่า `getRoleHomePage()` return path ถูกต้องหรือไม่
