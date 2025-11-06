# คู่มือการใช้งาน Manager Dashboard

## 🎯 สรุปสั้นๆ

ระบบ Manager Dashboard ทำงานได้สมบูรณ์แล้ว! Manager สามารถ:
- ✅ เข้าสู่ระบบและเข้าถึง Dashboard
- ✅ จัดการราคาห้องพัก (Pricing)
- ✅ จัดการสต็อกห้อง (Inventory)
- ✅ ดูรายงานต่างๆ (Reports)
- ✅ ไม่มี Error 403 หรือ 404

---

## 📋 ขั้นตอนการทดสอบ

### 1. เริ่มระบบ

```bash
# เริ่ม Backend + Database
cd backend
go run cmd/server/main.go

# เริ่ม Frontend (terminal ใหม่)
cd frontend
npm run dev
```

### 2. Login เป็น Manager

```
URL: http://localhost:3000/auth/signin
Email: manager@hotel.com
Password: staff123
```

### 3. ทดสอบฟีเจอร์

หลัง login จะ redirect ไปที่ `/dashboard` อัตโนมัติ

#### Dashboard (หน้าหลัก)
- แสดงรายได้วันนี้
- แสดงอัตราการเข้าพัก
- แสดงจำนวนการจอง
- มีปุ่มลัดไปยังเมนูต่างๆ

#### จัดการราคา (Pricing)
```
/pricing/tiers     - ตั้งค่า Rate Tiers
/pricing/calendar  - ปรับราคาตามวัน
/pricing/matrix    - ตารางราคาแบบละเอียด
```

#### จัดการสต็อก (Inventory)
```
/inventory - ตั้งค่าจำนวนห้องที่เปิดขาย
```

#### รายงาน (Reports)
```
/reports - ดูรายงานต่างๆ
  - รายงานการเข้าพัก (Occupancy)
  - รายงานรายได้ (Revenue)
  - รายงาน Voucher
  - รายงาน No-Show
```

---

## 🔍 การตรวจสอบอัตโนมัติ

### วิธีที่ 1: ใช้ Script ทดสอบ

```bash
# รัน script ทดสอบอัตโนมัติ
verify-manager-access.bat
```

Script นี้จะ:
1. Login เป็น Manager
2. ทดสอบ API ทุกตัวที่ Dashboard ใช้
3. แสดงผลว่าผ่านหรือไม่ผ่าน

### วิธีที่ 2: ทดสอบด้วยมือ

```bash
# 1. Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"staff123"}'

# คัดลอก accessToken จากผลลัพธ์

# 2. ทดสอบ Dashboard API
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2025-11-05&end_date=2025-11-05" \
  -H "Authorization: Bearer <TOKEN>"

# 3. ทดสอบ Pricing API
curl -X GET http://localhost:8080/api/pricing/tiers \
  -H "Authorization: Bearer <TOKEN>"

# 4. ทดสอบ Inventory API
curl -X GET "http://localhost:8080/api/inventory?start_date=2025-01-01&end_date=2025-01-31" \
  -H "Authorization: Bearer <TOKEN>"
```

---

## 🏗️ สถาปัตยกรรมระบบ

### Database Layer
```
roles table
  └── role_id: 4 = MANAGER
  └── role_code: 'MANAGER'

staff table
  └── email: manager@hotel.com
  └── role_id: 4 (references roles)

v_all_users view
  └── รวมข้อมูล guest + staff
  └── ใช้สำหรับ authentication
```

### Backend Layer
```
router.go
  └── /api/pricing/*    → RequireManager()
  └── /api/inventory/*  → RequireManager()
  └── /api/reports/*    → RequireManager()

middleware/role.go
  └── RequireManager() → ตรวจสอบ role_code = 'MANAGER'
  └── ถ้าไม่ใช่ → return 403 Forbidden
```

