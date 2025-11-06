-- ============================================================================
-- INTEGRATION TESTS FOR POSTGRESQL FUNCTIONS
-- ============================================================================
-- This file contains comprehensive integration tests for all critical
-- PostgreSQL functions in the hotel booking system.
--
-- Test Coverage:
-- 1. create_booking_hold - Booking hold creation and inventory management
-- 2. confirm_booking - Booking confirmation and stock movement
-- 3. check_in - Check-in process and room assignment
-- 4. check_out - Check-out process and room status updates
-- 5. Rollback scenarios - Transaction integrity
-- 6. Constraint violations - Data integrity enforcement
--
-- Usage:
--   psql -U postgres -d hotel_booking_test -f integration_tests.sql
-- ============================================================================

\set ON_ERROR_STOP on
\timing on

-- Create test schema
DROP SCHEMA IF EXISTS test CASCADE;
CREATE SCHEMA test;
SET search_path TO test, public;

-- ============================================================================
-- SETUP: Create test helper functions
-- ============================================================================

CREATE OR REPLACE FUNCTION test.assert_equals(
    test_name TEXT,
    expected ANYELEMENT,
    actual ANYELEMENT
) RETURNS void AS $$
BEGIN
    IF expected IS DISTINCT FROM actual THEN
        RAISE EXCEPTION 'TEST FAILED: % - Expected: %, Got: %', 
            test_name, expected, actual;
    ELSE
        RAISE NOTICE 'TEST PASSED: %', test_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.assert_true(
    test_name TEXT,
    condition BOOLEAN
) RETURNS void AS $$
BEGIN
    IF NOT condition THEN
        RAISE EXCEPTION 'TEST FAILED: %', test_name;
    ELSE
        RAISE NOTICE 'TEST PASSED: %', test_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST SUITE 1: create_booking_hold Tests
-- ============================================================================

CREATE OR REPLACE FUNCTION test.test_create_booking_hold_success()
RETURNS void AS $$
DECLARE
    v_hold_id BIGINT;
    v_success BOOLEAN;
    v_message TEXT;
    v_tentative_before INT;
    v_tentative_after INT;
BEGIN
    RAISE NOTICE '=== TEST SUITE 1: create_booking_hold ===';
    
    -- Setup: Get initial tentative count
    SELECT tentative_count INTO v_tentative_before
    FROM room_inventory
    WHERE room_type_id = 1 AND date = CURRENT_DATE
    LIMIT 1;
    
    -- Test: Create booking hold
    SELECT * INTO v_hold_id, v_success, v_message
    FROM create_booking_hold(
        'test-session-001',
        1,  -- guest_account_id
        1,  -- room_type_id
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '2 days'
    );
    
    -- Assert: Hold created successfully
    PERFORM test.assert_true(
        'create_booking_hold returns success',
        v_success
    );
    
    -- Assert: Tentative count increased
    SELECT tentative_count INTO v_tentative_after
    FROM room_inventory
    WHERE room_type_id = 1 AND date = CURRENT_DATE;
    
    PERFORM test.assert_equals(
        'tentative_count increased by 1',
        v_tentative_before + 1,
        v_tentative_after
    );
    
    -- Assert: Hold record exists
    PERFORM test.assert_true(
        'booking_holds record created',
        EXISTS(
            SELECT 1 FROM booking_holds
            WHERE session_id = 'test-session-001'
            AND room_type_id = 1
        )
    );
    
    RAISE NOTICE 'Test create_booking_hold_success completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_create_booking_hold_no_availability()
RETURNS void AS $$
DECLARE
    v_hold_id BIGINT;
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    -- Setup: Set allotment to 0 for a specific date
    UPDATE room_inventory
    SET allotment = 0, booked_count = 0, tentative_count = 0
    WHERE room_type_id = 1 AND date = CURRENT_DATE + INTERVAL '10 days';
    
    -- Test: Try to create hold when no rooms available
    SELECT * INTO v_hold_id, v_success, v_message
    FROM create_booking_hold(
        'test-session-no-avail',
        1,
        1,
        CURRENT_DATE + INTERVAL '10 days',
        CURRENT_DATE + INTERVAL '12 days'
    );
    
    -- Assert: Hold creation failed
    PERFORM test.assert_true(
        'create_booking_hold fails when no availability',
        NOT v_success
    );
    
    RAISE NOTICE 'Test create_booking_hold_no_availability completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_create_booking_hold_race_condition()
