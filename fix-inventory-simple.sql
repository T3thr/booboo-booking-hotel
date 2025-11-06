-- Simple fix for room inventory
-- Run this to make rooms available

-- Delete old inventory and recreate
DELETE FROM room_inventory WHERE date >= CURRENT_DATE;

-- Create inventory for next 90 days
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
) AS d;

-- Verify
SELECT 
    rt.name,
    COUNT(*) as days,
    AVG(ri.allotment - ri.booked_count - ri.tentative_count) as avg_available
FROM room_types rt
JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date >= CURRENT_DATE
GROUP BY rt.name;
