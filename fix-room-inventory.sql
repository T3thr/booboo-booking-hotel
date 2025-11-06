-- ============================================================================
-- แก้ไขปัญหาห้องเต็ม: สร้าง room_inventory สำหรับ 90 วันข้างหน้า
-- ============================================================================

BEGIN;

-- 1. ลบข้อมูล inventory เก่าที่อาจมีปัญหา (ถ้ามี)
DELETE FROM room_inventory WHERE date >= CURRENT_DATE;

-- 2. สร้าง inventory ใหม่สำหรับ 90 วันข้างหน้า
INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
SELECT 
    rt.room_type_id,
    d::date,
    rt.default_allotment,
    0,  -- เริ่มต้นไม่มีการจอง
    0   -- เริ่มต้นไม่มี hold
FROM room_types rt
CROSS JOIN generate_series(
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '90 days',
    INTERVAL '1 day'
) AS d
ON CONFLICT (room_type_id, date) DO UPDATE
SET 
    allotment = EXCLUDED.allotment,
    updated_at = NOW();

-- 3. ตรวจสอบผลลัพธ์
SELECT 
    rt.name as room_type,
    COUNT(*) as inventory_days,
    MIN(ri.date) as first_date,
    MAX(ri.date) as last_date,
    MIN(ri.allotment - ri.booked_count - ri.tentative_count) as min_available,
    MAX(ri.allotment - ri.booked_count - ri.tentative_count) as max_available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.room_type_id, rt.name
ORDER BY rt.name;

-- 4. แสดงตัวอย่างห้องว่างสำหรับ 7 วันข้างหน้า
SELECT 
    rt.name as room_type,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY rt.name, ri.date;

COMMIT;

-- แสดงสรุป
DO $$
DECLARE
    v_total_records INT;
    v_room_types INT;
BEGIN
    SELECT COUNT(*) INTO v_total_records
    FROM room_inventory
    WHERE date >= CURRENT_DATE;
    
    SELECT COUNT(DISTINCT room_type_id) INTO v_room_types
    FROM room_inventory
    WHERE date >= CURRENT_DATE;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'สร้าง Room Inventory สำเร็จ!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'จำนวน records: %', v_total_records;
    RAISE NOTICE 'จำนวนประเภทห้อง: %', v_room_types;
    RAISE NOTICE 'ช่วงวันที่: % ถึง %', 
        CURRENT_DATE, 
        CURRENT_DATE + INTERVAL '90 days';
    RAISE NOTICE '========================================';
END $$;
