-- ============================================================================
-- Test Script: test_booking_hold_function.sql
-- Description: ทดสอบ create_booking_hold function
-- Task: 11. สร้าง PostgreSQL Function - create_booking_hold
-- ============================================================================

-- ============================================================================
-- Setup: สร้างข้อมูลทดสอบ
-- ============================================================================

-- สร้าง test guest account (ถ้ายังไม่มี)
DO $$
DECLARE
    v_guest_id INT;
    v_guest_account_id INT;
BEGIN
    -- สร้าง guest
    INSERT INTO guests (first_name, last_name, email, phone)
    VALUES ('Test', 'User', 'test.hold@example.com', '0812345678')
    ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email
    RETURNING guest_id INTO v_guest_id;
    
    -- สร้าง guest account
    INSERT INTO guest_accounts (guest_id, hashed_password)
    VALUES (v_guest_id, '$2a$10$test.hash.password')
    ON CONFLICT (guest_id) DO NOTHING;
    
    RAISE NOTICE 'Test guest created/updated: guest_id = %', v_guest_id;
END $$;

-- ล้างข้อมูล hold เก่าของ test user
DELETE FROM booking_holds 
WHERE guest_account_id IN (
    SELECT ga.guest_account_id 
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com'
);

-- รีเซ็ต inventory สำหรับการทดสอบ
UPDATE room_inventory
SET tentative_count = 0,
    booked_count = LEAST(booked_count, allotment - 5) -- ให้แน่ใจว่ามีห้องว่างอย่างน้อย 5 ห้อง
WHERE date >= CURRENT_DATE
  AND date < CURRENT_DATE + INTERVAL '30 days';

RAISE NOTICE '=== Test Setup Complete ===';

-- ============================================================================
-- TEST 1: Basic Hold Creation (Success Case)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== TEST 1: Basic Hold Creation ===';

DO $$
DECLARE
    v_guest_account_id INT;
    v_room_type_id INT;
    v_result RECORD;
BEGIN
    -- ดึง guest_account_id
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com';
    
    -- ดึง room_type_id (Standard Room)
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    WHERE name = 'Standard Room'
    LIMIT 1;
    
    -- เรียก function
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-001',
        v_guest_account_id,
        v_room_type_id,
        CURRENT_DATE + INTERVAL '7 days',
        CURRENT_DATE + INTERVAL '10 days'
    );
    
    -- แสดงผลลัพธ์
    RAISE NOTICE 'Success: %', v_result.success;
    RAISE NOTICE 'Message: %', v_result.message;
    RAISE NOTICE 'Hold Expiry: %', v_result.hold_expiry;
    
    -- ตรวจสอบว่า hold ถูกสร้าง
    IF v_result.success THEN
        RAISE NOTICE 'Hold records created: %', (
            SELECT COUNT(*) 
            FROM booking_holds 
            WHERE session_id = 'test-session-001'
        );
        
        RAISE NOTICE 'Tentative count increased: %', (
            SELECT SUM(tentative_count)
            FROM room_inventory
            WHERE room_type_id = v_room_type_id
              AND date >= CURRENT_DATE + INTERVAL '7 days'
              AND date < CURRENT_DATE + INTERVAL '10 days'
        );
    END IF;
    
    ASSERT v_result.success = TRUE, 'TEST 1 FAILED: Hold creation should succeed';
    RAISE NOTICE '✓ TEST 1 PASSED';
END $$;

-- ============================================================================
-- TEST 2: Replace Existing Hold (Auto-release old hold)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== TEST 2: Replace Existing Hold ===';

DO $$
DECLARE
    v_guest_account_id INT;
    v_room_type_id INT;
    v_result RECORD;
    v_old_hold_count INT;
    v_new_hold_count INT;
