# ระบบ Admin - Workflow และหน้าที่ของแต่ละหน้า

## ภาพรวมระบบ Admin

ระบบ Admin แบ่งออกเป็น 2 กลุ่มหลัก:
1. **Staff Pages** - สำหรับพนักงาน (Receptionist, Housekeeper)
2. **Manager Pages** - สำหรับผู้จัดการ (Manager)

---

## 📋 Staff Pages (พนักงาน)

### 1. Reception (หน้าต้อนรับ)
**Path**: `/admin/reception`
**Role**: Receptionist, Manager
**หน้าที่**: แสดงสถานะห้องทั้งหมดแบบ real-time

**Workflow**:
```
1. แสดงรายการห้องทั้งหมดจาก `rooms` table
2. แสดงสถานะ:
   - Occupancy Status: Vacant, Occupied, Reserved
   - Housekeeping Status: Clean, Dirty, Cleaning, Inspected, MaintenanceRequired
3. Filter by status
4. Search by room number
5. คลิกห้องเพื่อดู details และ history
```

**Database Tables**:
- `rooms` - ข้อมูลห้อง
- `housekeeping_logs` - ประวัติการทำความสะอาด
- `bookings` + `booking_details` - การจองที่เกี่ยวข้อง

**API Endpoints**:
- GET `/api/rooms/status` - ดึงสถานะห้องทั้งหมด

---

### 2. Check-in (เช็คอิน)
**Path**: `/admin/checkin`
**Role**: Receptionist, Manager
**หน้าที่**: จัดการการเช็คอินของแขก

**Workflow**:
```
1. เลือกวันที่ → แสดง arrivals ของวันนั้น
2. แสดงรายการ bookings ที่ status = 'Confirmed' และ check_in = วันที่เลือก
3. เลือก booking → แสดงรายละเอียด
4. เลือกห้องที่ available (จาก room_type_id)
5. กด "Check In" → เรียก fn_check_in_booking()
6. อัพเดท:
   - booking_details.room_id = ห้องที่เลือก
   - booking_details.status = 'CheckedIn'
   - rooms.occupancy_status = 'Occupied'
   - rooms.housekeeping_status = 'Clean'
```

**Database Tables**:
- `bookings` - การจอง
- `booking_details` - รายละเอียดการจอง
- `rooms` - ห้องพัก
- `nightly_room_logs` - บันทึกรายวัน

**API Endpoints**:
- GET `/api/checkin/arrivals?date=YYYY-MM-DD` - ดึง arrivals
- GET `/api/checkin/available-rooms/:roomTypeId` - ดึงห้องว่าง
- POST `/api/checkin` - เช็คอิน

**Stored Procedure**:
```sql
fn_check_in_booking(
  p_booking_id INT,
  p_detail_id INT,
  p_room_id INT,
  p_staff_id INT
)
```

---

### 3. Check-out (เช็คเอาท์)
**Path**: `/admin/checkout`
**Role**: Receptionist, Manager
**หน้าที่**: จัดการการเช็คเอาท์ของแขก

**Workflow**:
```
1. เลือกวันที่ → แสดง departures ของวันนั้น
2. แสดงรายการ bookings ที่ status = 'CheckedIn' และ check_out = วันที่เลือก
3. เลือก booking → แสดงรายละเอียด (ห้อง, จำนวนเงิน)
4. กด "Check Out" → เรียก fn_check_out_booking()
5. อัพเดท:
   - booking_details.status = 'CheckedOut'
   - booking_details.actual_check_out = NOW()
   - rooms.occupancy_status = 'Vacant'
   - rooms.housekeeping_status = 'Dirty'
   - bookings.status = 'Completed' (ถ้าทุก details เช็คเอาท์แล้ว)
```

**Database Tables**:
- `bookings`
- `booking_details`
- `rooms`
- `nightly_room_logs`

**API Endpoints**:
- GET `/api/checkout/departures?date=YYYY-MM-DD` - ดึง departures
- POST `/api/checkout` - เช็คเอาท์

**Stored Procedure**:
```sql
fn_check_out_booking(
  p_booking_id INT,
  p_detail_id INT,
  p_staff_id INT
)
```

---

