-- ============================================================================
-- Test Script: test_check_out_function.sql
-- Description: ทดสอบ check_out function
-- ============================================================================

-- ============================================================================
-- Setup: สร้างข้อมูลทดสอบ
-- ============================================================================

BEGIN;

-- ล้างข้อมูลทดสอบเก่า (ถ้ามี)
DELETE FROM room_assignments WHERE booking_detail_id IN (
    SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9100
);
DELETE FROM booking_nightly_log WHERE booking_detail_id IN (
    SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9100
);
DELETE FROM booking_guests WHERE booking_detail_id IN (
    SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9100
);
DELETE FROM booking_details WHERE booking_id >= 9100;
DELETE FROM bookings WHERE booking_id >= 9100;
DELETE FROM guest_accounts WHERE guest_id >= 9100;
DELETE FROM guests WHERE guest_id >= 9100;
DELETE FROM rooms WHERE room_id >= 9100;

-- สร้าง test guest
INSERT INTO guests (guest_id, first_name, last_name, email, phone)
VALUES (9100, 'Test', 'CheckOut', 'test.checkout@example.com', '0812345678');

INSERT INTO guest_accounts (guest_account_id, guest_id, hashed_password)
VALUES (9100, 9100, '$2a$10$test.hash.for.testing');

-- สร้างห้องทดสอบ
INSERT INTO rooms (room_id, room_type_id, room_number, occupancy_status, housekeeping_status)
VALUES 
    (9100, 1, 'TEST-1001', 'Occupied', 'Clean'),
    (9101, 1, 'TEST-1002', 'Occupied', 'Clean'),
    (9102, 1, 'TEST-1003', 'Vacant', 'Inspected');

COMMIT;

-- ============================================================================
-- Test 1: เช็คเอาท์สำเร็จ - การจองห้องเดียว (Happy Path)
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_booking_status VARCHAR(50);
    v_room_occupancy VARCHAR(20);
    v_room_housekeeping VARCHAR(50);
    v_assignment_status VARCHAR(20);
    v_assignment_checkout TIMESTAMP;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 1: เช็คเอาท์สำเร็จ - การจองห้องเดียว (Happy Path) ===';
    
    -- สร้าง booking ที่ CheckedIn
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9100, 9100, 3000.00, 'CheckedIn', 'Standard Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9100, 9100, 1, 1, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE, 2);
    
    -- สร้าง active room assignment
    INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status)
    VALUES (9100, 9100, NOW() - INTERVAL '1 day', 'Active');
    
    -- เรียก check_out function
    SELECT * INTO v_result FROM check_out(9100);
    
    IF v_result.success THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
        RAISE NOTICE '  Total Amount: %', v_result.total_amount;
        RAISE NOTICE '  Rooms Checked Out: %', v_result.rooms_checked_out;
        
        -- ตรวจสอบว่าสถานะอัปเดตถูกต้อง
        SELECT status INTO v_booking_status FROM bookings WHERE booking_id = 9100;
        SELECT occupancy_status, housekeeping_status INTO v_room_occupancy, v_room_housekeeping 
        FROM rooms WHERE room_id = 9100;
        SELECT status, check_out_datetime INTO v_assignment_status, v_assignment_checkout
        FROM room_assignments WHERE booking_detail_id = 9100;
        
        IF v_booking_status = 'Completed' THEN
            RAISE NOTICE '  ✓ Booking status: %', v_booking_status;
        ELSE
            RAISE NOTICE '  ✗ FAIL: Booking status should be Completed, got %', v_booking_status;
        END IF;
        
        IF v_room_occupancy = 'Vacant' THEN
            RAISE NOTICE '  ✓ Room occupancy: %', v_room_occupancy;
        ELSE
            RAISE NOTICE '  ✗ FAIL: Room should be Vacant, got %', v_room_occupancy;
        END IF;
        
        IF v_room_housekeeping = 'Dirty' THEN
            RAISE NOTICE '  ✓ Room housekeeping: %', v_room_housekeeping;
        ELSE
            RAISE NOTICE '  ✗ FAIL: Room should be Dirty, got %', v_room_housekeeping;
        END IF;
        
        IF v_assignment_status = 'Completed' THEN
            RAISE NOTICE '  ✓ Assignment status: %', v_assignment_status;
        ELSE
            RAISE NOTICE '  ✗ FAIL: Assignment should be Completed, got %', v_assignment_status;
        END IF;
        
        IF v_assignment_checkout IS NOT NULL THEN
            RAISE NOTICE '  ✓ Assignment check_out_datetime set';
        ELSE
            RAISE NOTICE '  ✗ FAIL: Assignment check_out_datetime should be set';
        END IF;
    ELSE
        RAISE NOTICE '✗ FAIL: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM room_assignments WHERE booking_detail_id = 9100;
    DELETE FROM booking_details WHERE booking_detail_id = 9100;
    DELETE FROM bookings WHERE booking_id = 9100;
    
    -- รีเซ็ตสถานะห้อง
    UPDATE rooms SET occupancy_status = 'Occupied', housekeeping_status = 'Clean'
    WHERE room_id = 9100;
