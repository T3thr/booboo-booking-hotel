-- ============================================================================
-- Migration 021: Add Email and Phone to Booking Guests
-- ============================================================================
-- Description: Adds email and phone columns to booking_guests table
--              to store contact information for primary guests
-- ============================================================================

-- Add phone column (nullable, as not all guests need to provide phone)
ALTER TABLE booking_guests 
ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Add email column (nullable, only required for non-signed-in primary guests)
ALTER TABLE booking_guests 
ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- Add index for phone lookups
CREATE INDEX IF NOT EXISTS idx_booking_guests_phone 
ON booking_guests(phone) 
WHERE phone IS NOT NULL;

-- Add index for email lookups
CREATE INDEX IF NOT EXISTS idx_booking_guests_email 
ON booking_guests(email) 
WHERE email IS NOT NULL;

-- Comments
COMMENT ON COLUMN booking_guests.phone IS 'Contact phone number for the guest (required for primary guest)';
COMMENT ON COLUMN booking_guests.email IS 'Email address for the guest (required for non-signed-in primary guest)';

-- Verification query
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'booking_guests'
AND column_name IN ('phone', 'email')
ORDER BY ordinal_position;
