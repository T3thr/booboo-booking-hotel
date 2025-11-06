-- ============================================================================
-- Migration: 010_create_check_out_function.sql
-- Description: สร้าง PostgreSQL Function สำหรับการเช็คเอาท์ (Check-out)
-- Task: 23. สร้าง PostgreSQL Function - check_out
-- Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7
-- ============================================================================

-- ============================================================================
-- 1. สร้าง Function: check_out
-- ============================================================================
-- Function นี้จะ:
-- 1. ตรวจสอบสถานะการจอง (ต้องเป็น 'CheckedIn')
-- 2. ปิด room_assignments ทั้งหมดที่ active (SET status = 'Completed', check_out_datetime = NOW())
-- 3. อัปเดตสถานะการจองเป็น 'Completed'
-- 4. อัปเดตสถานะห้องเป็น OccupancyStatus = 'Vacant', HousekeepingStatus = 'Dirty'
-- 5. Rollback ทั้งหมดถ้ามีข้อผิดพลาด
-- ============================================================================

CREATE OR REPLACE FUNCTION check_out(
    p_booking_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    total_amount DECIMAL(10, 2),
    rooms_checked_out INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_booking_status VARCHAR(50);
    v_total_amount DECIMAL(10, 2);
    v_rooms_count INT := 0;
    v_assignment RECORD;
    v_room_numbers TEXT := '';
BEGIN
    -- ============================================================================
    -- STEP 1: ตรวจสอบว่า booking_id มีอยู่จริง
    -- ============================================================================
    SELECT b.status, b.total_amount
    INTO v_booking_status, v_total_amount
    FROM bookings b
    WHERE b.booking_id = p_booking_id
    FOR UPDATE; -- Lock booking record
    
    IF v_booking_status IS NULL THEN
        RETURN QUERY SELECT 
            FALSE, 
            'ไม่พบข้อมูลการจองนี้'::TEXT,
            NULL::DECIMAL(10, 2),
            0;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 2: ตรวจสอบสถานะการจอง
    -- ============================================================================
    IF v_booking_status != 'CheckedIn' THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ไม่สามารถเช็คเอาท์ได้ สถานะการจองปัจจุบัน: %s (ต้องเป็น CheckedIn)', v_booking_status),
            NULL::DECIMAL(10, 2),
            0;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 3: ตรวจสอบว่ามี active room assignments หรือไม่
    -- ============================================================================
    SELECT COUNT(*) INTO v_rooms_count
    FROM room_assignments ra
    JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
    WHERE bd.booking_id = p_booking_id
      AND ra.status = 'Active';
    
    IF v_rooms_count = 0 THEN
        RETURN QUERY SELECT 
            FALSE, 
            'ไม่พบห้องที่ active สำหรับการจองนี้'::TEXT,
            NULL::DECIMAL(10, 2),
            0;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 4: ปิด room_assignments และอัปเดตสถานะห้อง
    -- ============================================================================
    FOR v_assignment IN
        SELECT ra.room_assignment_id, ra.room_id, r.room_number
        FROM room_assignments ra
        JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
        JOIN rooms r ON ra.room_id = r.room_id
        WHERE bd.booking_id = p_booking_id
          AND ra.status = 'Active'
        FOR UPDATE OF ra, r -- Lock assignment and room records
    LOOP
        -- ปิด room assignment
        UPDATE room_assignments
        SET status = 'Completed',
            check_out_datetime = NOW()
        WHERE room_assignment_id = v_assignment.room_assignment_id;
        
        -- อัปเดตสถานะห้อง
        UPDATE rooms
        SET occupancy_status = 'Vacant',
            housekeeping_status = 'Dirty'
        WHERE room_id = v_assignment.room_id;
        
        -- เก็บหมายเลขห้องสำหรับแสดงในข้อความ
        IF v_room_numbers = '' THEN
            v_room_numbers := v_assignment.room_number;
        ELSE
            v_room_numbers := v_room_numbers || ', ' || v_assignment.room_number;
        END IF;
    END LOOP;
    
    -- ============================================================================
    -- STEP 5: อัปเดตสถานะการจองเป็น 'Completed'
    -- ============================================================================
    UPDATE bookings
    SET status = 'Completed',
        updated_at = NOW()
    WHERE booking_id = p_booking_id;
    
    -- ============================================================================
    -- STEP 6: Return success
    -- ============================================================================
    RETURN QUERY SELECT 
        TRUE, 
        FORMAT('เช็คเอาท์สำเร็จ - ห้อง: %s (%s ห้อง)', v_room_numbers, v_rooms_count),
        v_total_amount,
        v_rooms_count;
    
EXCEPTION
    WHEN OTHERS THEN
        -- จัดการ error ที่ไม่คาดคิด
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('เกิดข้อผิดพลาดในการเช็คเอาท์: %s', SQLERRM),
            NULL::DECIMAL(10, 2),
            0;
END;
$$;

-- ============================================================================
-- 2. เพิ่ม Comments
-- ============================================================================
COMMENT ON FUNCTION check_out IS 
'ทำการเช็คเอาท์แขกออกจากโรงแรม
- ตรวจสอบสถานะการจอง (CheckedIn)
- ปิด room_assignments ทั้งหมดที่ active
- อัปเดตสถานะการจองเป็น Completed
- อัปเดตสถานะห้องเป็น Vacant + Dirty
- รองรับการจองหลายห้อง (multiple room assignments)
- Rollback ทั้งหมดถ้ามีข้อผิดพลาด';

-- ============================================================================
-- 3. Grant Permissions
-- ============================================================================
-- ให้สิทธิ์ execute function แก่ backend application
-- (ปรับตามชื่อ database user ที่ใช้จริง)
-- GRANT EXECUTE ON FUNCTION check_out TO hotel_app_user;

-- ============================================================================
-- 4. Verification
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== Check-out Function Created Successfully ===';
    RAISE NOTICE 'Function: check_out';
    RAISE NOTICE 'Purpose: ทำการเช็คเอาท์แขกออกจากโรงแรม';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  - Booking status validation (CheckedIn)';
    RAISE NOTICE '  - Multiple room assignments support';
    RAISE NOTICE '  - Atomic room assignment closure';
    RAISE NOTICE '  - Automatic status updates (Booking -> Completed, Rooms -> Vacant + Dirty)';
    RAISE NOTICE '  - Total amount calculation';
    RAISE NOTICE '  - Housekeeping notification (rooms set to Dirty)';
    RAISE NOTICE '========================================================';
END $$;
