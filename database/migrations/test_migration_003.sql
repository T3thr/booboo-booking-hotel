-- ============================================================================
-- Test Script: test_migration_003.sql
-- Description: ทดสอบการทำงานของ Pricing & Inventory Schema
-- ============================================================================

\echo '=== Starting Pricing & Inventory Tests ==='
\echo ''

-- ============================================================================
-- Test 1: ทดสอบการค้นหาราคาสำหรับการจอง
-- ============================================================================
\echo 'Test 1: Price calculation for booking'

-- ทดสอบคำนวณราคาสำหรับ Standard Room, Standard Rate, 3 คืน
SELECT 
    rt.name as room_type,
    rp.name as rate_plan,
    pc.date,
    tier.name as rate_tier,
    rpr.price as price_per_night
FROM room_types rt
CROSS JOIN rate_plans rp
JOIN rate_pricing rpr ON rt.room_type_id = rpr.room_type_id 
    AND rp.rate_plan_id = rpr.rate_plan_id
JOIN pricing_calendar pc ON rpr.rate_tier_id = pc.rate_tier_id
JOIN rate_tiers tier ON pc.rate_tier_id = tier.rate_tier_id
WHERE rt.name = 'Standard Room'
  AND rp.name = 'Standard Rate'
  AND pc.date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '2 days'
ORDER BY pc.date;

-- คำนวณราคารวม
SELECT 
    rt.name as room_type,
    rp.name as rate_plan,
    COUNT(*) as nights,
    SUM(rpr.price) as total_price
FROM room_types rt
CROSS JOIN rate_plans rp
JOIN rate_pricing rpr ON rt.room_type_id = rpr.room_type_id 
    AND rp.rate_plan_id = rpr.rate_plan_id
JOIN pricing_calendar pc ON rpr.rate_tier_id = pc.rate_tier_id
WHERE rt.name = 'Standard Room'
  AND rp.name = 'Standard Rate'
  AND pc.date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '2 days'
GROUP BY rt.name, rp.name;

\echo ''

-- ============================================================================
-- Test 2: ทดสอบการตรวจสอบห้องว่าง
-- ============================================================================
\echo 'Test 2: Room availability check'

-- ตรวจสอบห้องว่างสำหรับ 3 วันข้างหน้า
SELECT 
    rt.name as room_type,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available,
    CASE 
        WHEN (ri.allotment - ri.booked_count - ri.tentative_count) > 0 
        THEN '✓ Available'
        ELSE '✗ Full'
    END as status
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '2 days'
ORDER BY rt.name, ri.date;

\echo ''

-- ============================================================================
-- Test 3: ทดสอบการใช้คูปอง
-- ============================================================================
\echo 'Test 3: Voucher validation'

-- ทดสอบคูปองที่ใช้ได้
SELECT 
    code,
    discount_type,
    discount_value,
    expiry_date,
    max_uses,
    current_uses,
    (max_uses - current_uses) as remaining,
    min_booking_amount,
    CASE 
        WHEN expiry_date < CURRENT_DATE THEN '✗ Expired'
        WHEN current_uses >= max_uses THEN '✗ Fully Used'
        WHEN NOT is_active THEN '✗ Inactive'
        ELSE '✓ Valid'
    END as status
FROM vouchers
ORDER BY expiry_date;

-- ทดสอบคำนวณส่วนลด
\echo ''
\echo 'Discount calculation examples:'

-- Percentage discount
SELECT 
    'WELCOME10' as voucher_code,
    'Percentage' as discount_type,
    10.00 as discount_value,
    5000.00 as booking_amount,
    5000.00 * (10.00 / 100) as discount_amount,
    5000.00 - (5000.00 * (10.00 / 100)) as final_amount;

-- Fixed amount discount
SELECT 
    'SAVE500' as voucher_code,
    'FixedAmount' as discount_type,
    500.00 as discount_value,
    5000.00 as booking_amount,
    500.00 as discount_amount,
    5000.00 - 500.00 as final_amount;