RETURNS void AS $$
DECLARE
    v_initial_allotment INT := 1;
    v_success1 BOOLEAN;
    v_success2 BOOLEAN;
    v_message1 TEXT;
    v_message2 TEXT;
BEGIN
    -- Setup: Set allotment to exactly 1
    UPDATE room_inventory
    SET allotment = v_initial_allotment, booked_count = 0, tentative_count = 0
    WHERE room_type_id = 2 AND date = CURRENT_DATE + INTERVAL '20 days';
    
    -- Test: Simulate concurrent holds (first should succeed, second should fail)
    BEGIN
        SELECT success, message INTO v_success1, v_message1
        FROM create_booking_hold(
            'race-session-1',
            1,
            2,
            CURRENT_DATE + INTERVAL '20 days',
            CURRENT_DATE + INTERVAL '21 days'
        );
        
        SELECT success, message INTO v_success2, v_message2
        FROM create_booking_hold(
            'race-session-2',
            2,
            2,
            CURRENT_DATE + INTERVAL '20 days',
            CURRENT_DATE + INTERVAL '21 days'
        );
    EXCEPTION WHEN OTHERS THEN
        -- Expected: One should fail
        RAISE NOTICE 'Race condition handled correctly';
    END;
    
    -- Assert: Only one hold succeeded
    PERFORM test.assert_true(
        'race condition prevents overbooking',
        (v_success1 AND NOT v_success2) OR (NOT v_success1 AND v_success2)
    );
    
    RAISE NOTICE 'Test create_booking_hold_race_condition completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST SUITE 2: confirm_booking Tests
-- ============================================================================

CREATE OR REPLACE FUNCTION test.test_confirm_booking_success()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_success BOOLEAN;
    v_message TEXT;
    v_booked_before INT;
    v_booked_after INT;
    v_tentative_before INT;
    v_tentative_after INT;
BEGIN
    RAISE NOTICE '=== TEST SUITE 2: confirm_booking ===';
    
    -- Setup: Create a pending booking
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 1000.00, 'PendingPayment', 'Standard', 'Standard cancellation policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    INSERT INTO booking_details (
        booking_id, room_type_id, rate_plan_id,
        check_in_date, check_out_date, num_guests
    ) VALUES (
        v_booking_id, 1, 1,
        CURRENT_DATE + INTERVAL '5 days',
        CURRENT_DATE + INTERVAL '7 days',
        2
    );
    
    -- Create hold first
    PERFORM create_booking_hold(
        'confirm-test-session',
        1, 1,
        CURRENT_DATE + INTERVAL '5 days',
        CURRENT_DATE + INTERVAL '7 days'
    );
    
    -- Get counts before confirmation
    SELECT booked_count, tentative_count 
    INTO v_booked_before, v_tentative_before
    FROM room_inventory
    WHERE room_type_id = 1 AND date = CURRENT_DATE + INTERVAL '5 days';
    
    -- Test: Confirm booking
    SELECT * INTO v_success, v_message
    FROM confirm_booking(v_booking_id);
    
    -- Assert: Confirmation succeeded
    PERFORM test.assert_true(
        'confirm_booking returns success',
        v_success
    );
    
    -- Assert: Booking status updated
    PERFORM test.assert_true(
        'booking status is Confirmed',
        EXISTS(
            SELECT 1 FROM bookings
            WHERE booking_id = v_booking_id
            AND status = 'Confirmed'
        )
    );
    
    -- Assert: Inventory updated correctly
    SELECT booked_count, tentative_count 
    INTO v_booked_after, v_tentative_after
    FROM room_inventory
    WHERE room_type_id = 1 AND date = CURRENT_DATE + INTERVAL '5 days';
    
    PERFORM test.assert_equals(
        'booked_count increased',
        v_booked_before + 1,
        v_booked_after
    );
    
    PERFORM test.assert_equals(
        'tentative_count decreased',
        v_tentative_before - 1,
        v_tentative_after
    );
    
    RAISE NOTICE 'Test confirm_booking_success completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_confirm_booking_invalid_status()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    -- Setup: Create a booking with Confirmed status
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 1000.00, 'Confirmed', 'Standard', 'Standard policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    -- Test: Try to confirm already confirmed booking
    SELECT * INTO v_success, v_message
    FROM confirm_booking(v_booking_id);
    
    -- Assert: Confirmation failed
    PERFORM test.assert_true(
        'confirm_booking fails for non-pending booking',
        NOT v_success
    );
    
    RAISE NOTICE 'Test confirm_booking_invalid_status completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST SUITE 3: check_in Tests
