-- ===================================================================
-- Test Script for Guests & Authentication Migration
-- Run this after applying 001_create_guests_tables.sql
-- ===================================================================

-- Test 1: Verify tables exist
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name IN ('guests', 'guest_accounts')
ORDER BY table_name;

-- Test 2: Verify columns in guests table
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'guests'
ORDER BY ordinal_position;

-- Test 3: Verify columns in guest_accounts table
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'guest_accounts'
ORDER BY ordinal_position;

-- Test 4: Verify constraints
SELECT
    tc.constraint_name,
    tc.constraint_type,
    tc.table_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name IN ('guests', 'guest_accounts')
ORDER BY tc.table_name, tc.constraint_type;

-- Test 5: Verify indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('guests', 'guest_accounts')
ORDER BY tablename, indexname;

-- Test 6: Verify foreign key relationships
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'guest_accounts';

-- Test 7: Count seed data
SELECT 
    'guests' as table_name,
    COUNT(*) as record_count
FROM guests
UNION ALL
SELECT 
    'guest_accounts' as table_name,
    COUNT(*) as record_count
FROM guest_accounts;

-- Test 8: Verify all guests have proper data
SELECT 
    guest_id,
    first_name,
    last_name,
    email,
    phone,
    created_at
FROM guests
ORDER BY guest_id;

-- Test 9: Verify guest accounts are linked correctly
SELECT 
    ga.guest_account_id,
    ga.guest_id,
    g.first_name,
    g.last_name,
    g.email,
    LENGTH(ga.hashed_password) as password_hash_length,
    ga.last_login,
    ga.created_at
FROM guest_accounts ga
JOIN guests g ON ga.guest_id = g.guest_id
ORDER BY ga.guest_account_id;

-- Test 10: Test unique constraint on email
-- This should fail if run twice (expected behavior)
-- INSERT INTO guests (first_name, last_name, email, phone) 
-- VALUES ('Test', 'User', 'somchai@example.com', '0999999999');

-- Test 11: Test foreign key constraint
-- This should fail (expected behavior)
-- INSERT INTO guest_accounts (guest_id, hashed_password) 
-- VALUES (9999, '$2a$10$test');

-- Test 12: Test cascade delete
-- Uncomment to test (will delete a guest and their account)
-- BEGIN;
-- DELETE FROM guests WHERE guest_id = 10;
-- SELECT COUNT(*) FROM guest_accounts WHERE guest_id = 10; -- Should be 0
-- ROLLBACK;

-- ===================================================================
-- Summary Report
-- ===================================================================

SELECT 
    'Migration Test Summary' as report_title,
    (SELECT COUNT(*) FROM guests) as total_guests,
    (SELECT COUNT(*) FROM guest_accounts) as total_accounts,
    (SELECT COUNT(*) FROM guests WHERE email IS NOT NULL) as guests_with_email,
    (SELECT COUNT(*) FROM guest_accounts WHERE hashed_password IS NOT NULL) as accounts_with_password;
