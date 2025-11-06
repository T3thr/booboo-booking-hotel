-- ============================================================================
-- Test Script for Bookings Tables (Migration 004)
-- ============================================================================
-- Purpose: Test all booking tables with sample data and verify constraints
-- ============================================================================

\echo '========================================='
\echo 'Testing Bookings Tables'
\echo '========================================='
\echo ''

BEGIN;

\echo 'Test 1: Insert a complete booking flow...'

-- Ensure we have test data from previous migrations
DO $$
BEGIN
    -- Check if we have required test data
    IF NOT EXISTS (SELECT 1 FROM guests LIMIT 1) THEN
        RAISE EXCEPTION 'No guests found. Please run migration 001 first.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM room_types LIMIT 1) THEN
        RAISE EXCEPTION 'No room types found. Please run migration 002 first.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM rate_plans LIMIT 1) THEN
        RAISE EXCEPTION 'No rate plans found. Please run migration 003 first.';
    END IF;
    
    RAISE NOTICE '✓ Required test data exists';
END $$;

-- Test 1: Create a booking
\echo ''
\echo 'Creating test booking...'

INSERT INTO bookings (
    guest_id,
    total_amount,
    status,
    policy_name,
    policy_description
)
SELECT 
    g.guest_id,
    1500.00,
    'PendingPayment',
    'Standard Cancellation',
    'Free cancellation up to 7 days before check-in. 50% refund for 3-7 days. No refund within 3 days.'
FROM guests g
LIMIT 1
RETURNING booking_id, guest_id, total_amount, status;

-- Get the booking_id for further tests
DO $$
DECLARE
    v_booking_id INT;
    v_room_type_id INT;
    v_rate_plan_id INT;
BEGIN
    SELECT booking_id INTO v_booking_id FROM bookings ORDER BY booking_id DESC LIMIT 1;
    SELECT room_type_id INTO v_room_type_id FROM room_types LIMIT 1;
    SELECT rate_plan_id INTO v_rate_plan_id FROM rate_plans LIMIT 1;
    
    RAISE NOTICE '✓ Created booking_id: %', v_booking_id;
    
    -- Test 2: Create booking detail
    INSERT INTO booking_details (
        booking_id,
        room_type_id,
        rate_plan_id,
        check_in_date,
        check_out_date,
        num_guests
    ) VALUES (
        v_booking_id,
        v_room_type_id,
        v_rate_plan_id,
        CURRENT_DATE + INTERVAL '7 days',
        CURRENT_DATE + INTERVAL '10 days',
        2
    );
    
    RAISE NOTICE '✓ Created booking detail';
END $$;

-- Test 3: Create booking guests
\echo ''
\echo 'Adding booking guests...'

INSERT INTO booking_guests (
    booking_detail_id,
    first_name,
    last_name,
    type,
    is_primary
)
SELECT 
    bd.booking_detail_id,
    'John',
    'Doe',
    'Adult',
    TRUE
FROM booking_details bd
ORDER BY bd.booking_detail_id DESC
LIMIT 1;

INSERT INTO booking_guests (
    booking_detail_id,
    first_name,
    last_name,
    type,
    is_primary
)
SELECT 
    bd.booking_detail_id,
    'Jane',
    'Doe',
    'Adult',
    FALSE
FROM booking_details bd
ORDER BY bd.booking_detail_id DESC
LIMIT 1;

SELECT COUNT(*) AS guest_count FROM booking_guests;
\echo '✓ Added booking guests'

-- Test 4: Create nightly log entries
\echo ''
\echo 'Creating nightly log entries...'

DO $$
DECLARE
    v_booking_detail_id INT;
    v_check_in DATE;
    v_check_out DATE;
    v_current_date DATE;
BEGIN
    SELECT booking_detail_id, check_in_date, check_out_date
    INTO v_booking_detail_id, v_check_in, v_check_out
    FROM booking_details
    ORDER BY booking_detail_id DESC
    LIMIT 1;
    
    v_current_date := v_check_in;
    
    WHILE v_current_date < v_check_out LOOP
        INSERT INTO booking_nightly_log (
            booking_detail_id,
            date,
            quoted_price
        ) VALUES (
            v_booking_detail_id,
            v_current_date,
            500.00
        );
        
        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;
    
    RAISE NOTICE '✓ Created % nightly log entries', (v_check_out - v_check_in);
END $$;

-- Test 5: Update booking status to Confirmed
\echo ''
\echo 'Confirming booking...'

UPDATE bookings
SET status = 'Confirmed'
WHERE booking_id = (SELECT booking_id FROM bookings ORDER BY booking_id DESC LIMIT 1);

SELECT booking_id, status, updated_at
FROM bookings
ORDER BY booking_id DESC
LIMIT 1;

\echo '✓ Booking confirmed'

-- Test 6: Create room assignment (check-in)
\echo ''
\echo 'Creating room assignment (check-in)...'