-- ============================================================================

CREATE OR REPLACE FUNCTION test.test_check_in_success()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_booking_detail_id INT;
    v_room_id INT;
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    RAISE NOTICE '=== TEST SUITE 3: check_in ===';
    
    -- Setup: Create confirmed booking
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 1500.00, 'Confirmed', 'Standard', 'Standard policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    INSERT INTO booking_details (
        booking_id, room_type_id, rate_plan_id,
        check_in_date, check_out_date, num_guests
    ) VALUES (
        v_booking_id, 1, 1,
        CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 2
    ) RETURNING booking_detail_id INTO v_booking_detail_id;
    
    -- Setup: Get a vacant and clean room
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
    AND occupancy_status = 'Vacant'
    AND housekeeping_status IN ('Clean', 'Inspected')
    LIMIT 1;
    
    -- Test: Check in
    SELECT * INTO v_success, v_message
    FROM check_in(v_booking_detail_id, v_room_id);
    
    -- Assert: Check-in succeeded
    PERFORM test.assert_true(
        'check_in returns success',
        v_success
    );
    
    -- Assert: Booking status updated
    PERFORM test.assert_true(
        'booking status is CheckedIn',
        EXISTS(
            SELECT 1 FROM bookings
            WHERE booking_id = v_booking_id
            AND status = 'CheckedIn'
        )
    );
    
    -- Assert: Room assignment created
    PERFORM test.assert_true(
        'room_assignment created',
        EXISTS(
            SELECT 1 FROM room_assignments
            WHERE booking_detail_id = v_booking_detail_id
            AND room_id = v_room_id
            AND status = 'Active'
        )
    );
    
    -- Assert: Room status updated
    PERFORM test.assert_true(
        'room occupancy_status is Occupied',
        EXISTS(
            SELECT 1 FROM rooms
            WHERE room_id = v_room_id
            AND occupancy_status = 'Occupied'
        )
    );
    
    RAISE NOTICE 'Test check_in_success completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_check_in_room_not_ready()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_booking_detail_id INT;
    v_room_id INT;
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    -- Setup: Create confirmed booking
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 1500.00, 'Confirmed', 'Standard', 'Standard policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    INSERT INTO booking_details (
        booking_id, room_type_id, rate_plan_id,
        check_in_date, check_out_date, num_guests
    ) VALUES (
        v_booking_id, 1, 1,
        CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 2
    ) RETURNING booking_detail_id INTO v_booking_detail_id;
    
    -- Setup: Get a dirty room
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
    AND occupancy_status = 'Vacant'
    LIMIT 1;
    
    UPDATE rooms
    SET housekeeping_status = 'Dirty'
    WHERE room_id = v_room_id;
    
    -- Test: Try to check in to dirty room
    SELECT * INTO v_success, v_message
    FROM check_in(v_booking_detail_id, v_room_id);
    
    -- Assert: Check-in failed
    PERFORM test.assert_true(
        'check_in fails for dirty room',
        NOT v_success
    );
    
    RAISE NOTICE 'Test check_in_room_not_ready completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_check_in_room_occupied()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_booking_detail_id INT;
    v_room_id INT;
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    -- Setup: Create confirmed booking
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 1500.00, 'Confirmed', 'Standard', 'Standard policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    INSERT INTO booking_details (
        booking_id, room_type_id, rate_plan_id,
        check_in_date, check_out_date, num_guests
    ) VALUES (
        v_booking_id, 1, 1,
        CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 2
    ) RETURNING booking_detail_id INTO v_booking_detail_id;
    
    -- Setup: Get an occupied room
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
    LIMIT 1;
    
    UPDATE rooms
    SET occupancy_status = 'Occupied'
    WHERE room_id = v_room_id;
    
    -- Test: Try to check in to occupied room
    SELECT * INTO v_success, v_message
    FROM check_in(v_booking_detail_id, v_room_id);
    
    -- Assert: Check-in failed
    PERFORM test.assert_true(
        'check_in fails for occupied room',
        NOT v_success
    );
    
    RAISE NOTICE 'Test check_in_room_occupied completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST SUITE 4: check_out Tests