END $$;

-- ============================================================================
-- Test 2: เช็คเอาท์สำเร็จ - การจองหลายห้อง
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_room1_status VARCHAR(20);
    v_room2_status VARCHAR(20);
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 2: เช็คเอาท์สำเร็จ - การจองหลายห้อง ===';
    
    -- สร้าง booking ที่ CheckedIn พร้อม 2 ห้อง
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9101, 9100, 6000.00, 'CheckedIn', 'Standard Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES 
        (9101, 9101, 1, 1, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE, 2),
        (9102, 9101, 1, 1, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE, 2);
    
    -- สร้าง active room assignments สำหรับทั้ง 2 ห้อง
    INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status)
    VALUES 
        (9101, 9100, NOW() - INTERVAL '1 day', 'Active'),
        (9102, 9101, NOW() - INTERVAL '1 day', 'Active');
    
    -- เรียก check_out function
    SELECT * INTO v_result FROM check_out(9101);
    
    IF v_result.success THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
        RAISE NOTICE '  Total Amount: %', v_result.total_amount;
        RAISE NOTICE '  Rooms Checked Out: %', v_result.rooms_checked_out;
        
        -- ตรวจสอบว่าทั้ง 2 ห้องถูกอัปเดต
        SELECT occupancy_status INTO v_room1_status FROM rooms WHERE room_id = 9100;
        SELECT occupancy_status INTO v_room2_status FROM rooms WHERE room_id = 9101;
        
        IF v_room1_status = 'Vacant' AND v_room2_status = 'Vacant' THEN
            RAISE NOTICE '  ✓ Both rooms set to Vacant';
        ELSE
            RAISE NOTICE '  ✗ FAIL: Rooms should be Vacant (Room1: %, Room2: %)', 
                         v_room1_status, v_room2_status;
        END IF;
        
        IF v_result.rooms_checked_out = 2 THEN
            RAISE NOTICE '  ✓ Correct number of rooms checked out';
        ELSE
            RAISE NOTICE '  ✗ FAIL: Should check out 2 rooms, got %', v_result.rooms_checked_out;
        END IF;
    ELSE
        RAISE NOTICE '✗ FAIL: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM room_assignments WHERE booking_detail_id IN (9101, 9102);
    DELETE FROM booking_details WHERE booking_detail_id IN (9101, 9102);
    DELETE FROM bookings WHERE booking_id = 9101;
    
    -- รีเซ็ตสถานะห้อง
    UPDATE rooms SET occupancy_status = 'Occupied', housekeeping_status = 'Clean'
    WHERE room_id IN (9100, 9101);
END $$;