### Frontend Layer
```
middleware.ts
  └── ตรวจสอบ session.user.role
  └── MANAGER → อนุญาตทุก route
  └── อื่นๆ → ตรวจสอบตาม roleAccess

lib/auth.ts (NextAuth)
  └── Login → เรียก /api/auth/login
  └── เก็บ role_code ใน JWT token
  └── เก็บ role ใน session
```

---

## 🔐 ระบบ Role-Based Access Control

### Role Hierarchy

```
MANAGER (ระดับสูงสุด)
  ├── เข้าถึงได้ทุกอย่าง
  ├── Dashboard, Pricing, Inventory, Reports
  ├── สามารถทำงานแทน Receptionist ได้
  └── สามารถทำงานแทน Housekeeper ได้

RECEPTIONIST
  ├── Check-in/Check-out
  ├── จัดการ Booking
  └── ดูสถานะห้อง

HOUSEKEEPER
  ├── ทำความสะอาดห้อง
  ├── รายงานซ่อมบำรุง
  └── ตรวจสอบห้อง

GUEST
  ├── ค้นหาห้อง
  ├── จองห้อง
  └── ดูประวัติการจองของตัวเอง
```

### การป้องกันใน Backend

```go
// ทุก endpoint ที่ Manager ใช้มี middleware ป้องกัน
pricing.Use(middleware.RequireManager())
inventory.Use(middleware.RequireManager())
reports.Use(middleware.RequireManager())

// ถ้า role ไม่ใช่ MANAGER จะได้ 403 Forbidden
{
  "error": "Forbidden",
  "message": "คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้",
  "required_roles": ["MANAGER"],
  "user_role": "RECEPTIONIST"
}
```

### การป้องกันใน Frontend

```typescript
// middleware.ts ตรวจสอบก่อนแสดงหน้า
if (userRole === 'MANAGER') {
  return NextResponse.next(); // อนุญาตทุกอย่าง
}

// ถ้าไม่ใช่ Manager และพยายามเข้า /dashboard
if (pathname.startsWith('/dashboard')) {
  if (!['MANAGER'].includes(userRole)) {
    return NextResponse.redirect('/unauthorized');
  }
}
```

---

## 📊 Dashboard API Calls

### Revenue Report
```typescript
api.get('/api/reports/revenue', {
  params: { 
    start_date: '2025-11-05', 
    end_date: '2025-11-05' 
  }
})

// Response:
{
  "data": [{
    "report_date": "2025-11-05",
    "total_revenue": 45000,
    "booking_count": 15
  }]
}
```

### Occupancy Report
```typescript
api.get('/api/reports/occupancy', {
  params: { 
    start_date: '2025-11-05', 
    end_date: '2025-11-05' 
  }
})

// Response:
{
  "data": [{
    "report_date": "2025-11-05",
    "occupancy_rate": 75.5,
    "occupied_rooms": 30,
    "total_rooms": 40
  }]
}
```

### Bookings
```typescript
api.get('/api/bookings', {
  params: { 
    status: 'Confirmed', 
    limit: 100 
  }
})

// Response:
{
  "data": [...bookings],
  "total": 45
}
```

---

## 🐛 แก้ปัญหาที่พบบ่อย

### ปัญหา: ได้ 403 Forbidden

**สาเหตุ**: Role ไม่ถูกต้องหรือ token หมดอายุ

**วิธีแก้**:
```javascript
// 1. ตรวจสอบ session ใน browser console
console.log(session);
// ต้องมี: { user: { role: 'MANAGER' } }

// 2. ตรวจสอบ token
console.log(session.accessToken);

// 3. Login ใหม่
signOut();
// แล้ว login อีกครั้ง
```

### ปัญหา: ได้ 404 Not Found

**สาเหตุ**: Backend ไม่ทำงานหรือ URL ผิด

