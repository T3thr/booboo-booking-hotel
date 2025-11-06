-- ============================================================================
-- Verification Script: verify_booking_hold.sql
-- Description: ตรวจสอบว่า create_booking_hold function ถูกสร้างและทำงานได้
-- ============================================================================

\echo '============================================================================'
\echo 'Verifying Booking Hold Function'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- 1. ตรวจสอบว่า function มีอยู่
-- ============================================================================
\echo '1. Checking if function exists...'

SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type,
    d.description
FROM pg_proc p
LEFT JOIN pg_description d ON p.oid = d.objoid
WHERE p.proname = 'create_booking_hold';

\echo ''

-- ============================================================================
-- 2. ตรวจสอบ indexes ที่เกี่ยวข้อง
-- ============================================================================
\echo '2. Checking related indexes...'

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('booking_holds', 'room_inventory')
  AND indexname LIKE '%hold%' OR indexname LIKE '%inventory%'
ORDER BY tablename, indexname;

\echo ''

-- ============================================================================
-- 3. ตรวจสอบ constraints
-- ============================================================================
\echo '3. Checking constraints...'

SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'room_inventory'::regclass
  AND conname LIKE '%inventory%';

\echo ''

-- ============================================================================
-- 4. แสดงตัวอย่างข้อมูล booking_holds
-- ============================================================================
\echo '4. Sample booking_holds data...'

SELECT 
    COUNT(*) as total_holds,
    COUNT(*) FILTER (WHERE hold_expiry > NOW()) as active_holds,
    COUNT(*) FILTER (WHERE hold_expiry <= NOW()) as expired_holds
FROM booking_holds;

\echo ''

-- ============================================================================
-- 5. แสดงตัวอย่างข้อมูล room_inventory
-- ============================================================================
\echo '5. Sample room_inventory data (next 7 days)...'

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
  AND ri.date < CURRENT_DATE + INTERVAL '7 days'
ORDER BY rt.name, ri.date
LIMIT 21;

\echo ''

-- ============================================================================
-- 6. ทดสอบ function แบบง่าย (dry run)
-- ============================================================================
\echo '6. Testing function (dry run - will rollback)...'

BEGIN;

DO $$
DECLARE
    v_guest_account_id INT;
    v_room_type_id INT;
    v_result RECORD;
BEGIN
    -- ดึง guest account ID แรก
    SELECT guest_account_id INTO v_guest_account_id
    FROM guest_accounts
    LIMIT 1;
    
    -- ดึง room type ID แรก
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    LIMIT 1;
    
    IF v_guest_account_id IS NULL OR v_room_type_id IS NULL THEN
        RAISE NOTICE 'Cannot test: Missing guest account or room type';
        RETURN;
    END IF;
    
    -- ทดสอบเรียก function
    SELECT * INTO v_result
    FROM create_booking_hold(
        'verify-test-session',
        v_guest_account_id,
        v_room_type_id,
        CURRENT_DATE + INTERVAL '30 days',
        CURRENT_DATE + INTERVAL '32 days'
    );
    
    RAISE NOTICE 'Test Result:';
    RAISE NOTICE '  Success: %', v_result.success;
    RAISE NOTICE '  Message: %', v_result.message;
    RAISE NOTICE '  Hold Expiry: %', v_result.hold_expiry;
    
    IF v_result.success THEN
        RAISE NOTICE '✓ Function is working correctly!';
    ELSE
        RAISE NOTICE '✗ Function returned failure (this may be expected if no inventory)';
    END IF;
END $$;

ROLLBACK;

\echo ''
\echo '============================================================================'
\echo 'Verification Complete!'
\echo '============================================================================'
\echo ''
\echo 'To run full tests, execute: run_test_booking_hold.bat (Windows) or'
\echo '                            ./run_test_booking_hold.sh (Linux/Mac)'
\echo ''