BEGIN
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com';
    
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    WHERE name = 'Standard Room'
    LIMIT 1;
    
    -- นับ hold เก่า
    SELECT COUNT(*) INTO v_old_hold_count
    FROM booking_holds
    WHERE guest_account_id = v_guest_account_id;
    
    RAISE NOTICE 'Old hold count: %', v_old_hold_count;
    
    -- สร้าง hold ใหม่ที่ซ้อนทับกับ hold เก่า
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-002',
        v_guest_account_id,
        v_room_type_id,
        CURRENT_DATE + INTERVAL '8 days',  -- ซ้อนทับกับ hold เก่า
        CURRENT_DATE + INTERVAL '12 days'
    );
    
    RAISE NOTICE 'Success: %', v_result.success;
    RAISE NOTICE 'Message: %', v_result.message;
    
    -- นับ hold ใหม่
    SELECT COUNT(*) INTO v_new_hold_count
    FROM booking_holds
    WHERE guest_account_id = v_guest_account_id;
    
    RAISE NOTICE 'New hold count: %', v_new_hold_count;
    RAISE NOTICE 'Hold records for new session: %', (
        SELECT COUNT(*) 
        FROM booking_holds 
        WHERE session_id = 'test-session-002'
    );
    
    ASSERT v_result.success = TRUE, 'TEST 2 FAILED: Hold replacement should succeed';
    RAISE NOTICE '✓ TEST 2 PASSED';
END $$;

-- ============================================================================
-- TEST 3: No Availability (Should Fail)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== TEST 3: No Availability ===';

DO $$
DECLARE
    v_guest_account_id INT;
    v_room_type_id INT;
    v_result RECORD;
    v_test_date DATE;
BEGIN
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com';
    
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    WHERE name = 'Standard Room'
    LIMIT 1;
    
    v_test_date := CURRENT_DATE + INTERVAL '20 days';
    
    -- ทำให้ห้องเต็มสำหรับวันที่ทดสอบ
    UPDATE room_inventory
    SET tentative_count = allotment - booked_count
    WHERE room_type_id = v_room_type_id
      AND date = v_test_date;
    
    RAISE NOTICE 'Set room to full for date: %', v_test_date;
    
    -- พยายามสร้าง hold (ควรล้มเหลว)
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-003',
        v_guest_account_id,
        v_room_type_id,
        v_test_date,
        v_test_date + INTERVAL '2 days'
    );
    
    RAISE NOTICE 'Success: %', v_result.success;
    RAISE NOTICE 'Message: %', v_result.message;
    
    ASSERT v_result.success = FALSE, 'TEST 3 FAILED: Should fail when no availability';
    ASSERT v_result.message LIKE '%ไม่ว่าง%', 'TEST 3 FAILED: Error message should mention unavailability';
    RAISE NOTICE '✓ TEST 3 PASSED';
    
    -- รีเซ็ตกลับ
    UPDATE room_inventory
    SET tentative_count = 0
    WHERE room_type_id = v_room_type_id
      AND date = v_test_date;
END $$;

-- ============================================================================
-- TEST 4: Invalid Date Range (Should Fail)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== TEST 4: Invalid Date Range ===';

DO $$
DECLARE
    v_guest_account_id INT;
    v_room_type_id INT;
    v_result RECORD;
BEGIN
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com';
    
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    WHERE name = 'Standard Room'
    LIMIT 1;
    
    -- Test 4a: Check-out before check-in
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-004a',
        v_guest_account_id,
        v_room_type_id,
        CURRENT_DATE + INTERVAL '10 days',
        CURRENT_DATE + INTERVAL '5 days'  -- ก่อน check-in
    );
    
    RAISE NOTICE 'Test 4a - Success: %', v_result.success;
    RAISE NOTICE 'Test 4a - Message: %', v_result.message;
    ASSERT v_result.success = FALSE, 'TEST 4a FAILED: Should fail when check-out before check-in';
    
    -- Test 4b: Past date
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-004b',
        v_guest_account_id,
        v_room_type_id,
        CURRENT_DATE - INTERVAL '5 days',  -- วันที่ผ่านมาแล้ว
        CURRENT_DATE - INTERVAL '3 days'
    );
    
    RAISE NOTICE 'Test 4b - Success: %', v_result.success;
    RAISE NOTICE 'Test 4b - Message: %', v_result.message;
    ASSERT v_result.success = FALSE, 'TEST 4b FAILED: Should fail for past dates';
    
    -- Test 4c: Too many nights (> 30)
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-004c',
        v_guest_account_id,
        v_room_type_id,
        CURRENT_DATE + INTERVAL '5 days',
        CURRENT_DATE + INTERVAL '40 days'  -- 35 คืน
    );
    
    RAISE NOTICE 'Test 4c - Success: %', v_result.success;
    RAISE NOTICE 'Test 4c - Message: %', v_result.message;
    ASSERT v_result.success = FALSE, 'TEST 4c FAILED: Should fail for > 30 nights';
    
    RAISE NOTICE '✓ TEST 4 PASSED (all sub-tests)';
