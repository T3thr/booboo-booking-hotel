-- ============================================================================
-- Migration 004: Create Bookings Tables
-- ============================================================================
-- Description: Creates tables for managing bookings, booking details,
--              room assignments, booking guests, and nightly logs
-- Requirements: 3.1-3.8, 4.1-4.9, 5.1-5.7, 6.1-6.9
-- ============================================================================

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS booking_nightly_log CASCADE;
DROP TABLE IF EXISTS booking_guests CASCADE;
DROP TABLE IF EXISTS room_assignments CASCADE;
DROP TABLE IF EXISTS booking_details CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;

-- ============================================================================
-- Table: bookings
-- ============================================================================
-- Purpose: Main booking records with status tracking and policy snapshots
-- Key Features:
--   - Stores snapshot of cancellation policy at booking time (immutable)
--   - Tracks booking lifecycle through status field
--   - Links to guest and optional voucher
-- ============================================================================

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT NOT NULL REFERENCES guests(guest_id) ON DELETE RESTRICT,
    voucher_id INT REFERENCES vouchers(voucher_id) ON DELETE SET NULL,
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    status VARCHAR(50) NOT NULL DEFAULT 'PendingPayment'
        CHECK (status IN ('PendingPayment', 'Confirmed', 'CheckedIn', 
               'Completed', 'Cancelled', 'NoShow')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Policy snapshot (immutable - captured at booking time)
    policy_name VARCHAR(100) NOT NULL,
    policy_description TEXT NOT NULL,
    
    -- Metadata
    CONSTRAINT chk_total_amount_positive CHECK (total_amount >= 0)
);

-- Indexes for bookings
CREATE INDEX idx_bookings_guest ON bookings(guest_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);
CREATE INDEX idx_bookings_voucher ON bookings(voucher_id) WHERE voucher_id IS NOT NULL;

-- Comments
COMMENT ON TABLE bookings IS 'Main booking records with policy snapshots';
COMMENT ON COLUMN bookings.policy_name IS 'Snapshot of cancellation policy name at booking time';
COMMENT ON COLUMN bookings.policy_description IS 'Snapshot of cancellation policy description at booking time';
COMMENT ON COLUMN bookings.status IS 'Booking lifecycle: PendingPayment -> Confirmed -> CheckedIn -> Completed (or Cancelled/NoShow)';

-- ============================================================================
-- Table: booking_details
-- ============================================================================
-- Purpose: Individual room bookings within a booking (supports multi-room)
-- Key Features:
--   - One booking can have multiple booking_details (multiple rooms)
--   - Links to room_type and rate_plan for pricing
--   - Stores check-in/check-out dates
-- ============================================================================

CREATE TABLE booking_details (
    booking_detail_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id) ON DELETE RESTRICT,
    rate_plan_id INT NOT NULL REFERENCES rate_plans(rate_plan_id) ON DELETE RESTRICT,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    num_guests INT NOT NULL CHECK (num_guests > 0),
    
    -- Constraints
    CONSTRAINT chk_date_order CHECK (check_out_date > check_in_date),
    CONSTRAINT chk_num_guests_positive CHECK (num_guests > 0)
);

-- Indexes for booking_details
CREATE INDEX idx_booking_details_booking ON booking_details(booking_id);
CREATE INDEX idx_booking_details_room_type ON booking_details(room_type_id);
CREATE INDEX idx_booking_details_dates ON booking_details(check_in_date, check_out_date);

-- Comments
COMMENT ON TABLE booking_details IS 'Individual room bookings within a booking (supports multi-room bookings)';
COMMENT ON COLUMN booking_details.num_guests IS 'Number of guests for this specific room booking';

-- ============================================================================
-- Table: room_assignments
-- ============================================================================
-- Purpose: Tracks which physical room is assigned to each booking detail
-- Key Features:
--   - Created during check-in process
--   - Supports room moves (status: Active -> Moved)
--   - Maintains complete audit trail of room changes
-- ============================================================================

CREATE TABLE room_assignments (
    room_assignment_id BIGSERIAL PRIMARY KEY,
    booking_detail_id INT NOT NULL REFERENCES booking_details(booking_detail_id) ON DELETE CASCADE,
    room_id INT NOT NULL REFERENCES rooms(room_id) ON DELETE RESTRICT,
    check_in_datetime TIMESTAMP NOT NULL,
    check_out_datetime TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (status IN ('Active', 'Moved', 'Completed')),
    
    -- Constraints
    CONSTRAINT chk_checkout_after_checkin CHECK (
        check_out_datetime IS NULL OR check_out_datetime > check_in_datetime
    )
);

-- Indexes for room_assignments
CREATE INDEX idx_room_assignments_booking_detail ON room_assignments(booking_detail_id);
CREATE INDEX idx_room_assignments_room ON room_assignments(room_id);
CREATE INDEX idx_room_assignments_status ON room_assignments(status);
CREATE INDEX idx_room_assignments_active ON room_assignments(booking_detail_id, status) 
    WHERE status = 'Active';

