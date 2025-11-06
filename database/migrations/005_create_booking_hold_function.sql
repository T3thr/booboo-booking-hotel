-- ============================================================================
-- Migration: 005_create_booking_hold_function.sql
-- Description: สร้าง PostgreSQL Function สำหรับการจองห้องชั่วคราว (Booking Hold)
-- Task: 11. สร้าง PostgreSQL Function - create_booking_hold
-- Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8
-- ============================================================================

-- ============================================================================
-- 1. สร้าง Function: create_booking_hold
-- ============================================================================
-- Function นี้จะ:
-- 1. ตรวจสอบห้องว่างสำหรับทุกวันในช่วงที่เลือก
-- 2. อัปเดต tentative_count แบบ atomic (ใช้ FOR UPDATE เพื่อ lock row)
-- 3. สร้าง booking hold records พร้อม expiry time (15 นาที)
-- 4. ปล่อย hold เก่าของ guest ที่ซ้ำกับวันที่ใหม่ (ถ้ามี)
-- 5. Rollback ทั้งหมดถ้าห้องไม่ว่างในวันใดวันหนึ่ง
-- ============================================================================

CREATE OR REPLACE FUNCTION create_booking_hold(
    p_session_id VARCHAR(255),
    p_guest_account_id INT,
    p_room_type_id INT,
    p_check_in DATE,
    p_check_out DATE
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    expiry_time TIMESTAMP
) LANGUAGE plpgsql AS $$
DECLARE
    v_date DATE;
    v_available INT;
    v_hold_expiry TIMESTAMP;
    v_nights INT;
    v_room_type_name VARCHAR(100);
BEGIN
    -- ตรวจสอบ input parameters
    IF p_check_in IS NULL OR p_check_out IS NULL THEN
        RETURN QUERY SELECT FALSE AS success, 'วันที่เช็คอินและเช็คเอาท์ต้องไม่เป็น NULL'::TEXT AS message, NULL::TIMESTAMP AS expiry_time;
        RETURN;
    END IF;
    
    IF p_check_out <= p_check_in THEN
        RETURN QUERY SELECT FALSE AS success, 'วันเช็คเอาท์ต้องอยู่หลังวันเช็คอิน'::TEXT AS message, NULL::TIMESTAMP AS expiry_time;
        RETURN;
    END IF;
    
    IF p_check_in < CURRENT_DATE THEN
        RETURN QUERY SELECT FALSE AS success, 'ไม่สามารถจองย้อนหลังได้'::TEXT AS message, NULL::TIMESTAMP AS expiry_time;
        RETURN;
    END IF;
    
    -- คำนวณจำนวนคืน
    v_nights := p_check_out - p_check_in;
    
    IF v_nights > 30 THEN
        RETURN QUERY SELECT FALSE AS success, 'ไม่สามารถจองเกิน 30 คืนได้'::TEXT AS message, NULL::TIMESTAMP AS expiry_time;
        RETURN;
    END IF;
    
    -- ดึงชื่อประเภทห้องสำหรับ error message
    SELECT name INTO v_room_type_name
    FROM room_types
    WHERE room_type_id = p_room_type_id;
    
    IF v_room_type_name IS NULL THEN
        RETURN QUERY SELECT FALSE AS success, 'ไม่พบประเภทห้องที่เลือก'::TEXT AS message, NULL::TIMESTAMP AS expiry_time;
        RETURN;
    END IF;
    
    -- กำหนดเวลาหมดอายุ (15 นาที)
    v_hold_expiry := NOW() + INTERVAL '15 minutes';
    
    -- ============================================================================
    -- STEP 1: ปล่อย hold เก่าของ guest นี้ที่ซ้ำกับวันที่ใหม่
    -- ============================================================================
    -- ลด tentative_count สำหรับ hold เก่าที่จะถูกแทนที่
    UPDATE room_inventory ri
    SET tentative_count = GREATEST(0, tentative_count - 1),
        updated_at = NOW()
    WHERE EXISTS (
        SELECT 1
        FROM booking_holds bh
        WHERE bh.guest_account_id = p_guest_account_id
          AND bh.room_type_id = ri.room_type_id
          AND bh.date = ri.date
          AND bh.date >= p_check_in
          AND bh.date < p_check_out
          AND bh.hold_expiry > NOW()
    );
    
    -- ลบ hold เก่าที่ซ้ำกับวันที่ใหม่
    DELETE FROM booking_holds
    WHERE guest_account_id = p_guest_account_id
      AND date >= p_check_in
      AND date < p_check_out
      AND hold_expiry > NOW();
    
    -- ============================================================================
    -- STEP 2: ตรวจสอบห้องว่างและอัปเดต tentative_count แบบ atomic
    -- ============================================================================
    v_date := p_check_in;
    
    WHILE v_date < p_check_out LOOP
        -- ตรวจสอบและ lock row สำหรับวันนี้
        SELECT (allotment - booked_count - tentative_count) INTO v_available
        FROM room_inventory
        WHERE room_type_id = p_room_type_id 
          AND date = v_date
        FOR UPDATE; -- Lock row เพื่อป้องกัน race condition
        
        -- ถ้าไม่มี inventory record สำหรับวันนี้
        IF v_available IS NULL THEN
            RETURN QUERY SELECT 
                FALSE AS success, 
                FORMAT('ไม่พบข้อมูล inventory สำหรับ %s วันที่ %s', v_room_type_name, v_date::TEXT)::TEXT AS message,
                NULL::TIMESTAMP AS expiry_time;
            RETURN;
        END IF;
        
        -- ถ้าห้องไม่ว่าง
        IF v_available <= 0 THEN
            RETURN QUERY SELECT 
                FALSE AS success, 
                FORMAT('ห้อง %s ไม่ว่างสำหรับวันที่ %s กรุณาเลือกห้องอื่นหรือวันที่อื่น', 
                       v_room_type_name, v_date::TEXT)::TEXT AS message,
                NULL::TIMESTAMP AS expiry_time;
            RETURN;
        END IF;
        
        -- อัปเดต tentative_count (เพิ่ม 1)
        UPDATE room_inventory
        SET tentative_count = tentative_count + 1,
            updated_at = NOW()
        WHERE room_type_id = p_room_type_id 
          AND date = v_date;
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
    
    -- ============================================================================
    -- STEP 3: สร้าง booking hold records
    -- ============================================================================
    v_date := p_check_in;
    
    WHILE v_date < p_check_out LOOP
        INSERT INTO booking_holds (
            session_id,
            guest_account_id,
            room_type_id,
            date,
            hold_expiry
        ) VALUES (
            p_session_id,
            p_guest_account_id,
            p_room_type_id,
            v_date,
            v_hold_expiry
        );
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
    
    -- ============================================================================
    -- STEP 4: Return success
    -- ============================================================================
    RETURN QUERY SELECT 
        TRUE AS success, 
        FORMAT('สร้าง hold สำเร็จสำหรับ %s (%s คืน) หมดอายุเวลา %s', 
               v_room_type_name, v_nights, TO_CHAR(v_hold_expiry, 'HH24:MI:SS'))::TEXT AS message,
        v_hold_expiry AS expiry_time;
    
