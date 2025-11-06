# ✅ Role-Based Authentication System - Implementation Complete

## สรุปการทำงาน

ระบบ Role-Based Authentication ได้รับการอัปเดตเรียบร้อยแล้ว รองรับทั้ง **Guests** และ **Staff** (Receptionist, Housekeeper, Manager) ผ่าน unified login endpoint เดียว

---

## 🎯 สิ่งที่ทำเสร็จแล้ว

### 1. Backend - Models & Data Structures
✅ **backend/internal/models/staff.go** - สร้างใหม่
- `Staff` model สำหรับข้อมูลพนักงาน
- `StaffAccount` model สำหรับ authentication
- `Role` model สำหรับบทบาท
- `UnifiedUser` model สำหรับ unified view (v_all_users)
- `LoginRequest` และ `LoginResponse` models
- Helper methods: `IsGuest()`, `IsStaff()`, `HasRole()`, `CanAccess()`

### 2. Backend - JWT Utilities
✅ **backend/pkg/utils/jwt.go** - อัปเดตแล้ว
- เพิ่ม `UserType` field ใน Claims (guest/staff)
- `GenerateToken()` - สร้าง token พร้อม role และ user type
- `RefreshToken()` - refresh token
- `IsTokenExpired()` - ตรวจสอบ expiration
- Helper methods: `IsGuest()`, `IsStaff()`, `IsManager()`, `HasRole()`, `CanAccess()`

### 3. Backend - Authentication Middleware
✅ **backend/internal/middleware/auth.go** - อัปเดตแล้ว
- `AuthMiddleware()` - validate JWT และ set user context
- `OptionalAuth()` - validate token ถ้ามี (ไม่บังคับ)
- Set context: `user_id`, `user_email`, `user_role`, `user_type`

✅ **backend/internal/middleware/role.go** - สร้างใหม่
- `RequireRole()` - ตรวจสอบ role ที่ต้องการ
- `RequireGuest()` - เฉพาะ guests
- `RequireStaff()` - เฉพาะ staff ทุกประเภท
- `RequireReceptionist()` - เฉพาะ receptionist และ manager
- `RequireHousekeeper()` - เฉพาะ housekeeper และ manager
- `RequireManager()` - เฉพาะ manager
- Helper functions: `GetUserRole()`, `GetUserID()`, `IsGuest()`, `IsStaff()`

### 4. Backend - Repository Layer
✅ **backend/internal/repository/auth_repository.go** - อัปเดตแล้ว
- `GetUserByEmail()` - unified query จาก v_all_users view
- `UpdateLastLogin()` - รองรับทั้ง guest และ staff
- `GetStaffByEmail()` - query staff พร้อม role
- `GetStaffAccountByStaffID()` - get staff account
- `CreateStaff()` - สร้าง staff ใหม่
- `CreateStaffAccount()` - สร้าง staff account
- `GetRoles()` - list ทุก roles
- `GetRoleByCode()` - get role by code
- รักษา backward compatibility กับ guest methods

### 5. Backend - Service Layer
✅ **backend/internal/service/auth_service.go** - อัปเดตแล้ว
- `Login()` - **Unified login** รองรับทั้ง guests และ staff
- `Register()` - guest registration (เช็ค email ซ้ำทั้ง guests และ staff)
- `CreateStaff()` - สร้าง staff account (สำหรับ admin)
- `GetRoles()` - list roles
- `ValidateToken()` - validate JWT
- `GetUserHomePage()` - redirect ตาม role
- `CanAccessResource()` - ตรวจสอบสิทธิ์

### 6. Backend - Handler Layer
✅ **backend/internal/handlers/auth_handler.go** - อัปเดตแล้ว
- `Login()` - unified login endpoint
- รองรับ error messages ภาษาไทย
- Return `LoginResponse` พร้อม role และ user type

### 7. Backend - Router
✅ **backend/internal/router/router.go** - ใช้งานได้แล้ว
- ใช้ `middleware.RequireRole()` ในทุก protected routes
- Role-based access control:
  - `/api/rooms/status` - receptionist
  - `/api/checkin/*` - receptionist
  - `/api/checkout/*` - receptionist
  - `/api/housekeeping/*` - housekeeper
  - `/api/pricing/*` - manager
  - `/api/inventory/*` - manager
  - `/api/policies/*` - manager
  - `/api/reports/*` - manager
  - `/api/admin/*` - manager

