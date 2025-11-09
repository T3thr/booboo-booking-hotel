-- ============================================================================
-- Fix: คืนห้องว่างหลังจากลบ booking_holds ด้วยตัวเอง
-- ============================================================================

-- วิธีที่ 1: รีเซ็ต tentative_count ทั้งหมดเป็น 0 (ถ้าไม่มี hold ที่ยังใช้งานอยู่)
UPDATE room_inventory
SET tentative_count = 0,
    updated_at = NOW()
WHERE tentative_count > 0;

-- วิธีที่ 2: คำนวณ tentative_count ใหม่จาก booking_holds ที่เหลืออยู่
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