\echo ''

-- ============================================================================
-- Test 4: ทดสอบ Inventory Constraint
-- ============================================================================
\echo 'Test 4: Inventory constraint enforcement'

-- พยายามสร้าง inventory ที่ละเมิด constraint (ควรล้มเหลว)
\echo 'Attempting to violate inventory constraint (should fail)...'

DO $
BEGIN
    -- พยายาม insert ข้อมูลที่ booked_count + tentative_count > allotment
    BEGIN
        INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
        VALUES (
            (SELECT room_type_id FROM room_types LIMIT 1),
            CURRENT_DATE + INTERVAL '100 days',
            10,
            8,
            5  -- 8 + 5 = 13 > 10 (should fail)
        );
        RAISE NOTICE '✗ FAILED: Constraint not enforced!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✓ PASSED: Constraint properly enforced';
    END;
END $;

\echo ''

-- ============================================================================
-- Test 5: ทดสอบการอัปเดต Inventory
-- ============================================================================
\echo 'Test 5: Inventory update simulation'

-- จำลองการจอง (เพิ่ม tentative_count)
DO $
DECLARE
    v_room_type_id INT;
    v_test_date DATE;
    v_before_tentative INT;
    v_after_tentative INT;
BEGIN
    -- เลือก room type และวันที่สำหรับทดสอบ
    SELECT room_type_id INTO v_room_type_id FROM room_types LIMIT 1;
    v_test_date := CURRENT_DATE + INTERVAL '50 days';
    
    -- บันทึกค่าก่อนอัปเดต
    SELECT tentative_count INTO v_before_tentative
    FROM room_inventory
    WHERE room_type_id = v_room_type_id AND date = v_test_date;
    
    -- จำลองการสร้าง hold
    UPDATE room_inventory
    SET tentative_count = tentative_count + 1
    WHERE room_type_id = v_room_type_id 
      AND date = v_test_date
      AND (allotment - booked_count - tentative_count) > 0;
    
    -- ตรวจสอบผลลัพธ์
    SELECT tentative_count INTO v_after_tentative
    FROM room_inventory
    WHERE room_type_id = v_room_type_id AND date = v_test_date;
    
    IF v_after_tentative = v_before_tentative + 1 THEN
        RAISE NOTICE '✓ PASSED: Tentative count increased correctly';
    ELSE
        RAISE NOTICE '✗ FAILED: Tentative count not updated';
    END IF;
    
    -- คืนค่าเดิม
    UPDATE room_inventory
    SET tentative_count = v_before_tentative
    WHERE room_type_id = v_room_type_id AND date = v_test_date;
END $;

\echo ''

-- ============================================================================
-- Test 6: ทดสอบการค้นหาห้องว่างสำหรับช่วงวันที่
-- ============================================================================
\echo 'Test 6: Multi-day availability check'

-- ค้นหาห้องที่ว่างทุกวันในช่วง 3 วันข้างหน้า
WITH date_range AS (
    SELECT generate_series(
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '2 days',
        INTERVAL '1 day'
    )::DATE as check_date
),
availability AS (
    SELECT 
        ri.room_type_id,
        dr.check_date,
        (ri.allotment - ri.booked_count - ri.tentative_count) as available
    FROM date_range dr
    JOIN room_inventory ri ON dr.check_date = ri.date
)
SELECT 
    rt.name as room_type,
    COUNT(*) as days_checked,
    MIN(a.available) as min_available,
    CASE 
        WHEN MIN(a.available) > 0 THEN '✓ Available all days'
        ELSE '✗ Not available'
    END as status
FROM availability a
JOIN room_types rt ON a.room_type_id = rt.room_type_id
GROUP BY rt.name
ORDER BY rt.name;

\echo ''

-- ============================================================================
-- Test 7: ทดสอบ Rate Plan และ Policy Relationship
-- ============================================================================
\echo 'Test 7: Rate plan and cancellation policy relationship'