---

## 🔐 Role Hierarchy

```
GUEST          → ผู้เข้าพัก (จองห้อง, ดูการจองของตัวเอง)
RECEPTIONIST   → พนักงานต้อนรับ (check-in, check-out, จัดการการจอง)
HOUSEKEEPER    → แม่บ้าน (จัดการสถานะห้อง, ทำความสะอาด)
MANAGER        → ผู้จัดการ (เข้าถึงทุกอย่าง, รายงาน, ตั้งค่า)
```

---

## 📋 Database Schema

ระบบใช้ **v_all_users view** ที่รวม guests และ staff เข้าด้วยกัน:

```sql
CREATE OR REPLACE VIEW v_all_users AS
SELECT 
    'guest' as user_type,
    g.guest_id as user_id,
    g.first_name,
    g.last_name,
    g.email,
    g.phone,
    'GUEST' as role_code,
    'Guest' as role_name,
    ga.hashed_password,
    ga.last_login,
    g.created_at
FROM guests g
JOIN guest_accounts ga ON g.guest_id = ga.guest_id

UNION ALL

SELECT 
    'staff' as user_type,
    s.staff_id as user_id,
    s.first_name,
    s.last_name,
    s.email,
    s.phone,
    r.role_code,
    r.role_name,
    sa.hashed_password,
    sa.last_login,
    s.created_at
FROM staff s
JOIN staff_accounts sa ON s.staff_id = sa.staff_id
JOIN roles r ON s.role_id = r.role_id
WHERE s.is_active = true;
```

---

## 🔄 Login Flow

### 1. Client ส่ง Login Request
```json
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
```

### 2. Backend Process
1. Query `v_all_users` view ด้วย email
2. ตรวจสอบ password hash
3. สร้าง JWT token พร้อม role และ user_type
4. Update last_login (guest_accounts หรือ staff_accounts)

### 3. Response
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role_code": "RECEPTIONIST",
  "role_name": "Receptionist",
  "user_type": "staff",
  "accessToken": "eyJhbGc..."
}
```

### 4. Frontend Redirect
- `GUEST` → `/`
- `RECEPTIONIST` → `/staff`
- `HOUSEKEEPER` → `/staff/housekeeping`
- `MANAGER` → `/admin`

---

## 🧪 Testing

### Test Unified Login
```bash
# Guest Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guest@example.com","password":"password123"}'

# Staff Login (Receptionist)
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"receptionist@hotel.com","password":"password123"}'

# Staff Login (Manager)
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"password123"}'
```

### Test Protected Endpoints
```bash
# Get token from login response
TOKEN="eyJhbGc..."

# Test receptionist endpoint
curl -X GET http://localhost:8080/api/checkin/arrivals \
  -H "Authorization: Bearer $TOKEN"

# Test manager endpoint
curl -X GET http://localhost:8080/api/reports/summary \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📝 Next Steps

### Frontend Integration (ต้องทำต่อ)
1. ✅ อัปเดต login form ให้รองรับ unified login
2. ✅ อัปเดต auth store ให้เก็บ role และ user_type
3. ✅ สร้าง role-based redirect logic
4. ✅ อัปเดต middleware ให้ตรวจสอบ role
5. ✅ สร้าง protected routes ตาม role

### Testing
1. ⏳ Unit tests สำหรับ auth service
2. ⏳ Integration tests สำหรับ login flow
3. ⏳ E2E tests สำหรับ role-based access

### Documentation
1. ✅ API documentation
2. ⏳ User guides สำหรับแต่ละ role
3. ⏳ Deployment guide

---

## 🎉 สรุป

ระบบ Role-Based Authentication ได้รับการพัฒนาเสร็จสมบูรณ์แล้ว! 

**Key Features:**
- ✅ Unified login สำหรับทั้ง guests และ staff
- ✅ JWT tokens พร้อม role และ user type
- ✅ Role-based middleware สำหรับ access control
- ✅ Backward compatible กับ guest authentication เดิม
- ✅ Database view (v_all_users) สำหรับ unified queries
- ✅ Helper methods สำหรับ role checking

**ระบบพร้อมใช้งานแล้ว!** 🚀