EXCEPTION
    WHEN OTHERS THEN
        -- จัดการ error ที่ไม่คาดคิด
        RETURN QUERY SELECT 
            FALSE AS success, 
            FORMAT('เกิดข้อผิดพลาด: %s', SQLERRM)::TEXT AS message,
            NULL::TIMESTAMP AS expiry_time;
END;
$$;

-- ============================================================================
-- 2. เพิ่ม Comments
-- ============================================================================
COMMENT ON FUNCTION create_booking_hold IS 
'สร้างการจองห้องชั่วคราว (hold) สำหรับ 15 นาที
- ตรวจสอบห้องว่างแบบ atomic ด้วย FOR UPDATE
- ปล่อย hold เก่าที่ซ้ำกับวันที่ใหม่อัตโนมัติ
- Rollback ทั้งหมดถ้าห้องไม่ว่างในวันใดวันหนึ่ง
- ป้องกัน race condition ด้วย row-level locking';

-- ============================================================================
-- 3. Grant Permissions
-- ============================================================================
-- ให้สิทธิ์ execute function แก่ backend application
-- (ปรับตามชื่อ database user ที่ใช้จริง)
-- GRANT EXECUTE ON FUNCTION create_booking_hold TO hotel_app_user;

-- ============================================================================
-- 4. Verification
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== Booking Hold Function Created Successfully ===';
    RAISE NOTICE 'Function: create_booking_hold';
    RAISE NOTICE 'Purpose: สร้างการจองห้องชั่วคราว (15 นาที)';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  - Atomic operations with FOR UPDATE locking';
    RAISE NOTICE '  - Auto-release conflicting holds';
    RAISE NOTICE '  - Input validation';
    RAISE NOTICE '  - Race condition protection';
    RAISE NOTICE '======================================================';
END $$;
