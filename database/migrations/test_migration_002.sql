-- ============================================================================
-- Test Script: test_migration_002.sql
-- Description: ทดสอบ Room Management Schema
-- ============================================================================

\echo '=== Testing Room Management Schema ==='
\echo ''

-- ============================================================================
-- Test 1: ตรวจสอบว่าตารางถูกสร้างครบถ้วน
-- ============================================================================
\echo 'Test 1: Checking if all tables exist...'
DO $$
DECLARE
    missing_tables TEXT[];
    table_name TEXT;
BEGIN
    SELECT ARRAY_AGG(t.table_name)
    INTO missing_tables
    FROM (
        SELECT 'room_types' as table_name
        UNION SELECT 'rooms'
        UNION SELECT 'amenities'
        UNION SELECT 'room_type_amenities'
    ) t
    WHERE NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = t.table_name
    );
    
    IF missing_tables IS NOT NULL THEN
        RAISE EXCEPTION 'Missing tables: %', array_to_string(missing_tables, ', ');
    ELSE
        RAISE NOTICE '✓ All tables exist';
    END IF;
END $$;

\echo ''

-- ============================================================================
-- Test 2: ตรวจสอบจำนวนข้อมูล
-- ============================================================================
\echo 'Test 2: Checking data counts...'
DO $$
DECLARE
    rt_count INT;
    room_count INT;
    amenity_count INT;
    mapping_count INT;
BEGIN
    SELECT COUNT(*) INTO rt_count FROM room_types;
    SELECT COUNT(*) INTO room_count FROM rooms;
    SELECT COUNT(*) INTO amenity_count FROM amenities;
    SELECT COUNT(*) INTO mapping_count FROM room_type_amenities;
    
    IF rt_count < 3 THEN
        RAISE EXCEPTION 'Expected at least 3 room types, found %', rt_count;
    END IF;
    
    IF room_count < 20 THEN
        RAISE EXCEPTION 'Expected at least 20 rooms, found %', room_count;
    END IF;
    
    IF amenity_count < 10 THEN
        RAISE EXCEPTION 'Expected at least 10 amenities, found %', amenity_count;
    END IF;
    
    IF mapping_count = 0 THEN
        RAISE EXCEPTION 'Expected room-amenity mappings, found none';
    END IF;
    
    RAISE NOTICE '✓ Room Types: %', rt_count;
    RAISE NOTICE '✓ Rooms: %', room_count;
    RAISE NOTICE '✓ Amenities: %', amenity_count;
    RAISE NOTICE '✓ Room-Amenity Mappings: %', mapping_count;
END $$;

\echo ''

-- ============================================================================
-- Test 3: ตรวจสอบ Constraints
-- ============================================================================
\echo 'Test 3: Testing constraints...'

-- Test CHECK constraint สำหรับ occupancy_status
DO $$
BEGIN
    INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
    VALUES (1, 'TEST001', 1, 'InvalidStatus', 'Clean');
    RAISE EXCEPTION 'CHECK constraint failed: occupancy_status should reject invalid values';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE '✓ occupancy_status CHECK constraint works';
END $$;

-- Test CHECK constraint สำหรับ housekeeping_status
DO $$
BEGIN
    INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
    VALUES (1, 'TEST002', 1, 'Vacant', 'InvalidStatus');
    RAISE EXCEPTION 'CHECK constraint failed: housekeeping_status should reject invalid values';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE '✓ housekeeping_status CHECK constraint works';
END $$;

-- Test UNIQUE constraint สำหรับ room_number
DO $$
DECLARE
    existing_room VARCHAR(10);
BEGIN
    SELECT room_number INTO existing_room FROM rooms LIMIT 1;
    INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
    VALUES (1, existing_room, 1, 'Vacant', 'Clean');
    RAISE EXCEPTION 'UNIQUE constraint failed: room_number should be unique';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE '✓ room_number UNIQUE constraint works';
