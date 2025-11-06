-- ============================================================================
-- แก้ไขปัญหาห้องเต็ม - รีเซ็ต Inventory ให้ห้องว่างทั้งหมด
-- ============================================================================

\echo '============================================'
\echo 'รีเซ็ต Room Inventory'
\echo '============================================'

-- 1. ลบ inventory เก่าทั้งหมด
DELETE FROM room_inventory WHERE date >= CURRENT_DATE;

-- 2. สร้าง inventory ใหม่สำหรับ 90 วันข้างหน้า (ห้องว่างทั้งหมด)
INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
SELECT 
    rt.room_type_id,
    d::date,
    rt.default_allotment,
    0,  -- ไม่มีการจอง
    0   -- ไม่มี hold
FROM room_types rt
CROSS JOIN generate_series(
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '90 days',
    INTERVAL '1 day'
) AS d;

\echo ''
\echo '============================================'
\echo 'ตรวจสอบผลลัพธ์'
\echo '============================================'

-- 3. แสดงสรุปห้องว่างตามประเภท
SELECT 
    rt.name as room_type,
    rt.default_allotment,
    COUNT(*) as total_days,
    MIN(ri.date) as first_date,
    MAX(ri.date) as last_date,
    SUM(ri.allotment - ri.booked_count - ri.tentative_count) as total_available_room_nights
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.room_type_id, rt.name, rt.default_allotment
ORDER BY rt.name;

-- 4. แสดงห้องว่างสำหรับ 7 วันข้างหน้า
\echo ''
\echo 'ห้องว่างสำหรับ 7 วันข้างหน้า:'
SELECT 
    ri.date,
    rt.name as room_type,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY ri.date, rt.name;

\echo ''
\echo '============================================'
\echo 'เสร็จสิ้น! ห้องทั้งหมดว่างแล้ว'
\echo '============================================'