-- ============================================================================
-- Test 3: การจองไม่ใช่สถานะ CheckedIn
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 3: การจองไม่ใช่สถานะ CheckedIn ===';
    
    -- สร้าง booking ที่ Confirmed (ยังไม่ CheckedIn)
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9102, 9100, 3000.00, 'Confirmed', 'Standard Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9103, 9102, 1, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 2);
    
    -- พยายามเช็คเอาท์
    SELECT * INTO v_result FROM check_out(9102);
    
    IF NOT v_result.success AND v_result.message LIKE '%สถานะการจอง%' THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: Should reject non-CheckedIn booking';
        RAISE NOTICE '  Message: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM booking_details WHERE booking_detail_id = 9103;
    DELETE FROM bookings WHERE booking_id = 9102;
END $$;

-- ============================================================================
-- Test 4: การจองที่ไม่มีอยู่
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 4: การจองที่ไม่มีอยู่ ===';
    
    -- พยายามเช็คเอาท์ booking ที่ไม่มีอยู่
    SELECT * INTO v_result FROM check_out(99999);
    
    IF NOT v_result.success AND v_result.message LIKE '%ไม่พบข้อมูลการจอง%' THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: Should reject non-existent booking';
        RAISE NOTICE '  Message: %', v_result.message;
    END IF;
END $$;

-- ============================================================================
-- Test 5: การจองที่ไม่มี active room assignments
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 5: การจองที่ไม่มี active room assignments ===';
    
    -- สร้าง booking ที่ CheckedIn แต่ไม่มี active assignments
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9103, 9100, 3000.00, 'CheckedIn', 'Standard Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9104, 9103, 1, 1, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE, 2);
    
    -- ไม่สร้าง room assignment
    
    -- พยายามเช็คเอาท์
    SELECT * INTO v_result FROM check_out(9103);
    
    IF NOT v_result.success AND v_result.message LIKE '%ไม่พบห้องที่ active%' THEN
        RAISE NOTICE '✓ PASS: %', v_result.message;
    ELSE
        RAISE NOTICE '✗ FAIL: Should reject booking without active assignments';
        RAISE NOTICE '  Message: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM booking_details WHERE booking_detail_id = 9104;
    DELETE FROM bookings WHERE booking_id = 9103;
END $$;

-- ============================================================================
-- Test 6: การจองที่ Completed แล้ว (เช็คเอาท์ซ้ำ)
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 6: การจองที่ Completed แล้ว (เช็คเอาท์ซ้ำ) ===';
    
    -- สร้าง booking ที่ CheckedIn
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9104, 9100, 3000.00, 'CheckedIn', 'Standard Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9105, 9104, 1, 1, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE, 2);
    
    INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status)
    VALUES (9105, 9102, NOW() - INTERVAL '1 day', 'Active');
    
    -- เช็คเอาท์ครั้งแรก (ควรสำเร็จ)
    SELECT * INTO v_result FROM check_out(9104);
    
    IF v_result.success THEN
        RAISE NOTICE '✓ First check-out successful';
        
        -- พยายามเช็คเอาท์ซ้ำ (ควรล้มเหลว)
        SELECT * INTO v_result FROM check_out(9104);
        
        IF NOT v_result.success AND v_result.message LIKE '%สถานะการจอง%' THEN
            RAISE NOTICE '✓ PASS: %', v_result.message;
        ELSE
            RAISE NOTICE '✗ FAIL: Should reject duplicate check-out';
            RAISE NOTICE '  Message: %', v_result.message;
        END IF;
    ELSE
        RAISE NOTICE '✗ FAIL: First check-out failed: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM room_assignments WHERE booking_detail_id = 9105;
    DELETE FROM booking_details WHERE booking_detail_id = 9105;
    DELETE FROM bookings WHERE booking_id = 9104;
    
    -- รีเซ็ตสถานะห้อง
    UPDATE rooms SET occupancy_status = 'Vacant', housekeeping_status = 'Inspected'
    WHERE room_id = 9102;