END $$;

-- Test FOREIGN KEY constraint
DO $$
BEGIN
    INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
    VALUES (99999, 'TEST003', 1, 'Vacant', 'Clean');
    RAISE EXCEPTION 'FOREIGN KEY constraint failed: should reject invalid room_type_id';
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE '✓ room_type_id FOREIGN KEY constraint works';
END $$;

\echo ''

-- ============================================================================
-- Test 4: ตรวจสอบ Indexes
-- ============================================================================
\echo 'Test 4: Checking indexes...'
DO $$
DECLARE
    index_count INT;
BEGIN
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename IN ('room_types', 'rooms', 'amenities', 'room_type_amenities')
      AND indexname LIKE 'idx_%';
    
    IF index_count < 5 THEN
        RAISE WARNING 'Expected at least 5 custom indexes, found %', index_count;
    ELSE
        RAISE NOTICE '✓ Found % custom indexes', index_count;
    END IF;
END $$;

\echo ''

-- ============================================================================
-- Test 5: ตรวจสอบ Triggers
-- ============================================================================
\echo 'Test 5: Testing triggers...'

-- Test updated_at trigger สำหรับ room_types
DO $$
DECLARE
    old_updated_at TIMESTAMP;
    new_updated_at TIMESTAMP;
    test_room_type_id INT;
BEGIN
    SELECT room_type_id, updated_at INTO test_room_type_id, old_updated_at
    FROM room_types LIMIT 1;
    
    -- รอสักครู่เพื่อให้ timestamp แตกต่าง
    PERFORM pg_sleep(0.1);
    
    UPDATE room_types
    SET description = 'Test update'
    WHERE room_type_id = test_room_type_id;
    
    SELECT updated_at INTO new_updated_at
    FROM room_types
    WHERE room_type_id = test_room_type_id;
    
    IF new_updated_at > old_updated_at THEN
        RAISE NOTICE '✓ room_types updated_at trigger works';
    ELSE
        RAISE EXCEPTION 'Trigger failed: updated_at was not updated';
    END IF;
    
    -- Rollback การเปลี่ยนแปลง
    ROLLBACK;
END $$;

-- Test updated_at trigger สำหรับ rooms
DO $$
DECLARE
    old_updated_at TIMESTAMP;
    new_updated_at TIMESTAMP;
    test_room_id INT;
BEGIN
    SELECT room_id, updated_at INTO test_room_id, old_updated_at
    FROM rooms LIMIT 1;
    
    PERFORM pg_sleep(0.1);
    
    UPDATE rooms
    SET notes = 'Test update'
    WHERE room_id = test_room_id;
    
    SELECT updated_at INTO new_updated_at
    FROM rooms
    WHERE room_id = test_room_id;
    
    IF new_updated_at > old_updated_at THEN
        RAISE NOTICE '✓ rooms updated_at trigger works';
    ELSE
        RAISE EXCEPTION 'Trigger failed: updated_at was not updated';
    END IF;
    
    ROLLBACK;
END $$;

\echo ''

-- ============================================================================
-- Test 6: ทดสอบ Query Performance
-- ============================================================================
\echo 'Test 6: Testing query performance...'

-- Test การค้นหาห้องว่างที่สะอาด
EXPLAIN ANALYZE
SELECT r.room_id, r.room_number, rt.name
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.occupancy_status = 'Vacant'
  AND r.housekeeping_status IN ('Clean', 'Inspected');

\echo ''

-- ============================================================================
-- Test 7: ทดสอบ Business Logic
-- ============================================================================
\echo 'Test 7: Testing business logic...'

-- ตรวจสอบว่าแต่ละประเภทห้องมี amenities
DO $$
DECLARE
    rt RECORD;
    amenity_count INT;