-- Comments
COMMENT ON TABLE room_assignments IS 'Tracks physical room assignments and supports room moves';
COMMENT ON COLUMN room_assignments.status IS 'Active: currently assigned, Moved: guest moved to another room, Completed: check-out completed';

-- ============================================================================
-- Table: booking_guests
-- ============================================================================
-- Purpose: Stores information about all guests in a booking
-- Key Features:
--   - Captures guest names for each booking detail
--   - Distinguishes between adults and children
--   - Identifies primary guest
-- ============================================================================

CREATE TABLE booking_guests (
    booking_guest_id BIGSERIAL PRIMARY KEY,
    booking_detail_id INT NOT NULL REFERENCES booking_details(booking_detail_id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    type VARCHAR(10) NOT NULL DEFAULT 'Adult' 
        CHECK (type IN ('Adult', 'Child')),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Constraints
    CONSTRAINT chk_first_name_not_empty CHECK (TRIM(first_name) != '')
);

-- Indexes for booking_guests
CREATE INDEX idx_booking_guests_booking_detail ON booking_guests(booking_detail_id);
CREATE INDEX idx_booking_guests_primary ON booking_guests(booking_detail_id, is_primary) 
    WHERE is_primary = TRUE;

-- Comments
COMMENT ON TABLE booking_guests IS 'Information about all guests in a booking';
COMMENT ON COLUMN booking_guests.is_primary IS 'Identifies the primary guest for this booking detail';

-- ============================================================================
-- Table: booking_nightly_log
-- ============================================================================
-- Purpose: Records the quoted price for each night of the stay
-- Key Features:
--   - Immutable price snapshot (protects against future price changes)
--   - One record per night per booking detail
--   - Used for accurate revenue reporting
-- ============================================================================

CREATE TABLE booking_nightly_log (
    booking_nightly_log_id SERIAL PRIMARY KEY,
    booking_detail_id INT NOT NULL REFERENCES booking_details(booking_detail_id) ON DELETE CASCADE,
    date DATE NOT NULL,
    quoted_price DECIMAL(10, 2) NOT NULL CHECK (quoted_price >= 0),
    
    -- Constraints
    CONSTRAINT uq_booking_nightly_log UNIQUE (booking_detail_id, date),
    CONSTRAINT chk_quoted_price_positive CHECK (quoted_price >= 0)
);

-- Indexes for booking_nightly_log
CREATE INDEX idx_booking_nightly_log_booking_detail ON booking_nightly_log(booking_detail_id);
CREATE INDEX idx_booking_nightly_log_date ON booking_nightly_log(date);

-- Comments
COMMENT ON TABLE booking_nightly_log IS 'Immutable snapshot of quoted prices for each night';
COMMENT ON COLUMN booking_nightly_log.quoted_price IS 'Price quoted at booking time (immutable)';

-- ============================================================================
-- Triggers for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Verify tables were created
DO $$
DECLARE
    table_count INT;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN ('bookings', 'booking_details', 'room_assignments', 
                       'booking_guests', 'booking_nightly_log');
    
    IF table_count = 5 THEN
        RAISE NOTICE '✓ All 5 booking tables created successfully';
    ELSE
        RAISE EXCEPTION '✗ Expected 5 tables, found %', table_count;
    END IF;
END $$;

-- Verify indexes
DO $$
DECLARE
    index_count INT;
BEGIN
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND tablename IN ('bookings', 'booking_details', 'room_assignments', 
                      'booking_guests', 'booking_nightly_log');
    
    RAISE NOTICE '✓ Created % indexes for booking tables', index_count;
END $$;

-- Verify foreign key constraints
DO $$
DECLARE
    fk_count INT;
BEGIN
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'public'
    AND constraint_type = 'FOREIGN KEY'
    AND table_name IN ('bookings', 'booking_details', 'room_assignments', 
                       'booking_guests', 'booking_nightly_log');
    
    RAISE NOTICE '✓ Created % foreign key constraints', fk_count;
END $$;

-- ============================================================================
-- Summary
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 004 Completed Successfully';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Created Tables:';
    RAISE NOTICE '  1. bookings - Main booking records';
    RAISE NOTICE '  2. booking_details - Individual room bookings';
    RAISE NOTICE '  3. room_assignments - Physical room assignments';
    RAISE NOTICE '  4. booking_guests - Guest information';
    RAISE NOTICE '  5. booking_nightly_log - Nightly price snapshots';
    RAISE NOTICE '';
    RAISE NOTICE 'Key Features:';
    RAISE NOTICE '  ✓ Policy snapshots (immutable)';
    RAISE NOTICE '  ✓ Multi-room booking support';
    RAISE NOTICE '  ✓ Room move tracking';
    RAISE NOTICE '  ✓ Complete audit trail';
    RAISE NOTICE '  ✓ Price protection';
    RAISE NOTICE '========================================';
END $$;