-- ============================================================================

CREATE OR REPLACE FUNCTION test.test_check_out_success()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_booking_detail_id INT;
    v_room_id INT;
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    RAISE NOTICE '=== TEST SUITE 4: check_out ===';
    
    -- Setup: Create checked-in booking
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 1500.00, 'CheckedIn', 'Standard', 'Standard policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    INSERT INTO booking_details (
        booking_id, room_type_id, rate_plan_id,
        check_in_date, check_out_date, num_guests
    ) VALUES (
        v_booking_id, 1, 1,
        CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE, 2
    ) RETURNING booking_detail_id INTO v_booking_detail_id;
    
    -- Setup: Create room assignment
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
    LIMIT 1;
    
    UPDATE rooms
    SET occupancy_status = 'Occupied'
    WHERE room_id = v_room_id;
    
    INSERT INTO room_assignments (
        booking_detail_id, room_id, check_in_datetime, status
    ) VALUES (
        v_booking_detail_id, v_room_id, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Active'
    );
    
    -- Test: Check out
    SELECT * INTO v_success, v_message
    FROM check_out(v_booking_id);
    
    -- Assert: Check-out succeeded
    PERFORM test.assert_true(
        'check_out returns success',
        v_success
    );
    
    -- Assert: Booking status updated
    PERFORM test.assert_true(
        'booking status is Completed',
        EXISTS(
            SELECT 1 FROM bookings
            WHERE booking_id = v_booking_id
            AND status = 'Completed'
        )
    );
    
    -- Assert: Room assignment completed
    PERFORM test.assert_true(
        'room_assignment status is Completed',
        EXISTS(
            SELECT 1 FROM room_assignments
            WHERE booking_detail_id = v_booking_detail_id
            AND status = 'Completed'
            AND check_out_datetime IS NOT NULL
        )
    );
    
    -- Assert: Room status updated
    PERFORM test.assert_true(
        'room is Vacant and Dirty',
        EXISTS(
            SELECT 1 FROM rooms
            WHERE room_id = v_room_id
            AND occupancy_status = 'Vacant'
            AND housekeeping_status = 'Dirty'
        )
    );
    
    RAISE NOTICE 'Test check_out_success completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_check_out_invalid_status()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    -- Setup: Create confirmed (not checked-in) booking
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 1500.00, 'Confirmed', 'Standard', 'Standard policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    -- Test: Try to check out non-checked-in booking
    SELECT * INTO v_success, v_message
    FROM check_out(v_booking_id);
    
    -- Assert: Check-out failed
    PERFORM test.assert_true(
        'check_out fails for non-checked-in booking',
        NOT v_success
    );
    
    RAISE NOTICE 'Test check_out_invalid_status completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST SUITE 5: Rollback Scenarios
-- ============================================================================

CREATE OR REPLACE FUNCTION test.test_rollback_on_constraint_violation()
RETURNS void AS $$
DECLARE
    v_initial_count INT;
    v_final_count INT;
BEGIN
    RAISE NOTICE '=== TEST SUITE 5: Rollback Scenarios ===';
    
    -- Get initial booking count
    SELECT COUNT(*) INTO v_initial_count FROM bookings;
    
    -- Test: Try to create booking with invalid data (should rollback)
    BEGIN
        INSERT INTO bookings (
            guest_id, total_amount, status, policy_name, policy_description
        ) VALUES (
            999999,  -- Non-existent guest
            1000.00,
            'Confirmed',
            'Test Policy',
            'Test Description'
        );
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key violation caught correctly';
    END;
    
    -- Assert: No booking was created
    SELECT COUNT(*) INTO v_final_count FROM bookings;
    PERFORM test.assert_equals(
        'rollback prevents invalid booking',
        v_initial_count,
        v_final_count
    );
    
    RAISE NOTICE 'Test rollback_on_constraint_violation completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_rollback_on_inventory_violation()
RETURNS void AS $$
DECLARE
    v_tentative_before INT;
    v_tentative_after INT;
    v_success BOOLEAN;