BEGIN
    FOR rt IN SELECT room_type_id, name FROM room_types LOOP
        SELECT COUNT(*) INTO amenity_count
        FROM room_type_amenities
        WHERE room_type_id = rt.room_type_id;
        
        IF amenity_count = 0 THEN
            RAISE WARNING 'Room type "%" has no amenities', rt.name;
        ELSE
            RAISE NOTICE '✓ Room type "%" has % amenities', rt.name, amenity_count;
        END IF;
    END LOOP;
END $$;

\echo ''

-- ============================================================================
-- Test 8: ตรวจสอบการกระจายห้อง
-- ============================================================================
\echo 'Test 8: Checking room distribution...'
SELECT 
    rt.name as room_type,
    COUNT(r.room_id) as total_rooms,
    COUNT(CASE WHEN r.occupancy_status = 'Occupied' THEN 1 END) as occupied,
    COUNT(CASE WHEN r.occupancy_status = 'Vacant' THEN 1 END) as vacant,
    COUNT(CASE WHEN r.housekeeping_status = 'Inspected' THEN 1 END) as inspected,
    COUNT(CASE WHEN r.housekeeping_status = 'Clean' THEN 1 END) as clean,
    COUNT(CASE WHEN r.housekeeping_status = 'Dirty' THEN 1 END) as dirty
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.name
ORDER BY rt.name;

\echo ''

-- ============================================================================
-- Test 9: ตรวจสอบความสมบูรณ์ของข้อมูล
-- ============================================================================
\echo 'Test 9: Checking data integrity...'

-- ตรวจสอบว่าทุกห้องมี room_type ที่ถูกต้อง
DO $$
DECLARE
    orphan_count INT;
BEGIN
    SELECT COUNT(*) INTO orphan_count
    FROM rooms r
    WHERE NOT EXISTS (
        SELECT 1 FROM room_types rt WHERE rt.room_type_id = r.room_type_id
    );
    
    IF orphan_count > 0 THEN
        RAISE EXCEPTION 'Found % rooms without valid room_type', orphan_count;
    ELSE
        RAISE NOTICE '✓ All rooms have valid room_type';
    END IF;
END $$;

-- ตรวจสอบว่าทุก amenity mapping มี room_type และ amenity ที่ถูกต้อง
DO $$
DECLARE
    invalid_count INT;
BEGIN
    SELECT COUNT(*) INTO invalid_count
    FROM room_type_amenities rta
    WHERE NOT EXISTS (
        SELECT 1 FROM room_types rt WHERE rt.room_type_id = rta.room_type_id
    ) OR NOT EXISTS (
        SELECT 1 FROM amenities a WHERE a.amenity_id = rta.amenity_id
    );
    
    IF invalid_count > 0 THEN
        RAISE EXCEPTION 'Found % invalid room-amenity mappings', invalid_count;
    ELSE
        RAISE NOTICE '✓ All room-amenity mappings are valid';
    END IF;
END $$;

\echo ''

-- ============================================================================
-- Summary
-- ============================================================================
\echo '=== Test Summary ==='
SELECT 
    'Tables' as category,
    COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('room_types', 'rooms', 'amenities', 'room_type_amenities')
UNION ALL
SELECT 
    'Room Types' as category,
    COUNT(*) as count
FROM room_types
UNION ALL
SELECT 
    'Rooms' as category,
    COUNT(*) as count
FROM rooms
UNION ALL
SELECT 
    'Amenities' as category,
    COUNT(*) as count
FROM amenities
UNION ALL
SELECT 
    'Room-Amenity Mappings' as category,
    COUNT(*) as count
FROM room_type_amenities
UNION ALL
SELECT 
    'Indexes' as category,
    COUNT(*) as count
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('room_types', 'rooms', 'amenities', 'room_type_amenities')
  AND indexname LIKE 'idx_%'
UNION ALL
SELECT 
    'Triggers' as category,
    COUNT(*) as count
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('room_types', 'rooms');

\echo ''
\echo '=== All Tests Completed Successfully! ==='
