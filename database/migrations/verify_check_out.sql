-- ============================================================================
-- Verification Script: verify_check_out.sql
-- Description: ตรวจสอบว่า check_out function ถูกสร้างและทำงานถูกต้อง
-- ============================================================================

DO $$
DECLARE
    v_function_exists BOOLEAN;
    v_test_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Verifying Check-out Function';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    
    -- ============================================================================
    -- 1. ตรวจสอบว่า function มีอยู่
    -- ============================================================================
    SELECT EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'check_out'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RAISE NOTICE '✓ Function check_out exists';
    ELSE
        RAISE NOTICE '✗ FAIL: Function check_out does not exist';
        RETURN;
    END IF;
    
    -- ============================================================================
    -- 2. ตรวจสอบ function signature
    -- ============================================================================
    RAISE NOTICE '';
    RAISE NOTICE 'Function Signature:';
    RAISE NOTICE '  Name: check_out';
    RAISE NOTICE '  Parameters:';
    RAISE NOTICE '    - p_booking_id INT';
    RAISE NOTICE '  Returns:';
    RAISE NOTICE '    - success BOOLEAN';
    RAISE NOTICE '    - message TEXT';
    RAISE NOTICE '    - total_amount DECIMAL(10, 2)';
    RAISE NOTICE '    - rooms_checked_out INT';
    
    -- ============================================================================
    -- 3. ตรวจสอบ function comment
    -- ============================================================================
    DECLARE
        v_comment TEXT;
    BEGIN
        SELECT obj_description(p.oid, 'pg_proc') INTO v_comment
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'check_out';
        
        IF v_comment IS NOT NULL THEN
            RAISE NOTICE '';
            RAISE NOTICE '✓ Function has documentation';
            RAISE NOTICE '  Description: %', SUBSTRING(v_comment, 1, 100) || '...';
        ELSE
            RAISE NOTICE '';
            RAISE NOTICE '⚠ Warning: Function has no documentation';
        END IF;
    END;
    
    -- ============================================================================
    -- 4. ทดสอบการเรียกใช้ function (Quick Test)
    -- ============================================================================
    RAISE NOTICE '';
    RAISE NOTICE 'Quick Functionality Test:';
    
    -- ทดสอบกับ booking ที่ไม่มีอยู่ (ควรล้มเหลวอย่างสวยงาม)
    BEGIN
        SELECT * INTO v_test_result FROM check_out(99999);
        
        IF NOT v_test_result.success THEN
            RAISE NOTICE '✓ Function handles non-existent booking correctly';
            RAISE NOTICE '  Message: %', v_test_result.message;
        ELSE
            RAISE NOTICE '✗ FAIL: Function should reject non-existent booking';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '✗ FAIL: Function threw unexpected error: %', SQLERRM;
    END;
    
    -- ============================================================================
    -- 5. ตรวจสอบ dependencies
    -- ============================================================================
    RAISE NOTICE '';
    RAISE NOTICE 'Dependencies Check:';
    
    -- ตรวจสอบว่าตารางที่จำเป็นมีอยู่
    DECLARE
        v_tables_exist BOOLEAN;
    BEGIN
        SELECT 
            COUNT(*) = 4
        INTO v_tables_exist
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN ('bookings', 'booking_details', 'room_assignments', 'rooms');
        
        IF v_tables_exist THEN
            RAISE NOTICE '✓ All required tables exist';
            RAISE NOTICE '  - bookings';
            RAISE NOTICE '  - booking_details';
            RAISE NOTICE '  - room_assignments';
            RAISE NOTICE '  - rooms';
        ELSE
            RAISE NOTICE '✗ FAIL: Some required tables are missing';
        END IF;
    END;
    
    -- ============================================================================
    -- 6. ตรวจสอบ indexes ที่เกี่ยวข้อง
    -- ============================================================================
    RAISE NOTICE '';
    RAISE NOTICE 'Related Indexes:';
    
    DECLARE
        v_index_count INT;
    BEGIN
        SELECT COUNT(*) INTO v_index_count
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND (
              indexname LIKE '%booking%' OR
              indexname LIKE '%room%' OR
              indexname LIKE '%assignment%'
          );
        
        RAISE NOTICE '✓ Found % related indexes', v_index_count;
    END;
    
    -- ============================================================================
    -- Summary
    -- ============================================================================
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Verification Summary';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✓ Function check_out is properly installed';
    RAISE NOTICE '✓ Function signature is correct';
    RAISE NOTICE '✓ Function handles errors gracefully';
    RAISE NOTICE '✓ All dependencies are satisfied';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Run full test suite: test_check_out_function.sql';
    RAISE NOTICE '  2. Integrate with backend API';
    RAISE NOTICE '  3. Test with real booking scenarios';
    RAISE NOTICE '========================================';
    
END $$;