BEGIN
    -- Setup: Set inventory to full
    UPDATE room_inventory
    SET allotment = 5, booked_count = 5, tentative_count = 0
    WHERE room_type_id = 1 AND date = CURRENT_DATE + INTERVAL '30 days';
    
    SELECT tentative_count INTO v_tentative_before
    FROM room_inventory
    WHERE room_type_id = 1 AND date = CURRENT_DATE + INTERVAL '30 days';
    
    -- Test: Try to create hold when fully booked
    SELECT success INTO v_success
    FROM create_booking_hold(
        'rollback-test',
        1, 1,
        CURRENT_DATE + INTERVAL '30 days',
        CURRENT_DATE + INTERVAL '31 days'
    );
    
    -- Assert: Hold creation failed
    PERFORM test.assert_true(
        'hold creation fails when fully booked',
        NOT v_success
    );
    
    -- Assert: Tentative count unchanged
    SELECT tentative_count INTO v_tentative_after
    FROM room_inventory
    WHERE room_type_id = 1 AND date = CURRENT_DATE + INTERVAL '30 days';
    
    PERFORM test.assert_equals(
        'tentative_count unchanged after failed hold',
        v_tentative_before,
        v_tentative_after
    );
    
    RAISE NOTICE 'Test rollback_on_inventory_violation completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST SUITE 6: Constraint Violations
-- ============================================================================

CREATE OR REPLACE FUNCTION test.test_inventory_constraint_violation()
RETURNS void AS $$
BEGIN
    RAISE NOTICE '=== TEST SUITE 6: Constraint Violations ===';
    
    -- Test: Try to violate inventory constraint
    BEGIN
        UPDATE room_inventory
        SET booked_count = 100, tentative_count = 100, allotment = 10
        WHERE room_type_id = 1 AND date = CURRENT_DATE;
        
        RAISE EXCEPTION 'Constraint should have been violated';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Inventory constraint enforced correctly';
    END;
    
    PERFORM test.assert_true(
        'inventory constraint prevents invalid data',
        TRUE
    );
    
    RAISE NOTICE 'Test inventory_constraint_violation completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_date_constraint_violation()
RETURNS void AS $$
BEGIN
    -- Test: Try to create booking with invalid dates
    BEGIN
        INSERT INTO booking_details (
            booking_id, room_type_id, rate_plan_id,
            check_in_date, check_out_date, num_guests
        ) VALUES (
            1, 1, 1,
            CURRENT_DATE + INTERVAL '10 days',
            CURRENT_DATE,  -- Check-out before check-in
            2
        );
        
        RAISE EXCEPTION 'Date constraint should have been violated';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Date constraint enforced correctly';
    END;
    
    PERFORM test.assert_true(
        'date constraint prevents invalid dates',
        TRUE
    );
    
    RAISE NOTICE 'Test date_constraint_violation completed';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_status_constraint_violation()
RETURNS void AS $$
BEGIN
    -- Test: Try to set invalid booking status
    BEGIN
        INSERT INTO bookings (
            guest_id, total_amount, status, policy_name, policy_description
        ) VALUES (
            1, 1000.00, 'InvalidStatus', 'Test', 'Test'
        );
        
        RAISE EXCEPTION 'Status constraint should have been violated';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Status constraint enforced correctly';
    END;
    
    PERFORM test.assert_true(
        'status constraint prevents invalid status',
        TRUE
    );
    
    RAISE NOTICE 'Test status_constraint_violation completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST SUITE 7: Complex Integration Scenarios
-- ============================================================================

CREATE OR REPLACE FUNCTION test.test_full_booking_flow()
RETURNS void AS $$
DECLARE
    v_booking_id INT;
    v_booking_detail_id INT;
    v_room_id INT;
    v_hold_success BOOLEAN;
    v_confirm_success BOOLEAN;
    v_checkin_success BOOLEAN;
    v_checkout_success BOOLEAN;
