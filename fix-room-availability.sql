-- ============================================================================
-- Fix Room Availability Issue
-- ============================================================================
-- This script ensures room_inventory has correct data for demo

-- 1. Check current inventory status
\echo 'Current inventory status:'
SELECT 
    rt.name as room_type,
    COUNT(DISTINCT ri.date) as days_with_inventory,
    MIN(ri.date) as first_date,
    MAX(ri.date) as last_date,
    SUM(ri.allotment) as total_allotment,
    SUM(ri.booked_count) as total_booked,
    SUM(ri.tentative_count) as total_tentative,
    SUM(ri.allotment - ri.booked_count - ri.tentative_count) as total_available
FROM room_types rt
LEFT JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
GROUP BY rt.room_type_id, rt.name
ORDER BY rt.name;

-- 2. Ensure inventory exists for next 90 days
\echo ''
\echo 'Creating/updating inventory for next 90 days...'

INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
SELECT 
    rt.room_type_id,
    d::date,
    rt.default_allotment,
    0,
    0
FROM room_types rt
CROSS JOIN generate_series(
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '90 days',
    INTERVAL '1 day'
) AS d
ON CONFLICT (room_type_id, date) 
DO UPDATE SET
    allotment = EXCLUDED.allotment,
    updated_at = CURRENT_TIMESTAMP
WHERE room_inventory.allotment = 0;

-- 3. Verify inventory after fix
\echo ''
\echo 'Inventory after fix:'
SELECT 
    rt.name as room_type,
    COUNT(DISTINCT ri.date) as days_with_inventory,
    MIN(ri.date) as first_date,
    MAX(ri.date) as last_date,
    AVG(ri.allotment - ri.booked_count - ri.tentative_count) as avg_available
FROM room_types rt
LEFT JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.room_type_id, rt.name
ORDER BY rt.name;

-- 4. Test availability query (same as backend uses)
\echo ''
\echo 'Testing availability for next 7 days (2 guests):'
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
    WHERE rt.max_occupancy >= 2 AND rt.is_active = true
)
SELECT 
    room_type_id,
    name,
    MIN(available) as min_available,
    MAX(available) as max_available,
    AVG(available) as avg_available,
    COUNT(*) as total_days
FROM daily_availability
GROUP BY room_type_id, name
ORDER BY name;

\echo ''
\echo '============================================================================'
\echo 'Fix completed! Rooms should now be available for booking.'
\echo '============================================================================'
