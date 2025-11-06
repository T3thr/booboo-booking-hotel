-- ============================================================================
-- แก้ไขปัญหาห้องเต็ม - สร้าง Inventory สำหรับ 90 วันข้างหน้า
-- ============================================================================

-- 1. ลบ inventory เก่าที่อาจมีปัญหา (optional - ถ้าต้องการเริ่มใหม่)
-- DELETE FROM room_inventory WHERE date >= CURRENT_DATE;

-- 2. สร้าง inventory สำหรับ 90 วันข้างหน้า
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
ON CONFLICT (room_type_id, date) 
DO UPDATE SET
    allotment = EXCLUDED.allotment,
    -- ไม่แก้ไข booked_count และ tentative_count ที่มีอยู่แล้ว
    booked_count = room_inventory.booked_count,
    tentative_count = room_inventory.tentative_count;

-- 3. ตรวจสอบผลลัพธ์
SELECT 
    rt.name as room_type,
    COUNT(*) as days_created,
    MIN(ri.date) as first_date,
    MAX(ri.date) as last_date,
    AVG(ri.allotment) as avg_allotment,
    SUM(ri.allotment - ri.booked_count - ri.tentative_count) as total_available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.room_type_id, rt.name
ORDER BY rt.name;

-- 4. แสดงห้องว่างสำหรับ 7 วันข้างหน้า
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

-- 5. สรุปสถานะ
SELECT 
    'Total Room Types' as metric,
    COUNT(DISTINCT room_type_id)::text as value
FROM room_types
UNION ALL
SELECT 
    'Total Inventory Records',
    COUNT(*)::text
FROM room_inventory
WHERE date >= CURRENT_DATE
UNION ALL
SELECT 
    'Date Range',
    MIN(date)::text || ' to ' || MAX(date)::text
FROM room_inventory
WHERE date >= CURRENT_DATE;

COMMIT;
