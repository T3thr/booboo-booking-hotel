-- Fix Mock Guest Data in Existing Bookings
-- This script updates booking_guests table to use real guest account data
-- for bookings that were created by signed-in users

-- Update booking_guests with real guest account data
-- for primary guests where booking has a guest_id (signed-in user)
UPDATE booking_guests bg
SET 
    first_name = g.first_name,
    last_name = g.last_name,
    email = g.email,
    phone = g.phone
FROM booking_details bd
JOIN bookings b ON bd.booking_id = b.booking_id
JOIN guests g ON b.guest_id = g.guest_id
WHERE bg.booking_detail_id = bd.booking_detail_id
  AND bg.is_primary = true
  AND b.guest_id IS NOT NULL
  -- Only update if current data looks like mock data
  AND (
    bg.first_name IN ('Fon', 'Guest', 'Test') 
    OR bg.last_name IN ('Testuser', 'User', 'Test')
    OR bg.email LIKE '%test%@example.com'
    OR bg.phone LIKE '086789%'
  );

-- Verify the update
SELECT 
    b.booking_id,
    b.guest_id,
    CONCAT(g.first_name, ' ', g.last_name) as account_name,
    g.email as account_email,
    g.phone as account_phone,
    CONCAT(bg.first_name, ' ', bg.last_name) as booking_guest_name,
    bg.email as booking_guest_email,
    bg.phone as booking_guest_phone,
    CASE 
        WHEN bg.first_name = g.first_name 
         AND bg.last_name = g.last_name 
         AND bg.email = g.email 
         AND bg.phone = g.phone 
        THEN 'MATCHED ✓'
        ELSE 'NOT MATCHED ✗'
    END as status
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE bg.is_primary = true
  AND b.guest_id IS NOT NULL
ORDER BY b.booking_id DESC
LIMIT 20;

-- Summary
SELECT 
    COUNT(*) as total_primary_guests_with_account,
    SUM(CASE 
        WHEN bg.first_name = g.first_name 
         AND bg.last_name = g.last_name 
         AND bg.email = g.email 
         AND bg.phone = g.phone 
        THEN 1 ELSE 0 
    END) as matched,
    SUM(CASE 
        WHEN bg.first_name != g.first_name 
          OR bg.last_name != g.last_name 
          OR bg.email != g.email 
          OR bg.phone != g.phone 
        THEN 1 ELSE 0 
    END) as not_matched
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE bg.is_primary = true
  AND b.guest_id IS NOT NULL;
