# แก้ไขปัญหาข้อมูลไม่แสดงใน Admin Pages

## ปัญหาที่พบ

Admin pages ทั้งหมดไม่แสดงข้อมูลเพราะ:
1. Seed data ไม่ครอบคลุมตาราง `payment_proofs` (ต้องใช้ migration 015)
2. Room inventory ไม่ครอบคลุมวันที่ปัจจุบัน (ต้องรัน migration 016)
3. Bookings ใน seed data ไม่มี status = 'Pending' (ที่ dashboard ต้องการ)
4. ไม่มี payment_proofs ที่ status = 'pending' (ที่ bookings page ต้องการ)

## วิธีแก้ไข

### ขั้นตอนที่ 1: รัน Migrations ที่ขาดหายไป

```bash
# รัน migration 015 - สร้างตาราง payment_proofs
cd database/migrations
psql -U postgres -d hotel_booking -f 015_create_payment_proof_table.sql

# รัน migration 016 - สร้าง inventory สำหรับ 100 วันข้างหน้า
psql -U postgres -d hotel_booking -f 016_seed_available_inventory.sql

# รัน migration 017 - เพิ่ม phone column
psql -U postgres -d hotel_booking -f 017_add_phone_to_booking_guests.sql
```

### ขั้นตอนที่ 2: เพิ่มข้อมูล Demo สำหรับ Admin Pages

สร้างไฟล์ SQL ใหม่: `database/migrations/018_seed_admin_demo_data.sql`

```sql
-- ============================================================================
-- Migration 018: Seed Admin Demo Data
-- เพิ่มข้อมูล demo สำหรับ Admin pages
-- ============================================================================

\echo 'Adding demo data for Admin pages...'

-- 1. เพิ่ม bookings ที่มี status = 'Pending' (สำหรับ dashboard)
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(31, 1, 3500.00, 'Pending', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(32, 2, 4200.00, 'Pending', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(33, 3, 2800.00, 'Pending', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '30 minutes');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(31, 31, 1, 1, CURRENT_DATE + INTERVAL '3 days', CURRENT_DATE + INTERVAL '5 days', 2),
(32, 32, 2, 1, CURRENT_DATE + INTERVAL '4 days', CURRENT_DATE + INTERVAL '7 days', 2),
(33, 33, 1, 1, CURRENT_DATE + INTERVAL '2 days', CURRENT_DATE + INTERVAL '4 days', 1);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, phone, type, is_primary) VALUES
(31, 'Somchai', 'Pending1', '0812345678', 'Adult', true),
(32, 'Suda', 'Pending2', '0823456789', 'Adult', true),
(33, 'Niran', 'Pending3', '0834567890', 'Adult', true);

-- 2. เพิ่ม payment_proofs ที่ status = 'pending' (สำหรับ bookings page)
INSERT INTO payment_proofs (booking_id, payment_method, amount, proof_url, status, created_at) VALUES
(31, 'bank_transfer', 3500.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Payment+Proof+1', 'pending', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(32, 'qr_code', 4200.00, 'https://via.placeholder.com/400x600/2196F3/FFFFFF?text=Payment+Proof+2', 'pending', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(33, 'bank_transfer', 2800.00, 'https://via.placeholder.com/400x600/FF9800/FFFFFF?text=Payment+Proof+3', 'pending', CURRENT_TIMESTAMP - INTERVAL '30 minutes');

-- 3. เพิ่ม bookings ที่ approved (สำหรับ revenue reports)
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(34, 4, 5000.00, 'Confirmed', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_DATE - INTERVAL '1 day'),
(35, 5, 6500.00, 'Confirmed', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_DATE - INTERVAL '2 days'),
(36, 6, 4800.00, 'Confirmed', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_DATE - INTERVAL '3 days');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(34, 34, 2, 1, CURRENT_DATE + INTERVAL '5 days', CURRENT_DATE + INTERVAL '8 days', 2),
(35, 35, 3, 1, CURRENT_DATE + INTERVAL '6 days', CURRENT_DATE + INTERVAL '10 days', 3),
(36, 36, 2, 1, CURRENT_DATE + INTERVAL '4 days', CURRENT_DATE + INTERVAL '6 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, phone, type, is_primary) VALUES
(34, 'Apinya', 'Confirmed1', '0845678901', 'Adult', true),
(35, 'Wichai', 'Confirmed2', '0856789012', 'Adult', true),
(36, 'Pranee', 'Confirmed3', '0867890123', 'Adult', true);

-- เพิ่ม payment_proofs ที่ approved
INSERT INTO payment_proofs (booking_id, payment_method, amount, proof_url, status, approved_at, created_at) VALUES
(34, 'bank_transfer', 5000.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Approved+1', 'approved', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_DATE - INTERVAL '1 day'),
(35, 'qr_code', 6500.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Approved+2', 'approved', CURRENT_TIMESTAMP - INTERVAL '18 hours', CURRENT_DATE - INTERVAL '2 days'),
(36, 'bank_transfer', 4800.00, 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=Approved+3', 'approved', CURRENT_TIMESTAMP - INTERVAL '24 hours', CURRENT_DATE - INTERVAL '3 days');

-- 4. Update inventory สำหรับ bookings ใหม่
UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 1 
  AND date >= CURRENT_DATE + INTERVAL '3 days' 
  AND date < CURRENT_DATE + INTERVAL '5 days';

UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 2 
  AND date >= CURRENT_DATE + INTERVAL '4 days' 
  AND date < CURRENT_DATE + INTERVAL '7 days';

UPDATE room_inventory 
SET booked_count = booked_count + 1
WHERE room_type_id = 1 
  AND date >= CURRENT_DATE + INTERVAL '2 days' 
  AND date < CURRENT_DATE + INTERVAL '4 days';

\echo 'Admin demo data seeded successfully!'
\echo ''
\echo 'Summary:'
\echo '- Added 3 pending bookings with payment proofs'
\echo '- Added 3 confirmed bookings with approved payments'
\echo '- Updated room inventory accordingly'
\echo ''
\echo 'You can now:'
\echo '1. View pending payments in Manager > Bookings'
\echo '2. See revenue data in Manager > Dashboard'
\echo '3. Check inventory in Manager > Inventory'
\echo '4. View reports in Manager > Reports'
```

