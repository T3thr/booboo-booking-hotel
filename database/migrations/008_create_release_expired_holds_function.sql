-- ============================================================================
-- Migration: 008_create_release_expired_holds_function.sql
-- Description: สร้าง PostgreSQL Function สำหรับปล่อย booking holds ที่หมดอายุ
-- Task: 14. สร้าง PostgreSQL Function - release_expired_holds
-- Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8
-- ============================================================================

-- ============================================================================
-- 1. สร้าง Function: release_expired_holds
-- ============================================================================
-- Function นี้จะ:
-- 1. หา booking holds ที่หมดอายุแล้ว (hold_expiry < NOW())
-- 2. คืน tentative_count กลับเข้า room_inventory แบบ atomic
-- 3. ลบ booking holds ที่หมดอายุออกจากระบบ
-- 4. Return จำนวน holds ที่ถูกปล่อย
-- 
-- Function นี้ควรถูกเรียกโดย background job ทุก 5 นาที
-- ============================================================================

CREATE OR REPLACE FUNCTION release_expired_holds()
RETURNS TABLE(
    released_count INT,
    message TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_expired_count INT;
    v_affected_inventory INT;
BEGIN
    -- ============================================================================
    -- STEP 1: คืน tentative_count กลับเข้า inventory
    -- ============================================================================
    -- อัปเดต room_inventory โดยลด tentative_count สำหรับแต่ละ hold ที่หมดอายุ
    -- ใช้ subquery เพื่อนับจำนวน holds ที่หมดอายุสำหรับแต่ละ (room_type_id, date)
    WITH expired_holds AS (
        SELECT 
            room_type_id,
            date,
            COUNT(*) as hold_count
        FROM booking_holds
        WHERE hold_expiry < NOW()
        GROUP BY room_type_id, date
    )
    UPDATE room_inventory ri
    SET 
        tentative_count = GREATEST(0, tentative_count - eh.hold_count),
        updated_at = NOW()
    FROM expired_holds eh
    WHERE ri.room_type_id = eh.room_type_id 
      AND ri.date = eh.date
      AND ri.tentative_count > 0;
    
    -- เก็บจำนวน rows ที่ถูกอัปเดต
    GET DIAGNOSTICS v_affected_inventory = ROW_COUNT;
    
    -- ============================================================================
    -- STEP 2: ลบ booking holds ที่หมดอายุ
    -- ============================================================================
    DELETE FROM booking_holds
    WHERE hold_expiry < NOW();
    
    -- เก็บจำนวน holds ที่ถูกลบ
    GET DIAGNOSTICS v_expired_count = ROW_COUNT;
    
    -- ============================================================================
    -- STEP 3: Return ผลลัพธ์
    -- ============================================================================
    IF v_expired_count > 0 THEN
        RETURN QUERY SELECT 
            v_expired_count,
            FORMAT('ปล่อย %s holds ที่หมดอายุ และอัปเดต %s inventory records', 
                   v_expired_count, v_affected_inventory);
    ELSE
        RETURN QUERY SELECT 
            0,
            'ไม่มี holds ที่หมดอายุ'::TEXT;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- จัดการ error ที่ไม่คาดคิด
        RETURN QUERY SELECT 
            -1,
            FORMAT('เกิดข้อผิดพลาด: %s', SQLERRM);
END;
$$;

-- ============================================================================
-- 2. เพิ่ม Comments
-- ============================================================================
COMMENT ON FUNCTION release_expired_holds IS 
'ปล่อย booking holds ที่หมดอายุและคืน tentative_count กลับเข้า inventory
- ควรถูกเรียกโดย background job ทุก 5 นาที
- ใช้ CTE เพื่อนับจำนวน holds ที่หมดอายุแบบ grouped
- คืนสต็อกกลับเข้า inventory แบบ atomic
- ป้องกัน tentative_count ติดลบด้วย GREATEST(0, ...)';

-- ============================================================================
-- 3. Grant Permissions
-- ============================================================================
-- ให้สิทธิ์ execute function แก่ backend application
-- (ปรับตามชื่อ database user ที่ใช้จริง)
-- GRANT EXECUTE ON FUNCTION release_expired_holds TO hotel_app_user;

-- ============================================================================
-- 4. Verification
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== Release Expired Holds Function Created Successfully ===';
    RAISE NOTICE 'Function: release_expired_holds';
    RAISE NOTICE 'Purpose: ปล่อย booking holds ที่หมดอายุและคืนสต็อก';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  - Atomic inventory updates';
    RAISE NOTICE '  - Grouped hold counting with CTE';
    RAISE NOTICE '  - Prevents negative tentative_count';
    RAISE NOTICE '  - Returns statistics';
    RAISE NOTICE 'Usage: Should be called by background job every 5 minutes';
    RAISE NOTICE '==============================================================';
END $$;
