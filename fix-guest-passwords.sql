-- Fix guest account passwords
-- Password for all: password123

UPDATE guest_accounts 
SET hashed_password = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE guest_id IN (
    SELECT guest_id FROM guests 
    WHERE email IN (
        'somchai@example.com',
        'somying@example.com', 
        'prayut@example.com',
        'yingluck@example.com',
        'abhisit@example.com'
    )
);

-- Create anan.test@example.com if not exists
INSERT INTO guests (first_name, last_name, email, phone) 
VALUES ('Anan', 'Testsawat', 'anan.test@example.com', '0812345001')
ON CONFLICT (email) DO UPDATE SET first_name = EXCLUDED.first_name;

-- Add account for anan.test
INSERT INTO guest_accounts (guest_id, hashed_password)
SELECT guest_id, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
FROM guests 
WHERE email = 'anan.test@example.com'
ON CONFLICT (guest_id) DO UPDATE SET hashed_password = EXCLUDED.hashed_password;

-- Verify
SELECT g.email, LEFT(ga.hashed_password, 20) as hash_preview
FROM guests g
JOIN guest_accounts ga ON g.guest_id = ga.guest_id
WHERE g.email IN ('somchai@example.com', 'anan.test@example.com')
ORDER BY g.email;
