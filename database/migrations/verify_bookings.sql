-- ============================================================================
-- Verification Script for Bookings Tables (Migration 004)
-- ============================================================================

\echo '========================================='
\echo 'Verifying Bookings Tables'
\echo '========================================='
\echo ''

-- Check if all tables exist
\echo 'Checking table existence...'
SELECT 
    CASE 
        WHEN COUNT(*) = 5 THEN '✓ All 5 booking tables exist'
        ELSE '✗ Missing tables! Found: ' || COUNT(*)::TEXT
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('bookings', 'booking_details', 'room_assignments', 
                   'booking_guests', 'booking_nightly_log');

\echo ''
\echo 'Table Details:'
\echo '----------------------------------------'

-- bookings table
\echo '1. bookings table:'
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'bookings'
ORDER BY ordinal_position;

\echo ''
\echo '2. booking_details table:'
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'booking_details'
ORDER BY ordinal_position;

\echo ''
\echo '3. room_assignments table:'
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'room_assignments'
ORDER BY ordinal_position;

\echo ''
\echo '4. booking_guests table:'
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'booking_guests'
ORDER BY ordinal_position;

\echo ''
\echo '5. booking_nightly_log table:'
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'booking_nightly_log'
ORDER BY ordinal_position;

\echo ''
\echo '----------------------------------------'
\echo 'Checking Constraints...'
\echo '----------------------------------------'

-- Check constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('bookings', 'booking_details', 'room_assignments', 
                      'booking_guests', 'booking_nightly_log')
ORDER BY tc.table_name, tc.constraint_type;

\echo ''
\echo '----------------------------------------'
\echo 'Checking Indexes...'
\echo '----------------------------------------'

SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('bookings', 'booking_details', 'room_assignments', 
                  'booking_guests', 'booking_nightly_log')
ORDER BY tablename, indexname;

\echo ''
\echo '----------------------------------------'
\echo 'Checking Foreign Keys...'
\echo '----------------------------------------'

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('bookings', 'booking_details', 'room_assignments', 
                      'booking_guests', 'booking_nightly_log')
ORDER BY tc.table_name, kcu.column_name;

\echo ''
\echo '========================================='
\echo 'Verification Complete'
\echo '========================================='
