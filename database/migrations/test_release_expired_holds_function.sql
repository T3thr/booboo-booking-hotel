-- ============================================================================
-- Test Script: test_release_expired_holds_function.sql
-- Description: ทดสอบ release_expired_holds function
-- Task: 14. สร้าง PostgreSQL Function - release_expired_holds
-- ============================================================================

-- ============================================================================
-- Setup: เตรียมข้อมูลทดสอบ
-- ============================================================================
DO $
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Starting Release Expired Holds Function Tests ===';
    RAISE NOTICE '';
END $;

-- ล้างข้อมูลทดสอบเก่า
DELETE FROM booking_holds WHERE session_id LIKE 'TEST_RELEASE_%';
DELETE FROM room_inventory WHERE room_type_id = 1 AND date >= CURRENT_DATE;

-- สร้าง inventory สำหรับทดสอบ (3 วัน)
INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
VALUES 
    (1, CURRENT_DATE, 10, 0, 0),
    (1, CURRENT_DATE + 1, 10, 0, 0),
    (1, CURRENT_DATE + 2, 10, 0, 0);

-- ============================================================================
-- Test 1: ทดสอบการปล่อย holds ที่หมดอายุ
-- ============================================================================
DO $
DECLARE
    v_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '--- Test 1: Release Expired Holds ---';
    
    -- สร้าง holds ที่หมดอายุแล้ว (expiry ในอดีต)
    INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
    VALUES 
        ('TEST_RELEASE_EXPIRED_1', 1, 1, CURRENT_DATE, NOW() - INTERVAL '1 hour'),
        ('TEST_RELEASE_EXPIRED_1', 1, 1, CURRENT_DATE + 1, NOW() - INTERVAL '1 hour'),
        ('TEST_RELEASE_EXPIRED_2', 2, 1, CURRENT_DATE, NOW() - INTERVAL '30 minutes');
    
    -- อัปเดต tentative_count ให้สอดคล้องกับ holds
    UPDATE room_inventory 
    SET tentative_count = 2 
    WHERE room_type_id = 1 AND date = CURRENT_DATE;
    
    UPDATE room_inventory 
    SET tentative_count = 1 
    WHERE room_type_id = 1 AND date = CURRENT_DATE + 1;
    
    RAISE NOTICE 'Created 3 expired holds';
    RAISE NOTICE 'Inventory before: Date=%s, Tentative=%s', 
        CURRENT_DATE, 
        (SELECT tentative_count FROM room_inventory WHERE room_type_id = 1 AND date = CURRENT_DATE);
    
    -- เรียก function
    SELECT * INTO v_result FROM release_expired_holds();
    
    RAISE NOTICE 'Result: Released Count = %s', v_result.released_count;
    RAISE NOTICE 'Result: Message = %s', v_result.message;
    
    -- ตรวจสอบผลลัพธ์
    IF v_result.released_count = 3 THEN
        RAISE NOTICE '✓ Test 1 PASSED: Released 3 expired holds';
    ELSE
        RAISE NOTICE '✗ Test 1 FAILED: Expected 3, got %s', v_result.released_count;
    END IF;
    
    -- ตรวจสอบว่า tentative_count ถูกคืนแล้ว
    IF (SELECT tentative_count FROM room_inventory WHERE room_type_id = 1 AND date = CURRENT_DATE) = 0 THEN
        RAISE NOTICE '✓ Inventory restored correctly for CURRENT_DATE';
    ELSE
        RAISE NOTICE '✗ Inventory NOT restored correctly';
    END IF;
    
    -- ตรวจสอบว่า holds ถูกลบแล้ว
    IF NOT EXISTS (SELECT 1 FROM booking_holds WHERE session_id LIKE 'TEST_RELEASE_EXPIRED_%') THEN
        RAISE NOTICE '✓ Expired holds deleted successfully';
    ELSE
        RAISE NOTICE '✗ Expired holds still exist';
    END IF;
END $;

