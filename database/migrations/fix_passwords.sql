-- Fix password hashes for demo accounts
-- Password: password123
-- Bcrypt hash: $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy

UPDATE guest_accounts 
SET hashed_password = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE guest_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

-- Verify the update
SELECT ga.guest_account_id, ga.guest_id, g.email, 
       CASE 
         WHEN ga.hashed_password = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy' 
         THEN 'FIXED' 
         ELSE 'OLD' 
       END as status
FROM guest_accounts ga
JOIN guests g ON g.guest_id = ga.guest_id
WHERE ga.guest_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
ORDER BY ga.guest_id;