**วิธีแก้**:
```bash
# 1. ตรวจสอบ backend ทำงานหรือไม่
curl http://localhost:8080/health

# 2. ตรวจสอบ endpoint
curl http://localhost:8080/api/pricing/tiers

# 3. ตรวจสอบ .env
# NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

### ปัญหา: Dashboard ไม่แสดงข้อมูล

**สาเหตุ**: API ไม่มีข้อมูลหรือ query ผิด

**วิธีแก้**:
```bash
# 1. ตรวจสอบว่ามีข้อมูลใน database
psql -U postgres -d hotel_booking
SELECT * FROM bookings LIMIT 5;

# 2. ตรวจสอบ API response
# เปิด Network tab ใน browser DevTools
# ดูว่า API return อะไร

# 3. Seed ข้อมูลใหม่ถ้าจำเป็น
cd database/migrations
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

---

## ✅ Checklist การทดสอบ

### Backend
- [ ] Backend ทำงาน (port 8080)
- [ ] Database มีข้อมูล staff (manager@hotel.com)
- [ ] Migration 014 รันแล้ว (role system)
- [ ] API /health ตอบกลับ OK

### Authentication
- [ ] Login ด้วย manager@hotel.com สำเร็จ
- [ ] ได้ accessToken กลับมา
- [ ] Token มี role_code = 'MANAGER'
- [ ] Session มี user.role = 'MANAGER'

### Dashboard
- [ ] Redirect ไป /dashboard หลัง login
- [ ] แสดงรายได้วันนี้
- [ ] แสดงอัตราการเข้าพัก
- [ ] แสดงจำนวนการจอง
- [ ] ไม่มี error ใน console

### Pricing
- [ ] เข้า /pricing/tiers ได้
- [ ] แสดงรายการ rate tiers
- [ ] สามารถสร้าง/แก้ไข tier ได้
- [ ] ไม่มี 403 error

### Inventory
- [ ] เข้า /inventory ได้
- [ ] แสดงข้อมูล inventory
- [ ] สามารถแก้ไขได้
- [ ] ไม่มี 403 error

### Reports
- [ ] เข้า /reports ได้
- [ ] แสดงรายงานต่างๆ
- [ ] สามารถ export ได้
- [ ] ไม่มี 403 error

---

## 📝 บันทึกการพัฒนา

### ✅ สิ่งที่ทำเสร็จแล้ว

1. **Database Schema**
   - สร้าง roles table (4 roles)
   - สร้าง staff table (เชื่อมกับ roles)
   - สร้าง v_all_users view (unified authentication)
   - Seed ข้อมูล manager@hotel.com

2. **Backend API**
   - สร้าง role middleware (RequireManager, RequireStaff, etc.)
   - ป้องกัน pricing endpoints
   - ป้องกัน inventory endpoints
   - ป้องกัน reports endpoints
   - Return 403 ถ้า role ไม่ถูกต้อง

3. **Frontend**
   - NextAuth integration
   - Role-based middleware
   - Manager dashboard page
   - Pricing management pages
   - Inventory management page
   - Reports page
   - API client with auth headers

4. **Testing**
   - สร้าง verify-manager-access.bat
   - สร้าง test-manager-flow.bat
   - เขียนเอกสารคู่มือ

### 🎯 ผลลัพธ์

Manager สามารถ:
- ✅ Login เข้าระบบ
- ✅ เข้าถึง Dashboard
- ✅ จัดการราคา (Pricing)
- ✅ จัดการสต็อก (Inventory)
- ✅ ดูรายงาน (Reports)
- ✅ ไม่มี 403 หรือ 404 errors

---

## 🚀 พร้อมสำหรับ Demo!

ระบบพร้อมใช้งานแล้ว ทดสอบได้ทันทีด้วย:

```bash
# 1. เริ่มระบบ
start.bat

# 2. ทดสอบ Manager flow
verify-manager-access.bat

# 3. เปิด browser
http://localhost:3000/auth/signin

# 4. Login
manager@hotel.com / staff123
```

สนุกกับการใช้งาน! 🎉
