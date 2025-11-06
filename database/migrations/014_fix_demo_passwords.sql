-- ============================================================================
-- Fix Demo Data Passwords with Correct Bcrypt Hashes
-- ============================================================================
-- This script updates the demo user passwords with properly hashed bcrypt values
-- Password for all demo users: password123
-- Bcrypt hash generated with cost 10
-- ============================================================================

\echo 'Fixing demo user passwords...'

-- Update all demo user passwords with correct bcrypt hash
-- Hash for "password123" with bcrypt cost 10
-- Generated and verified with Go bcrypt package
UPDATE guest_accounts
SET hashed_password = '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'
WHERE guest_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

\echo 'Password hashes updated successfully!'
\echo ''
\echo 'You can now login with:'
\echo '  Email: anan.test@example.com'
\echo '  Password: password123'
\echo ''
