-- ============================================================================
-- Test Script: Performance Optimization
-- ============================================================================
-- Description: Tests and verifies performance improvements from migration 012
-- ============================================================================

\timing on

-- ============================================================================
-- PART 1: VERIFY INDEXES WERE CREATED
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 1: Verify Indexes'
\echo '========================================='
\echo ''

-- Count total indexes
SELECT 
    'Total Indexes' as metric,
    COUNT(*) as count
FROM pg_indexes
WHERE schemaname = 'public';

-- List new performance indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND (
    indexname LIKE '%_guest_status_created%'
    OR indexname LIKE '%_checkin_date%'
    OR indexname LIKE '%_checkout_date%'
    OR indexname LIKE '%_availability_search%'
    OR indexname LIKE '%_dashboard%'
    OR indexname LIKE '%_revenue_report%'
    OR indexname LIKE '%_cleanup%'
    OR indexname LIKE '%_night_audit%'
)
ORDER BY tablename, indexname;

-- ============================================================================
-- PART 2: VERIFY MATERIALIZED VIEWS WERE CREATED
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 2: Verify Materialized Views'
\echo '========================================='
\echo ''

-- List all materialized views
SELECT 
    schemaname,
    matviewname,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) as size
FROM pg_matviews
WHERE schemaname = 'public'
ORDER BY matviewname;

-- Check row counts in materialized views
SELECT 'mv_room_status_summary' as view_name, COUNT(*) as row_count 
FROM mv_room_status_summary
UNION ALL
SELECT 'mv_daily_occupancy', COUNT(*) 
FROM mv_daily_occupancy
UNION ALL
SELECT 'mv_revenue_summary', COUNT(*) 
FROM mv_revenue_summary
UNION ALL
SELECT 'mv_upcoming_arrivals', COUNT(*) 
FROM mv_upcoming_arrivals;

-- ============================================================================
-- PART 3: TEST QUERY PERFORMANCE - BEFORE AND AFTER
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 3: Test Query Performance'
\echo '========================================='
\echo ''

-- Test 1: Guest booking history (should use idx_bookings_guest_status_created)
\echo 'Test 1: Guest Booking History Query'
EXPLAIN ANALYZE
SELECT b.booking_id, b.status, b.total_amount, b.created_at
FROM bookings b
WHERE b.guest_id = 1
AND b.status IN ('Confirmed', 'CheckedIn', 'Completed')
ORDER BY b.created_at DESC
LIMIT 10;

-- Test 2: Room availability search (should use idx_room_inventory_availability_search)
\echo ''
\echo 'Test 2: Room Availability Search Query'
EXPLAIN ANALYZE
SELECT 
    rt.room_type_id,
    rt.name,
    COUNT(DISTINCT ri.date) as available_days
FROM room_types rt
JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
WHERE ri.date >= CURRENT_DATE
AND ri.date < CURRENT_DATE + INTERVAL '7 days'
AND (ri.allotment - ri.booked_count - ri.tentative_count) > 0
GROUP BY rt.room_type_id, rt.name;

-- Test 3: Room status dashboard (should use idx_rooms_dashboard)
\echo ''
\echo 'Test 3: Room Status Dashboard Query'
EXPLAIN ANALYZE
SELECT 
    r.room_id,
    r.room_number,
    rt.name as room_type,
    r.occupancy_status,
    r.housekeeping_status
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
ORDER BY r.room_number;

-- Test 4: Upcoming arrivals (should use idx_booking_details_checkin_date)
\echo ''
\echo 'Test 4: Upcoming Arrivals Query'
EXPLAIN ANALYZE
SELECT 
    b.booking_id,
    g.first_name || ' ' || g.last_name as guest_name,
    bd.check_in_date,
    rt.name as room_type
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
WHERE bd.check_in_date >= CURRENT_DATE
AND bd.check_in_date <= CURRENT_DATE + INTERVAL '7 days'
AND b.status = 'Confirmed'
ORDER BY bd.check_in_date;

-- Test 5: Revenue report (should use idx_bookings_revenue_report)
\echo ''
\echo 'Test 5: Revenue Report Query'
EXPLAIN ANALYZE
SELECT 
    DATE(b.created_at) as booking_date,
    COUNT(*) as total_bookings,
    SUM(b.total_amount) as total_revenue
FROM bookings b
WHERE b.created_at >= CURRENT_DATE - INTERVAL '30 days'
AND b.status IN ('Confirmed', 'CheckedIn', 'Completed')
GROUP BY DATE(b.created_at)
ORDER BY booking_date DESC;

-- ============================================================================
-- PART 4: TEST MATERIALIZED VIEW PERFORMANCE
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 4: Test Materialized View Performance'
\echo '========================================='
\echo ''

-- Test MV 1: Room status summary (should be instant)
\echo 'Test MV 1: Room Status Summary'
EXPLAIN ANALYZE
SELECT * FROM mv_room_status_summary;