### 4. Move Room (ย้ายห้อง)
**Path**: `/admin/move-room`
**Role**: Receptionist, Manager
**หน้าที่**: ย้ายแขกจากห้องหนึ่งไปอีกห้องหนึ่ง

**Workflow**:
```
1. แสดงรายการ bookings ที่ status = 'CheckedIn'
2. เลือก booking → แสดงห้องปัจจุบัน
3. เลือกห้องใหม่ (ต้องเป็น room_type เดียวกันและ available)
4. กรอกเหตุผล (reason)
5. กด "Move Room" → เรียก fn_move_room()
6. อัพเดท:
   - ห้องเก่า: occupancy_status = 'Vacant', housekeeping_status = 'Dirty'
   - ห้องใหม่: occupancy_status = 'Occupied'
   - booking_details.room_id = ห้องใหม่
   - สร้าง room_move_log
```

**Database Tables**:
- `bookings`
- `booking_details`
- `rooms`
- `room_move_logs`

**API Endpoints**:
- POST `/api/checkin/move-room` - ย้ายห้อง

**Stored Procedure**:
```sql
fn_move_room(
  p_booking_id INT,
  p_detail_id INT,
  p_new_room_id INT,
  p_reason TEXT,
  p_staff_id INT
)
```

---

### 5. No-Show (ไม่มาเช็คอิน)
**Path**: `/admin/no-show`
**Role**: Receptionist, Manager
**หน้าที่**: ทำเครื่องหมายการจองที่แขกไม่มาเช็คอิน

**Workflow**:
```
1. แสดงรายการ bookings ที่:
   - status = 'Confirmed'
   - check_in < TODAY
   - ยังไม่ได้เช็คอิน
2. เลือก booking
3. กด "Mark as No-Show"
4. อัพเดท:
   - booking_details.status = 'NoShow'
   - bookings.status = 'NoShow'
   - คืน inventory (allotment)
```

**Database Tables**:
- `bookings`
- `booking_details`
- `room_inventory`

**API Endpoints**:
- POST `/api/bookings/:id/no-show` - ทำเครื่องหมาย no-show

---

### 6. Housekeeping (แม่บ้าน)
**Path**: `/admin/housekeeping`
**Role**: Housekeeper, Manager
**หน้าที่**: จัดการงานทำความสะอาดห้อง

**Workflow**:
```
1. แสดง tasks ของวันนี้ (ห้องที่ต้องทำความสะอาด)
2. Filter by status: Dirty, Cleaning, Clean
3. เลือกห้อง → อัพเดทสถานะ:
   - Dirty → Cleaning (เริ่มทำความสะอาด)
   - Cleaning → Clean (ทำเสร็จแล้ว)
4. สร้าง housekeeping_log
5. ถ้าพบปัญหา → Report Maintenance
```

**Database Tables**:
- `rooms`
- `housekeeping_logs`
- `maintenance_requests` (ถ้ามี)

**API Endpoints**:
- GET `/api/housekeeping/tasks` - ดึง tasks
- PUT `/api/housekeeping/rooms/:id/status` - อัพเดทสถานะ
- POST `/api/housekeeping/rooms/:id/maintenance` - รายงานปัญหา

---

### 7. Housekeeping Inspection (ตรวจสอบห้อง)
**Path**: `/admin/housekeeping/inspection`
**Role**: Housekeeper (Supervisor), Manager
**หน้าที่**: ตรวจสอบห้องที่ทำความสะอาดเสร็จแล้ว

**Workflow**:
```
1. แสดงห้องที่ status = 'Clean' (รอตรวจสอบ)
2. เลือกห้อง → ตรวจสอบ
3. Approve → status = 'Inspected'
4. Reject → status = 'Dirty' (ต้องทำใหม่) + เหตุผล
5. สร้าง housekeeping_log
```

**Database Tables**:
- `rooms`
- `housekeeping_logs`

**API Endpoints**:
- GET `/api/housekeeping/inspection` - ดึงห้องที่รอตรวจ
- POST `/api/housekeeping/rooms/:id/inspect` - ตรวจสอบห้อง

---

## 👔 Manager Pages (ผู้จัดการ)

