# แก้ไขระบบ Admin ให้ทำงานสมบูรณ์กับ Database

## สรุปปัญหาและแนวทางแก้ไข

### ปัญหาหลัก
1. **Inventory Page** - ไม่มีข้อมูลแสดง (empty response)
2. **Reception Page** - ไม่มีข้อมูลห้อง
3. **Pricing Tiers** - ไม่สามารถจัดการราคาได้
4. **Bookings Page** - ต้องแสดง payment proofs และ approve/reject

### สาเหตุ
- Backend APIs บางตัวยังไม่ได้ register ใน router
- Frontend hooks บางตัวยังใช้ mock data
- Database มีข้อมูลแล้ว แต่ API ไม่ได้ดึงมา

## แผนการแก้ไขแบบ Step-by-Step

### Step 1: แก้ไข Backend Router (สำคัญที่สุด!)
ต้องเช็คว่า routes ทั้งหมด register แล้วหรือยัง

### Step 2: แก้ไข Frontend API Calls
ให้เรียก backend APIs จริง ไม่ใช้ mock data

### Step 3: แก้ไข UI Components
ให้แสดงข้อมูลจาก database และ handle empty states

### Step 4: เพิ่ม CRUD Operations
ให้ admin สามารถ create, update, delete ได้จริง

## การแก้ไขแต่ละหน้า

### 1. Inventory Management Page
**ปัญหา**: Empty response `{}`
**สาเหตุ**: API ไม่ได้ return data หรือ route ไม่ได้ register
**แก้ไข**:
1. เช็ค backend router ว่ามี `/api/inventory` หรือไม่
2. แก้ไข `use-inventory.ts` ให้ handle empty data
3. เพิ่ม loading และ empty states ใน UI
4. เพิ่ม CRUD operations

### 2. Reception (Room Status) Page
**ปัญหา**: ไม่มีข้อมูลห้อง
**สาเหตุ**: API endpoint อาจไม่ถูกต้อง
**แก้ไข**:
1. ใช้ `/api/rooms/status` หรือ `/api/housekeeping/tasks`
2. แสดงสถานะห้องจาก `rooms` table
3. เพิ่ม filters และ search
4. เชื่อมกับ housekeeping system

### 3. Pricing Tiers Page
**ปัญหา**: ไม่สามารถจัดการ tiers ได้
**สาเหตุ**: ขาด CRUD operations
**แก้ไข**:
1. เพิ่ม POST `/api/pricing/tiers` (create)
2. เพิ่ม PUT `/api/pricing/tiers/:id` (update)
3. เพิ่ม DELETE `/api/pricing/tiers/:id` (delete)
4. เพิ่ม UI forms สำหรับ CRUD

### 4. Pricing Matrix Page
**ปัญหา**: ไม่แสดง matrix
**สาเหตุ**: ขาด API endpoint
**แก้ไข**:
1. สร้าง `/api/pricing/matrix` endpoint
2. Return data: room_types × rate_plans
3. เพิ่ม inline editing
4. Save changes to database

### 5. Bookings Management Page
**ปัญหา**: ไม่แสดง payment proofs
**สาเหตุ**: ต้องดึงจาก `payment_proofs` table
**แก้ไข**:
1. ใช้ `/api/admin/payment-proofs` (มีแล้ว)
2. แสดง bookings ที่มี proof
3. เพิ่ม approve/reject buttons
4. Update booking status หลัง approve

### 6. Manager Dashboard
**ปัญหา**: ต้องแสดง real-time stats
**แก้ไข**:
1. สร้าง `/api/dashboard/stats` endpoint
2. Return: occupancy rate, revenue, pending bookings
3. แสดง charts และ summary cards
4. Auto-refresh ทุก 5 นาที

### 7. Housekeeping Page
**ปัญหา**: ต้องแสดง tasks จริง
**แก้ไข**:
1. ใช้ `/api/housekeeping/tasks`
2. แสดงห้องที่ต้องทำความสะอาด
3. เพิ่ม status update buttons
4. เชื่อมกับ `housekeeping_logs` table

