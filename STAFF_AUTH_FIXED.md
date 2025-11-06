# ✅ Staff Authentication System - FIXED!

## สิ่งที่แก้ไข

### 1. เพิ่ม `/auth/admin` เป็น Public Route
แก้ไข `frontend/src/middleware.ts`:
- เพิ่ม `/auth/admin` ใน `publicRoutes` array
- ทำให้ผู้ใช้ที่ยังไม่ได้ login สามารถเข้าถึงหน้า admin login ได้

### 2. รัน Migration 014
รันคำสั่ง:
```bash
cd backend
go run run-migration-014-simple.go
```

สิ่งที่ Migration 014 สร้าง:
- ✅ `roles` table (4 roles: GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
- ✅ `staff` table (7 staff members)
- ✅ `staff_accounts` table (authentication data)
- ✅ `v_all_users` view (unified view สำหรับ guest + staff)

### 3. Backend Authentication
Backend มี code รองรับ staff authentication อยู่แล้ว:
- `auth_service.go` - ใช้ `GetUserByEmail()` ที่ query จาก `v_all_users` view
- `auth_repository.go` - มี `UnifiedUser` model และ functions สำหรับ staff
- `models/staff.go` - มี `UnifiedUser`, `Staff`, `StaffAccount` models

## การทดสอบ

### Staff Login Credentials
```
Manager:
  Email: manager@hotel.com
  Password: staff123

Receptionist:
  Email: receptionist1@hotel.com
  Password: staff123

Housekeeper:
  Email: housekeeper1@hotel.com
  Password: staff123
```

### ขั้นตอนการทดสอบ
1. **Restart Backend Server** (ถ้ารันอยู่)
   ```bash
   # หยุด backend แล้วรันใหม่
   cd backend
   go run cmd/server/main.go
   ```

2. **เปิด Frontend**
   ```bash
   cd frontend
   npm run dev
   ```

3. **ทดสอบ Login**
   - ไปที่ http://localhost:3000
   - คลิก "เข้าสู่ระบบพนักงาน" ที่ด้านล่างของหน้า
   - จะไปที่ `/auth/admin` (ไม่ redirect ไป `/auth/signin` อีกแล้ว)
   - ใส่ email และ password ของ staff
   - ควรจะ login สำเร็จและ redirect ไปหน้าที่เหมาะสมตาม role

## การทำงานของระบบ

### Authentication Flow
1. User กรอก email/password ที่หน้า `/auth/admin`
2. Frontend เรียก NextAuth credentials provider
3. NextAuth เรียก backend API `/api/auth/login`
4. Backend query `v_all_users` view (รวม guest + staff)
5. ตรวจสอบ password ด้วย bcrypt
6. สร้าง JWT token พร้อม role information
7. Return user data + token กลับไป frontend
8. Frontend redirect ตาม role:
   - GUEST → `/`
   - RECEPTIONIST → `/staff/reception`
   - HOUSEKEEPER → `/staff/housekeeping`
   - MANAGER → `/manager/dashboard`

### Database Schema
```
v_all_users (VIEW)
├── FROM guests + guest_accounts (user_type = 'guest', role_code = 'GUEST')
└── FROM staff + staff_accounts + roles (user_type = 'staff', role_code = RECEPTIONIST/HOUSEKEEPER/MANAGER)
```

## ปัญหาที่แก้ไปแล้ว

### ❌ ปัญหาเดิม
1. คลิก "เข้าสู่ระบบพนักงาน" → redirect ไป `/auth/signin` แทน `/auth/admin`
2. Backend log แสดง "Guest not found" เมื่อพยายาม login ด้วย staff email
3. ไม่มี `v_all_users` view ในฐานข้อมูล

### ✅ แก้ไขแล้ว
1. เพิ่ม `/auth/admin` ใน middleware public routes
2. รัน migration 014 เพื่อสร้าง staff tables และ view
3. Backend ใช้ `v_all_users` view ที่รวม guest + staff authentication

## Files ที่เกี่ยวข้อง

### Frontend
- `frontend/src/middleware.ts` - Route protection และ role-based access
- `frontend/src/app/auth/admin/page.tsx` - Staff login page
- `frontend/src/app/page.tsx` - Homepage with staff login link

### Backend
- `backend/internal/service/auth_service.go` - Authentication logic
- `backend/internal/repository/auth_repository.go` - Database queries
- `backend/internal/models/staff.go` - Staff และ UnifiedUser models
- `backend/internal/models/guest.go` - Guest models

### Database
- `database/migrations/014_create_role_system_clean.sql` - Migration script
- `backend/run-migration-014-simple.go` - Migration runner

## Next Steps

หลังจากนี้คุณสามารถ:
1. ✅ Login ด้วย staff accounts
2. ✅ เข้าถึงหน้าต่างๆ ตาม role
3. ✅ ทดสอบ features ต่างๆ ของแต่ละ role
4. 🔄 เพิ่ม staff members ใหม่ผ่าน database หรือสร้าง admin UI

## หมายเหตุ

- Password ทั้งหมดถูก hash ด้วย bcrypt (cost 10)
- JWT tokens มี expiration time 24 ชั่วโมง
- Role-based access control ทำงานทั้งใน frontend (middleware) และ backend (JWT verification)
