-- ============================================================================
-- Migration: 009_create_check_in_function.sql
-- Description: สร้าง PostgreSQL Function สำหรับการเช็คอิน (Check-in)
-- Task: 22. สร้าง PostgreSQL Function - check_in
-- Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8
-- ============================================================================

-- ============================================================================
-- 1. สร้าง Function: check_in
-- ============================================================================
-- Function นี้จะ:
-- 1. ตรวจสอบสถานะห้อง (OccupancyStatus = 'Vacant' AND HousekeepingStatus IN ('Clean', 'Inspected'))
-- 2. ตรวจสอบสถานะการจอง (ต้องเป็น 'Confirmed')
-- 3. สร้าง room_assignment พร้อม Status = 'Active'
-- 4. อัปเดตสถานะการจองเป็น 'CheckedIn'
-- 5. อัปเดตสถานะห้องเป็น OccupancyStatus = 'Occupied'
-- 6. Rollback ทั้งหมดถ้ามีข้อผิดพลาด
-- ============================================================================

CREATE OR REPLACE FUNCTION check_in(
    p_booking_detail_id INT,
    p_room_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    room_assignment_id BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_occupancy VARCHAR(20);
    v_housekeeping VARCHAR(50);
    v_booking_id INT;
    v_booking_status VARCHAR(50);
    v_room_type_id INT;
    v_booking_room_type_id INT;
    v_room_number VARCHAR(10);
    v_assignment_id BIGINT;
    v_existing_assignment_count INT;
BEGIN
    -- ============================================================================
    -- STEP 1: ตรวจสอบว่า booking_detail_id มีอยู่จริง
    -- ============================================================================
    SELECT bd.booking_id, bd.room_type_id
    INTO v_booking_id, v_booking_room_type_id
    FROM booking_details bd
    WHERE bd.booking_detail_id = p_booking_detail_id;
    
    IF v_booking_id IS NULL THEN
        RETURN QUERY SELECT 
            FALSE, 
            'ไม่พบข้อมูลการจองนี้'::TEXT,
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 2: ตรวจสอบว่ามี assignment active อยู่แล้วหรือไม่
    -- ============================================================================
    SELECT COUNT(*) INTO v_existing_assignment_count
    FROM room_assignments
    WHERE booking_detail_id = p_booking_detail_id
      AND status = 'Active';
    
    IF v_existing_assignment_count > 0 THEN
        RETURN QUERY SELECT 
            FALSE, 
            'การจองนี้ได้ทำการเช็คอินแล้ว'::TEXT,
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 3: ตรวจสอบสถานะการจอง
    -- ============================================================================
    SELECT b.status INTO v_booking_status
    FROM bookings b
    WHERE b.booking_id = v_booking_id
    FOR UPDATE; -- Lock booking record
    
    IF v_booking_status != 'Confirmed' AND v_booking_status != 'CheckedIn' THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ไม่สามารถเช็คอินได้ สถานะการจองปัจจุบัน: %s (ต้องเป็น Confirmed)', v_booking_status),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 4: ตรวจสอบสถานะห้องและ room_type
    -- ============================================================================
    SELECT 
        r.occupancy_status, 
        r.housekeeping_status,
        r.room_type_id,
        r.room_number
    INTO v_occupancy, v_housekeeping, v_room_type_id, v_room_number
    FROM rooms r
    WHERE r.room_id = p_room_id
    FOR UPDATE; -- Lock room record
    
    IF v_occupancy IS NULL THEN
        RETURN QUERY SELECT 
            FALSE, 
            'ไม่พบห้องนี้ในระบบ'::TEXT,
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ตรวจสอบว่าห้องตรงกับ room_type ที่จองหรือไม่
    IF v_room_type_id != v_booking_room_type_id THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ห้องนี้ไม่ตรงกับประเภทห้องที่จอง (ห้อง: %s, จอง: %s)', 
                   v_room_type_id, v_booking_room_type_id),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ตรวจสอบว่าห้องว่างหรือไม่
    IF v_occupancy != 'Vacant' THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ห้อง %s ไม่ว่าง (สถานะ: %s)', v_room_number, v_occupancy),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ตรวจสอบว่าห้องสะอาดหรือไม่
    IF v_housekeeping NOT IN ('Clean', 'Inspected') THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ห้อง %s ยังไม่พร้อมสำหรับเช็คอิน (สถานะการทำความสะอาด: %s)', 
                   v_room_number, v_housekeeping),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 5: สร้าง room_assignment
    -- ============================================================================
    INSERT INTO room_assignments (
        booking_detail_id,
        room_id,
        check_in_datetime,
        status
    ) VALUES (
        p_booking_detail_id,
        p_room_id,
        NOW(),
        'Active'
    ) RETURNING room_assignment_id INTO v_assignment_id;
    
    -- ============================================================================
    -- STEP 6: อัปเดตสถานะการจองเป็น 'CheckedIn'
    -- ============================================================================
    UPDATE bookings
    SET status = 'CheckedIn',
        updated_at = NOW()
    WHERE booking_id = v_booking_id;
    
    -- ============================================================================
    -- STEP 7: อัปเดตสถานะห้องเป็น 'Occupied'
    -- ============================================================================
    UPDATE rooms
    SET occupancy_status = 'Occupied'
    WHERE room_id = p_room_id;
    
    -- ============================================================================
    -- STEP 8: Return success
    -- ============================================================================
    RETURN QUERY SELECT 
        TRUE, 
        FORMAT('เช็คอินสำเร็จ - ห้อง %s (Assignment ID: %s)', v_room_number, v_assignment_id),
        v_assignment_id;
    
EXCEPTION
    WHEN OTHERS THEN
        -- จัดการ error ที่ไม่คาดคิด
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('เกิดข้อผิดพลาดในการเช็คอิน: %s', SQLERRM),
            NULL::BIGINT;
END;
$$;

-- ============================================================================
-- 2. เพิ่ม Comments
-- ============================================================================
COMMENT ON FUNCTION check_in IS 
'ทำการเช็คอินแขกเข้าห้องพัก
- ตรวจสอบสถานะห้อง (Vacant + Clean/Inspected)
- ตรวจสอบสถานะการจอง (Confirmed)
- ตรวจสอบว่า room_type ตรงกับที่จองหรือไม่
- สร้าง room_assignment พร้อม status Active
- อัปเดตสถานะการจองเป็น CheckedIn
- อัปเดตสถานะห้องเป็น Occupied
- Rollback ทั้งหมดถ้ามีข้อผิดพลาด';

-- ============================================================================
-- 3. Grant Permissions
-- ============================================================================
-- ให้สิทธิ์ execute function แก่ backend application
-- (ปรับตามชื่อ database user ที่ใช้จริง)
-- GRANT EXECUTE ON FUNCTION check_in TO hotel_app_user;

-- ============================================================================
-- 4. Verification
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== Check-in Function Created Successfully ===';
    RAISE NOTICE 'Function: check_in';
    RAISE NOTICE 'Purpose: ทำการเช็คอินแขกเข้าห้องพัก';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  - Room status validation (Vacant + Clean/Inspected)';
    RAISE NOTICE '  - Booking status validation (Confirmed)';
    RAISE NOTICE '  - Room type matching validation';
    RAISE NOTICE '  - Duplicate check-in prevention';
    RAISE NOTICE '  - Atomic room assignment creation';
    RAISE NOTICE '  - Automatic status updates (Booking -> CheckedIn, Room -> Occupied)';
    RAISE NOTICE '========================================================';
END $$;