### 8. Dashboard (แดชบอร์ด)
**Path**: `/admin/dashboard`
**Role**: Manager
**หน้าที่**: แสดงภาพรวมของโรงแรม

**Workflow**:
```
1. แสดง Summary Cards:
   - Occupancy Rate วันนี้
   - Revenue วันนี้/เดือนนี้
   - Pending Bookings
   - Pending Payment Proofs
2. แสดง Recent Bookings (10 รายการล่าสุด)
3. แสดง Alerts:
   - Payment proofs ที่รออนุมัติ
   - Maintenance requests
   - No-shows
4. แสดง Charts:
   - Occupancy trend (7 วันที่ผ่านมา)
   - Revenue trend (30 วันที่ผ่านมา)
```

**Database Tables**:
- `bookings`
- `payment_proofs`
- `nightly_room_logs`
- `room_inventory`

**API Endpoints**:
- GET `/api/reports/occupancy?start_date=X&end_date=Y`
- GET `/api/reports/revenue?start_date=X&end_date=Y`
- GET `/api/admin/payment-proofs?status=pending`

---

### 9. Bookings Management (จัดการการจอง)
**Path**: `/admin/bookings`
**Role**: Manager
**หน้าที่**: จัดการการจองและอนุมัติหลักฐานการชำระเงิน

**Workflow**:
```
1. แสดงรายการ bookings ทั้งหมด
2. Filter by status:
   - Pending Payment (รอชำระเงิน)
   - Pending Approval (รออนุมัติหลักฐาน)
   - Confirmed (ยืนยันแล้ว)
   - Cancelled (ยกเลิก)
3. คลิก booking → แสดง details + payment proof (ถ้ามี)
4. ถ้ามี payment proof:
   - คลิกดูรูป
   - Approve → booking.status = 'Confirmed'
   - Reject → booking.status = 'Cancelled' + เหตุผล
5. ส่ง email แจ้งผลการอนุมัติ
```

**Database Tables**:
- `bookings`
- `booking_details`
- `payment_proofs`
- `booking_guests`

**API Endpoints**:
- GET `/api/bookings?status=pending_payment`
- GET `/api/admin/payment-proofs`
- POST `/api/admin/payment-proofs/:id/approve`
- POST `/api/admin/payment-proofs/:id/reject`

---

### 10. Inventory Management (จัดการห้องว่าง)
**Path**: `/admin/inventory`
**Role**: Manager
**หน้าที่**: จัดการจำนวนห้องที่เปิดขาย (allotment)

**Workflow**:
```
1. เลือก Room Type (Standard, Deluxe, Suite)
2. เลือกเดือน/ปี
3. แสดง Calendar View:
   - แต่ละวันแสดง: Allotment / Booked / Available
4. คลิกวัน → เปิด modal แก้ไข
5. แก้ไข allotment (จำนวนห้องที่เปิดขาย)
6. Save → อัพเดท room_inventory
7. Validation: allotment >= booked_count + tentative_count
```

**Database Tables**:
- `room_types`
- `room_inventory`

**API Endpoints**:
- GET `/api/inventory?room_type_id=X&start_date=Y&end_date=Z`
- PUT `/api/inventory` - อัพเดทวันเดียว
- POST `/api/inventory/bulk` - อัพเดทหลายวัน

**ตัวอย่าง**:
```
วันที่ 2025-11-10:
- Allotment: 18 (เปิดขาย 18 ห้อง)
- Booked: 5 (จองแล้ว 5 ห้อง)
- Tentative: 2 (hold ไว้ 2 ห้อง)
- Available: 11 (เหลือ 11 ห้อง)
```

---

### 11. Pricing Tiers (ระดับราคา)
**Path**: `/admin/pricing/tiers`
**Role**: Manager
**หน้าที่**: จัดการระดับราคา (Low Season, High Season, etc.)