-- ============================================================================
-- Test 2: ทดสอบกรณีไม่มี holds ที่หมดอายุ
-- ============================================================================
DO $
DECLARE
    v_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '--- Test 2: No Expired Holds ---';
    
    -- เรียก function เมื่อไม่มี holds ที่หมดอายุ
    SELECT * INTO v_result FROM release_expired_holds();
    
    RAISE NOTICE 'Result: Released Count = %s', v_result.released_count;
    RAISE NOTICE 'Result: Message = %s', v_result.message;
    
    IF v_result.released_count = 0 THEN
        RAISE NOTICE '✓ Test 2 PASSED: No holds to release';
    ELSE
        RAISE NOTICE '✗ Test 2 FAILED: Expected 0, got %s', v_result.released_count;
    END IF;
END $;

-- ============================================================================
-- Test 3: ทดสอบกรณีมีทั้ง holds ที่หมดอายุและยังไม่หมดอายุ
-- ============================================================================
DO $
DECLARE
    v_result RECORD;
    v_active_holds_before INT;
    v_active_holds_after INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '--- Test 3: Mixed Expired and Active Holds ---';
    
    -- สร้าง holds ที่หมดอายุ
    INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
    VALUES 
        ('TEST_RELEASE_EXPIRED_3', 1, 1, CURRENT_DATE, NOW() - INTERVAL '5 minutes'),
        ('TEST_RELEASE_EXPIRED_3', 1, 1, CURRENT_DATE + 1, NOW() - INTERVAL '5 minutes');
    
    -- สร้าง holds ที่ยังไม่หมดอายุ
    INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
    VALUES 
        ('TEST_RELEASE_ACTIVE', 2, 1, CURRENT_DATE, NOW() + INTERVAL '10 minutes'),
        ('TEST_RELEASE_ACTIVE', 2, 1, CURRENT_DATE + 1, NOW() + INTERVAL '10 minutes');
    
    -- อัปเดต inventory
    UPDATE room_inventory 
    SET tentative_count = 2 
    WHERE room_type_id = 1 AND date = CURRENT_DATE;
    
    UPDATE room_inventory 
    SET tentative_count = 2 
    WHERE room_type_id = 1 AND date = CURRENT_DATE + 1;
    
    -- นับ active holds ก่อนเรียก function
    SELECT COUNT(*) INTO v_active_holds_before
    FROM booking_holds 
    WHERE session_id = 'TEST_RELEASE_ACTIVE';
    
    RAISE NOTICE 'Created 2 expired holds and 2 active holds';
    
    -- เรียก function
    SELECT * INTO v_result FROM release_expired_holds();
    
    RAISE NOTICE 'Result: Released Count = %s', v_result.released_count;
    RAISE NOTICE 'Result: Message = %s', v_result.message;
    
    -- นับ active holds หลังเรียก function
    SELECT COUNT(*) INTO v_active_holds_after
    FROM booking_holds 
    WHERE session_id = 'TEST_RELEASE_ACTIVE';
    
    IF v_result.released_count = 2 THEN
        RAISE NOTICE '✓ Test 3 PASSED: Released only expired holds';
    ELSE
        RAISE NOTICE '✗ Test 3 FAILED: Expected 2, got %s', v_result.released_count;
    END IF;
    
    IF v_active_holds_before = v_active_holds_after AND v_active_holds_after = 2 THEN
        RAISE NOTICE '✓ Active holds preserved correctly';
    ELSE
        RAISE NOTICE '✗ Active holds affected (Before: %s, After: %s)', 
            v_active_holds_before, v_active_holds_after;
    END IF;
    
    -- ตรวจสอบ inventory (ควรเหลือ tentative_count = 1 สำหรับ active holds)
    IF (SELECT tentative_count FROM room_inventory WHERE room_type_id = 1 AND date = CURRENT_DATE) = 1 THEN
        RAISE NOTICE '✓ Inventory correctly shows 1 tentative (active hold)';
    ELSE
        RAISE NOTICE '✗ Inventory incorrect: %s', 
            (SELECT tentative_count FROM room_inventory WHERE room_type_id = 1 AND date = CURRENT_DATE);
    END IF;
END $;

