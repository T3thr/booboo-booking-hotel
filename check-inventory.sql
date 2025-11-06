-- ตรวจสอบ room_inventory
SELECT 
    rt.name as room_type,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_types rt
LEFT JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date BETWEEN '2025-11-06' AND '2025-11-08'
ORDER BY rt.name, ri.date;

-- ตรวจสอบว่ามี inventory หรือไม่
SELECT 
    COUNT(*) as total_records,
    MIN(date) as first_date,
    MAX(date) as last_date
FROM room_inventory
WHERE date >= CURRENT_DATE;
