-- ============================================================================
-- Verification Script: verify_pricing_inventory.sql
-- Description: ตรวจสอบความถูกต้องของ Pricing & Inventory Schema
-- ============================================================================

\echo '=== Starting Pricing & Inventory Schema Verification ==='
\echo ''

-- ============================================================================
-- 1. ตรวจสอบการสร้างตาราง
-- ============================================================================
\echo '1. Checking if all tables exist...'

SELECT 
    table_name,
    CASE 
        WHEN table_name IN (
            'cancellation_policies', 'rate_tiers', 'rate_plans', 
            'pricing_calendar', 'rate_pricing', 'room_inventory',
            'vouchers', 'booking_holds'
        ) THEN '✓ EXISTS'
        ELSE '✗ MISSING'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'cancellation_policies', 'rate_tiers', 'rate_plans', 
      'pricing_calendar', 'rate_pricing', 'room_inventory',
      'vouchers', 'booking_holds'
  )
ORDER BY table_name;

\echo ''

-- ============================================================================
-- 2. ตรวจสอบ Constraints
-- ============================================================================
\echo '2. Checking constraints...'

-- CHECK constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name IN (
      'cancellation_policies', 'rate_tiers', 'rate_plans', 
      'pricing_calendar', 'rate_pricing', 'room_inventory',
      'vouchers', 'booking_holds'
  )
  AND tc.constraint_type = 'CHECK'
ORDER BY tc.table_name, tc.constraint_name;

\echo ''

-- ============================================================================
-- 3. ตรวจสอบ Foreign Keys
-- ============================================================================
\echo '3. Checking foreign key relationships...'

SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN (
      'rate_plans', 'pricing_calendar', 'rate_pricing', 
      'room_inventory', 'booking_holds'
  )
ORDER BY tc.table_name, kcu.column_name;

\echo ''

-- ============================================================================
-- 4. ตรวจสอบ Indexes
-- ============================================================================
\echo '4. Checking indexes...'

SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
      'room_inventory', 'pricing_calendar', 'rate_pricing',
      'booking_holds', 'vouchers'
  )
ORDER BY tablename, indexname;

\echo ''

-- ============================================================================
-- 5. ตรวจสอบข้อมูล Seed Data
-- ============================================================================
\echo '5. Checking seed data...'

-- Cancellation Policies
SELECT 
    'Cancellation Policies' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 3 THEN '✓ OK' ELSE '✗ INSUFFICIENT' END as status
FROM cancellation_policies;

-- Rate Tiers
SELECT 
    'Rate Tiers' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 4 THEN '✓ OK' ELSE '✗ INSUFFICIENT' END as status
FROM rate_tiers;

-- Rate Plans
SELECT 
    'Rate Plans' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 2 THEN '✓ OK' ELSE '✗ INSUFFICIENT' END as status
FROM rate_plans;

-- Rate Pricing
SELECT 
    'Rate Pricing' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 24 THEN '✓ OK' ELSE '✗ INSUFFICIENT' END as status
FROM rate_pricing;

-- Pricing Calendar
SELECT 
    'Pricing Calendar' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 90 THEN '✓ OK' ELSE '✗ INSUFFICIENT' END as status
FROM pricing_calendar;

-- Room Inventory
SELECT 
    'Room Inventory' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 270 THEN '✓ OK' ELSE '✗ INSUFFICIENT' END as status
FROM room_inventory;

-- Vouchers
SELECT 
    'Vouchers' as table_name,
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 5 THEN '✓ OK' ELSE '✗ INSUFFICIENT' END as status
FROM vouchers;

\echo ''

-- ============================================================================
-- 6. ตรวจสอบความสมบูรณ์ของเมทริกซ์ราคา
-- ============================================================================
\echo '6. Checking rate pricing matrix completeness...'

-- ตรวจสอบว่าทุก combination มีราคากำหนดไว้
SELECT 
    rp.name as rate_plan,
    rt.name as room_type,
    COUNT(DISTINCT tier.rate_tier_id) as tiers_with_price,
    (SELECT COUNT(*) FROM rate_tiers WHERE is_active = TRUE) as total_tiers,
    CASE 
        WHEN COUNT(DISTINCT tier.rate_tier_id) = (SELECT COUNT(*) FROM rate_tiers WHERE is_active = TRUE)
        THEN '✓ COMPLETE'
        ELSE '✗ INCOMPLETE'
    END as status
