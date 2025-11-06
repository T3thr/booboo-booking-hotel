-- Migration 017: Add phone column to booking_guests table
-- This adds phone number support for booking guests

-- Add phone column to booking_guests
ALTER TABLE booking_guests 
ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Add comment
COMMENT ON COLUMN booking_guests.phone IS 'Guest phone number for contact';

-- Verify the change
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'booking_guests'
ORDER BY ordinal_position;