-- Test MV 2: Daily occupancy (should be fast)
\echo ''
\echo 'Test MV 2: Daily Occupancy'
EXPLAIN ANALYZE
SELECT * FROM mv_daily_occupancy
WHERE date >= CURRENT_DATE
AND date <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY date, room_type_name;

-- Test MV 3: Revenue summary (should be fast)
\echo ''
\echo 'Test MV 3: Revenue Summary'
EXPLAIN ANALYZE
SELECT * FROM mv_revenue_summary
WHERE booking_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY booking_date DESC;

-- Test MV 4: Upcoming arrivals (should be instant)
\echo ''
\echo 'Test MV 4: Upcoming Arrivals'
EXPLAIN ANALYZE
SELECT * FROM mv_upcoming_arrivals
WHERE check_in_date = CURRENT_DATE;

-- ============================================================================
-- PART 5: TEST HELPER FUNCTIONS
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 5: Test Helper Functions'
\echo '========================================='
\echo ''

-- Test function: Get table sizes
\echo 'Table Sizes:'
SELECT * FROM get_table_sizes()
LIMIT 10;

-- Test function: Get index usage
\echo ''
\echo 'Index Usage Statistics (Top 10):'
SELECT * FROM get_index_usage()
LIMIT 10;

-- Test function: Refresh materialized views
\echo ''
\echo 'Testing Materialized View Refresh:'
SELECT refresh_room_status_view();

-- ============================================================================
-- PART 6: PERFORMANCE COMPARISON
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 6: Performance Comparison'
\echo '========================================='
\echo ''

-- Compare direct query vs materialized view for room status
\echo 'Direct Query vs Materialized View - Room Status'
\echo 'Direct Query:'
EXPLAIN ANALYZE
SELECT 
    rt.room_type_id,
    rt.name as room_type_name,
    COUNT(r.room_id) as total_rooms,
    COUNT(r.room_id) FILTER (WHERE r.occupancy_status = 'Vacant') as vacant_rooms,
    COUNT(r.room_id) FILTER (WHERE r.occupancy_status = 'Occupied') as occupied_rooms
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.room_type_id, rt.name;

\echo ''
\echo 'Materialized View:'
EXPLAIN ANALYZE
SELECT 
    room_type_id,
    room_type_name,
    total_rooms,
    vacant_rooms,
    occupied_rooms
FROM mv_room_status_summary;

-- ============================================================================
-- PART 7: INDEX USAGE VERIFICATION
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 7: Verify Index Usage'
\echo '========================================='
\echo ''

-- Check if new indexes are being used
SELECT 
    schemaname || '.' || tablename as table_name,
    indexrelname as index_name,
    idx_scan as times_used,
    idx_tup_read as rows_read,
    idx_tup_fetch as rows_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
AND (
    indexrelname LIKE '%_guest_status_created%'
    OR indexrelname LIKE '%_checkin_date%'
    OR indexrelname LIKE '%_checkout_date%'
    OR indexrelname LIKE '%_availability_search%'
    OR indexrelname LIKE '%_dashboard%'
)
ORDER BY idx_scan DESC;

-- ============================================================================
-- PART 8: SUMMARY AND RECOMMENDATIONS
-- ============================================================================

\echo ''
\echo '========================================='
\echo 'PART 8: Summary'
\echo '========================================='
\echo ''

DO $
DECLARE
    total_indexes INT;
    total_mvs INT;
    total_size TEXT;
BEGIN
    -- Count indexes
    SELECT COUNT(*) INTO total_indexes
    FROM pg_indexes
    WHERE schemaname = 'public';
    
    -- Count materialized views
    SELECT COUNT(*) INTO total_mvs
    FROM pg_matviews
    WHERE schemaname = 'public';
    
    -- Get total database size
    SELECT pg_size_pretty(pg_database_size(current_database())) INTO total_size;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Performance Optimization Summary';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Database: %', current_database();
    RAISE NOTICE 'Total Size: %', total_size;
    RAISE NOTICE 'Total Indexes: %', total_indexes;
    RAISE NOTICE 'Materialized Views: %', total_mvs;
    RAISE NOTICE '';
    RAISE NOTICE 'Recommendations:';
    RAISE NOTICE '  1. Monitor query performance regularly';
    RAISE NOTICE '  2. Refresh materialized views on schedule:';
    RAISE NOTICE '     - mv_room_status_summary: Every 5 minutes';
    RAISE NOTICE '     - mv_daily_occupancy: Daily at 3 AM';
    RAISE NOTICE '     - mv_revenue_summary: Hourly';
    RAISE NOTICE '     - mv_upcoming_arrivals: Every 15 minutes';
    RAISE NOTICE '  3. Run VACUUM ANALYZE weekly';
    RAISE NOTICE '  4. Check index usage monthly';
    RAISE NOTICE '  5. Monitor slow queries with analyze_slow_queries()';
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
END $;

\timing off