-- ============================================================================
-- Test 4: ทดสอบการป้องกัน tentative_count ติดลบ
-- ============================================================================
DO $
DECLARE
    v_result RECORD;
    v_tentative_after INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '--- Test 4: Prevent Negative Tentative Count ---';
    
    -- ล้างข้อมูลเก่า
    DELETE FROM booking_holds WHERE session_id LIKE 'TEST_RELEASE_%';
    
    -- ตั้งค่า inventory ให้ tentative_count = 0
    UPDATE room_inventory 
    SET tentative_count = 0 
    WHERE room_type_id = 1 AND date = CURRENT_DATE + 2;
    
    -- สร้าง expired hold (แต่ inventory มี tentative_count = 0 อยู่แล้ว)
    INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
    VALUES ('TEST_RELEASE_NEGATIVE', 1, 1, CURRENT_DATE + 2, NOW() - INTERVAL '1 hour');
    
    RAISE NOTICE 'Created expired hold with tentative_count already at 0';
    
    -- เรียก function
    SELECT * INTO v_result FROM release_expired_holds();
    
    -- ตรวจสอบว่า tentative_count ไม่ติดลบ
    SELECT tentative_count INTO v_tentative_after
    FROM room_inventory 
    WHERE room_type_id = 1 AND date = CURRENT_DATE + 2;
    
    IF v_tentative_after >= 0 THEN
        RAISE NOTICE '✓ Test 4 PASSED: Tentative count = %s (not negative)', v_tentative_after;
    ELSE
        RAISE NOTICE '✗ Test 4 FAILED: Tentative count is negative: %s', v_tentative_after;
    END IF;
END $;

-- ============================================================================
-- Test 5: ทดสอบ Performance กับ holds จำนวนมาก
-- ============================================================================
DO $
DECLARE
    v_result RECORD;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration INTERVAL;
    i INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '--- Test 5: Performance Test (100 Expired Holds) ---';
    
    -- ล้างข้อมูลเก่า
    DELETE FROM booking_holds WHERE session_id LIKE 'TEST_RELEASE_%';
    
    -- รีเซ็ต inventory
    UPDATE room_inventory 
    SET tentative_count = 0 
    WHERE room_type_id = 1;
    
    -- สร้าง 100 expired holds
    FOR i IN 1..100 LOOP
        INSERT INTO booking_holds (session_id, guest_account_id, room_type_id, date, hold_expiry)
        VALUES (
            'TEST_RELEASE_PERF_' || i,
            (i % 10) + 1,  -- Guest IDs 1-10
            1,
            CURRENT_DATE + ((i % 3)::TEXT || ' days')::INTERVAL,
            NOW() - INTERVAL '1 hour'
        );
    END LOOP;
    
    -- อัปเดต inventory ให้สอดคล้อง
    UPDATE room_inventory ri
    SET tentative_count = (
        SELECT COUNT(*)
        FROM booking_holds bh
        WHERE bh.room_type_id = ri.room_type_id
          AND bh.date = ri.date
    )
    WHERE room_type_id = 1;
    
    RAISE NOTICE 'Created 100 expired holds';
    
    -- วัดเวลา
    v_start_time := clock_timestamp();
    SELECT * INTO v_result FROM release_expired_holds();
    v_end_time := clock_timestamp();
    v_duration := v_end_time - v_start_time;
    
    RAISE NOTICE 'Result: Released Count = %s', v_result.released_count;
    RAISE NOTICE 'Duration: %s ms', EXTRACT(MILLISECONDS FROM v_duration);
    
    IF v_result.released_count = 100 THEN
        RAISE NOTICE '✓ Test 5 PASSED: Released all 100 holds';
    ELSE
        RAISE NOTICE '✗ Test 5 FAILED: Expected 100, got %s', v_result.released_count;
    END IF;
    
    IF EXTRACT(MILLISECONDS FROM v_duration) < 1000 THEN
        RAISE NOTICE '✓ Performance acceptable (< 1 second)';
    ELSE
        RAISE NOTICE '⚠ Performance warning: took %s ms', EXTRACT(MILLISECONDS FROM v_duration);
    END IF;
END $;

-- ============================================================================
-- Cleanup: ล้างข้อมูลทดสอบ
-- ============================================================================
DO $
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '--- Cleanup ---';
    
    DELETE FROM booking_holds WHERE session_id LIKE 'TEST_RELEASE_%';
    DELETE FROM room_inventory WHERE room_type_id = 1 AND date >= CURRENT_DATE;
    
    RAISE NOTICE 'Test data cleaned up';
    RAISE NOTICE '';
    RAISE NOTICE '=== All Tests Completed ===';
    RAISE NOTICE '';
END $;
