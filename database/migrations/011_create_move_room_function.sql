-- ============================================================================
-- Migration: 011_create_move_room_function.sql
-- Description: สร้าง PostgreSQL Function สำหรับการย้ายห้อง (Move Room)
-- Task: 24. สร้าง PostgreSQL Function - move_room
-- Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7
-- ============================================================================

-- ============================================================================
-- 1. สร้าง Function: move_room
-- ============================================================================
-- Function นี้จะ:
-- 1. ตรวจสอบว่า room_assignment ที่ระบุมีอยู่และมีสถานะ 'Active'
-- 2. ตรวจสอบสถานะห้องใหม่ (OccupancyStatus = 'Vacant' AND HousekeepingStatus IN ('Clean', 'Inspected'))
-- 3. ปิด room_assignment เก่า (SET Status = 'Moved', CheckOutDateTime = NOW())
-- 4. สร้าง room_assignment ใหม่พร้อม Status = 'Active'
-- 5. อัปเดตห้องเก่า (OccupancyStatus = 'Vacant', HousekeepingStatus = 'Dirty')
-- 6. อัปเดตห้องใหม่ (OccupancyStatus = 'Occupied')
-- 7. Rollback ทั้งหมดถ้ามีข้อผิดพลาด
-- ============================================================================

CREATE OR REPLACE FUNCTION move_room(
    p_room_assignment_id BIGINT,
    p_new_room_id INT,
    p_reason TEXT DEFAULT NULL
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    new_assignment_id BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_old_room_id INT;
    v_booking_detail_id INT;
    v_old_room_number VARCHAR(10);
    v_new_room_number VARCHAR(10);
    v_new_occupancy VARCHAR(20);
    v_new_housekeeping VARCHAR(50);
    v_old_room_type_id INT;
    v_new_room_type_id INT;
    v_assignment_status VARCHAR(20);
    v_new_assignment_id BIGINT;
BEGIN
    -- ============================================================================
    -- STEP 1: ตรวจสอบว่า room_assignment มีอยู่และมีสถานะ 'Active'
    -- ============================================================================
    SELECT 
        ra.room_id,
        ra.booking_detail_id,
        ra.status,
        r.room_number,
        r.room_type_id
    INTO 
        v_old_room_id,
        v_booking_detail_id,
        v_assignment_status,
        v_old_room_number,
        v_old_room_type_id
    FROM room_assignments ra
    JOIN rooms r ON ra.room_id = r.room_id
    WHERE ra.room_assignment_id = p_room_assignment_id
    FOR UPDATE OF ra; -- Lock assignment record
    
    IF v_old_room_id IS NULL THEN
        RETURN QUERY SELECT 
            FALSE, 
            'ไม่พบข้อมูล room assignment นี้'::TEXT,
            NULL::BIGINT;
        RETURN;
    END IF;
    
    IF v_assignment_status != 'Active' THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ไม่สามารถย้ายห้องได้ สถานะ assignment ปัจจุบัน: %s (ต้องเป็น Active)', v_assignment_status),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 2: ตรวจสอบว่าไม่ได้ย้ายไปห้องเดิม
    -- ============================================================================
    IF v_old_room_id = p_new_room_id THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ไม่สามารถย้ายไปห้องเดิม (ห้อง %s)', v_old_room_number),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ============================================================================
    -- STEP 3: ตรวจสอบสถานะห้องใหม่
    -- ============================================================================
    SELECT 
        r.occupancy_status,
        r.housekeeping_status,
        r.room_number,
        r.room_type_id
    INTO 
        v_new_occupancy,
        v_new_housekeeping,
        v_new_room_number,
        v_new_room_type_id
    FROM rooms r
    WHERE r.room_id = p_new_room_id
    FOR UPDATE; -- Lock new room record
    
    IF v_new_occupancy IS NULL THEN
        RETURN QUERY SELECT 
            FALSE, 
            'ไม่พบห้องใหม่ในระบบ'::TEXT,
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ตรวจสอบว่าห้องใหม่ว่างหรือไม่
    IF v_new_occupancy != 'Vacant' THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ห้อง %s ไม่ว่าง (สถานะ: %s)', v_new_room_number, v_new_occupancy),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ตรวจสอบว่าห้องใหม่สะอาดหรือไม่
    IF v_new_housekeeping NOT IN ('Clean', 'Inspected') THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ห้อง %s ยังไม่พร้อมสำหรับการย้าย (สถานะการทำความสะอาด: %s)', 
                   v_new_room_number, v_new_housekeeping),
            NULL::BIGINT;
        RETURN;
    END IF;
    
    -- ตรวจสอบว่าห้องใหม่เป็น room_type เดียวกันหรือสูงกว่า
    -- (สำหรับการตรวจสอบนี้ เราจะอนุญาตให้ย้ายได้ทุก room_type 
    -- แต่ในระบบจริงอาจต้องเพิ่มตรรกะเปรียบเทียบ room_type hierarchy)
    IF v_new_room_type_id != v_old_room_type_id THEN
        -- แจ้งเตือนว่ากำลังย้ายไป room_type ที่ต่างกัน
        RAISE NOTICE 'กำลังย้ายจาก room_type % ไป room_type %', v_old_room_type_id, v_new_room_type_id;
    END IF;
    
    -- ============================================================================
    -- STEP 4: ปิด room_assignment เก่า
    -- ============================================================================
    UPDATE room_assignments
    SET 
        check_out_datetime = NOW(),
        status = 'Moved'
    WHERE room_assignment_id = p_room_assignment_id;
    
    -- ============================================================================
    -- STEP 5: สร้าง room_assignment ใหม่
    -- ============================================================================
    INSERT INTO room_assignments (
        booking_detail_id,
        room_id,
        check_in_datetime,
        status
    ) VALUES (
        v_booking_detail_id,
        p_new_room_id,
        NOW(),
        'Active'
    ) RETURNING room_assignment_id INTO v_new_assignment_id;
    
    -- ============================================================================
    -- STEP 6: อัปเดตห้องเก่า (Vacant + Dirty)
    -- ============================================================================
    UPDATE rooms
    SET 
        occupancy_status = 'Vacant',
        housekeeping_status = 'Dirty'
    WHERE room_id = v_old_room_id;
    
    -- ============================================================================
    -- STEP 7: อัปเดตห้องใหม่ (Occupied)
    -- ============================================================================
    UPDATE rooms
    SET occupancy_status = 'Occupied'
    WHERE room_id = p_new_room_id;
    
    -- ============================================================================
    -- STEP 8: บันทึก log (ถ้ามีเหตุผล)
    -- ============================================================================
    IF p_reason IS NOT NULL THEN
        RAISE NOTICE 'เหตุผลในการย้ายห้อง: %', p_reason;
        -- ในระบบจริง อาจต้องบันทึกลงตาราง move_room_log
    END IF;
    
    -- ============================================================================
    -- STEP 9: Return success
    -- ============================================================================
    RETURN QUERY SELECT 
        TRUE, 
        FORMAT('ย้ายห้องสำเร็จ - จากห้อง %s ไปห้อง %s (Assignment ID: %s)', 
               v_old_room_number, v_new_room_number, v_new_assignment_id),
        v_new_assignment_id;
    
