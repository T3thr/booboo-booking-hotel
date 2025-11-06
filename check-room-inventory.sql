-- ตรวจสอบข้อมูล room_inventory
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
ORDER BY rt.name, ri.date
LIMIT 50;

-- ตรวจสอบว่ามี inventory สำหรับวันที่ในอนาคตหรือไม่
SELECT 
    rt.name,
    COUNT(*) as inventory_days,
    MIN(ri.date) as first_date,
    MAX(ri.date) as last_date
FROM room_types rt
LEFT JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date >= CURRENT_DATE OR ri.date IS NULL
GROUP BY rt.room_type_id, rt.name;

-- ตรวจสอบ default_allotment ของแต่ละประเภทห้อง
SELECT 
    room_type_id,
    name,
    default_allotment,
    max_occupancy,
    is_active
FROM room_types
ORDER BY name;
