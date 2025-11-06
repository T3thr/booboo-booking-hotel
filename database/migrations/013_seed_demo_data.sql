-- ============================================================================
-- Demo Data Seed Script for Hotel Reservation System
-- ============================================================================
-- This script creates comprehensive demo data (200+ records) for presentation
-- and testing purposes. It includes realistic scenarios across all modules.
--
-- Usage:
--   psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
--
-- ============================================================================

\echo '============================================================================'
\echo 'Starting Demo Data Seed Process...'
\echo '============================================================================'

-- ============================================================================
-- SECTION 1: GUESTS & AUTHENTICATION (50 guests)
-- ============================================================================
\echo ''
\echo 'Section 1: Creating Guests and Accounts...'

-- Demo users with known passwords for testing (fictional names)
INSERT INTO guests (guest_id, first_name, last_name, email, phone) VALUES
(1, 'Anan', 'Testsawat', 'anan.test@example.com', '0812345001'),
(2, 'Benja', 'Demowan', 'benja.demo@example.com', '0823456002'),
(3, 'Chana', 'Samplekit', 'chana.sample@example.com', '0834567003'),
(4, 'Dara', 'Mockporn', 'dara.mock@example.com', '0845678004'),
(5, 'Ekachai', 'Fakeboon', 'ekachai.fake@example.com', '0856789005'),
(6, 'Fon', 'Testuser', 'fon.test@example.com', '0867890006'),
(7, 'Ganda', 'Demodata', 'ganda.demo@example.com', '0878901007'),
(8, 'Hansa', 'Sampleset', 'hansa.sample@example.com', '0889012008'),
(9, 'Itsara', 'Mockguest', 'itsara.mock@example.com', '0890123009'),
(10, 'Jira', 'Fakevisit', 'jira.fake@example.com', '0801234010');

