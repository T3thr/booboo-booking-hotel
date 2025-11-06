-- ============================================================================
-- Fix: confirm_booking - Handle Existing Nightly Logs
-- ============================================================================
-- แก้ไข confirm_booking function ให้ skip การสร้าง nightly log ถ้ามีอยู่แล้ว

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
    v_existing_log_count INT;
BEGIN
    -- ============================================================================
    -- STEP 1: ตรวจสอบสถานะการจอง
    -- ============================================================================
    SELECT b.status, b.guest_id INTO v_status, v_guest_id
    FROM bookings b
    WHERE b.booking_id = p_booking_id
    FOR UPDATE;
    
    IF v_status IS NULL THEN
        RETURN QUERY SELECT 
            FALSE::BOOLEAN, 
            'ไม่พบการจองนี้'::TEXT,
            NULL::INT;
        RETURN;
    END IF;
    
    IF v_status != 'PendingPayment' THEN
        RETURN QUERY SELECT 
            FALSE::BOOLEAN, 
            FORMAT('ไม่สามารถยืนยันการจองได้ สถานะปัจจุบัน: %s (ต้องเป็น PendingPayment)', v_status)::TEXT,
            NULL::INT;
        RETURN;
    END IF;
    
    SELECT ga.guest_account_id INTO v_guest_account_id
    FROM guest_accounts ga
    WHERE ga.guest_id = v_guest_id;
    
    -- ============================================================================
    -- STEP 2: ตรวจสอบห้องว่างและอัปเดต inventory
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
        
        WHILE v_date < v_detail.check_out_date LOOP
            SELECT (allotment - booked_count - tentative_count) INTO v_available
            FROM room_inventory
            WHERE room_type_id = v_detail.room_type_id 
              AND date = v_date
            FOR UPDATE;
            
            IF v_available IS NULL THEN
                RETURN QUERY SELECT 
                    FALSE::BOOLEAN, 
                    FORMAT('ไม่พบข้อมูล inventory สำหรับ %s วันที่ %s', 
                           v_detail.room_type_name, v_date::TEXT)::TEXT,
                    NULL::INT;
                RETURN;
            END IF;
            
            UPDATE room_inventory
            SET booked_count = booked_count + 1,
                tentative_count = GREATEST(tentative_count - 1, 0),
                updated_at = NOW()
            WHERE room_type_id = v_detail.room_type_id 
              AND date = v_date;
            
            -- ============================================================================
            -- STEP 3: บันทึก nightly log (ถ้ายังไม่มี)
            -- ============================================================================
            -- ตรวจสอบว่ามี log อยู่แล้วหรือไม่
            SELECT COUNT(*) INTO v_existing_log_count
            FROM booking_nightly_log
            WHERE booking_detail_id = v_detail.booking_detail_id
              AND date = v_date;
            
            -- ถ้ายังไม่มี ให้สร้างใหม่
            IF v_existing_log_count = 0 THEN
                SELECT pc.rate_tier_id INTO v_rate_tier_id
                FROM pricing_calendar pc
                WHERE pc.date = v_date;
                
                IF v_rate_tier_id IS NULL THEN
                    SELECT rate_tier_id INTO v_rate_tier_id
                    FROM rate_tiers
                    ORDER BY rate_tier_id
                    LIMIT 1;
                END IF;
                
                SELECT rp.price INTO v_price
                FROM rate_pricing rp
                WHERE rp.rate_plan_id = v_detail.rate_plan_id
                  AND rp.room_type_id = v_detail.room_type_id
                  AND rp.rate_tier_id = v_rate_tier_id;
                
                IF v_price IS NULL THEN
                    v_price := 0;
                END IF;
                
                INSERT INTO booking_nightly_log (
                    booking_detail_id,
                    date,
                    quoted_price
                ) VALUES (
                    v_detail.booking_detail_id,
                    v_date,
                    v_price
                );
            END IF;
            
            v_total_nights := v_total_nights + 1;
            v_date := v_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
    
    -- ============================================================================
    -- STEP 4: บันทึก policy snapshot
    -- ============================================================================
    SELECT cp.name, cp.description 
    INTO v_policy_name, v_policy_description
    FROM booking_details bd
    JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
    JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
    WHERE bd.booking_id = p_booking_id
    LIMIT 1;
    
    IF v_policy_name IS NULL THEN
        v_policy_name := 'No Refund';
        v_policy_description := 'ไม่สามารถยกเลิกหรือคืนเงินได้';
    END IF;
    
    -- ============================================================================
    -- STEP 5: อัปเดตสถานะเป็น Confirmed
    -- ============================================================================
    UPDATE bookings
    SET status = 'Confirmed',
        policy_name = v_policy_name,
        policy_description = v_policy_description,
        updated_at = NOW()
    WHERE booking_id = p_booking_id;
    
    -- ============================================================================
    -- STEP 6: ลบ booking holds
    -- ============================================================================
    IF v_guest_account_id IS NOT NULL THEN
        DELETE FROM booking_holds
        WHERE guest_account_id = v_guest_account_id;
    END IF;
    
    -- ============================================================================
    -- STEP 7: Return success
    -- ============================================================================
    RETURN QUERY SELECT 
        TRUE::BOOLEAN, 
        FORMAT('ยืนยันการจองสำเร็จ (Booking ID: %s, %s คืน)', 
               p_booking_id, v_total_nights)::TEXT,
        p_booking_id::INT;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 
            FALSE::BOOLEAN, 
            FORMAT('เกิดข้อผิดพลาดในการยืนยันการจอง: %s', SQLERRM)::TEXT,
            NULL::INT;
END;
$$;

COMMENT ON FUNCTION confirm_booking IS 
'ยืนยันการจองและอัปเดตสถานะเป็น Confirmed (Fixed: Skip existing nightly logs)';

-- Verification
DO $$
BEGIN
    RAISE NOTICE '=== Confirm Booking Function Updated ===';
    RAISE NOTICE 'Fix: Skip creating nightly logs if they already exist';
    RAISE NOTICE '========================================';
END $$;
