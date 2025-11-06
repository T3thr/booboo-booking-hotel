-- ============================================================================
-- Verification Script for Migration 016
-- ============================================================================

\echo '============================================'
\echo 'Verifying Migration 016: Available Inventory'
\echo '============================================'

-- 1. ตรวจสอบจำนวน records
\echo ''
\echo '1. Total Inventory Records:'
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT room_type_id) as room_types,
    COUNT(DISTINCT date) as unique_dates
FROM room_inventory
WHERE date >= CURRENT_DATE;

-- 2. ตรวจสอบว่าทุกห้องมี available > 0
\echo ''
\echo '2. Rooms with Zero Availability (should be 0 or very few):'
SELECT 
    rt.name,
    COUNT(*) as days_with_zero_availability
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
  AND (ri.allotment - ri.booked_count - ri.tentative_count) = 0
GROUP BY rt.name;

-- 3. ตรวจสอบห้องว่างสำหรับวันนี้
\echo ''
\echo '3. Available Rooms for Today:'
SELECT 
    rt.name as room_type,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date = CURRENT_DATE
ORDER BY rt.name;

-- 4. ตรวจสอบ date range
\echo ''
\echo '4. Date Range Coverage:'
SELECT 
    MIN(date) as first_date,
    MAX(date) as last_date,
    (MAX(date) - MIN(date)) as days_covered
FROM room_inventory
WHERE date >= CURRENT_DATE;

-- 5. ตรวจสอบ occupancy rate
\echo ''
\echo '5. Occupancy Statistics:'
SELECT 
    rt.name as room_type,
    ROUND(AVG(ri.booked_count::decimal / NULLIF(ri.allotment, 0) * 100), 2) as avg_occupancy_pct,
    ROUND(AVG(ri.allotment - ri.booked_count - ri.tentative_count), 2) as avg_available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.name
ORDER BY rt.name;

-- 6. ทดสอบ query ที่ backend ใช้
\echo ''
\echo '6. Backend Query Test (Next 7 Days):'
WITH date_range AS (
    SELECT generate_series(
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '7 days' - INTERVAL '1 day',
        INTERVAL '1 day'
    )::date AS date
),
daily_availability AS (
    SELECT 
        rt.room_type_id,
        rt.name,
        dr.date,
        COALESCE(ri.allotment, rt.default_allotment) as total_allotment,
        COALESCE(ri.booked_count, 0) as booked,
        COALESCE(ri.tentative_count, 0) as tentative,
        COALESCE(ri.allotment, rt.default_allotment) - 
            COALESCE(ri.booked_count, 0) - 
            COALESCE(ri.tentative_count, 0) as available
    FROM room_types rt
    CROSS JOIN date_range dr
    LEFT JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id AND ri.date = dr.date
    WHERE rt.is_active = true
)
SELECT 
    room_type_id,
    name,
    MIN(available) as min_available,
    MAX(available) as max_available,
    ROUND(AVG(available), 2) as avg_available
FROM daily_availability
GROUP BY room_type_id, name
ORDER BY name;

\echo ''
\echo '============================================'
\echo 'Verification Complete!'
\echo '============================================'
\echo ''
\echo 'Expected Results:'
\echo '- Total records: ~300 (3 room types × 100 days)'
\echo '- All rooms should have available > 0 for most days'
\echo '- Min available should be > 0 for backend query test'
\echo '============================================'