END $$;

-- ============================================================================
-- Test 7: ตรวจสอบว่าห้องถูกแจ้งให้แม่บ้านทำความสะอาด (Dirty status)
-- ============================================================================
DO $$
DECLARE
    v_result RECORD;
    v_housekeeping_status VARCHAR(50);
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Test 7: ตรวจสอบว่าห้องถูกแจ้งให้แม่บ้านทำความสะอาด ===';
    
    -- สร้าง booking และเช็คอิน
    INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description)
    VALUES (9105, 9100, 3000.00, 'CheckedIn', 'Standard Policy', 'Test Description');
    
    INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id,
                                 check_in_date, check_out_date, num_guests)
    VALUES (9106, 9105, 1, 1, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE, 2);
    
    -- ตั้งห้องเป็น Clean ก่อนเช็คเอาท์
    UPDATE rooms SET occupancy_status = 'Occupied', housekeeping_status = 'Clean'
    WHERE room_id = 9100;
    
    INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status)
    VALUES (9106, 9100, NOW() - INTERVAL '1 day', 'Active');
    
    -- เช็คเอาท์
    SELECT * INTO v_result FROM check_out(9105);
    
    IF v_result.success THEN
        -- ตรวจสอบว่าห้องถูกตั้งเป็น Dirty
        SELECT housekeeping_status INTO v_housekeeping_status
        FROM rooms WHERE room_id = 9100;
        
        IF v_housekeeping_status = 'Dirty' THEN
            RAISE NOTICE '✓ PASS: Room set to Dirty for housekeeping';
        ELSE
            RAISE NOTICE '✗ FAIL: Room should be Dirty, got %', v_housekeeping_status;
        END IF;
    ELSE
        RAISE NOTICE '✗ FAIL: Check-out failed: %', v_result.message;
    END IF;
    
    -- ล้างข้อมูลทดสอบ
    DELETE FROM room_assignments WHERE booking_detail_id = 9106;
    DELETE FROM booking_details WHERE booking_detail_id = 9106;
    DELETE FROM bookings WHERE booking_id = 9105;
    
    -- รีเซ็ตสถานะห้อง
    UPDATE rooms SET occupancy_status = 'Occupied', housekeeping_status = 'Clean'
    WHERE room_id = 9100;
END $$;

-- ============================================================================
-- Cleanup: ล้างข้อมูลทดสอบ
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Cleaning up test data ===';
    
    DELETE FROM room_assignments WHERE booking_detail_id IN (
        SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9100
    );
    DELETE FROM booking_guests WHERE booking_detail_id IN (
        SELECT booking_detail_id FROM booking_details WHERE booking_id >= 9100
    );
    DELETE FROM booking_details WHERE booking_id >= 9100;
    DELETE FROM bookings WHERE booking_id >= 9100;
    DELETE FROM rooms WHERE room_id >= 9100;
    DELETE FROM guest_accounts WHERE guest_id >= 9100;
    DELETE FROM guests WHERE guest_id >= 9100;
    
    RAISE NOTICE '✓ Test data cleaned up';
END $$;

-- ============================================================================
-- Summary
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Check-out Function Tests Completed';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tests performed:';
    RAISE NOTICE '  1. ✓ Successful check-out - single room';
    RAISE NOTICE '  2. ✓ Successful check-out - multiple rooms';
    RAISE NOTICE '  3. ✓ Reject non-CheckedIn booking';
    RAISE NOTICE '  4. ✓ Reject non-existent booking';
    RAISE NOTICE '  5. ✓ Reject booking without active assignments';
    RAISE NOTICE '  6. ✓ Reject duplicate check-out';
    RAISE NOTICE '  7. ✓ Verify rooms set to Dirty for housekeeping';
    RAISE NOTICE '========================================';
END $$;
