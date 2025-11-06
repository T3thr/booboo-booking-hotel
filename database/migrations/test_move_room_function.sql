-- ============================================================================
-- Test Script: test_move_room_function.sql
-- Description: ทดสอบ move_room function
-- Task: 24. สร้าง PostgreSQL Function - move_room
-- ============================================================================

-- ============================================================================
-- Setup: สร้างข้อมูลทดสอบ
-- ============================================================================
DO $
DECLARE
    v_guest_id INT;
    v_guest_account_id INT;
    v_room_type_id INT;
    v_booking_id INT;
    v_booking_detail_id INT;
    v_old_room_id INT;
    v_new_room_id INT;
    v_assignment_id BIGINT;
    v_result RECORD;
BEGIN
    RAISE NOTICE '=== Starting Move Room Function Tests ===';
    RAISE NOTICE '';
    
    -- ============================================================================
    -- TEST SETUP: สร้างข้อมูลทดสอบ
    -- ============================================================================
    RAISE NOTICE '--- Setting up test data ---';
    
    -- สร้าง guest
    INSERT INTO guests (first_name, last_name, email, phone)
    VALUES ('Test', 'MoveRoom', 'test.moveroom@example.com', '0812345678')
    RETURNING guest_id INTO v_guest_id;
    
    INSERT INTO guest_accounts (guest_id, hashed_password)
    VALUES (v_guest_id, 'hashed_password_test')
    RETURNING guest_account_id INTO v_guest_account_id;
    
    -- หา room_type ที่มีอยู่
    SELECT room_type_id INTO v_room_type_id
    FROM room_types
    LIMIT 1;
    
    -- หาห้องสองห้องที่ว่างและสะอาด
    SELECT room_id INTO v_old_room_id
    FROM rooms
    WHERE room_type_id = v_room_type_id
      AND occupancy_status = 'Vacant'
      AND housekeeping_status IN ('Clean', 'Inspected')
    LIMIT 1;
    
    SELECT room_id INTO v_new_room_id
    FROM rooms
    WHERE room_type_id = v_room_type_id
      AND occupancy_status = 'Vacant'
      AND housekeeping_status IN ('Clean', 'Inspected')
      AND room_id != v_old_room_id
    LIMIT 1;
    
    IF v_old_room_id IS NULL OR v_new_room_id IS NULL THEN
        RAISE EXCEPTION 'ไม่พบห้องว่างเพียงพอสำหรับการทดสอบ';
    END IF;
    
    -- สร้างการจอง
    INSERT INTO bookings (
        guest_id, total_amount, status,
        policy_name, policy_description
    ) VALUES (
        v_guest_id, 1000.00, 'Confirmed',
        'Test Policy', 'Test policy description'
    ) RETURNING booking_id INTO v_booking_id;
    
    INSERT INTO booking_details (
        booking_id, room_type_id, rate_plan_id,
        check_in_date, check_out_date, num_guests
    ) VALUES (
        v_booking_id, v_room_type_id, 1,
        CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 2
    ) RETURNING booking_detail_id INTO v_booking_detail_id;
    
    -- เช็คอินเข้าห้องเก่า
    SELECT * INTO v_result
    FROM check_in(v_booking_detail_id, v_old_room_id);
    
    IF NOT v_result.success THEN
        RAISE EXCEPTION 'ไม่สามารถเช็คอินสำหรับการทดสอบได้: %', v_result.message;
    END IF;
    
    v_assignment_id := v_result.room_assignment_id;
    
    RAISE NOTICE 'Test data created:';
    RAISE NOTICE '  Guest ID: %', v_guest_id;
    RAISE NOTICE '  Booking ID: %', v_booking_id;
    RAISE NOTICE '  Old Room ID: % (checked in)', v_old_room_id;
    RAISE NOTICE '  New Room ID: % (available)', v_new_room_id;
    RAISE NOTICE '  Assignment ID: %', v_assignment_id;
    RAISE NOTICE '';
    
    -- ============================================================================
    -- TEST 1: ย้ายห้องสำเร็จ (Happy Path)
    -- ============================================================================
    RAISE NOTICE '--- TEST 1: ย้ายห้องสำเร็จ ---';
    
    SELECT * INTO v_result
    FROM move_room(v_assignment_id, v_new_room_id, 'ทดสอบการย้ายห้อง');
    
    IF v_result.success THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
        
        -- ตรวจสอบว่า assignment เก่าถูกปิด
        IF EXISTS (
            SELECT 1 FROM room_assignments
            WHERE room_assignment_id = v_assignment_id
              AND status = 'Moved'
              AND check_out_datetime IS NOT NULL
        ) THEN
            RAISE NOTICE '✓ PASS: Assignment เก่าถูกปิดแล้ว (status = Moved)';
        ELSE
            RAISE NOTICE '✗ FAIL: Assignment เก่าไม่ถูกปิด';
        END IF;
        
        -- ตรวจสอบว่า assignment ใหม่ถูกสร้าง
        IF EXISTS (
            SELECT 1 FROM room_assignments
            WHERE room_assignment_id = v_result.new_assignment_id
              AND status = 'Active'
              AND room_id = v_new_room_id
        ) THEN
            RAISE NOTICE '✓ PASS: Assignment ใหม่ถูกสร้างแล้ว (status = Active)';
        ELSE
            RAISE NOTICE '✗ FAIL: Assignment ใหม่ไม่ถูกสร้าง';
        END IF;
        
        -- ตรวจสอบสถานะห้องเก่า
        IF EXISTS (
            SELECT 1 FROM rooms
            WHERE room_id = v_old_room_id
              AND occupancy_status = 'Vacant'
              AND housekeeping_status = 'Dirty'
        ) THEN
            RAISE NOTICE '✓ PASS: ห้องเก่าถูกอัปเดตเป็น Vacant + Dirty';
        ELSE
            RAISE NOTICE '✗ FAIL: ห้องเก่าไม่ถูกอัปเดตอย่างถูกต้อง';
        END IF;
        
        -- ตรวจสอบสถานะห้องใหม่
        IF EXISTS (
            SELECT 1 FROM rooms
            WHERE room_id = v_new_room_id
              AND occupancy_status = 'Occupied'
        ) THEN
            RAISE NOTICE '✓ PASS: ห้องใหม่ถูกอัปเดตเป็น Occupied';
        ELSE
            RAISE NOTICE '✗ FAIL: ห้องใหม่ไม่ถูกอัปเดตอย่างถูกต้อง';
        END IF;
        
        -- อัปเดต assignment_id สำหรับการทดสอบต่อไป
        v_assignment_id := v_result.new_assignment_id;
    ELSE
        RAISE NOTICE '✗ FAIL: %', v_result.message;
    END IF;
    RAISE NOTICE '';
    
    -- ============================================================================
    -- TEST 2: ไม่สามารถย้ายไปห้องเดิม
    -- ============================================================================
    RAISE NOTICE '--- TEST 2: ไม่สามารถย้ายไปห้องเดิม ---';
    
    SELECT * INTO v_result
    FROM move_room(v_assignment_id, v_new_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%ห้องเดิม%' THEN
        RAISE NOTICE '✓ PASS: ป้องกันการย้ายไปห้องเดิมได้: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: ไม่ได้ป้องกันการย้ายไปห้องเดิม';
    END IF;
    RAISE NOTICE '';
    
    -- ============================================================================
    -- TEST 3: ไม่สามารถย้ายไปห้องที่ไม่ว่าง
    -- ============================================================================
    RAISE NOTICE '--- TEST 3: ไม่สามารถย้ายไปห้องที่ไม่ว่าง ---';
    
    -- ทำให้ห้องเก่าเป็น Occupied (จำลองว่ามีคนอยู่)
    UPDATE rooms SET occupancy_status = 'Occupied' WHERE room_id = v_old_room_id;
    
    SELECT * INTO v_result
    FROM move_room(v_assignment_id, v_old_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%ไม่ว่าง%' THEN
        RAISE NOTICE '✓ PASS: ป้องกันการย้ายไปห้องที่ไม่ว่างได้: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: ไม่ได้ป้องกันการย้ายไปห้องที่ไม่ว่าง';
    END IF;
    
    -- คืนสถานะห้องเก่า
    UPDATE rooms SET occupancy_status = 'Vacant' WHERE room_id = v_old_room_id;
    RAISE NOTICE '';
    
    -- ============================================================================
    -- TEST 4: ไม่สามารถย้ายไปห้องที่ไม่สะอาด
    -- ============================================================================
    RAISE NOTICE '--- TEST 4: ไม่สามารถย้ายไปห้องที่ไม่สะอาด ---';
    
    -- ทำให้ห้องเก่าเป็น Dirty
    UPDATE rooms SET housekeeping_status = 'Dirty' WHERE room_id = v_old_room_id;
    
    SELECT * INTO v_result
    FROM move_room(v_assignment_id, v_old_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%ไม่พร้อม%' THEN
        RAISE NOTICE '✓ PASS: ป้องกันการย้ายไปห้องที่ไม่สะอาดได้: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: ไม่ได้ป้องกันการย้ายไปห้องที่ไม่สะอาด';
    END IF;
    RAISE NOTICE '';
    
    -- ============================================================================
    -- TEST 5: ไม่สามารถย้ายห้อง assignment ที่ไม่ใช่ Active
    -- ============================================================================
    RAISE NOTICE '--- TEST 5: ไม่สามารถย้าย assignment ที่ไม่ใช่ Active ---';
    
    -- ปิด assignment ปัจจุบัน
    UPDATE room_assignments 
    SET status = 'Completed', check_out_datetime = NOW()
    WHERE room_assignment_id = v_assignment_id;
    
    -- คืนสถานะห้องเก่าให้สะอาด
    UPDATE rooms 
    SET housekeeping_status = 'Clean', occupancy_status = 'Vacant'
    WHERE room_id = v_old_room_id;
    
    SELECT * INTO v_result
    FROM move_room(v_assignment_id, v_old_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%Active%' THEN
        RAISE NOTICE '✓ PASS: ป้องกันการย้าย assignment ที่ไม่ใช่ Active ได้: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: ไม่ได้ป้องกันการย้าย assignment ที่ไม่ใช่ Active';
    END IF;
    RAISE NOTICE '';
    
    -- ============================================================================
    -- TEST 6: ไม่สามารถย้ายห้อง assignment ที่ไม่มีอยู่
    -- ============================================================================
    RAISE NOTICE '--- TEST 6: ไม่สามารถย้าย assignment ที่ไม่มีอยู่ ---';
    
    SELECT * INTO v_result
    FROM move_room(999999, v_old_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%ไม่พบ%' THEN
        RAISE NOTICE '✓ PASS: ป้องกันการย้าย assignment ที่ไม่มีอยู่ได้: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: ไม่ได้ป้องกันการย้าย assignment ที่ไม่มีอยู่';
    END IF;
    RAISE NOTICE '';
    
    -- ============================================================================
    -- Cleanup: ลบข้อมูลทดสอบ
    -- ============================================================================
    RAISE NOTICE '--- Cleaning up test data ---';
    
    DELETE FROM room_assignments WHERE booking_detail_id = v_booking_detail_id;
    DELETE FROM booking_details WHERE booking_id = v_booking_id;
    DELETE FROM bookings WHERE booking_id = v_booking_id;
    DELETE FROM guest_accounts WHERE guest_account_id = v_guest_account_id;
    DELETE FROM guests WHERE guest_id = v_guest_id;
    
    -- คืนสถานะห้อง
    UPDATE rooms 
    SET occupancy_status = 'Vacant', housekeeping_status = 'Clean'
    WHERE room_id IN (v_old_room_id, v_new_room_id);
    
    RAISE NOTICE 'Test data cleaned up';
    RAISE NOTICE '';
    RAISE NOTICE '=== Move Room Function Tests Completed ===';
END $;
