-- ============================================================================
-- Migration 015: Create Payment Proof Table
-- ============================================================================
-- This migration creates a table to store payment proof information
-- for manual payment verification (mockup payment system)
--
-- Usage:
--   psql -U postgres -d hotel_booking -f 015_create_payment_proof_table.sql
--
-- ============================================================================

\echo '============================================================================'
\echo 'Migration 015: Creating Payment Proof Table...'
\echo '============================================================================'

-- ============================================================================
-- SECTION 1: CREATE PAYMENT PROOF TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_proofs (
    payment_proof_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('bank_transfer', 'qr_code', 'credit_card', 'cash')),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    proof_url TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    verified_by INT REFERENCES staff(staff_id),
    verified_at TIMESTAMP,
    rejection_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_payment_proofs_booking_id ON payment_proofs(booking_id);
CREATE INDEX idx_payment_proofs_status ON payment_proofs(status);
CREATE INDEX idx_payment_proofs_created_at ON payment_proofs(created_at);

-- Create updated_at trigger
CREATE TRIGGER update_payment_proofs_updated_at
    BEFORE UPDATE ON payment_proofs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

\echo 'Payment proof table created successfully'

-- ============================================================================
-- SECTION 2: ADD PAYMENT STATUS TO BOOKINGS
-- ============================================================================

-- Add payment_status column to bookings table if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bookings' AND column_name = 'payment_status'
    ) THEN
        ALTER TABLE bookings 
        ADD COLUMN payment_status VARCHAR(20) DEFAULT 'pending' 
        CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed'));
        
        \echo 'Added payment_status column to bookings table';
    END IF;
END $$;

-- Create index on payment_status
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON bookings(payment_status);

\echo 'Payment status column added to bookings table'

-- ============================================================================
-- SECTION 3: CREATE VIEWS FOR ADMIN
-- ============================================================================

-- View for pending payment verifications
CREATE OR REPLACE VIEW pending_payment_verifications AS
SELECT 
    pp.payment_proof_id,
    pp.booking_id,
    b.guest_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    g.email AS guest_email,
    g.phone AS guest_phone,
    pp.payment_method,
    pp.amount,
    pp.proof_url,
    pp.status,
    pp.created_at,
    b.total_amount AS booking_total,
    b.status AS booking_status,
    bd.check_in_date,
    bd.check_out_date,
    rt.name AS room_type_name
FROM payment_proofs pp
INNER JOIN bookings b ON pp.booking_id = b.booking_id
INNER JOIN guests g ON b.guest_id = g.guest_id
LEFT JOIN booking_details bd ON b.booking_id = bd.booking_id
LEFT JOIN room_types rt ON bd.room_type_id = rt.room_type_id
WHERE pp.status = 'pending'
ORDER BY pp.created_at ASC;

\echo 'Created pending_payment_verifications view'

-- View for payment verification history
CREATE OR REPLACE VIEW payment_verification_history AS
SELECT 
    pp.payment_proof_id,
    pp.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    pp.payment_method,
    pp.amount,
    pp.status,
    pp.verified_by,
    s.first_name || ' ' || s.last_name AS verified_by_name,
    pp.verified_at,
    pp.rejection_reason,
    pp.created_at
FROM payment_proofs pp
INNER JOIN bookings b ON pp.booking_id = b.booking_id
INNER JOIN guests g ON b.guest_id = g.guest_id
LEFT JOIN staff s ON pp.verified_by = s.staff_id
WHERE pp.status IN ('approved', 'rejected')
ORDER BY pp.verified_at DESC;

\echo 'Created payment_verification_history view'

-- ============================================================================
-- SECTION 4: CREATE FUNCTIONS FOR PAYMENT VERIFICATION
-- ============================================================================

-- Function to approve payment
CREATE OR REPLACE FUNCTION approve_payment(
    p_payment_proof_id INT,
    p_staff_id INT,
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    booking_id INT
) AS $$
DECLARE
    v_booking_id INT;
    v_current_status VARCHAR(20);