**Workflow - แบบ All-in-One**:
```
=== Tab 1: Manage Tiers ===
1. แสดงรายการ tiers ทั้งหมด
2. Create New Tier:
   - Tier Name (เช่น "Low Season")
   - Multiplier (เช่น 0.8 = ลด 20%)
3. Edit Tier:
   - แก้ไข name, multiplier
4. Delete Tier (ถ้าไม่มีการใช้งาน)

=== Tab 2: Pricing Calendar ===
1. เลือกปี
2. แสดง Calendar 12 เดือน
3. คลิกวัน → เลือก tier สำหรับวันนั้น
4. Bulk Select:
   - เลือกช่วงวันที่
   - เลือก tier
   - Apply to all selected dates
5. Save → อัพเดท pricing_calendar

=== Tab 3: Pricing Matrix ===
1. แสดง Matrix: Room Types × Rate Plans
2. แต่ละ cell แสดงราคา
3. คลิก cell → แก้ไขราคา
4. ราคาจะคำนวณจาก:
   Base Price × Tier Multiplier × Rate Plan Multiplier
5. Save → อัพเดท rate_pricing
```

**Database Tables**:
- `pricing_tiers` - ระดับราคา
- `pricing_calendar` - กำหนดวันที่ใช้ tier ไหน
- `rate_plans` - แผนราคา (Standard, Flexible, Non-refundable)
- `rate_pricing` - ราคาจริงของแต่ละ room type × rate plan
- `room_types` - ประเภทห้อง

**API Endpoints**:
- GET `/api/pricing/tiers` - ดึง tiers
- POST `/api/pricing/tiers` - สร้าง tier
- PUT `/api/pricing/tiers/:id` - แก้ไข tier
- DELETE `/api/pricing/tiers/:id` - ลบ tier
- GET `/api/pricing/calendar?year=2025` - ดึง calendar
- PUT `/api/pricing/calendar` - อัพเดท calendar
- GET `/api/pricing/rates` - ดึง matrix
- PUT `/api/pricing/rates` - อัพเดท rates

**ตัวอย่าง**:
```
Tier: Low Season (multiplier = 0.8)
Room Type: Standard (base_price = 1000)
Rate Plan: Standard (multiplier = 1.0)

Final Price = 1000 × 0.8 × 1.0 = 800 บาท
```

---

### 12. Reports (รายงาน)
**Path**: `/admin/reports`
**Role**: Manager
**หน้าที่**: ดูรายงานต่างๆ

**Workflow**:
```
1. เลือกประเภทรายงาน:
   - Occupancy Report (อัตราการเข้าพัก)
   - Revenue Report (รายได้)
   - Voucher Report (การใช้คูปอง)
   - No-Show Report (ไม่มาเช็คอิน)
2. เลือกช่วงวันที่
3. เลือก View Mode: Daily, Weekly, Monthly
4. แสดงรายงานในรูปแบบ:
   - Table
   - Chart (Line, Bar)
5. Export:
   - CSV
   - Excel
   - PDF
```

**Database Tables**:
- `nightly_room_logs` - บันทึกรายวัน
- `bookings`
- `booking_details`
- `vouchers`
- `voucher_usage`

**API Endpoints**:
- GET `/api/reports/occupancy?start_date=X&end_date=Y`
- GET `/api/reports/revenue?start_date=X&end_date=Y`
- GET `/api/reports/vouchers?start_date=X&end_date=Y`
- GET `/api/reports/no-shows?start_date=X&end_date=Y`
- GET `/api/reports/export/occupancy?format=csv`

---

## 🔄 Workflow ระหว่างหน้า

### Booking Flow (จากแขกจนถึง Check-out)
```
1. Guest: จองห้องผ่าน /rooms/search
   → สร้าง booking (status = 'Pending')
   
2. Guest: อัพโหลดหลักฐานการชำระเงิน
   → สร้าง payment_proof (status = 'pending')
   
3. Manager: อนุมัติหลักฐาน (/admin/bookings)
   → booking.status = 'Confirmed'
   → payment_proof.status = 'approved'
   
4. Receptionist: เช็คอิน (/admin/checkin)
   → booking_details.status = 'CheckedIn'
   → rooms.occupancy_status = 'Occupied'
   
5. Housekeeper: ทำความสะอาดห้อง (ระหว่างพัก)
   → rooms.housekeeping_status = 'Clean'
   
6. Receptionist: เช็คเอาท์ (/admin/checkout)
   → booking_details.status = 'CheckedOut'
   → rooms.occupancy_status = 'Vacant'
   → rooms.housekeeping_status = 'Dirty'
   
7. Housekeeper: ทำความสะอาดห้อง (/admin/housekeeping)
   → rooms.housekeeping_status = 'Clean'
   
8. Housekeeper: ตรวจสอบห้อง (/admin/housekeeping/inspection)
   → rooms.housekeeping_status = 'Inspected'
   → ห้องพร้อมให้แขกคนต่อไป
```