SELECT 
    rp.name as rate_plan,
    cp.name as cancellation_policy,
    cp.days_before_check_in,
    cp.refund_percentage,
    CASE 
        WHEN cp.policy_id IS NOT NULL THEN '✓ Valid'
        ELSE '✗ Missing Policy'
    END as status
FROM rate_plans rp
LEFT JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
ORDER BY rp.name;

\echo ''

-- ============================================================================
-- Test 8: ทดสอบ Pricing Calendar Coverage
-- ============================================================================
\echo 'Test 8: Pricing calendar date coverage'

-- ตรวจสอบว่ามีวันที่ครบ 90 วัน
WITH expected_dates AS (
    SELECT generate_series(
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '89 days',
        INTERVAL '1 day'
    )::DATE as expected_date
)
SELECT 
    COUNT(DISTINCT ed.expected_date) as expected_days,
    COUNT(DISTINCT pc.date) as actual_days,
    CASE 
        WHEN COUNT(DISTINCT ed.expected_date) = COUNT(DISTINCT pc.date) 
        THEN '✓ Complete coverage'
        ELSE '✗ Missing dates'
    END as status
FROM expected_dates ed
LEFT JOIN pricing_calendar pc ON ed.expected_date = pc.date;

-- แสดงวันที่หายไป (ถ้ามี)
SELECT 
    ed.expected_date as missing_date
FROM (
    SELECT generate_series(
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '89 days',
        INTERVAL '1 day'
    )::DATE as expected_date
) ed
LEFT JOIN pricing_calendar pc ON ed.expected_date = pc.date
WHERE pc.date IS NULL
LIMIT 10;

\echo ''

-- ============================================================================
-- Test 9: ทดสอบ Price Comparison
-- ============================================================================
\echo 'Test 9: Price comparison between rate plans'

-- เปรียบเทียบราคาระหว่าง Standard Rate และ Non-Refundable Rate
SELECT 
    rt.name as room_type,
    tier.name as rate_tier,
    MAX(CASE WHEN rp.name = 'Standard Rate' THEN rpr.price END) as standard_price,
    MAX(CASE WHEN rp.name = 'Non-Refundable Rate' THEN rpr.price END) as non_refundable_price,
    MAX(CASE WHEN rp.name = 'Standard Rate' THEN rpr.price END) - 
    MAX(CASE WHEN rp.name = 'Non-Refundable Rate' THEN rpr.price END) as price_difference,
    ROUND(
        (MAX(CASE WHEN rp.name = 'Non-Refundable Rate' THEN rpr.price END) * 100.0 / 
         NULLIF(MAX(CASE WHEN rp.name = 'Standard Rate' THEN rpr.price END), 0)) - 100,
        2
    ) as discount_percentage
FROM rate_pricing rpr
JOIN rate_plans rp ON rpr.rate_plan_id = rp.rate_plan_id
JOIN room_types rt ON rpr.room_type_id = rt.room_type_id
JOIN rate_tiers tier ON rpr.rate_tier_id = tier.rate_tier_id
GROUP BY rt.name, tier.name, tier.display_order
ORDER BY rt.name, tier.display_order;

\echo ''

-- ============================================================================
-- Test 10: ทดสอบ Voucher Usage Limit
-- ============================================================================
\echo 'Test 10: Voucher usage limit enforcement'

DO $
BEGIN
    -- พยายามอัปเดต current_uses ให้เกิน max_uses (ควรล้มเหลว)
    BEGIN
        UPDATE vouchers
        SET current_uses = max_uses + 1
        WHERE code = 'WELCOME10';
        
        RAISE NOTICE '✗ FAILED: Voucher constraint not enforced!';
        
        -- คืนค่าเดิม
        UPDATE vouchers
        SET current_uses = 0
        WHERE code = 'WELCOME10';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✓ PASSED: Voucher usage limit properly enforced';
    END;
END $;

\echo ''
\echo '=== All Tests Complete ==='