DO $$
DECLARE
    v_booking_detail_id INT;
    v_room_id INT;
BEGIN
    SELECT booking_detail_id INTO v_booking_detail_id
    FROM booking_details
    ORDER BY booking_detail_id DESC
    LIMIT 1;
    
    SELECT room_id INTO v_room_id
    FROM rooms
    LIMIT 1;
    
    IF v_room_id IS NULL THEN
        RAISE EXCEPTION 'No rooms found. Please run migration 002 first.';
    END IF;
    
    INSERT INTO room_assignments (
        booking_detail_id,
        room_id,
        check_in_datetime,
        status
    ) VALUES (
        v_booking_detail_id,
        v_room_id,
        NOW(),
        'Active'
    );
    
    RAISE NOTICE '✓ Created room assignment for room_id: %', v_room_id;
END $$;

-- Test 7: Test constraint validations
\echo ''
\echo 'Testing constraints...'

-- Test date order constraint
DO $$
BEGIN
    INSERT INTO booking_details (
        booking_id,
        room_type_id,
        rate_plan_id,
        check_in_date,
        check_out_date,
        num_guests
    )
    SELECT 
        booking_id,
        (SELECT room_type_id FROM room_types LIMIT 1),
        (SELECT rate_plan_id FROM rate_plans LIMIT 1),
        CURRENT_DATE + INTERVAL '10 days',
        CURRENT_DATE + INTERVAL '7 days',  -- Invalid: check_out before check_in
        2
    FROM bookings
    ORDER BY booking_id DESC
    LIMIT 1;
    
    RAISE EXCEPTION 'Should have failed: check_out_date must be after check_in_date';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE '✓ Date order constraint working correctly';
END $$;

-- Test positive amount constraint
DO $$
BEGIN
    INSERT INTO bookings (
        guest_id,
        total_amount,
        status,
        policy_name,
        policy_description
    )
    SELECT 
        guest_id,
        -100.00,  -- Invalid: negative amount
        'PendingPayment',
        'Test Policy',
        'Test Description'
    FROM guests
    LIMIT 1;
    
    RAISE EXCEPTION 'Should have failed: total_amount must be positive';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE '✓ Positive amount constraint working correctly';
END $$;

-- Test status constraint
DO $$
BEGIN
    INSERT INTO bookings (
        guest_id,
        total_amount,
        status,
        policy_name,
        policy_description
    )
    SELECT 
        guest_id,
        100.00,
        'InvalidStatus',  -- Invalid status
        'Test Policy',
        'Test Description'
    FROM guests
    LIMIT 1;
    
    RAISE EXCEPTION 'Should have failed: invalid status value';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE '✓ Status constraint working correctly';
END $$;

-- Test unique constraint on nightly log
DO $$
DECLARE
    v_booking_detail_id INT;
    v_date DATE;
BEGIN
    SELECT booking_detail_id, date
    INTO v_booking_detail_id, v_date
    FROM booking_nightly_log
    LIMIT 1;
    
    INSERT INTO booking_nightly_log (
        booking_detail_id,
        date,
        quoted_price
    ) VALUES (
        v_booking_detail_id,
        v_date,  -- Duplicate date for same booking_detail
        500.00
    );
    
    RAISE EXCEPTION 'Should have failed: duplicate nightly log entry';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE '✓ Unique constraint on nightly log working correctly';
END $$;

-- Display test results
\echo ''
\echo '========================================='
\echo 'Test Results Summary'
\echo '========================================='

SELECT 
    'bookings' AS table_name,
    COUNT(*) AS record_count
FROM bookings
UNION ALL
SELECT 
    'booking_details',
    COUNT(*)
FROM booking_details
UNION ALL
SELECT 
    'room_assignments',
    COUNT(*)
FROM room_assignments
UNION ALL
SELECT 
    'booking_guests',
    COUNT(*)
FROM booking_guests
UNION ALL
SELECT 
    'booking_nightly_log',
    COUNT(*)
FROM booking_nightly_log;

\echo ''
\echo 'Sample Booking Data:'
SELECT 
    b.booking_id,
    b.status,
    b.total_amount,
    bd.check_in_date,
    bd.check_out_date,
    bd.num_guests,
    COUNT(bg.booking_guest_id) AS guest_count,
    COUNT(bnl.booking_nightly_log_id) AS night_count
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
LEFT JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
LEFT JOIN booking_nightly_log bnl ON bd.booking_detail_id = bnl.booking_detail_id
GROUP BY b.booking_id, b.status, b.total_amount, bd.check_in_date, bd.check_out_date, bd.num_guests
ORDER BY b.booking_id DESC
LIMIT 5;

\echo ''
\echo '========================================='
\echo 'All Tests Passed Successfully!'
\echo '========================================='

ROLLBACK;

\echo ''
\echo 'Note: All test data has been rolled back.'
