-- Update existing bookings to add phone numbers for testing
-- This adds mock phone numbers to existing booking_guests records

-- Update primary guests with mock phone numbers
UPDATE booking_guests
SET phone = '0918384976'
WHERE is_primary = true AND phone IS NULL
LIMIT 5;

-- Verify the update
SELECT bg.booking_guest_id, bg.first_name, bg.last_name, bg.phone, bg.is_primary, bd.booking_id
FROM booking_guests bg
JOIN booking_details bd ON bg.booking_detail_id = bd.booking_detail_id
WHERE bg.phone IS NOT NULL
ORDER BY bg.booking_guest_id DESC
LIMIT 10;