EXCEPTION
    WHEN OTHERS THEN
        -- จัดการ error ที่ไม่คาดคิด
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('เกิดข้อผิดพลาดในการย้ายห้อง: %s', SQLERRM),
            NULL::BIGINT;
END;
$$;

-- ============================================================================
-- 2. เพิ่ม Comments
-- ============================================================================
COMMENT ON FUNCTION move_room IS 
'ย้ายแขกจากห้องหนึ่งไปอีกห้องหนึ่งระหว่างการเข้าพัก
- ตรวจสอบว่า assignment มีสถานะ Active
- ตรวจสอบสถานะห้องใหม่ (Vacant + Clean/Inspected)
- ปิด assignment เก่า (status = Moved)
- สร้าง assignment ใหม่ (status = Active)
- อัปเดตห้องเก่า (Vacant + Dirty)
- อัปเดตห้องใหม่ (Occupied)
- รักษาบันทึกการตรวจสอบที่สมบูรณ์
- Rollback ทั้งหมดถ้ามีข้อผิดพลาด';

-- ============================================================================
-- 3. Grant Permissions
-- ============================================================================
-- ให้สิทธิ์ execute function แก่ backend application
-- (ปรับตามชื่อ database user ที่ใช้จริง)
-- GRANT EXECUTE ON FUNCTION move_room TO hotel_app_user;

-- ============================================================================
-- 4. Verification
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== Move Room Function Created Successfully ===';
    RAISE NOTICE 'Function: move_room';
    RAISE NOTICE 'Purpose: ย้ายแขกจากห้องหนึ่งไปอีกห้องหนึ่งระหว่างการเข้าพัก';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  - Assignment status validation (Active)';
    RAISE NOTICE '  - New room status validation (Vacant + Clean/Inspected)';
    RAISE NOTICE '  - Duplicate room prevention';
    RAISE NOTICE '  - Atomic assignment closure and creation';
    RAISE NOTICE '  - Automatic status updates (Old room -> Vacant+Dirty, New room -> Occupied)';
    RAISE NOTICE '  - Complete audit trail maintenance';
    RAISE NOTICE '  - Optional reason logging';
    RAISE NOTICE '========================================================';
END $$;