BEGIN
    -- Get payment proof details
    SELECT pp.booking_id, pp.status
    INTO v_booking_id, v_current_status
    FROM payment_proofs pp
    WHERE pp.payment_proof_id = p_payment_proof_id;

    IF v_booking_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'ไม่พบหลักฐานการชำระเงิน'::TEXT, NULL::INT;
        RETURN;
    END IF;

    IF v_current_status != 'pending' THEN
        RETURN QUERY SELECT FALSE, 'หลักฐานการชำระเงินนี้ได้รับการตรวจสอบแล้ว'::TEXT, v_booking_id;
        RETURN;
    END IF;

    -- Update payment proof
    UPDATE payment_proofs
    SET status = 'approved',
        verified_by = p_staff_id,
        verified_at = CURRENT_TIMESTAMP,
        notes = p_notes,
        updated_at = CURRENT_TIMESTAMP
    WHERE payment_proof_id = p_payment_proof_id;

    -- Update booking payment status
    UPDATE bookings
    SET payment_status = 'paid',
        updated_at = CURRENT_TIMESTAMP
    WHERE booking_id = v_booking_id;

    -- If booking is PendingPayment, change to Confirmed
    UPDATE bookings
    SET status = 'Confirmed',
        updated_at = CURRENT_TIMESTAMP
    WHERE booking_id = v_booking_id
      AND status = 'PendingPayment';

    RETURN QUERY SELECT TRUE, 'อนุมัติการชำระเงินสำเร็จ'::TEXT, v_booking_id;
END;
$$ LANGUAGE plpgsql;

\echo 'Created approve_payment function'

-- Function to reject payment
CREATE OR REPLACE FUNCTION reject_payment(
    p_payment_proof_id INT,
    p_staff_id INT,
    p_rejection_reason TEXT
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    booking_id INT
) AS $$
DECLARE
    v_booking_id INT;
    v_current_status VARCHAR(20);
BEGIN
    -- Get payment proof details
    SELECT pp.booking_id, pp.status
    INTO v_booking_id, v_current_status
    FROM payment_proofs pp
    WHERE pp.payment_proof_id = p_payment_proof_id;

    IF v_booking_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'ไม่พบหลักฐานการชำระเงิน'::TEXT, NULL::INT;
        RETURN;
    END IF;

    IF v_current_status != 'pending' THEN
        RETURN QUERY SELECT FALSE, 'หลักฐานการชำระเงินนี้ได้รับการตรวจสอบแล้ว'::TEXT, v_booking_id;
        RETURN;
    END IF;

    -- Update payment proof
    UPDATE payment_proofs
    SET status = 'rejected',
        verified_by = p_staff_id,
        verified_at = CURRENT_TIMESTAMP,
        rejection_reason = p_rejection_reason,
        updated_at = CURRENT_TIMESTAMP
    WHERE payment_proof_id = p_payment_proof_id;

    -- Update booking payment status
    UPDATE bookings
    SET payment_status = 'failed',
        updated_at = CURRENT_TIMESTAMP
    WHERE booking_id = v_booking_id;

    RETURN QUERY SELECT TRUE, 'ปฏิเสธการชำระเงินสำเร็จ'::TEXT, v_booking_id;
END;
$$ LANGUAGE plpgsql;

\echo 'Created reject_payment function'

-- ============================================================================
-- SECTION 5: VERIFICATION
-- ============================================================================

\echo ''
\echo 'Verifying migration...'

-- Check if table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_proofs')
        THEN 'payment_proofs table: ✓ EXISTS'
        ELSE 'payment_proofs table: ✗ MISSING'
    END AS table_check;

-- Check if views exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'pending_payment_verifications')
        THEN 'pending_payment_verifications view: ✓ EXISTS'
        ELSE 'pending_payment_verifications view: ✗ MISSING'
    END AS view_check;

-- Check if functions exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'approve_payment')
        THEN 'approve_payment function: ✓ EXISTS'
        ELSE 'approve_payment function: ✗ MISSING'
    END AS function_check;

\echo ''
\echo '============================================================================'
\echo 'Migration 015 completed successfully!'
\echo '============================================================================'
\echo ''
\echo 'New Features:'
\echo '  - Payment proof storage and verification'
\echo '  - Admin views for pending verifications'
\echo '  - Approve/reject payment functions'
\echo '  - Payment status tracking'
\echo '============================================================================'
