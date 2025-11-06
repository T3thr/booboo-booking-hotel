-- ============================================================================
-- Verification Script: verify_confirm_booking.sql
-- Description: ตรวจสอบว่า confirm_booking function ถูกสร้างและทำงานถูกต้อง
-- Task: 12. สร้าง PostgreSQL Function - confirm_booking
-- ============================================================================

\echo '========================================'
\echo 'Verifying Confirm Booking Function'
\echo '========================================'
\echo ''

-- ============================================================================
-- 1. ตรวจสอบว่า function มีอยู่
-- ============================================================================
\echo '1. Checking if function exists...'
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type,
    d.description
FROM pg_proc p
LEFT JOIN pg_description d ON p.oid = d.objoid
WHERE p.proname = 'confirm_booking';

\echo ''

-- ============================================================================
-- 2. แสดงข้อมูล function
-- ============================================================================
\echo '2. Function details:'
\df+ confirm_booking

\echo ''

-- ============================================================================
-- 3. ตรวจสอบ permissions
-- ============================================================================
\echo '3. Function permissions:'
SELECT 
    p.proname as function_name,
    pg_catalog.pg_get_userbyid(p.proowner) as owner,
    p.proacl as access_privileges
FROM pg_proc p
WHERE p.proname = 'confirm_booking';

\echo ''

-- ============================================================================
-- 4. ตรวจสอบตารางที่เกี่ยวข้อง
-- ============================================================================
\echo '4. Checking related tables...'

-- ตรวจสอบ bookings table
SELECT 
    'bookings' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN status = 'PendingPayment' THEN 1 END) as pending_payment,
    COUNT(CASE WHEN status = 'Confirmed' THEN 1 END) as confirmed,
    COUNT(CASE WHEN policy_name IS NOT NULL AND policy_name != '' THEN 1 END) as with_policy
FROM bookings;

-- ตรวจสอบ booking_nightly_log table
SELECT 
    'booking_nightly_log' as table_name,
    COUNT(*) as total_records,
    MIN(quoted_price) as min_price,
    MAX(quoted_price) as max_price,
    AVG(quoted_price)::DECIMAL(10,2) as avg_price
FROM booking_nightly_log;

-- ตรวจสอบ room_inventory
SELECT 
    'room_inventory' as table_name,
    SUM(allotment) as total_allotment,
    SUM(booked_count) as total_booked,
    SUM(tentative_count) as total_tentative,
    SUM(allotment - booked_count - tentative_count) as total_available
FROM room_inventory
WHERE date >= CURRENT_DATE
  AND date < CURRENT_DATE + INTERVAL '30 days';

\echo ''

-- ============================================================================
-- 5. ตัวอย่างการใช้งาน
-- ============================================================================
\echo '5. Example usage:'
\echo ''
\echo 'To confirm a booking:'
\echo '  SELECT * FROM confirm_booking(123);'
\echo ''
\echo 'Expected return columns:'
\echo '  - success (BOOLEAN): TRUE if successful'
\echo '  - message (TEXT): Success/error message'
\echo '  - booking_id (INT): Confirmed booking ID'
\echo ''

-- ============================================================================
-- 6. แสดง confirmed bookings ล่าสุด
-- ============================================================================
\echo '6. Recent confirmed bookings:'
SELECT 
    b.booking_id,
    g.email as guest_email,
    b.status,
    b.total_amount,
    b.policy_name,
    b.created_at,
    b.updated_at,
    COUNT(DISTINCT bd.booking_detail_id) as num_rooms,
    COUNT(bnl.booking_nightly_log_id) as num_nights
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
LEFT JOIN booking_details bd ON b.booking_id = bd.booking_id
LEFT JOIN booking_nightly_log bnl ON bd.booking_detail_id = bnl.booking_detail_id
WHERE b.status = 'Confirmed'
GROUP BY b.booking_id, g.email, b.status, b.total_amount, b.policy_name, b.created_at, b.updated_at
ORDER BY b.updated_at DESC
LIMIT 5;

\echo ''

-- ============================================================================
-- 7. ตรวจสอบ data integrity
-- ============================================================================
\echo '7. Data integrity checks:'

-- ตรวจสอบว่า confirmed bookings มี policy
SELECT 
    'Confirmed bookings without policy' as check_name,
    COUNT(*) as count
FROM bookings
WHERE status = 'Confirmed'
  AND (policy_name IS NULL OR policy_name = '');

-- ตรวจสอบว่า confirmed bookings มี nightly log
SELECT 
    'Confirmed bookings without nightly log' as check_name,
    COUNT(*) as count
FROM bookings b
LEFT JOIN booking_details bd ON b.booking_id = bd.booking_id
LEFT JOIN booking_nightly_log bnl ON bd.booking_detail_id = bnl.booking_detail_id
WHERE b.status = 'Confirmed'
  AND bnl.booking_nightly_log_id IS NULL;

-- ตรวจสอบ inventory consistency
SELECT 
    'Inventory violations (booked + tentative > allotment)' as check_name,
    COUNT(*) as count
FROM room_inventory
WHERE booked_count + tentative_count > allotment;

\echo ''
\echo '========================================'
\echo 'Verification Complete'
\echo '========================================'
\echo ''
\echo 'If all checks pass:'
\echo '  - Function exists and is properly defined'
\echo '  - Related tables are accessible'
\echo '  - Data integrity is maintained'
\echo '  - No constraint violations'
\echo ''
\echo 'Next steps:'
\echo '  1. Run comprehensive tests: run_test_confirm_booking.sh'
\echo '  2. Test with real booking scenarios'
\echo '  3. Monitor function performance'
\echo ''
