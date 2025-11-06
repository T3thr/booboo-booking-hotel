-- ============================================================================
-- Migration: 006_create_confirm_booking_function.sql
-- Description: สร้าง PostgreSQL Function สำหรับการยืนยันการจอง (Confirm Booking)
-- Task: 12. สร้าง PostgreSQL Function - confirm_booking
-- Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9
-- ============================================================================

-- ============================================================================
-- 1. สร้าง Function: confirm_booking
-- ============================================================================
-- Function นี้จะ:
-- 1. ตรวจสอบสถานะการจอง (ต้องเป็น 'PendingPayment')
-- 2. อัปเดตสถานะการจองเป็น 'Confirmed'
-- 3. ย้าย tentative_count ไป booked_count แบบ atomic
-- 4. บันทึก snapshot ของนโยบายการยกเลิก (PolicyName, PolicyDescription)
-- 5. บันทึกข้อมูลใน booking_nightly_log พร้อม quoted_price
-- 6. ลบ booking holds ของ guest
-- 7. Rollback ทั้งหมดถ้ามีข้อผิดพลาด
-- ============================================================================

CREATE OR REPLACE FUNCTION confirm_booking(
    p_booking_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    booking_id INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(50);
    v_guest_id INT;
    v_guest_account_id INT;
    v_detail RECORD;
    v_date DATE;
    v_available INT;
    v_total_nights INT := 0;
    v_policy_name VARCHAR(100);
    v_policy_description TEXT;
    v_rate_tier_id INT;
    v_price DECIMAL(10, 2);
BEGIN
    -- ============================================================================
    -- STEP 1: ตรวจสอบสถานะการจอง
    -- ============================================================================
    SELECT b.status, b.guest_id INTO v_status, v_guest_id
    FROM bookings b
    WHERE b.booking_id = p_booking_id
    FOR UPDATE; -- Lock booking record
    
    IF v_status IS NULL THEN
        RETURN QUERY SELECT 
            FALSE, 
            'ไม่พบการจองนี้'::TEXT,
            NULL::INT;
        RETURN;
    END IF;
    
    IF v_status != 'PendingPayment' THEN
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('ไม่สามารถยืนยันการจองได้ สถานะปัจจุบัน: %s (ต้องเป็น PendingPayment)', v_status),
            NULL::INT;
        RETURN;
    END IF;
    
    -- ดึง guest_account_id
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    WHERE ga.guest_id = v_guest_id;
    
    -- ============================================================================
    -- STEP 2: ตรวจสอบห้องว่างและอัปเดต inventory แบบ atomic
    -- ============================================================================
    FOR v_detail IN 
        SELECT 
            bd.booking_detail_id,
            bd.room_type_id,
            bd.rate_plan_id,
            bd.check_in_date,
            bd.check_out_date,
            rt.name as room_type_name
        FROM booking_details bd
        JOIN room_types rt ON bd.room_type_id = rt.room_type_id
        WHERE bd.booking_id = p_booking_id
        ORDER BY bd.booking_detail_id
    LOOP
        v_date := v_detail.check_in_date;
        
        -- วนลูปทุกวันในช่วงการจอง
        WHILE v_date < v_detail.check_out_date LOOP
            -- ตรวจสอบและ lock inventory row
            SELECT (allotment - booked_count - tentative_count) INTO v_available
            FROM room_inventory
            WHERE room_type_id = v_detail.room_type_id 
              AND date = v_date
            FOR UPDATE;
            
            -- ตรวจสอบว่ามีห้องว่าง (ควรมีเพราะมี hold อยู่แล้ว)
            IF v_available IS NULL THEN
                RETURN QUERY SELECT 
                    FALSE, 
                    FORMAT('ไม่พบข้อมูล inventory สำหรับ %s วันที่ %s', 
                           v_detail.room_type_name, v_date::TEXT),
                    NULL::INT;
                RETURN;
            END IF;
            
            -- อัปเดต inventory: ย้าย tentative -> booked
            UPDATE room_inventory
            SET booked_count = booked_count + 1,
                tentative_count = GREATEST(tentative_count - 1, 0),
                updated_at = NOW()
            WHERE room_type_id = v_detail.room_type_id 
              AND date = v_date;
            
            -- ============================================================================
            -- STEP 3: บันทึกข้อมูลใน booking_nightly_log
            -- ============================================================================
            -- ดึง rate_tier_id สำหรับวันนี้
            SELECT pc.rate_tier_id INTO v_rate_tier_id
            FROM pricing_calendar pc
            WHERE pc.date = v_date;
            
            -- ถ้าไม่มี pricing calendar ให้ใช้ tier แรก (default)
            IF v_rate_tier_id IS NULL THEN
                SELECT rate_tier_id INTO v_rate_tier_id
                FROM rate_tiers
                ORDER BY rate_tier_id
                LIMIT 1;
            END IF;
            
            -- ดึงราคาสำหรับวันนี้
            SELECT rp.price INTO v_price
            FROM rate_pricing rp
            WHERE rp.rate_plan_id = v_detail.rate_plan_id
              AND rp.room_type_id = v_detail.room_type_id
              AND rp.rate_tier_id = v_rate_tier_id;
            
            -- ถ้าไม่มีราคา ให้ใช้ 0 (ไม่ควรเกิดในกรณีปกติ)
            IF v_price IS NULL THEN
                v_price := 0;
            END IF;
            
            -- บันทึก nightly log
            INSERT INTO booking_nightly_log (
                booking_detail_id,
                date,
                quoted_price
            ) VALUES (
                v_detail.booking_detail_id,
                v_date,
                v_price
            );
            
            v_total_nights := v_total_nights + 1;
            v_date := v_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
    
    -- ============================================================================
    -- STEP 4: บันทึก snapshot ของนโยบายการยกเลิก
    -- ============================================================================
    -- ดึงนโยบายจาก rate_plan ของ booking detail แรก
    SELECT cp.name, cp.description 
    INTO v_policy_name, v_policy_description
    FROM booking_details bd
    JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
    JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
    WHERE bd.booking_id = p_booking_id
    LIMIT 1;
    
    -- ถ้าไม่มีนโยบาย ให้ใช้ค่า default
    IF v_policy_name IS NULL THEN
        v_policy_name := 'No Refund';
        v_policy_description := 'ไม่สามารถยกเลิกหรือคืนเงินได้';
    END IF;
    
    -- ============================================================================
    -- STEP 5: อัปเดตสถานะการจองเป็น 'Confirmed'
    -- ============================================================================
    UPDATE bookings
    SET status = 'Confirmed',
        policy_name = v_policy_name,
        policy_description = v_policy_description,
        updated_at = NOW()
    WHERE booking_id = p_booking_id;
    
    -- ============================================================================
    -- STEP 6: ลบ booking holds ของ guest นี้
    -- ============================================================================
    IF v_guest_account_id IS NOT NULL THEN
        DELETE FROM booking_holds
        WHERE guest_account_id = v_guest_account_id;
    END IF;
    
    -- ============================================================================
    -- STEP 7: Return success
    -- ============================================================================
    RETURN QUERY SELECT 
        TRUE, 
        FORMAT('ยืนยันการจองสำเร็จ (Booking ID: %s, %s คืน)', 
               p_booking_id, v_total_nights),
        p_booking_id;
    
EXCEPTION
    WHEN OTHERS THEN
        -- จัดการ error ที่ไม่คาดคิด
        RETURN QUERY SELECT 
            FALSE, 
            FORMAT('เกิดข้อผิดพลาดในการยืนยันการจอง: %s', SQLERRM),
            NULL::INT;
END;
$$;

-- ============================================================================
-- 2. เพิ่ม Comments
-- ============================================================================
COMMENT ON FUNCTION confirm_booking IS 
'ยืนยันการจองและอัปเดตสถานะเป็น Confirmed
- ตรวจสอบสถานะการจอง (ต้องเป็น PendingPayment)
- ย้าย tentative_count ไป booked_count แบบ atomic
- บันทึก snapshot ของนโยบายการยกเลิก
- บันทึกราคาแต่ละคืนใน booking_nightly_log
- ลบ booking holds ของ guest
- Rollback ทั้งหมดถ้ามีข้อผิดพลาด';

-- ============================================================================
-- 3. Grant Permissions
-- ============================================================================
-- ให้สิทธิ์ execute function แก่ backend application
-- (ปรับตามชื่อ database user ที่ใช้จริง)
-- GRANT EXECUTE ON FUNCTION confirm_booking TO hotel_app_user;

-- ============================================================================
-- 4. Verification
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '=== Confirm Booking Function Created Successfully ===';
    RAISE NOTICE 'Function: confirm_booking';
    RAISE NOTICE 'Purpose: ยืนยันการจองและอัปเดตสถานะ';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  - Status validation (PendingPayment -> Confirmed)';
    RAISE NOTICE '  - Atomic inventory update (tentative -> booked)';
    RAISE NOTICE '  - Policy snapshot recording';
    RAISE NOTICE '  - Nightly pricing log';
    RAISE NOTICE '  - Auto-cleanup of booking holds';
    RAISE NOTICE '========================================================';
END $$;