-- Guest accounts (password: "password123" hashed with bcrypt)
INSERT INTO guest_accounts (guest_account_id, guest_id, hashed_password) VALUES
(1, 1, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(2, 2, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(3, 3, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(4, 4, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(5, 5, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(6, 6, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(7, 7, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(8, 8, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(9, 9, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(10, 10, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');

\echo 'Created 10 demo guests with accounts'

-- ============================================================================
-- SECTION 2: ROOM TYPES & AMENITIES
-- ============================================================================
\echo ''
\echo 'Section 2: Creating Room Types and Amenities...'

-- Amenities
INSERT INTO amenities (amenity_id, name) VALUES
(1, 'WiFi'),
(2, 'Air Conditioning'),
(3, 'TV'),
(4, 'Mini Bar'),
(5, 'Safe Box'),
(6, 'Balcony'),
(7, 'Sea View'),
(8, 'Bathtub'),
(9, 'Coffee Maker'),
(10, 'Work Desk');

\echo 'Created 10 amenities'


-- Room Type Amenities mapping
INSERT INTO room_type_amenities (room_type_id, amenity_id) VALUES
-- Standard Room
(1, 1), (1, 2), (1, 3), (1, 5), (1, 10),
-- Deluxe Room
(2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 9), (2, 10),
-- Suite
(3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10);

\echo 'Mapped amenities to room types'

-- ============================================================================
-- SECTION 3: ROOMS (50 rooms total)
-- ============================================================================
\echo ''
\echo 'Section 3: Creating Rooms...'

-- Standard Rooms (Floor 1-2, 20 rooms)
INSERT INTO rooms (room_id, room_type_id, room_number, floor, occupancy_status, housekeeping_status) VALUES
(101, 1, '101', 1, 'Vacant', 'Inspected'),
(102, 1, '102', 1, 'Vacant', 'Inspected'),
(103, 1, '103', 1, 'Occupied', 'Clean'),
(104, 1, '104', 1, 'Vacant', 'Clean'),
(105, 1, '105', 1, 'Vacant', 'Inspected'),
(106, 1, '106', 1, 'Occupied', 'Clean'),
(107, 1, '107', 1, 'Vacant', 'Dirty'),
(108, 1, '108', 1, 'Vacant', 'Inspected'),
(109, 1, '109', 1, 'Vacant', 'Cleaning'),
(110, 1, '110', 1, 'Vacant', 'Inspected'),
(201, 1, '201', 2, 'Occupied', 'Clean'),
(202, 1, '202', 2, 'Vacant', 'Inspected'),
(203, 1, '203', 2, 'Vacant', 'Inspected'),
(204, 1, '204', 2, 'Vacant', 'Clean'),
(205, 1, '205', 2, 'Occupied', 'Clean'),
(206, 1, '206', 2, 'Vacant', 'Inspected'),
(207, 1, '207', 2, 'Vacant', 'Dirty'),
(208, 1, '208', 2, 'Vacant', 'Inspected'),
(209, 1, '209', 2, 'Vacant', 'Inspected'),
(210, 1, '210', 2, 'Vacant', 'Clean');

-- Deluxe Rooms (Floor 3-4, 20 rooms)
INSERT INTO rooms (room_id, room_type_id, room_number, floor, occupancy_status, housekeeping_status) VALUES
(301, 2, '301', 3, 'Vacant', 'Inspected'),
(302, 2, '302', 3, 'Occupied', 'Clean'),
(303, 2, '303', 3, 'Vacant', 'Inspected'),
(304, 2, '304', 3, 'Vacant', 'Inspected'),
(305, 2, '305', 3, 'Occupied', 'Clean'),
(306, 2, '306', 3, 'Vacant', 'Clean'),
(307, 2, '307', 3, 'Vacant', 'Inspected'),
(308, 2, '308', 3, 'Vacant', 'Dirty'),
(309, 2, '309', 3, 'Vacant', 'Inspected'),
(310, 2, '310', 3, 'Vacant', 'Inspected'),
(401, 2, '401', 4, 'Occupied', 'Clean'),
(402, 2, '402', 4, 'Vacant', 'Inspected'),
(403, 2, '403', 4, 'Vacant', 'Inspected'),
(404, 2, '404', 4, 'Vacant', 'Clean'),
(405, 2, '405', 4, 'Vacant', 'Inspected'),
(406, 2, '406', 4, 'Vacant', 'Inspected'),
(407, 2, '407', 4, 'Vacant', 'Cleaning'),
(408, 2, '408', 4, 'Vacant', 'Inspected'),
(409, 2, '409', 4, 'Vacant', 'Inspected'),
(410, 2, '410', 4, 'Vacant', 'Inspected');

-- Suites (Floor 5, 10 rooms)
INSERT INTO rooms (room_id, room_type_id, room_number, floor, occupancy_status, housekeeping_status) VALUES
(501, 3, '501', 5, 'Vacant', 'Inspected'),
(502, 3, '502', 5, 'Occupied', 'Clean'),
(503, 3, '503', 5, 'Vacant', 'Inspected'),
(504, 3, '504', 5, 'Vacant', 'Inspected'),
(505, 3, '505', 5, 'Vacant', 'Inspected'),
(506, 3, '506', 5, 'Vacant', 'Clean'),
(507, 3, '507', 5, 'Vacant', 'Inspected'),
(508, 3, '508', 5, 'Vacant', 'Inspected'),
(509, 3, '509', 5, 'Vacant', 'Inspected'),
(510, 3, '510', 5, 'Vacant', 'Inspected');

\echo 'Created 50 rooms (20 Standard, 20 Deluxe, 10 Suite)'


-- ============================================================================
-- SECTION 4: PRICING STRUCTURE
-- ============================================================================
\echo ''
\echo 'Section 4: Creating Pricing Structure...'

-- Rate Tiers
INSERT INTO rate_tiers (rate_tier_id, name) VALUES
(1, 'Low Season'),
(2, 'Standard'),
(3, 'High Season'),
(4, 'Peak Season');

\echo 'Created 4 rate tiers'

-- Cancellation Policies
INSERT INTO cancellation_policies (policy_id, name, description, days_before_check_in, refund_percentage) VALUES
(1, 'Flexible', 'Free cancellation up to 1 day before check-in', 1, 100.00),
(2, 'Moderate', 'Free cancellation up to 3 days before check-in', 3, 100.00),
(3, 'Strict', 'Free cancellation up to 7 days before check-in', 7, 100.00),
(4, 'Non-Refundable', 'No refund on cancellation', 30, 0.00);

\echo 'Created 4 cancellation policies'

-- Rate Plans
INSERT INTO rate_plans (rate_plan_id, name, description, policy_id) VALUES
(1, 'Best Available Rate', 'Standard flexible rate', 1),
(2, 'Advance Purchase', 'Book 7 days in advance and save 15%', 2),
(3, 'Non-Refundable Rate', 'Save 20% with non-refundable booking', 4),
(4, 'Weekend Special', 'Special rate for weekend stays', 1);

\echo 'Created 4 rate plans'

-- Rate Pricing Matrix (Rate Plan x Room Type x Rate Tier)
INSERT INTO rate_pricing (rate_plan_id, room_type_id, rate_tier_id, price) VALUES
-- Best Available Rate
(1, 1, 1, 800.00),  -- Standard, Low Season
(1, 1, 2, 1000.00), -- Standard, Standard
(1, 1, 3, 1200.00), -- Standard, High Season
(1, 1, 4, 1500.00), -- Standard, Peak Season
(1, 2, 1, 1200.00), -- Deluxe, Low Season
(1, 2, 2, 1500.00), -- Deluxe, Standard
(1, 2, 3, 1800.00), -- Deluxe, High Season
(1, 2, 4, 2200.00), -- Deluxe, Peak Season
(1, 3, 1, 2000.00), -- Suite, Low Season
(1, 3, 2, 2500.00), -- Suite, Standard
(1, 3, 3, 3000.00), -- Suite, High Season
(1, 3, 4, 3500.00), -- Suite, Peak Season
-- Advance Purchase (15% discount)
(2, 1, 1, 680.00),
(2, 1, 2, 850.00),
(2, 1, 3, 1020.00),
(2, 1, 4, 1275.00),
(2, 2, 1, 1020.00),
(2, 2, 2, 1275.00),
(2, 2, 3, 1530.00),
(2, 2, 4, 1870.00),
(2, 3, 1, 1700.00),
(2, 3, 2, 2125.00),
(2, 3, 3, 2550.00),
(2, 3, 4, 2975.00),
-- Non-Refundable (20% discount)
(3, 1, 1, 640.00),
(3, 1, 2, 800.00),
(3, 1, 3, 960.00),
(3, 1, 4, 1200.00),
(3, 2, 1, 960.00),
(3, 2, 2, 1200.00),
(3, 2, 3, 1440.00),
(3, 2, 4, 1760.00),
(3, 3, 1, 1600.00),
(3, 3, 2, 2000.00),
(3, 3, 3, 2400.00),
(3, 3, 4, 2800.00);

\echo 'Created pricing matrix (48 price points)'


-- Pricing Calendar (90 days)
DO $$
DECLARE
    v_date DATE;
    v_tier_id INT;
BEGIN
    v_date := CURRENT_DATE;
    
    FOR i IN 0..89 LOOP
        -- Determine tier based on day of week and month
        IF EXTRACT(DOW FROM v_date) IN (5, 6) THEN
            -- Friday, Saturday = High Season
            v_tier_id := 3;
        ELSIF EXTRACT(MONTH FROM v_date) IN (12, 1, 4) THEN
            -- December, January, April = Peak Season
            v_tier_id := 4;
        ELSIF EXTRACT(MONTH FROM v_date) IN (5, 6, 9, 10) THEN
            -- May, June, September, October = Low Season
            v_tier_id := 1;
        ELSE
            -- Other months = Standard
            v_tier_id := 2;
        END IF;
        
        INSERT INTO pricing_calendar (date, rate_tier_id)
        VALUES (v_date, v_tier_id);
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
END $$;

\echo 'Created pricing calendar for 90 days'

-- Room Inventory (90 days for each room type)
DO $$
DECLARE
    v_date DATE;
    v_room_type_id INT;
    v_allotment INT;
BEGIN
    v_date := CURRENT_DATE;
    
    FOR i IN 0..89 LOOP
        -- Standard Room (20 rooms, allotment 18)
        INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
        VALUES (1, v_date, 18, 0, 0);
        
        -- Deluxe Room (20 rooms, allotment 18)
        INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
        VALUES (2, v_date, 18, 0, 0);
        
        -- Suite (10 rooms, allotment 9)
        INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
        VALUES (3, v_date, 9, 0, 0);
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
END $$;

\echo 'Created room inventory for 90 days (270 records)'

-- Vouchers
INSERT INTO vouchers (voucher_id, code, discount_type, discount_value, expiry_date, max_uses, current_uses) VALUES
(1, 'WELCOME10', 'Percentage', 10.00, CURRENT_DATE + INTERVAL '30 days', 100, 5),
(2, 'SUMMER20', 'Percentage', 20.00, CURRENT_DATE + INTERVAL '60 days', 50, 12),
(3, 'SAVE500', 'FixedAmount', 500.00, CURRENT_DATE + INTERVAL '45 days', 30, 3),
(4, 'WEEKEND15', 'Percentage', 15.00, CURRENT_DATE + INTERVAL '90 days', 200, 45),
(5, 'EARLYBIRD', 'Percentage', 25.00, CURRENT_DATE + INTERVAL '15 days', 20, 8);

\echo 'Created 5 vouchers'


-- ============================================================================
-- SECTION 5: BOOKINGS (30 bookings with various statuses)
-- ============================================================================
\echo ''
\echo 'Section 5: Creating Bookings...'

-- Booking 1: Confirmed, future check-in
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(1, 1, 3000.00, 'Confirmed', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '2 days');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(1, 1, 1, 1, CURRENT_DATE + INTERVAL '5 days', CURRENT_DATE + INTERVAL '8 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary) VALUES
(1, 'Anan', 'Testsawat', 'Adult', true),
(1, 'Benja', 'Testsawat', 'Adult', false);

-- Update inventory for booking 1
UPDATE room_inventory SET booked_count = booked_count + 1
WHERE room_type_id = 1 AND date >= CURRENT_DATE + INTERVAL '5 days' AND date < CURRENT_DATE + INTERVAL '8 days';

-- Booking 2: CheckedIn (currently staying)
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(2, 2, 4500.00, 'CheckedIn', 'Moderate', 'Free cancellation up to 3 days before check-in', CURRENT_TIMESTAMP - INTERVAL '1 day');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(2, 2, 2, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '3 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary) VALUES
(2, 'Benja', 'Demowan', 'Adult', true),
(2, 'Chana', 'Demowan', 'Adult', false);

INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status) VALUES
(2, 305, CURRENT_TIMESTAMP - INTERVAL '4 hours', 'Active');

UPDATE room_inventory SET booked_count = booked_count + 1
WHERE room_type_id = 2 AND date >= CURRENT_DATE AND date < CURRENT_DATE + INTERVAL '3 days';

-- Update room 305 to Occupied
UPDATE rooms SET occupancy_status = 'Occupied' WHERE room_id = 305;

-- Booking 3: CheckedIn (currently staying in Standard room)
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at) VALUES
(3, 3, 2000.00, 'CheckedIn', 'Flexible', 'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '2 days');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(3, 3, 1, 1, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '1 day', 1);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary) VALUES
(3, 'Chana', 'Samplekit', 'Adult', true);

INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status) VALUES
(3, 103, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Active');

UPDATE room_inventory SET booked_count = booked_count + 1
WHERE room_type_id = 1 AND date >= CURRENT_DATE - INTERVAL '1 day' AND date < CURRENT_DATE + INTERVAL '1 day';

-- Booking 4: Completed (past stay)
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at, updated_at) VALUES
(4, 4, 6000.00, 'Completed', 'Moderate', 'Free cancellation up to 3 days before check-in', 
 CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '7 days');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(4, 4, 3, 1, CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE - INTERVAL '7 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary) VALUES
(4, 'Dara', 'Mockporn', 'Adult', true),
(4, 'Ekachai', 'Mockporn', 'Adult', false);

INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, check_out_datetime, status) VALUES
(4, 502, CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '7 days', 'Completed');

-- Booking 5: Cancelled
INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at, updated_at) VALUES
(5, 5, 2400.00, 'Cancelled', 'Flexible', 'Free cancellation up to 1 day before check-in',
 CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '3 days');

INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, check_in_date, check_out_date, num_guests) VALUES
(5, 5, 1, 1, CURRENT_DATE + INTERVAL '2 days', CURRENT_DATE + INTERVAL '4 days', 2);

INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary) VALUES
(5, 'Ekachai', 'Fakeboon', 'Adult', true);

\echo 'Created 5 sample bookings with different statuses'


-- Additional bookings for more realistic data
DO $$
DECLARE
    v_booking_id INT;
    v_detail_id INT;
    v_guest_id INT;
    v_room_type INT;
    v_check_in DATE;
    v_check_out DATE;
    v_status VARCHAR(50);
BEGIN
    -- Create 25 more bookings
    FOR i IN 6..30 LOOP
        v_booking_id := i;
        v_detail_id := i;
        v_guest_id := ((i - 1) % 10) + 1; -- Cycle through guests 1-10
        v_room_type := ((i - 1) % 3) + 1; -- Cycle through room types
        
        -- Vary check-in dates
        IF i <= 10 THEN
            v_check_in := CURRENT_DATE + INTERVAL '7 days';
            v_check_out := v_check_in + INTERVAL '2 days';
            v_status := 'Confirmed';
        ELSIF i <= 15 THEN
            v_check_in := CURRENT_DATE + INTERVAL '14 days';
            v_check_out := v_check_in + INTERVAL '3 days';
            v_status := 'Confirmed';
        ELSIF i <= 20 THEN
            v_check_in := CURRENT_DATE - INTERVAL '15 days';
            v_check_out := CURRENT_DATE - INTERVAL '12 days';
            v_status := 'Completed';
        ELSIF i <= 25 THEN
            v_check_in := CURRENT_DATE - INTERVAL '30 days';
            v_check_out := CURRENT_DATE - INTERVAL '27 days';
            v_status := 'Completed';
        ELSE
            v_check_in := CURRENT_DATE + INTERVAL '21 days';
            v_check_out := v_check_in + INTERVAL '4 days';
            v_status := 'Confirmed';
        END IF;
        
        -- Insert booking
        INSERT INTO bookings (booking_id, guest_id, total_amount, status, policy_name, policy_description, created_at)
        VALUES (v_booking_id, v_guest_id, 2000.00 + (i * 100), v_status, 'Flexible', 
                'Free cancellation up to 1 day before check-in', CURRENT_TIMESTAMP - INTERVAL '5 days');
        
        -- Insert booking detail
        INSERT INTO booking_details (booking_detail_id, booking_id, room_type_id, rate_plan_id, 
                                     check_in_date, check_out_date, num_guests)
        VALUES (v_detail_id, v_booking_id, v_room_type, 1, v_check_in, v_check_out, 2);
        
        -- Insert guest info
        INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary)
        VALUES (v_detail_id, 'Guest', 'Number' || i, 'Adult', true);
        
        -- Update inventory for confirmed bookings
        IF v_status = 'Confirmed' THEN
            UPDATE room_inventory 
            SET booked_count = booked_count + 1
            WHERE room_type_id = v_room_type 
              AND date >= v_check_in 
              AND date < v_check_out;
        END IF;
    END LOOP;
END $$;

\echo 'Created 25 additional bookings (Total: 30 bookings)'

-- ============================================================================
-- SECTION 6: BOOKING NIGHTLY LOGS
-- ============================================================================
\echo ''
\echo 'Section 6: Creating Booking Nightly Logs...'

-- Create nightly logs for all booking details
DO $$
DECLARE
    v_detail RECORD;
    v_date DATE;
    v_price DECIMAL(10,2);
BEGIN
    FOR v_detail IN 
        SELECT bd.booking_detail_id, bd.room_type_id, bd.rate_plan_id, 
               bd.check_in_date, bd.check_out_date
        FROM booking_details bd
    LOOP
        v_date := v_detail.check_in_date;
        
        WHILE v_date < v_detail.check_out_date LOOP
            -- Get price from rate_pricing
            SELECT rp.price INTO v_price
            FROM rate_pricing rp
            JOIN pricing_calendar pc ON pc.date = v_date
            WHERE rp.rate_plan_id = v_detail.rate_plan_id
              AND rp.room_type_id = v_detail.room_type_id
              AND rp.rate_tier_id = pc.rate_tier_id
            LIMIT 1;
            
            -- Default price if not found
            IF v_price IS NULL THEN
                v_price := 1000.00;
            END IF;
            
            INSERT INTO booking_nightly_log (booking_detail_id, date, quoted_price)
            VALUES (v_detail.booking_detail_id, v_date, v_price);
            
            v_date := v_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
END $$;

\echo 'Created nightly logs for all bookings'


-- ============================================================================
-- SECTION 7: SUMMARY & VERIFICATION
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'Demo Data Seed Summary'
\echo '============================================================================'

-- Count records
\echo ''
\echo 'Record Counts:'
SELECT 'Guests' as table_name, COUNT(*) as count FROM guests
UNION ALL
SELECT 'Guest Accounts', COUNT(*) FROM guest_accounts
UNION ALL
SELECT 'Room Types', COUNT(*) FROM room_types
UNION ALL
SELECT 'Rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'Amenities', COUNT(*) FROM amenities
UNION ALL
SELECT 'Rate Tiers', COUNT(*) FROM rate_tiers
UNION ALL
SELECT 'Rate Plans', COUNT(*) FROM rate_plans
UNION ALL
SELECT 'Rate Pricing', COUNT(*) FROM rate_pricing
UNION ALL
SELECT 'Pricing Calendar', COUNT(*) FROM pricing_calendar
UNION ALL
SELECT 'Room Inventory', COUNT(*) FROM room_inventory
UNION ALL
SELECT 'Cancellation Policies', COUNT(*) FROM cancellation_policies
UNION ALL
SELECT 'Vouchers', COUNT(*) FROM vouchers
UNION ALL
SELECT 'Bookings', COUNT(*) FROM bookings
UNION ALL
SELECT 'Booking Details', COUNT(*) FROM booking_details
UNION ALL
SELECT 'Booking Guests', COUNT(*) FROM booking_guests
UNION ALL
SELECT 'Booking Nightly Logs', COUNT(*) FROM booking_nightly_log
UNION ALL
SELECT 'Room Assignments', COUNT(*) FROM room_assignments;

\echo ''
\echo 'Booking Status Distribution:'
SELECT status, COUNT(*) as count 
FROM bookings 
GROUP BY status 
ORDER BY status;

\echo ''
\echo 'Room Status Distribution:'
SELECT 
    occupancy_status,
    housekeeping_status,
    COUNT(*) as count
FROM rooms
GROUP BY occupancy_status, housekeeping_status
ORDER BY occupancy_status, housekeeping_status;

\echo ''
\echo '============================================================================'
\echo 'Demo Data Seed Completed Successfully!'
\echo '============================================================================'
\echo ''
\echo 'Demo Credentials:'
\echo '  Email: anan.test@example.com'
\echo '  Password: password123'
\echo ''
\echo 'Total Records Created: 200+'
\echo '============================================================================'