END $$;

-- ============================================================================
-- TEST 5: Invalid Room Type (Should Fail)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== TEST 5: Invalid Room Type ===';

DO $$
DECLARE
    v_guest_account_id INT;
    v_result RECORD;
BEGIN
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com';
    
    -- ใช้ room_type_id ที่ไม่มีอยู่
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-005',
        v_guest_account_id,
        99999,  -- room_type_id ที่ไม่มีอยู่
        CURRENT_DATE + INTERVAL '5 days',
        CURRENT_DATE + INTERVAL '7 days'
    );
    
    RAISE NOTICE 'Success: %', v_result.success;
    RAISE NOTICE 'Message: %', v_result.message;
    
    ASSERT v_result.success = FALSE, 'TEST 5 FAILED: Should fail for invalid room type';
    ASSERT v_result.message LIKE '%ไม่พบประเภทห้อง%', 'TEST 5 FAILED: Error message should mention invalid room type';
    RAISE NOTICE '✓ TEST 5 PASSED';
END $$;

-- ============================================================================
-- TEST 6: Concurrent Holds (Race Condition Test)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== TEST 6: Concurrent Holds (Simulated) ===';

DO $$
DECLARE
    v_guest1_id INT;
    v_guest2_id INT;
    v_room_type_id INT;
    v_result1 RECORD;
    v_result2 RECORD;
    v_test_date DATE;
    v_available_before INT;
    v_available_after INT;
BEGIN
    -- สร้าง guest ที่ 2
    INSERT INTO guests (first_name, last_name, email, phone)
    VALUES ('Test2', 'User2', 'test.hold2@example.com', '0823456789')
    ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email;
    
    INSERT INTO guest_accounts (guest_id, hashed_password)
    SELECT guest_id, '$2a$10$test.hash.password2'
    FROM guests
    WHERE email = 'test.hold2@example.com'
    ON CONFLICT (guest_id) DO NOTHING;
    
    -- ดึง guest account IDs
    SELECT ga.guest_account_id INTO v_guest1_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com';
    
    SELECT ga.guest_account_id INTO v_guest2_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold2@example.com';
    
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    WHERE name = 'Standard Room'
    LIMIT 1;
    
    v_test_date := CURRENT_DATE + INTERVAL '25 days';
    
    -- ตั้งค่าให้มีห้องว่างเพียง 1 ห้อง
    UPDATE room_inventory
    SET allotment = booked_count + tentative_count + 1,
        updated_at = NOW()
    WHERE room_type_id = v_room_type_id
      AND date = v_test_date;
    
    SELECT (allotment - booked_count - tentative_count) INTO v_available_before
    FROM room_inventory
    WHERE room_type_id = v_room_type_id
      AND date = v_test_date;
    
    RAISE NOTICE 'Available rooms before: %', v_available_before;
    
    -- Guest 1 จอง
    SELECT * INTO v_result1
    FROM create_booking_hold(
        'test-session-006a',
        v_guest1_id,
        v_room_type_id,
        v_test_date,
        v_test_date + INTERVAL '1 day'
    );
    
    RAISE NOTICE 'Guest 1 - Success: %', v_result1.success;
    RAISE NOTICE 'Guest 1 - Message: %', v_result1.message;
    
    -- Guest 2 พยายามจอง (ควรล้มเหลวเพราะห้องเต็ม)
    SELECT * INTO v_result2
    FROM create_booking_hold(
        'test-session-006b',
        v_guest2_id,
        v_room_type_id,
        v_test_date,
        v_test_date + INTERVAL '1 day'
    );
    
    RAISE NOTICE 'Guest 2 - Success: %', v_result2.success;
    RAISE NOTICE 'Guest 2 - Message: %', v_result2.message;
    
    SELECT (allotment - booked_count - tentative_count) INTO v_available_after
    FROM room_inventory
    WHERE room_type_id = v_room_type_id
      AND date = v_test_date;
    
    RAISE NOTICE 'Available rooms after: %', v_available_after;
    
    -- ตรวจสอบว่า guest 1 สำเร็จ และ guest 2 ล้มเหลว
    ASSERT v_result1.success = TRUE, 'TEST 6 FAILED: Guest 1 should succeed';
    ASSERT v_result2.success = FALSE, 'TEST 6 FAILED: Guest 2 should fail (no availability)';
    ASSERT v_available_after = 0, 'TEST 6 FAILED: Should have 0 rooms available after';
    
    RAISE NOTICE '✓ TEST 6 PASSED';
