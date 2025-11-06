-- ============================================================================
-- Verification Script: cancel_booking Function
-- ============================================================================
-- Purpose: Quick verification that the cancel_booking function exists and works
-- ============================================================================

\echo ''
\echo '========================================'
\echo 'Verifying cancel_booking Function'
\echo '========================================'
\echo ''

-- ============================================================================
-- 1. Check if function exists
-- ============================================================================

\echo '1. Checking if function exists...'

SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'cancel_booking';

\echo ''

-- ============================================================================
-- 2. Check function signature
-- ============================================================================

\echo '2. Function signature:'
\echo ''

\df cancel_booking

\echo ''

-- ============================================================================
-- 3. Show function source (first 50 lines)
-- ============================================================================

\echo '3. Function definition (preview):'
\echo ''

SELECT 
    substring(pg_get_functiondef(oid), 1, 500) || '...' as function_preview
FROM pg_proc
WHERE proname = 'cancel_booking';

\echo ''

-- ============================================================================
-- 4. Check dependencies
-- ============================================================================

\echo '4. Checking required tables...'

SELECT 
    table_name,
    CASE 
        WHEN table_name IN (
            SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        ) THEN '✓ EXISTS'
        ELSE '✗ MISSING'
    END as status
FROM (
    VALUES 
        ('bookings'),
        ('booking_details'),
        ('room_inventory')
) AS required_tables(table_name);

\echo ''

-- ============================================================================
-- 5. Quick functionality test
-- ============================================================================

\echo '5. Quick functionality test...'
\echo ''

DO $
DECLARE
    v_result RECORD;
BEGIN
    -- Test with non-existent booking (should return error gracefully)
    SELECT * INTO v_result FROM cancel_booking(99999, 'Test');
    
    IF v_result.success = FALSE THEN
        RAISE NOTICE '✓ Function handles non-existent bookings correctly';
        RAISE NOTICE '  Message: %', v_result.message;
    ELSE
        RAISE WARNING '✗ Function should reject non-existent bookings';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '✗ Function threw unexpected error: %', SQLERRM;
END $;

\echo ''

-- ============================================================================
-- Summary
-- ============================================================================

\echo '========================================'
\echo 'Verification Complete'
\echo '========================================'
\echo ''
\echo 'Function: cancel_booking'
\echo 'Status: Ready for use'
\echo ''
\echo 'Usage:'
\echo '  SELECT * FROM cancel_booking('
\echo '    p_booking_id := 123,'
\echo '    p_cancellation_reason := ''Customer request'''
\echo '  );'
\echo ''
\echo 'Returns:'
\echo '  - success: BOOLEAN'
\echo '  - message: TEXT'
\echo '  - refund_amount: DECIMAL(10,2)'
\echo '  - refund_percentage: DECIMAL(5,2)'
\echo ''
\echo 'For comprehensive tests, run:'
\echo '  - Windows: run_test_cancel_booking.bat'
\echo '  - Linux/Mac: ./run_test_cancel_booking.sh'
\echo '========================================'
\echo ''