BEGIN
    RAISE NOTICE '=== TEST SUITE 7: Complex Integration Scenarios ===';
    
    -- Step 1: Create hold
    SELECT success INTO v_hold_success
    FROM create_booking_hold(
        'full-flow-test',
        1, 1,
        CURRENT_DATE + INTERVAL '40 days',
        CURRENT_DATE + INTERVAL '42 days'
    );
    
    PERFORM test.assert_true('Step 1: Hold created', v_hold_success);
    
    -- Step 2: Create booking
    INSERT INTO bookings (
        guest_id, total_amount, status, policy_name, policy_description
    ) VALUES (
        1, 2000.00, 'PendingPayment', 'Standard', 'Standard policy'
    ) RETURNING booking_id INTO v_booking_id;
    
    INSERT INTO booking_details (
        booking_id, room_type_id, rate_plan_id,
        check_in_date, check_out_date, num_guests
    ) VALUES (
        v_booking_id, 1, 1,
        CURRENT_DATE + INTERVAL '40 days',
        CURRENT_DATE + INTERVAL '42 days',
        2
    ) RETURNING booking_detail_id INTO v_booking_detail_id;
    
    -- Step 3: Confirm booking
    SELECT success INTO v_confirm_success
    FROM confirm_booking(v_booking_id);
    
    PERFORM test.assert_true('Step 2: Booking confirmed', v_confirm_success);
    
    -- Step 4: Check in (simulate arrival date)
    UPDATE booking_details
    SET check_in_date = CURRENT_DATE, check_out_date = CURRENT_DATE + INTERVAL '2 days'
    WHERE booking_detail_id = v_booking_detail_id;
    
    UPDATE bookings SET status = 'Confirmed' WHERE booking_id = v_booking_id;
    
    SELECT room_id INTO v_room_id
    FROM rooms
    WHERE room_type_id = 1
    AND occupancy_status = 'Vacant'
    AND housekeeping_status IN ('Clean', 'Inspected')
    LIMIT 1;
    
    SELECT success INTO v_checkin_success
    FROM check_in(v_booking_detail_id, v_room_id);
    
    PERFORM test.assert_true('Step 3: Check-in successful', v_checkin_success);
    
    -- Step 5: Check out
    SELECT success INTO v_checkout_success
    FROM check_out(v_booking_id);
    
    PERFORM test.assert_true('Step 4: Check-out successful', v_checkout_success);
    
    -- Verify final state
    PERFORM test.assert_true(
        'Final: Booking completed',
        EXISTS(
            SELECT 1 FROM bookings
            WHERE booking_id = v_booking_id
            AND status = 'Completed'
        )
    );
    
    PERFORM test.assert_true(
        'Final: Room vacant and dirty',
        EXISTS(
            SELECT 1 FROM rooms
            WHERE room_id = v_room_id
            AND occupancy_status = 'Vacant'
            AND housekeeping_status = 'Dirty'
        )
    );
    
    RAISE NOTICE 'Test full_booking_flow completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MAIN TEST RUNNER
-- ============================================================================

CREATE OR REPLACE FUNCTION test.run_all_tests()
RETURNS void AS $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'RUNNING INTEGRATION TESTS FOR POSTGRESQL FUNCTIONS';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    
    -- Test Suite 1: create_booking_hold
    PERFORM test.test_create_booking_hold_success();
    PERFORM test.test_create_booking_hold_no_availability();
    PERFORM test.test_create_booking_hold_race_condition();
    
    -- Test Suite 2: confirm_booking
    PERFORM test.test_confirm_booking_success();
    PERFORM test.test_confirm_booking_invalid_status();
    
    -- Test Suite 3: check_in
    PERFORM test.test_check_in_success();
    PERFORM test.test_check_in_room_not_ready();
    PERFORM test.test_check_in_room_occupied();
    
    -- Test Suite 4: check_out
    PERFORM test.test_check_out_success();
    PERFORM test.test_check_out_invalid_status();
    
    -- Test Suite 5: Rollback Scenarios
    PERFORM test.test_rollback_on_constraint_violation();
    PERFORM test.test_rollback_on_inventory_violation();
    
    -- Test Suite 6: Constraint Violations
    PERFORM test.test_inventory_constraint_violation();
    PERFORM test.test_date_constraint_violation();
    PERFORM test.test_status_constraint_violation();
    
    -- Test Suite 7: Complex Integration
    PERFORM test.test_full_booking_flow();
    
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'ALL INTEGRATION TESTS COMPLETED';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RUN TESTS
-- ============================================================================

-- Execute all tests
SELECT test.run_all_tests();

-- Cleanup
DROP SCHEMA IF EXISTS test CASCADE;
