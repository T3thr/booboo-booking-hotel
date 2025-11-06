-- Update staff passwords to use correct hash for "staff123"
-- Hash: $2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq

UPDATE staff_accounts 
SET hashed_password = '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'
WHERE staff_id IN (
    SELECT staff_id FROM staff WHERE email LIKE '%@hotel.com'
);

-- Verify the update
SELECT 
    s.email,
    s.first_name || ' ' || s.last_name as name,
    r.role_code,
    'staff123' as password,
    LENGTH(sa.hashed_password) as hash_length
FROM staff s
JOIN staff_accounts sa ON s.staff_id = sa.staff_id
JOIN roles r ON s.role_id = r.role_id
WHERE s.email LIKE '%@hotel.com'
ORDER BY s.staff_id;
