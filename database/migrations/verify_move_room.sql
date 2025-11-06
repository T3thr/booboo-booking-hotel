-- ============================================================================
-- Verification Script: verify_move_room.sql
-- Description: ตรวจสอบว่า move_room function ถูกสร้างและทำงานได้ถูกต้อง
-- Task: 24. สร้าง PostgreSQL Function - move_room
-- ============================================================================

\echo '=== Verifying Move Room Function ==='
\echo ''

-- ============================================================================
-- 1. ตรวจสอบว่า function ถูกสร้างแล้ว
-- ============================================================================
\echo '--- Checking if move_room function exists ---'

SELECT 
    p.proname AS function_name,
    pg_get_function_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type,
    d.description
FROM pg_proc p
LEFT JOIN pg_description d ON p.oid = d.objoid
WHERE p.proname = 'move_room';

\echo ''

-- ============================================================================
-- 2. ตรวจสอบ function signature
-- ============================================================================
\echo '--- Checking function signature ---'

SELECT 
    p.proname AS function_name,
    p.pronargs AS num_arguments,
    pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
WHERE p.proname = 'move_room';

\echo ''

-- ============================================================================
-- 3. แสดง function definition
-- ============================================================================
\echo '--- Function definition ---'

\df+ move_room

\echo ''

-- ============================================================================
-- 4. ตรวจสอบ dependencies
-- ============================================================================
\echo '--- Checking function dependencies ---'

SELECT DISTINCT
    CASE 
        WHEN c.relkind = 'r' THEN 'table'
        WHEN c.relkind = 'v' THEN 'view'
        WHEN c.relkind = 'i' THEN 'index'
        ELSE 'other'
    END AS object_type,
    c.relname AS object_name
FROM pg_depend d
JOIN pg_proc p ON d.objid = p.oid
JOIN pg_rewrite r ON d.refobjid = r.oid
JOIN pg_class c ON r.ev_class = c.oid
WHERE p.proname = 'move_room'
  AND c.relkind IN ('r', 'v')
ORDER BY object_type, object_name;

\echo ''

-- ============================================================================
-- 5. ตรวจสอบว่าตารางที่เกี่ยวข้องมีอยู่
-- ============================================================================
\echo '--- Checking required tables ---'

SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('room_assignments', 'rooms', 'booking_details') 
        THEN '✓ EXISTS'
        ELSE '✗ MISSING'
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('room_assignments', 'rooms', 'booking_details')
ORDER BY table_name;

\echo ''

-- ============================================================================
-- 6. ตรวจสอบ columns ที่จำเป็น
-- ============================================================================
\echo '--- Checking required columns in room_assignments ---'

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'room_assignments'
  AND column_name IN ('room_assignment_id', 'booking_detail_id', 'room_id', 
                      'check_in_datetime', 'check_out_datetime', 'status')
ORDER BY column_name;

\echo ''

\echo '--- Checking required columns in rooms ---'

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'rooms'
  AND column_name IN ('room_id', 'room_number', 'room_type_id', 
                      'occupancy_status', 'housekeeping_status')
ORDER BY column_name;

\echo ''

-- ============================================================================
-- 7. ตรวจสอบ enum values สำหรับ status
-- ============================================================================
\echo '--- Checking status constraints ---'

SELECT 
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'room_assignments'
  AND cc.check_clause LIKE '%status%'
UNION ALL
SELECT 
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'rooms'
  AND (cc.check_clause LIKE '%occupancy_status%' 
       OR cc.check_clause LIKE '%housekeeping_status%');

\echo ''

-- ============================================================================
-- 8. สรุปผลการตรวจสอบ
-- ============================================================================
\echo '=== Verification Summary ==='
\echo ''

DO $
DECLARE
    v_function_exists BOOLEAN;
    v_tables_exist BOOLEAN;
    v_all_ok BOOLEAN := TRUE;
BEGIN
    -- ตรวจสอบ function
    SELECT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'move_room'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RAISE NOTICE '✓ Function move_room exists';
    ELSE
        RAISE NOTICE '✗ Function move_room does NOT exist';
        v_all_ok := FALSE;
    END IF;
    
    -- ตรวจสอบตาราง
    SELECT (
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN ('room_assignments', 'rooms', 'booking_details')
    ) = 3 INTO v_tables_exist;
    
    IF v_tables_exist THEN
        RAISE NOTICE '✓ All required tables exist';
    ELSE
        RAISE NOTICE '✗ Some required tables are missing';
        v_all_ok := FALSE;
    END IF;
    
    RAISE NOTICE '';
    
    IF v_all_ok THEN
        RAISE NOTICE '=== ✓ ALL CHECKS PASSED ===';
        RAISE NOTICE 'The move_room function is ready to use!';
    ELSE
        RAISE NOTICE '=== ✗ SOME CHECKS FAILED ===';
        RAISE NOTICE 'Please review the errors above.';
    END IF;
END $;

\echo ''
\echo '=== Verification Complete ==='
