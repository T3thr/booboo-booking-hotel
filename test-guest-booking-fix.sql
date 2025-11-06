-- Test that guest_id can be NULL in bookings table

-- Check column definition
SELECT 
    column_name,
    is_nullable,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_name = 'bookings' 
  AND column_name = 'guest_id';

-- Try to insert a test booking with NULL guest_id
BEGIN;

INSERT INTO bookings (
    guest_id, 
    total_amount, 
    status, 
    policy_name, 
    policy_description
) VALUES (
    NULL,  -- This should work now
    1000.00,
    'PendingPayment',
    'Test Policy',
    'Test Description'
) RETURNING booking_id, guest_id, status;

-- Rollback the test insert
ROLLBACK;

SELECT 'Migration 020 successful - guest_id can be NULL' AS result;
