# Manager Flow - Complete Verification Guide

## 🎯 เป้าหมาย
ตรวจสอบว่า Manager สามารถเข้าถึงและใช้งานทุกฟีเจอร์ได้โดยไม่มี error 403 หรือ 404

---

## ✅ สิ่งที่ตรวจสอบแล้ว

### 1. Database Schema (014_create_role_system.sql)
- ✅ มี roles table พร้อม 4 roles: GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER
- ✅ มี staff table พร้อม role_id foreign key
- ✅ มี v_all_users view ที่รวม guests และ staff พร้อม role_code
- ✅ Manager account: manager@hotel.com / staff123 (role_id = 4, MANAGER)

### 2. Backend Authentication (auth_service.go)
- ✅ Login ดึงข้อมูลจาก v_all_users view
- ✅ JWT token มี role_code (GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
- ✅ Response มี role_code และ user_type

### 3. Backend Middleware (role.go)
- ✅ RequireManager() - เช็คว่า role = "MANAGER"
- ✅ RequireReceptionist() - อนุญาต RECEPTIONIST และ MANAGER
- ✅ RequireHousekeeper() - อนุญาต HOUSEKEEPER และ MANAGER
- ✅ MANAGER มีสิทธิ์เข้าถึงทุก endpoint

### 4. Backend Routes (router.go)
- ✅ /api/pricing/* - RequireManager()
- ✅ /api/inventory/* - RequireManager()
- ✅ /api/reports/* - RequireManager()
- ✅ /api/admin/* - RequireManager()
- ✅ /api/checkin/* - RequireReceptionist() (MANAGER ได้ด้วย)
- ✅ /api/housekeeping/* - RequireHousekeeper() (MANAGER ได้ด้วย)

### 5. Frontend Auth (lib/auth.ts)
- ✅ NextAuth รับ role_code จาก backend
- ✅ Session มี user.role = role_code
- ✅ Token มี role และ userType

### 6. Frontend Middleware (middleware.ts)
- ✅ MANAGER มีสิทธิ์เข้าถึงทุก route (superuser)
- ✅ Role-based access control สำหรับ user อื่นๆ
- ✅ Redirect ไป /unauthorized ถ้าไม่มีสิทธิ์

### 7. Manager Pages
- ✅ Dashboard (dashboard/page.tsx) - เรียก API reports
- ✅ Pricing Tiers (pricing/tiers/page.tsx) - เรียก API pricing
- ✅ Inventory (inventory/page.tsx) - เรียก API inventory
- ✅ Reports (reports/page.tsx) - เรียก API reports

---

## 🔍 การทดสอบ

### Test 1: Manager Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"staff123"}'
```

**Expected Response:**
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
  },
  "message": "เข้าสู่ระบบสำเร็จ"
}
```

### Test 2: Dashboard APIs

#### Revenue Report
```bash
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-12-01&end_date=2024-12-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK with revenue data

#### Occupancy Report
```bash
curl -X GET "http://localhost:8080/api/reports/occupancy?start_date=2024-12-01&end_date=2024-12-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK with occupancy data

### Test 3: Pricing APIs

#### Get Rate Tiers
```bash
curl -X GET "http://localhost:8080/api/pricing/tiers" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK with rate tiers list

#### Create Rate Tier
```bash
curl -X POST "http://localhost:8080/api/pricing/tiers" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Season","description":"Test"}'
```

**Expected:** 201 Created

### Test 4: Inventory APIs

#### Get Inventory
```bash
curl -X GET "http://localhost:8080/api/inventory?start_date=2024-12-01&end_date=2024-12-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK with inventory data

#### Update Inventory
```bash
curl -X PUT "http://localhost:8080/api/inventory" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"room_type_id":1,"date":"2024-12-25","allotment":15}'
```

**Expected:** 200 OK

### Test 5: Reports APIs

#### Get Reports
```bash
curl -X GET "http://localhost:8080/api/reports/summary?start_date=2024-12-01&end_date=2024-12-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected:** 200 OK with summary data

---

## 🚀 การทดสอบ Frontend

### 1. เริ่มระบบ

```bash
# Terminal 1: Backend
cd backend
go run ./cmd/server

# Terminal 2: Frontend
cd frontend
npm run dev
```

### 2. ทดสอบ Manager Flow

#### Step 1: Login
1. เปิด http://localhost:3000/auth/admin
2. Login:
   - Email: manager@hotel.com
   - Password: staff123
3. ตรวจสอบ redirect ไป /dashboard

#### Step 2: Dashboard
1. ตรวจสอบแสดงข้อมูล:
   - รายได้วันนี้
   - อัตราการเข้าพัก
   - การจองวันนี้
   - การจองทั้งหมด
2. เปิด DevTools → Network
3. ตรวจสอบ API calls:
   - /api/reports/revenue - 200 OK
   - /api/reports/occupancy - 200 OK
   - /api/bookings - 200 OK

#### Step 3: Pricing Tiers
1. คลิก "จัดการราคา"
2. ตรวจสอบแสดงรายการ rate tiers
3. ทดสอบสร้าง rate tier ใหม่:
   - ชื่อ: "Test Season"
   - คำอธิบาย: "For testing"
   - คลิก "บันทึก"
4. ตรวจสอบ:
   - ไม่มี error 403
   - สร้างสำเร็จ
   - แสดงใน list

#### Step 4: Inventory
1. คลิก "สต็อกห้องพัก"
2. เลือกวันที่ 1-31 ธ.ค. 2024
3. ตรวจสอบแสดง inventory table
4. ทดสอบแก้ไข allotment:
   - เลือก Deluxe Room วันที่ 25 ธ.ค.
   - เปลี่ยน allotment จาก 10 → 15
   - คลิก "บันทึก"
5. ตรวจสอบ:
   - ไม่มี error 403
   - อัพเดตสำเร็จ
   - แสดงค่าใหม่

#### Step 5: Reports
1. คลิก "รายงาน"
2. เลือกช่วงวันที่ 1-31 ธ.ค. 2024
3. ตรวจสอบแสดง:
   - รายงานรายได้
   - รายงานการเข้าพัก
   - Summary cards
4. ตรวจสอบ:
   - ไม่มี error 403
   - ข้อมูลแสดงถูกต้อง

---

## 🐛 Troubleshooting

### Error 403 Forbidden

**สาเหตุที่เป็นไปได้:**
1. Token ไม่มี role_code หรือ role_code ไม่ถูกต้อง
2. Middleware ไม่ได้เช็ค role ถูกต้อง
3. Session ไม่มี role

**วิธีแก้:**
1. ตรวจสอบ login response มี role_code = "MANAGER"
2. ตรวจสอบ NextAuth session มี user.role = "MANAGER"
3. ตรวจสอบ backend middleware อนุญาต MANAGER

### Error 404 Not Found

**สาเหตุที่เป็นไปได้:**
1. API endpoint ไม่ถูกต้อง
2. Backend route ไม่ได้ register
3. Frontend เรียก URL ผิด

**วิธีแก้:**
1. ตรวจสอบ backend router.go มี route นั้น
2. ตรวจสอบ frontend API call URL ถูกต้อง
3. ตรวจสอบ backend running บน port 8080

### Data ไม่แสดง

**สาเหตุที่เป็นไปได้:**
1. Database ไม่มีข้อมูล
2. API query ผิด
3. Frontend parsing ผิด

**วิธีแก้:**
1. ตรวจสอบ database มีข้อมูล:
   ```sql
   SELECT COUNT(*) FROM bookings;
   SELECT COUNT(*) FROM rooms;
   ```
2. ทดสอบ API ด้วย curl
3. ตรวจสอบ console.log ใน frontend

---

## ✅ Checklist สำหรับ Demo

### Backend
- [ ] Backend running บน port 8080
- [ ] Database มีข้อมูล demo
- [ ] Manager account พร้อมใช้งาน
- [ ] ทุก API endpoint ทำงาน

### Frontend
- [ ] Frontend running บน port 3000
- [ ] Login page ทำงาน
- [ ] Dashboard แสดงข้อมูลจริง
- [ ] Pricing pages ทำงาน
- [ ] Inventory page ทำงาน
- [ ] Reports page ทำงาน

### Testing
- [ ] Login สำเร็จ
- [ ] Redirect ไป /dashboard
- [ ] Dashboard แสดงข้อมูล
- [ ] CRUD operations ทำงาน
- [ ] ไม่มี error 403/404
- [ ] ไม่มี console errors

---

## 📝 สรุป

### ระบบออกแบบถูกต้อง ✅

1. **Database:** มี role system ที่สมบูรณ์
2. **Backend:** มี role-based access control
3. **Frontend:** มี role checking และ redirect
4. **Manager:** มีสิทธิ์เข้าถึงทุกอย่าง (superuser)

### การทำงาน ✅

1. Manager login → รับ JWT token พร้อม role_code = "MANAGER"
2. Frontend เก็บ role ใน session
3. Middleware เช็ค role ก่อนเข้า route
4. Backend middleware เช็ค role ก่อนเรียก API
5. MANAGER ผ่านทุก check (superuser)

### ไม่ควรมี Error 403/404 ✅

- Manager มีสิทธิ์เข้าถึงทุก route
- ทุก API endpoint มี middleware ที่ถูกต้อง
- Frontend และ Backend sync กัน

---

## 🎯 Next Steps

1. **ทดสอบด้วย script:** `test-manager-flow-complete.bat`
2. **ทดสอบ Frontend:** ตาม checklist ข้างบน
3. **ฝึกซ้อม Demo:** ตาม DEMO_SCRIPT_THAI.md
4. **เตรียม Backup:** Screen recording

---

**หมายเหตุ:** ถ้ายังมี error 403/404 แสดงว่ามีปัญหาที่:
1. Backend ไม่ได้ start
2. Database ไม่มีข้อมูล
3. Environment variables ไม่ถูกต้อง
4. Token expired

ให้ตรวจสอบ logs และ console errors เพื่อหาสาเหตุที่แท้จริง