END $$;

-- ============================================================================
-- TEST 7: Hold Expiry Time (15 minutes)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== TEST 7: Hold Expiry Time ===';

DO $$
DECLARE
    v_guest_account_id INT;
    v_room_type_id INT;
    v_result RECORD;
    v_expiry_diff INTERVAL;
BEGIN
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    JOIN guests g ON ga.guest_id = g.guest_id
    WHERE g.email = 'test.hold@example.com';
    
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    WHERE name = 'Deluxe Room'
    LIMIT 1;
    
    -- สร้าง hold
    SELECT * INTO v_result
    FROM create_booking_hold(
        'test-session-007',
        v_guest_account_id,
        v_room_type_id,
        CURRENT_DATE + INTERVAL '15 days',
        CURRENT_DATE + INTERVAL '17 days'
    );
    
    RAISE NOTICE 'Success: %', v_result.success;
    RAISE NOTICE 'Hold Expiry: %', v_result.hold_expiry;
    
    -- คำนวณความแตกต่างของเวลา
    v_expiry_diff := v_result.hold_expiry - NOW();
    
    RAISE NOTICE 'Time until expiry: %', v_expiry_diff;
    
    -- ตรวจสอบว่า expiry อยู่ระหว่าง 14-16 นาที (ให้เผื่อเวลาในการรัน test)
    ASSERT v_expiry_diff >= INTERVAL '14 minutes', 'TEST 7 FAILED: Expiry should be at least 14 minutes';
    ASSERT v_expiry_diff <= INTERVAL '16 minutes', 'TEST 7 FAILED: Expiry should be at most 16 minutes';
    
    RAISE NOTICE '✓ TEST 7 PASSED';
END $$;

-- ============================================================================
-- Summary
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '=== ALL TESTS COMPLETED ===';
RAISE NOTICE 'Summary:';
RAISE NOTICE '  ✓ TEST 1: Basic Hold Creation';
RAISE NOTICE '  ✓ TEST 2: Replace Existing Hold';
RAISE NOTICE '  ✓ TEST 3: No Availability';
RAISE NOTICE '  ✓ TEST 4: Invalid Date Range';
RAISE NOTICE '  ✓ TEST 5: Invalid Room Type';
RAISE NOTICE '  ✓ TEST 6: Concurrent Holds (Race Condition)';
RAISE NOTICE '  ✓ TEST 7: Hold Expiry Time';
RAISE NOTICE '';
RAISE NOTICE 'All tests passed successfully!';
RAISE NOTICE '============================';

-- ============================================================================
-- Display Current Holds
-- ============================================================================
SELECT 
    bh.hold_id,
    bh.session_id,
    g.email as guest_email,
    rt.name as room_type,
    bh.date,
    bh.hold_expiry,
    CASE 
        WHEN bh.hold_expiry > NOW() THEN 'Active'
        ELSE 'Expired'
    END as status,
    EXTRACT(EPOCH FROM (bh.hold_expiry - NOW())) / 60 as minutes_remaining
FROM booking_holds bh
JOIN guest_accounts ga ON bh.guest_account_id = ga.guest_account_id
JOIN guests g ON ga.guest_id = g.guest_id
JOIN room_types rt ON bh.room_type_id = rt.room_type_id
WHERE g.email IN ('test.hold@example.com', 'test.hold2@example.com')
ORDER BY bh.hold_expiry DESC, bh.date;