### 8. Check-in/Check-out Pages
**ปัญหา**: ต้องเรียก stored procedures
**แก้ไข**:
1. ใช้ `/api/checkin` และ `/api/checkout`
2. เรียก `fn_check_in_booking()` และ `fn_check_out_booking()`
3. แสดง arrivals/departures ของวันที่เลือก
4. เลือกห้องที่ available

## Database Tables ที่ใช้

```sql
-- Inventory
room_inventory (room_type_id, date, allotment, booked_count, tentative_count)

-- Rooms
rooms (room_id, room_number, room_type_id, occupancy_status, housekeeping_status)

-- Pricing
rate_plans (rate_plan_id, plan_name)
pricing_tiers (tier_id, tier_name, multiplier)
pricing_calendar (room_type_id, date, tier_id, rate_plan_id)

-- Bookings
bookings (booking_id, guest_account_id, status, total_amount)
booking_details (detail_id, booking_id, room_type_id, check_in, check_out)
payment_proofs (proof_id, booking_id, image_url, status, uploaded_at)

-- Housekeeping
housekeeping_logs (log_id, room_id, status, staff_id, timestamp)
```

## API Endpoints ที่ต้องมี

### ✅ มีแล้ว
- GET /api/rooms/search
- GET /api/bookings
- POST /api/bookings
- POST /api/bookings/:id/confirm
- POST /api/bookings/:id/cancel
- GET /api/admin/payment-proofs
- POST /api/admin/payment-proofs/:id/approve
- POST /api/admin/payment-proofs/:id/reject

### ❌ ต้องเพิ่ม/แก้ไข
- GET /api/inventory (แก้ไขให้ return data ถูกต้อง)
- PUT /api/inventory (update single date)
- POST /api/inventory/bulk (bulk update)
- GET /api/rooms/status (สำหรับ reception)
- GET /api/pricing/tiers
- POST /api/pricing/tiers
- PUT /api/pricing/tiers/:id
- DELETE /api/pricing/tiers/:id
- GET /api/pricing/matrix
- PUT /api/pricing/rates
- GET /api/dashboard/stats
- GET /api/housekeeping/tasks
- PUT /api/housekeeping/rooms/:id/status
- GET /api/checkin/arrivals
- GET /api/checkout/departures

## ลำดับการแก้ไข (Priority)

### High Priority (ต้องแก้ก่อน)
1. ✅ Backend Router - register ทุก routes
2. ✅ Inventory API - ให้ return data ถูกต้อง
3. ✅ Room Status API - สำหรับ reception
4. ✅ Bookings + Payment Proofs - approve/reject

### Medium Priority
5. ✅ Pricing Tiers CRUD
6. ✅ Pricing Matrix
7. ✅ Dashboard Stats

### Low Priority
8. ✅ Housekeeping Tasks
9. ✅ Check-in/Check-out improvements

## Testing Checklist

### Inventory Page
- [ ] แสดงรายการ room types
- [ ] เลือก room type แล้วแสดง calendar
- [ ] คลิกวันแล้วแก้ไข allotment ได้
- [ ] Save แล้วข้อมูลอัพเดทใน database

### Reception Page
- [ ] แสดงรายการห้องทั้งหมด
- [ ] Filter by status ได้
- [ ] Search by room number ได้
- [ ] คลิกห้องแล้วดู details ได้

### Pricing Tiers Page
- [ ] แสดงรายการ tiers
- [ ] Create new tier ได้
- [ ] Edit tier ได้
- [ ] Delete tier ได้

### Bookings Page
- [ ] แสดง bookings ที่มี payment proof
- [ ] คลิกดูรูป proof ได้
- [ ] Approve แล้ว status เปลี่ยนเป็น Confirmed
- [ ] Reject แล้ว status เปลี่ยนเป็น Cancelled

## Next Steps

1. เริ่มจากการเช็ค backend router
2. แก้ไข inventory API ให้ทำงาน
3. แก้ไข frontend hooks ทีละตัว
4. แก้ไข UI pages ทีละหน้า
5. Test ทุกหน้าให้ทำงานได้
