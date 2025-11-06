-- Test query for available rooms
-- Check-in: 2025-11-06, Check-out: 2025-11-08, Guests: 1

WITH date_range AS (
    SELECT generate_series('2025-11-06'::date, '2025-11-08'::date - interval '1 day', interval '1 day')::date AS date
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
    WHERE rt.max_occupancy >= 1 AND rt.is_active = true
)
SELECT 
    room_type_id,
    name,
    date,
    total_allotment,
    booked,
    tentative,
    available
FROM daily_availability
ORDER BY room_type_id, date;

-- Summary
WITH date_range AS (
    SELECT generate_series('2025-11-06'::date, '2025-11-08'::date - interval '1 day', interval '1 day')::date AS date
),
daily_availability AS (
    SELECT 
        rt.room_type_id,
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
    WHERE rt.max_occupancy >= 1 AND rt.is_active = true
),
available_room_types AS (
    SELECT 
        room_type_id,
        MIN(available) as min_available,
        COUNT(*) as total_days
    FROM daily_availability
    GROUP BY room_type_id
    HAVING MIN(available) > 0
       AND COUNT(*) = ('2025-11-08'::date - '2025-11-06'::date)
)
SELECT 
    rt.room_type_id,
    rt.name,
    rt.description,
    rt.max_occupancy,
    rt.default_allotment,
    art.min_available as available_rooms
FROM room_types rt
INNER JOIN available_room_types art ON rt.room_type_id = art.room_type_id
ORDER BY rt.name;