FROM rate_plans rp
CROSS JOIN room_types rt
LEFT JOIN rate_pricing rpr ON rp.rate_plan_id = rpr.rate_plan_id 
    AND rt.room_type_id = rpr.room_type_id
LEFT JOIN rate_tiers tier ON rpr.rate_tier_id = tier.rate_tier_id
WHERE rp.is_active = TRUE AND rt.room_type_id IS NOT NULL
GROUP BY rp.name, rt.name
ORDER BY rp.name, rt.name;

\echo ''

-- ============================================================================
-- 7. ตรวจสอบ Inventory Constraint
-- ============================================================================
\echo '7. Checking inventory constraints...'

-- ตรวจสอบว่าไม่มี record ที่ booked_count + tentative_count > allotment
SELECT 
    COUNT(*) as violation_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ NO VIOLATIONS'
        ELSE '✗ CONSTRAINT VIOLATIONS FOUND'
    END as status
FROM room_inventory
WHERE booked_count + tentative_count > allotment;

-- แสดง violations ถ้ามี
SELECT 
    rt.name as room_type,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.booked_count + ri.tentative_count - ri.allotment) as overflow
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.booked_count + ri.tentative_count > ri.allotment
LIMIT 10;

\echo ''

-- ============================================================================
-- 8. ตรวจสอบ Voucher Constraints
-- ============================================================================
\echo '8. Checking voucher constraints...'

-- ตรวจสอบว่าไม่มี voucher ที่ current_uses > max_uses
SELECT 
    COUNT(*) as violation_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ NO VIOLATIONS'
        ELSE '✗ CONSTRAINT VIOLATIONS FOUND'
    END as status
FROM vouchers
WHERE current_uses > max_uses;

\echo ''

-- ============================================================================
-- 9. ตรวจสอบความสัมพันธ์ระหว่างตาราง
-- ============================================================================
\echo '9. Checking table relationships...'

-- ตรวจสอบว่า rate_plans ทุกตัวมี policy
SELECT 
    COUNT(*) as plans_without_policy,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ ALL PLANS HAVE POLICIES'
        ELSE '✗ SOME PLANS MISSING POLICIES'
    END as status
FROM rate_plans rp
LEFT JOIN cancellation_policies cp ON rp.policy_id = cp.policy_id
WHERE cp.policy_id IS NULL;

-- ตรวจสอบว่า pricing_calendar ทุกวันมี tier
SELECT 
    COUNT(*) as days_without_tier,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ ALL DAYS HAVE TIERS'
        ELSE '✗ SOME DAYS MISSING TIERS'
    END as status
FROM pricing_calendar pc
LEFT JOIN rate_tiers tier ON pc.rate_tier_id = tier.rate_tier_id
WHERE tier.rate_tier_id IS NULL;

\echo ''

-- ============================================================================
-- 10. สรุปข้อมูลสถิติ
-- ============================================================================
\echo '10. Summary statistics...'

-- สรุปราคาตามประเภทห้อง
\echo 'Price range by room type:'
SELECT 
    rt.name as room_type,
    MIN(rpr.price) as min_price,
    MAX(rpr.price) as max_price,
    ROUND(AVG(rpr.price), 2) as avg_price
FROM rate_pricing rpr
JOIN room_types rt ON rpr.room_type_id = rt.room_type_id
GROUP BY rt.name
ORDER BY avg_price;

\echo ''

-- สรุป inventory availability
\echo 'Inventory availability summary:'
SELECT 
    rt.name as room_type,
    COUNT(*) as total_days,
    ROUND(AVG(ri.allotment), 2) as avg_allotment,
    ROUND(AVG(ri.booked_count), 2) as avg_booked,
    ROUND(AVG(ri.allotment - ri.booked_count - ri.tentative_count), 2) as avg_available,
    ROUND(AVG(ri.booked_count) * 100.0 / NULLIF(AVG(ri.allotment), 0), 2) as avg_occupancy_pct
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
GROUP BY rt.name
ORDER BY rt.name;

\echo ''

-- สรุป pricing calendar distribution
\echo 'Pricing calendar tier distribution:'
SELECT 
    tier.name as rate_tier,
    COUNT(*) as days,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM pricing_calendar), 2) as percentage
FROM pricing_calendar pc
JOIN rate_tiers tier ON pc.rate_tier_id = tier.rate_tier_id
GROUP BY tier.name, tier.display_order
ORDER BY tier.display_order;

\echo ''
\echo '=== Verification Complete ==='
