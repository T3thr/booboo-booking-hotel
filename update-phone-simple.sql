-- Simple update for testing - run this in Neon SQL Editor

-- Update primary guests with mock phone numbers
UPDATE booking_guests
SET phone = '0918384976'
WHERE booking_guest_id IN (
    SELECT booking_guest_id
    FROM booking_guests
    WHERE is_primary = true AND phone IS NULL
    LIMIT 5
);

-- Verify the update
SELECT bg.booking_guest_id, bg.first_name, bg.last_name, bg.phone, bg.is_primary, bd.booking_id
FROM booking_guests bg
JOIN booking_details bd ON bg.booking_detail_id = bd.booking_detail_id
WHERE bg.phone IS NOT NULL
ORDER BY bg.booking_guest_id DESC
LIMIT 10;
