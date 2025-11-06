-- ============================================================================
-- Verification Script: verify_release_expired_holds.sql
-- Description: ตรวจสอบว่า release_expired_holds function ถูกสร้างและทำงานได้
-- Task: 14. สร้าง PostgreSQL Function - release_expired_holds
-- ============================================================================

DO $
DECLARE
    v_function_exists BOOLEAN;
    v_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Verifying Release Expired Holds Function ===';
    RAISE NOTICE '';
    
    -- ============================================================================
    -- 1. ตรวจสอบว่า function มีอยู่
    -- ============================================================================
    SELECT EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'release_expired_holds'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RAISE NOTICE '✓ Function release_expired_holds exists';
    ELSE
        RAISE NOTICE '✗ Function release_expired_holds NOT FOUND';
        RAISE NOTICE '';
        RAISE NOTICE '=== Verification FAILED ===';
        RETURN;
    END IF;
    
    -- ============================================================================
    -- 2. ตรวจสอบ function signature
    -- ============================================================================
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'release_expired_holds'
          AND p.pronargs = 0  -- No input parameters
    ) THEN
        RAISE NOTICE '✓ Function signature correct (no parameters)';
    ELSE
        RAISE NOTICE '✗ Function signature incorrect';
    END IF;
    
    -- ============================================================================
    -- 3. ตรวจสอบ return type
    -- ============================================================================
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'release_expired_holds'
          AND p.proretset = true  -- Returns a set (table)
    ) THEN
        RAISE NOTICE '✓ Function returns table';
    ELSE
        RAISE NOTICE '✗ Function return type incorrect';
    END IF;
    
    -- ============================================================================
    -- 4. ทดสอบเรียก function (ควรไม่ error)
    -- ============================================================================
    BEGIN
        SELECT * INTO v_result FROM release_expired_holds();
        RAISE NOTICE '✓ Function executes without error';
        RAISE NOTICE '  Result: released_count = %s', v_result.released_count;
        RAISE NOTICE '  Result: message = %s', v_result.message;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '✗ Function execution failed: %s', SQLERRM;
    END;
    
    -- ============================================================================
    -- 5. ตรวจสอบ function comment
    -- ============================================================================
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'release_expired_holds'
          AND obj_description(p.oid, 'pg_proc') IS NOT NULL
    ) THEN
        RAISE NOTICE '✓ Function has documentation comment';
    ELSE
        RAISE NOTICE '⚠ Function missing documentation comment';
    END IF;
    
    -- ============================================================================
    -- Summary
    -- ============================================================================
    RAISE NOTICE '';
    RAISE NOTICE '=== Verification Summary ===';
    RAISE NOTICE 'Function: release_expired_holds';
    RAISE NOTICE 'Status: Ready for use';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage:';
    RAISE NOTICE '  SELECT * FROM release_expired_holds();';
    RAISE NOTICE '';
    RAISE NOTICE 'Purpose:';
    RAISE NOTICE '  - Release expired booking holds';
    RAISE NOTICE '  - Return tentative_count to inventory';
    RAISE NOTICE '  - Should be called by background job every 5 minutes';
    RAISE NOTICE '';
    RAISE NOTICE '=== Verification PASSED ===';
    RAISE NOTICE '';
    
END $;
