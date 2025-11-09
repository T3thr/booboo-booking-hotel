# แก้ปัญหาห้องไม่กลับมาว่างหลังลบ Booking Hold

## สาเหตุ
เมื่อคุณลบข้อมูลใน `booking_holds` ด้วยตัวเอง (DELETE FROM booking_holds) 
ระบบไม่ได้คืน `tentative_count` กลับไปที่ตาราง `room_inventory` 
ทำให้ห้องยังถูกนับว่าถูก hold อยู่

## วิธีแก้ไข

### วิธีที่ 1: รีเซ็ต tentative_count ทั้งหมด (เร็วที่สุด)
```sql
-- เชื่อมต่อ database
psql -U postgres -d hotel_reservation

-- รีเซ็ต tentative_count เป็น 0
UPDATE room_inventory
SET tentative_count = 0,
    updated_at = NOW()
WHERE tentative_count > 0;

-- ตรวจสอบผลลัพธ์
SELECT 
    rt.name as room_type,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
  AND ri.date <= CURRENT_DATE + INTERVAL '7 days'
ORDER BY ri.date, rt.name;
```

### วิธีที่ 2: คำนวณใหม่จาก holds ที่เหลือ (ถูกต้องที่สุด)
```sql
-- คำนวณ tentative_count ใหม่จาก booking_holds ที่ยังไม่หมดอายุ
UPDATE room_inventory ri
SET tentative_count = COALESCE(
    (SELECT COUNT(*)
     FROM booking_holds bh
     WHERE bh.room_type_id = ri.room_type_id
       AND bh.date = ri.date
       AND bh.hold_expiry > NOW()),
    0
),
updated_at = NOW();
```

### วิธีที่ 3: ใช้ไฟล์ที่เตรียมไว้
```bash
cd database/migrations
run_fix_inventory.bat
```

## ป้องกันปัญหาในอนาคต

### 1. ใช้ function แทนการลบด้วยตัวเอง
```sql
-- แทนที่จะใช้ DELETE FROM booking_holds
-- ให้ใช้ function นี้แทน
SELECT * FROM release_expired_holds();
```

### 2. ตั้ง background job ให้รันอัตโนมัติ
Backend มี job ที่รันทุก 5 นาทีอยู่แล้ว:
- ไฟล์: `backend/internal/jobs/hold_cleanup.go`
- ตรวจสอบว่า backend กำลังรันอยู่หรือไม่

### 3. ลบ holds แบบปลอดภัย
ถ้าต้องการลบ hold ของ guest คนใดคนหนึ่ง:
```sql
-- ขั้นตอนที่ 1: คืน tentative_count ก่อน
UPDATE room_inventory ri
SET tentative_count = GREATEST(0, tentative_count - 1),
    updated_at = NOW()
WHERE EXISTS (
    SELECT 1 FROM booking_holds bh
    WHERE bh.room_type_id = ri.room_type_id
      AND bh.date = ri.date
      AND bh.guest_account_id = 123  -- เปลี่ยนเป็น guest_id ที่ต้องการ
);

-- ขั้นตอนที่ 2: ลบ hold
DELETE FROM booking_holds
WHERE guest_account_id = 123;
```

## ตรวจสอบสถานะปัจจุบัน

```sql
-- ดูห้องว่างทั้งหมด
SELECT 
    rt.name,
    ri.date,
    ri.allotment as total,
    ri.booked_count as booked,
    ri.tentative_count as on_hold,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
ORDER BY ri.date, rt.name;

-- ดู holds ที่ยังไม่หมดอายุ
SELECT 
    bh.hold_id,
    rt.name as room_type,
    bh.date,
    bh.hold_expiry,
    bh.guest_account_id,
    CASE 
        WHEN bh.hold_expiry > NOW() THEN 'Active'
        ELSE 'Expired'
    END as status
FROM booking_holds bh
JOIN room_types rt ON bh.room_type_id = rt.room_type_id
ORDER BY bh.hold_expiry DESC;
```

## คำสั่งด่วน (Quick Fix)

```bash
# Windows
psql -U postgres -d hotel_reservation -c "UPDATE room_inventory SET tentative_count = 0 WHERE tentative_count > 0;"

# หรือใช้ไฟล์
cd database/migrations
run_fix_inventory.bat
```
