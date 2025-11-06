-- ============================================================================
-- Migration 016: Seed Available Room Inventory
-- Description: สร้าง room_inventory ที่มีห้องว่างสำหรับ 100 วันข้างหน้า
-- Purpose: แก้ไขปัญหาห้องเต็ม - ให้ Frontend เจอ available_rooms > 0
-- ============================================================================

\echo '============================================'
\echo 'Migration 016: Seeding Available Room Inventory'
\echo '============================================'

-- ============================================================================
-- 1. ลบ inventory เก่าที่อาจมีปัญหา
-- ============================================================================
\echo ''
\echo 'Step 1: Cleaning old inventory data...'

DELETE FROM room_inventory WHERE date >= CURRENT_DATE;

\echo 'Old inventory data cleaned.'

-- ============================================================================
-- 2. สร้าง inventory ใหม่สำหรับ 100 วันข้างหน้า (ห้องว่างทั้งหมด)
-- ============================================================================
\echo ''
\echo 'Step 2: Creating new inventory for 100 days...'

INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
SELECT 
    rt.room_type_id,
    d::date,
    rt.default_allotment,
    0,  -- ไม่มีการจอง (ห้องว่างทั้งหมด)
    0   -- ไม่มี hold
FROM room_types rt
CROSS JOIN generate_series(
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '100 days',
    INTERVAL '1 day'
) AS d
ON CONFLICT (room_type_id, date) 
DO UPDATE SET
    allotment = EXCLUDED.allotment,
    booked_count = 0,
    tentative_count = 0;

\echo 'Inventory created for 100 days.'

-- ============================================================================
-- 3. สร้าง sample bookings (10% ของห้อง) เพื่อให้ดูเหมือนจริง
-- ============================================================================
\echo ''
\echo 'Step 3: Creating sample bookings (10% occupancy)...'

-- สร้างการจองตัวอย่างสำหรับ 10 วันแรก (10% ของห้อง)
UPDATE room_inventory
SET booked_count = FLOOR(allotment * 0.1)::INT
WHERE date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '10 days'
  AND room_type_id IN (SELECT room_type_id FROM room_types);

\echo 'Sample bookings created.'

-- ============================================================================
-- 4. ตรวจสอบผลลัพธ์
-- ============================================================================
\echo ''
\echo '============================================'
\echo 'Verification Results'
\echo '============================================'

-- แสดงสรุปห้องว่างตามประเภท
\echo ''
\echo 'Summary by Room Type:'
SELECT 
    rt.name as room_type,
    rt.default_allotment,
    COUNT(*) as total_days,
    MIN(ri.date) as first_date,
    MAX(ri.date) as last_date,
    ROUND(AVG(ri.allotment - ri.booked_count - ri.tentative_count), 2) as avg_available,
    SUM(ri.allotment - ri.booked_count - ri.tentative_count) as total_available_room_nights
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.room_type_id, rt.name, rt.default_allotment
ORDER BY rt.name;

-- แสดงห้องว่างสำหรับ 7 วันข้างหน้า
\echo ''
\echo 'Available Rooms for Next 7 Days:'
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

-- แสดงสถิติรวม
\echo ''
\echo 'Overall Statistics:'
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
WHERE date >= CURRENT_DATE
UNION ALL
SELECT 
    'Total Available Room-Nights',
    SUM(allotment - booked_count - tentative_count)::text
FROM room_inventory
WHERE date >= CURRENT_DATE
UNION ALL
SELECT 
    'Average Occupancy Rate',
    ROUND(AVG(booked_count::decimal / NULLIF(allotment, 0) * 100), 2)::text || '%'
FROM room_inventory
WHERE date >= CURRENT_DATE;

\echo ''
\echo '============================================'
\echo 'Migration 016 Completed Successfully!'
\echo '============================================'
\echo ''
\echo 'Next Steps:'
\echo '1. Test API: curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"'
\echo '2. Open Frontend: http://localhost:3000/rooms/search'
\echo '3. Search for rooms - You should see "จองห้องนี้" button (enabled)'
\echo ''
\echo 'Expected Results:'
\echo '- All room types should have available_rooms > 0'
\echo '- Standard Room: ~9 rooms available (10 - 1 booked)'
\echo '- Deluxe Room: ~7 rooms available (8 - 1 booked)'
\echo '- Suite Room: ~4-5 rooms available (5 - 0-1 booked)'
\echo '============================================'

COMMIT;
