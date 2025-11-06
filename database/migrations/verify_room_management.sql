-- ============================================================================
-- Verification Script: verify_room_management.sql
-- Description: ตรวจสอบว่า Room Management Schema ถูกสร้างและมีข้อมูลครบถ้วน
-- ============================================================================

\echo '=== Verifying Room Management Schema ==='
\echo ''

-- ============================================================================
-- 1. ตรวจสอบตารางที่สร้าง
-- ============================================================================
\echo '1. Checking Tables...'
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('room_types', 'rooms', 'amenities', 'room_type_amenities') 
        THEN '✓ EXISTS'
        ELSE '✗ MISSING'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('room_types', 'rooms', 'amenities', 'room_type_amenities')
ORDER BY table_name;

\echo ''

-- ============================================================================
-- 2. ตรวจสอบจำนวนข้อมูล
-- ============================================================================
\echo '2. Checking Data Counts...'
SELECT 
    'room_types' as table_name,
    COUNT(*) as count,
    CASE WHEN COUNT(*) >= 3 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM room_types
UNION ALL
SELECT 
    'rooms' as table_name,
    COUNT(*) as count,
    CASE WHEN COUNT(*) >= 20 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM rooms
UNION ALL
SELECT 
    'amenities' as table_name,
    COUNT(*) as count,
    CASE WHEN COUNT(*) >= 10 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM amenities
UNION ALL
SELECT 
    'room_type_amenities' as table_name,
    COUNT(*) as count,
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM room_type_amenities;

\echo ''

-- ============================================================================
-- 3. ตรวจสอบ Constraints
-- ============================================================================
\echo '3. Checking Constraints...'
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    '✓' as status
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
  AND tc.table_name IN ('room_types', 'rooms', 'amenities', 'room_type_amenities')
  AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'CHECK', 'UNIQUE')
ORDER BY tc.table_name, tc.constraint_type;

\echo ''

-- ============================================================================
-- 4. ตรวจสอบ Indexes
-- ============================================================================
\echo '4. Checking Indexes...'
SELECT 
    schemaname,
    tablename,
    indexname,
    '✓' as status
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('room_types', 'rooms', 'amenities', 'room_type_amenities')
ORDER BY tablename, indexname;

\echo ''

-- ============================================================================
-- 5. ตรวจสอบข้อมูล Room Types
-- ============================================================================
\echo '5. Room Types Summary...'
SELECT 
    room_type_id,
    name,
    max_occupancy,
    default_allotment,
    base_price,
    size_sqm,
    bed_type
FROM room_types
ORDER BY room_type_id;

\echo ''

-- ============================================================================
-- 6. ตรวจสอบการกระจายห้องตามประเภท
-- ============================================================================
\echo '6. Rooms Distribution by Type...'
SELECT 
    rt.name as room_type,
    COUNT(r.room_id) as total_rooms,
    MIN(r.room_number) as first_room,
    MAX(r.room_number) as last_room,
    SUM(CASE WHEN r.occupancy_status = 'Occupied' THEN 1 ELSE 0 END) as occupied,
    SUM(CASE WHEN r.occupancy_status = 'Vacant' THEN 1 ELSE 0 END) as vacant
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.name
ORDER BY rt.name;

\echo ''

-- ============================================================================
-- 7. ตรวจสอบสถานะห้อง
-- ============================================================================
\echo '7. Room Status Summary...'
SELECT 
    occupancy_status,
    housekeeping_status,
    COUNT(*) as count
FROM rooms
GROUP BY occupancy_status, housekeeping_status
ORDER BY occupancy_status, housekeeping_status;

\echo ''

-- ============================================================================
-- 8. ตรวจสอบ Amenities
-- ============================================================================
\echo '8. Amenities List...'
SELECT 
    amenity_id,
    name,
    category,
    icon
FROM amenities
ORDER BY category, name;

\echo ''

-- ============================================================================
-- 9. ตรวจสอบ Amenities ของแต่ละประเภทห้อง
-- ============================================================================
\echo '9. Amenities by Room Type...'
SELECT 
    rt.name as room_type,
    COUNT(rta.amenity_id) as amenity_count,
    STRING_AGG(a.name, ', ' ORDER BY a.name) as amenities
FROM room_types rt
LEFT JOIN room_type_amenities rta ON rt.room_type_id = rta.room_type_id
LEFT JOIN amenities a ON rta.amenity_id = a.amenity_id
GROUP BY rt.name
ORDER BY rt.name;

\echo ''

-- ============================================================================
-- 10. ตรวจสอบ Triggers
-- ============================================================================
\echo '10. Checking Triggers...'
SELECT 
    trigger_name,
    event_object_table as table_name,
    action_timing,
    event_manipulation,
    '✓' as status
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('room_types', 'rooms')
ORDER BY event_object_table, trigger_name;

\echo ''

-- ============================================================================
-- 11. ตรวจสอบตัวอย่างห้องพัก
-- ============================================================================
\echo '11. Sample Rooms (First 5)...'
SELECT 
    r.room_number,
    rt.name as room_type,
    r.floor,
    r.occupancy_status,
    r.housekeeping_status
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
ORDER BY r.room_number
LIMIT 5;

\echo ''
\echo '=== Verification Complete ==='
