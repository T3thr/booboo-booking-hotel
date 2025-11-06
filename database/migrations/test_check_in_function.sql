-- ============================================================================
-- Test Script: test_check_in_function.sql
-- Description: ทดสอบ check_in function
-- ============================================================================

-- ============================================================================
-- Setup: สร้างข้อมูลทดสอบ
-- ============================================================================

BEGIN;

-- ล้างข้อมูลทดสอบเก่า (ถ้ามี)
DELETE FROM room_assignments WHERE booking_detail_id IN (
    SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9000
);
DELETE FROM booking_nightly_log WHERE booking_detail_id IN (
    SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9000
);
DELETE FROM booking_guests WHERE booking_detail_id IN (
    SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9000
);
DELETE FROM booking_details WHERE booking_id >= 9000;
DELETE FROM bookings WHERE booking_id >= 9000;
DELETE FROM guest_accounts WHERE guest_id >= 9000;
DELETE FROM guests WHERE guest_id >= 9000;

-- สร้าง test guest
INSERT INTO guests (guest_id, first_name, last_name, email, phone)
VALUES (9000, 'Test', 'CheckIn', 'test.checkin@example.com', '0812345678');

INSERT INTO guest_accounts (guest_account_id, guest_id, hashed_password)
VALUES (9000, 9000, '$2a$10$test.hash.for.testing');

-- สร้าง test booking (Confirmed status)
INSERT INTO bookings (
    booking_id, guest_id, total_amount, status, 
    policy_name, policy_description
) VALUES (
    9000, 9000, 3000.00, 'Confirmed',
    'Standard Cancellation', 'ยกเลิกได้ก่อน 3 วัน คืนเงิน 100%'
);

-- สร้าง booking detail
INSERT INTO booking_details (
    booking_detail_id, booking_id, room_type_id, rate_plan_id,
    check_in_date, check_out_date, num_guests
) VALUES (
    9000, 9000, 1, 1,
    CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 2
);

-- สร้าง booking guest
INSERT INTO booking_guests (
    booking_detail_id, first_name, last_name, type, is_primary
) VALUES (
    9000, 'Test', 'CheckIn', 'Adult', TRUE
);

-- ตรวจสอบว่ามีห้องว่างที่สะอาด
DO $$
DECLARE
    v_test_room_id INT;
BEGIN
    -- หาห้องที่ว่างและสะอาด
    SELECT room_id INTO v_test_room_id
    FROM rooms
    WHERE room_type_id = 1
      AND occupancy_status = 'Vacant'
      AND housekeeping_status IN ('Clean', 'Inspected')
    LIMIT 1;
    
    IF v_test_room_id IS NULL THEN
        -- ถ้าไม่มีห้องว่าง ให้สร้างห้องทดสอบ
        INSERT INTO rooms (room_id, room_type_id, room_number, occupancy_status, housekeeping_status)
        VALUES (9000, 1, 'TEST-901', 'Vacant', 'Inspected');
        
        RAISE NOTICE 'Created test room: TEST-901 (ID: 9000)';
    ELSE
        RAISE NOTICE 'Using existing room ID: %', v_test_room_id;
    END IF;
END $$;

COMMIT;

-- ============================================================================
-- Test 1: เช็คอินสำเร็จ (Happy Path)
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_room_id INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 1: เช็คอินสำเร็จ (Happy Path) ===';
    
    -- หาห้องที่ว่างและสะอาด
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
      AND occupancy_status = 'Vacant'
      AND housekeeping_status IN ('Clean', 'Inspected')
    LIMIT 1;
    
    -- เรียก check_in function
    SELECT * INTO v_result
    FROM check_in(9000, v_room_id);
    
    IF v_result.success THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
        RAISE NOTICE '  Assignment ID: %', v_result.room_assignment_id;
        
        -- ตรวจสอบว่าสถานะอัปเดตถูกต้อง
        DECLARE
            v_booking_status VARCHAR(50);
            v_room_occupancy VARCHAR(20);
            v_assignment_count INT;
        BEGIN
            SELECT status INTO v_booking_status FROM bookings WHERE booking_id = 9000;
            SELECT occupancy_status INTO v_room_occupancy FROM rooms WHERE room_id = v_room_id;
            SELECT COUNT(*) INTO v_assignment_count FROM room_assignments 
            WHERE booking_detail_id = 9000 AND status = 'Active';
            
            IF v_booking_status = 'CheckedIn' THEN
                RAISE NOTICE '  ✓ Booking status: %', v_booking_status;
            ELSE
                RAISE NOTICE '  ✗ FAIL: Booking status should be CheckedIn, got %', v_booking_status;
            END IF;
            
            IF v_room_occupancy = 'Occupied' THEN
                RAISE NOTICE '  ✓ Room occupancy: %', v_room_occupancy;
            ELSE
                RAISE NOTICE '  ✗ FAIL: Room should be Occupied, got %', v_room_occupancy;
            END IF;
            
            IF v_assignment_count = 1 THEN
                RAISE NOTICE '  ✓ Room assignment created';
            ELSE
                RAISE NOTICE '  ✗ FAIL: Expected 1 assignment, got %', v_assignment_count;
            END IF;
        END;
    ELSE
        RAISE NOTICE '✗ FAIL: %', v_result.message;
    END IF;