### ขั้นตอนที่ 3: รันไฟล์ SQL ใหม่

```bash
cd database/migrations
psql -U postgres -d hotel_booking -f 018_seed_admin_demo_data.sql
```

### ขั้นตอนที่ 4: ตรวจสอบข้อมูล

```sql
-- ตรวจสอบ pending bookings
SELECT COUNT(*) FROM bookings WHERE status = 'Pending';

-- ตรวจสอบ pending payment proofs
SELECT COUNT(*) FROM payment_proofs WHERE status = 'pending';

-- ตรวจสอบ approved payments
SELECT COUNT(*) FROM payment_proofs WHERE status = 'approved';

-- ตรวจสอบ inventory
SELECT 
    rt.name,
    COUNT(*) as days_with_inventory,
    SUM(ri.allotment - ri.booked_count - ri.tentative_count) as total_available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.room_type_id, rt.name;
```

## ผลลัพธ์ที่คาดหวัง

หลังจากทำตามขั้นตอนข้างต้น:

### 1. Dashboard Page
- ✅ แสดงรายได้วันนี้ (จาก approved payments)
- ✅ แสดงรายได้เดือนนี้
- ✅ แสดงอัตราการเข้าพัก
- ✅ แสดงจำนวน pending payments (3 รายการ)
- ✅ แสดงการจองล่าสุด

### 2. Bookings Page
- ✅ แสดง 3 payment proofs ที่รอตรวจสอบ
- ✅ สามารถอนุมัติ/ปฏิเสธได้
- ✅ แสดงรูปภาพหลักฐานการโอนเงิน

### 3. Inventory Page
- ✅ แสดง inventory สำหรับ 100 วันข้างหน้า
- ✅ แสดงจำนวนห้องว่าง/จอง/กำลังจอง
- ✅ สามารถแก้ไข allotment ได้

### 4. Reports Page
- ✅ แสดงรายงานการเข้าพัก
- ✅ แสดงรายงานรายได้
- ✅ แสดงกราฟและสถิติ

### 5. Pricing Pages
- ✅ แสดง rate tiers (4 tiers จาก seed data)
- ✅ แสดง pricing calendar
- ✅ แสดง pricing matrix

## หมายเหตุ

- ข้อมูล demo ใช้ placeholder images จาก via.placeholder.com
- ในการใช้งานจริง ควรให้ผู้ใช้อัปโหลดรูปภาพจริง
- Inventory จะถูกอัปเดตอัตโนมัติเมื่อมีการจอง/ยกเลิก