### Pricing Flow (กำหนดราคา)
```
1. Manager: สร้าง Pricing Tiers (/admin/pricing/tiers - Tab 1)
   → Low Season (0.8), High Season (1.2), Peak (1.5)
   
2. Manager: กำหนดวันที่ใช้ tier (/admin/pricing/tiers - Tab 2)
   → 1-15 พ.ย. = Low Season
   → 16-30 พ.ย. = High Season
   → 1-31 ธ.ค. = Peak Season
   
3. Manager: กำหนดราคาใน Matrix (/admin/pricing/tiers - Tab 3)
   → Standard × Standard Plan = 1000 บาท
   → Deluxe × Standard Plan = 1500 บาท
   
4. System: คำนวณราคาจริงเมื่อแขกจอง
   → วันที่ 10 พ.ย. (Low Season)
   → Standard Room × Standard Plan
   → 1000 × 0.8 × 1.0 = 800 บาท
```

### Inventory Flow (จัดการห้องว่าง)
```
1. Manager: กำหนด allotment (/admin/inventory)
   → Standard Room: 18 ห้อง (จาก 20 ห้องทั้งหมด)
   → เก็บ 2 ห้องไว้สำหรับ walk-in
   
2. Guest: จองห้อง
   → room_inventory.booked_count += 1
   → available = allotment - booked_count - tentative_count
   
3. Manager: ปรับ allotment ตามความต้องการ
   → ช่วง Peak Season: เพิ่ม allotment เป็น 20
   → ช่วง Low Season: ลด allotment เป็น 15
```

---

## 📊 Database Relationships

```
bookings (การจอง)
  ├─ booking_details (รายละเอียดแต่ละห้อง)
  │   ├─ room_types (ประเภทห้อง)
  │   ├─ rooms (ห้องจริงที่พัก)
  │   └─ rate_plans (แผนราคา)
  ├─ booking_guests (ข้อมูลแขก)
  ├─ payment_proofs (หลักฐานการชำระเงิน)
  └─ guest_accounts (บัญชีแขก)

rooms (ห้องพัก)
  ├─ room_types (ประเภทห้อง)
  ├─ housekeeping_logs (ประวัติการทำความสะอาด)
  └─ nightly_room_logs (บันทึกรายวัน)

room_inventory (ห้องว่าง)
  └─ room_types (ประเภทห้อง)

pricing_calendar (ปฏิทินราคา)
  ├─ room_types (ประเภทห้อง)
  ├─ pricing_tiers (ระดับราคา)
  └─ rate_plans (แผนราคา)

rate_pricing (ราคาจริง)
  ├─ room_types (ประเภทห้อง)
  └─ rate_plans (แผนราคา)
```

---

## 🎯 สรุป

### Staff (พนักงาน) ทำอะไร?
- **Receptionist**: Check-in, Check-out, Move Room, No-Show, ดูสถานะห้อง
- **Housekeeper**: ทำความสะอาด, ตรวจสอบห้อง, รายงานปัญหา

### Manager (ผู้จัดการ) ทำอะไร?
- อนุมัติหลักฐานการชำระเงิน
- จัดการ inventory (ห้องว่าง)
- กำหนดราคา (tiers, calendar, matrix)
- ดูรายงานต่างๆ
- ดูภาพรวมใน dashboard

### ระบบทำงานร่วมกันอย่างไร?
1. **Guest** จอง → **Manager** อนุมัติ
2. **Receptionist** เช็คอิน → **Housekeeper** ดูแลห้อง
3. **Receptionist** เช็คเอาท์ → **Housekeeper** ทำความสะอาด
4. **Manager** กำหนดราคา → **System** คำนวณราคาให้แขก
5. **Manager** จัดการ inventory → **System** แสดงห้องว่างให้แขก