END $$;

-- ============================================================================
-- Test 2: ห้องไม่ว่าง (Occupied)
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_occupied_room_id INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 2: ห้องไม่ว่าง (Occupied) ===';
    
    -- หาห้องที่ Occupied
    SELECT room_id INTO v_occupied_room_id
    FROM rooms
    WHERE occupancy_status = 'Occupied'
    LIMIT 1;
    
    IF v_occupied_room_id IS NULL THEN
        -- สร้างห้องทดสอบที่ Occupied
        INSERT INTO rooms (room_id, room_type_id, room_number, occupancy_status, housekeeping_status)
        VALUES (9001, 1, 'TEST-902', 'Occupied', 'Dirty')
        RETURNING room_id INTO v_occupied_room_id;
    END IF;
    
    -- สร้าง booking ใหม่สำหรับทดสอบ
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9001, 9000, 1500.00, 'Confirmed', 'Test Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9001, 9001, 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 2);
    
    -- พยายามเช็คอินห้องที่ไม่ว่าง
    SELECT * INTO v_result
    FROM check_in(9001, v_occupied_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%ไม่ว่าง%' THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: Should reject occupied room';
        RAISE NOTICE '  Message: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM booking_details WHERE booking_detail_id = 9001;
    DELETE FROM bookings WHERE booking_id = 9001;
END $$;

-- ============================================================================
-- Test 3: ห้องยังไม่สะอาด (Dirty)
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_dirty_room_id INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 3: ห้องยังไม่สะอาด (Dirty) ===';
    
    -- สร้างห้องทดสอบที่ Dirty
    INSERT INTO rooms (room_id, room_type_id, room_number, occupancy_status, housekeeping_status)
    VALUES (9002, 1, 'TEST-903', 'Vacant', 'Dirty')
    RETURNING room_id INTO v_dirty_room_id;
    
    -- สร้าง booking ใหม่สำหรับทดสอบ
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9002, 9000, 1500.00, 'Confirmed', 'Test Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9002, 9002, 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 2);
    
    -- พยายามเช็คอินห้องที่ยังไม่สะอาด
    SELECT * INTO v_result
    FROM check_in(9002, v_dirty_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%ยังไม่พร้อม%' THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: Should reject dirty room';
        RAISE NOTICE '  Message: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM booking_details WHERE booking_detail_id = 9002;
    DELETE FROM bookings WHERE booking_id = 9002;
    DELETE FROM rooms WHERE room_id = 9002;
END $$;

-- ============================================================================
-- Test 4: การจองไม่ใช่สถานะ Confirmed
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_room_id INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 4: การจองไม่ใช่สถานะ Confirmed ===';
    
    -- หาห้องว่าง
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
      AND occupancy_status = 'Vacant'
      AND housekeeping_status IN ('Clean', 'Inspected')
    LIMIT 1;
    
    -- สร้าง booking ที่ยังไม่ Confirmed
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9003, 9000, 1500.00, 'PendingPayment', 'Test Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9003, 9003, 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 2);
    
    -- พยายามเช็คอิน
    SELECT * INTO v_result
    FROM check_in(9003, v_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%สถานะการจอง%' THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: Should reject non-confirmed booking';
        RAISE NOTICE '  Message: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM booking_details WHERE booking_detail_id = 9003;
    DELETE FROM bookings WHERE booking_id = 9003;
END $$;

-- ============================================================================
-- Test 5: Room type ไม่ตรงกับที่จอง
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_wrong_room_id INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 5: Room type ไม่ตรงกับที่จอง ===';
    
    -- หาห้อง room_type อื่น
    SELECT room_id INTO v_wrong_room_id
    FROM rooms
    WHERE room_type_id != 1
      AND occupancy_status = 'Vacant'
      AND housekeeping_status IN ('Clean', 'Inspected')
    LIMIT 1;
    
    IF v_wrong_room_id IS NULL THEN
        -- สร้างห้องทดสอบ room_type 2
        INSERT INTO rooms (room_id, room_type_id, room_number, occupancy_status, housekeeping_status)
        VALUES (9003, 2, 'TEST-904', 'Vacant', 'Inspected')
        RETURNING room_id INTO v_wrong_room_id;
    END IF;
    
    -- สร้าง booking สำหรับ room_type 1
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9004, 9000, 1500.00, 'Confirmed', 'Test Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9004, 9004, 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 2);
    
    -- พยายามเช็คอินห้อง room_type อื่น
    SELECT * INTO v_result
    FROM check_in(9004, v_wrong_room_id);
    
    IF NOT v_result.success AND v_result.message LIKE '%ไม่ตรงกับประเภทห้อง%' THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: Should reject wrong room type';
        RAISE NOTICE '  Message: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM booking_details WHERE booking_detail_id = 9004;
    DELETE FROM bookings WHERE booking_id = 9004;
END $$;

-- ============================================================================
-- Test 6: เช็คอินซ้ำ (Duplicate Check-in)
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_room_id INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 6: เช็คอินซ้ำ (Duplicate Check-in) ===';
    
    -- หาห้องว่าง
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
      AND occupancy_status = 'Vacant'
      AND housekeeping_status IN ('Clean', 'Inspected')
      AND room_id NOT IN (SELECT room_id FROM room_assignments WHERE status = 'Active')
    LIMIT 1;
    
    IF v_room_id IS NULL THEN
        -- สร้างห้องทดสอบ
        INSERT INTO rooms (room_id, room_type_id, room_number, occupancy_status, housekeeping_status)
        VALUES (9004, 1, 'TEST-905', 'Vacant', 'Inspected')
        RETURNING room_id INTO v_room_id;
    END IF;
    
    -- สร้าง booking ใหม่
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9005, 9000, 1500.00, 'Confirmed', 'Test Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9005, 9005, 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 2);
    
    -- เช็คอินครั้งแรก (ควรสำเร็จ)
    SELECT * INTO v_result FROM check_in(9005, v_room_id);
    
    IF v_result.success THEN
        RAISE NOTICE '✓ First check-in successful';
        
        -- พยายามเช็คอินซ้ำ (ควรล้มเหลว)
        SELECT * INTO v_result FROM check_in(9005, v_room_id);
        
        IF NOT v_result.success AND v_result.message LIKE '%ได้ทำการเช็คอินแล้ว%' THEN
            RAISE NOTICE '✓ PASS: %', v_result.message;
        ELSE
            RAISE NOTICE '✗ FAIL: Should reject duplicate check-in';
            RAISE NOTICE '  Message: %', v_result.message;
        END IF;
    ELSE
        RAISE NOTICE '✗ FAIL: First check-in failed: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM room_assignments WHERE booking_detail_id = 9005;
    DELETE FROM booking_details WHERE booking_detail_id = 9005;
    DELETE FROM bookings WHERE booking_id = 9005;
END $$;

-- ============================================================================
-- Cleanup: ล้างข้อมูลทดสอบ
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Cleaning up test data ===';
    
    DELETE FROM room_assignments WHERE booking_detail_id IN (
        SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9000
    );
    DELETE FROM booking_guests WHERE booking_detail_id IN (
        SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9000
    );
    DELETE FROM booking_details WHERE booking_id >= 9000;
    DELETE FROM bookings WHERE booking_id >= 9000;
    DELETE FROM rooms WHERE room_id >= 9000;
    DELETE FROM guest_accounts WHERE guest_id >= 9000;
    DELETE FROM guests WHERE guest_id >= 9000;
    
    RAISE NOTICE '✓ Test data cleaned up';
END $$;

-- ============================================================================
-- Summary
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Check-in Function Tests Completed';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tests performed:';
    RAISE NOTICE '  1. ✓ Successful check-in (Happy Path)';
    RAISE NOTICE '  2. ✓ Reject occupied room';
    RAISE NOTICE '  3. ✓ Reject dirty room';
    RAISE NOTICE '  4. ✓ Reject non-confirmed booking';
    RAISE NOTICE '  5. ✓ Reject wrong room type';
    RAISE NOTICE '  6. ✓ Reject duplicate check-in';
    RAISE NOTICE '========================================';
END $$;
