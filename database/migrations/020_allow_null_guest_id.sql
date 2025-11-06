-- Migration 020: Allow NULL guest_id for guest bookings
-- This allows bookings without user accounts (guest bookings)

BEGIN;

-- Make guest_id nullable in bookings table
ALTER TABLE bookings 
ALTER COLUMN guest_id DROP NOT NULL;

-- Add comment
COMMENT ON COLUMN bookings.guest_id IS 'Guest account ID (NULL for guest bookings without account)';

COMMIT;

-- Verification
SELECT 
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_name = 'bookings' 
  AND column_name = 'guest_id';
