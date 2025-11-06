-- ===================================================================
-- Fix Staff Password Hashes
-- Description: Update staff passwords to use correct bcrypt hash
-- ===================================================================

-- Generate new hash for password "staff123" using bcrypt cost 10
-- This hash was generated using: bcrypt.GenerateFromPassword([]byte("staff123"), 10)
-- Hash: $2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq

-- Update all staff accounts with the correct hash
UPDATE staff_accounts 
SET hashed_password = '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'
WHERE staff_id IN (
    SELECT staff_id FROM staff WHERE email LIKE '%@hotel.com'
);

-- Verify the update
SELECT 
    s.staff_id,
    s.email,
    s.first_name,
    s.last_name,
    r.role_code,
    LENGTH(sa.hashed_password) as hash_length
FROM staff s
JOIN staff_accounts sa ON s.staff_id = sa.staff_id
JOIN roles r ON s.role_id = r.role_id
WHERE s.email LIKE '%@hotel.com'
ORDER BY s.staff_id;

-- ===================================================================
-- Password: staff123
-- All staff can login with this password
-- ===================================================================
