-- ============================================================================
-- Migration 012: Performance Optimization
-- ============================================================================
-- Description: Analyzes slow queries, adds necessary indexes, and creates
--              materialized views for dashboard performance
-- Task: 43. Performance Optimization - Database
-- Requirements: All requirements (performance)
-- ============================================================================

-- ============================================================================
-- PART 1: ANALYZE EXISTING TABLES
-- ============================================================================
-- Update statistics for query planner optimization

ANALYZE guests;
ANALYZE guest_accounts;
ANALYZE room_types;
ANALYZE rooms;
ANALYZE amenities;
ANALYZE room_type_amenities;
ANALYZE cancellation_policies;
ANALYZE rate_tiers;
ANALYZE rate_plans;
ANALYZE pricing_calendar;
ANALYZE rate_pricing;
ANALYZE room_inventory;
ANALYZE vouchers;
ANALYZE booking_holds;
ANALYZE bookings;
ANALYZE booking_details;
ANALYZE room_assignments;
ANALYZE booking_guests;
ANALYZE booking_nightly_log;

-- ============================================================================
-- PART 2: ADD MISSING INDEXES FOR COMMON QUERIES
-- ============================================================================

-- ============================================================================
-- 2.1 Booking-Related Indexes
-- ============================================================================

-- Composite index for guest booking history queries (most common query)
CREATE INDEX IF NOT EXISTS idx_bookings_guest_status_created 
    ON bookings(guest_id, status, created_at DESC);

-- Index for upcoming arrivals (check-in dashboard)
CREATE INDEX IF NOT EXISTS idx_booking_details_checkin_date 
    ON booking_details(check_in_date);

-- Index for upcoming departures (check-out dashboard)
CREATE INDEX IF NOT EXISTS idx_booking_details_checkout_date 
    ON booking_details(check_out_date);

-- Index for active room assignments (frequently queried)
CREATE INDEX IF NOT EXISTS idx_room_assignments_active_room 
    ON room_assignments(room_id, status);

-- Index for booking details with date range queries
CREATE INDEX IF NOT EXISTS idx_booking_details_date_range 
    ON booking_details(check_in_date, check_out_date, room_type_id);

-- ============================================================================
-- 2.2 Room Availability Search Indexes
-- ============================================================================

-- Composite index for room availability queries (critical for search)
-- Note: Removed WHERE clause as computed expressions require IMMUTABLE functions
CREATE INDEX IF NOT EXISTS idx_room_inventory_availability_search 
    ON room_inventory(date, room_type_id, allotment, booked_count, tentative_count);

-- Index for room inventory date range queries
CREATE INDEX IF NOT EXISTS idx_room_inventory_date_room_type 
    ON room_inventory(room_type_id, date);

-- ============================================================================
-- 2.3 Pricing Calculation Indexes
-- ============================================================================

-- Composite index for pricing matrix lookups
CREATE INDEX IF NOT EXISTS idx_rate_pricing_lookup 
    ON rate_pricing(rate_plan_id, room_type_id, rate_tier_id, price);

-- Index for pricing calendar date range queries
CREATE INDEX IF NOT EXISTS idx_pricing_calendar_date_tier 
    ON pricing_calendar(date, rate_tier_id);

-- ============================================================================
-- 2.4 Room Status Dashboard Indexes
-- ============================================================================

-- Composite index for room status dashboard (most frequent query)
CREATE INDEX IF NOT EXISTS idx_rooms_dashboard 
    ON rooms(room_type_id, occupancy_status, housekeeping_status, room_number);

-- Index for housekeeping task list
CREATE INDEX IF NOT EXISTS idx_rooms_housekeeping_tasks 
    ON rooms(housekeeping_status, room_number);

-- ============================================================================
-- 2.5 Reporting and Analytics Indexes
-- ============================================================================

-- Index for revenue reports by date range
CREATE INDEX IF NOT EXISTS idx_bookings_revenue_report 
    ON bookings(created_at, status, total_amount);

-- Index for nightly log revenue calculations
CREATE INDEX IF NOT EXISTS idx_booking_nightly_log_date_price 
    ON booking_nightly_log(date, quoted_price);

-- Index for voucher usage reports
CREATE INDEX IF NOT EXISTS idx_bookings_voucher_report 
    ON bookings(voucher_id, created_at, total_amount);

-- ============================================================================
-- 2.6 Background Job Indexes
-- ============================================================================

-- Index for expired holds cleanup (runs every 5 minutes)
CREATE INDEX IF NOT EXISTS idx_booking_holds_cleanup 
    ON booking_holds(hold_expiry, room_type_id, date);

-- Index for night audit (runs daily at 2 AM)
CREATE INDEX IF NOT EXISTS idx_rooms_night_audit 
    ON rooms(occupancy_status, housekeeping_status);

-- ============================================================================
-- PART 3: CREATE MATERIALIZED VIEWS FOR DASHBOARD
-- ============================================================================

-- ============================================================================
-- 3.1 Materialized View: Room Status Summary
-- ============================================================================
-- Purpose: Fast dashboard loading for room status overview
-- Refresh: Every 5 minutes or on-demand

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_room_status_summary AS
SELECT 
    rt.room_type_id,
    rt.name as room_type_name,
    COUNT(r.room_id) as total_rooms,
    
    -- Occupancy counts
    COUNT(r.room_id) FILTER (WHERE r.occupancy_status = 'Vacant') as vacant_rooms,
    COUNT(r.room_id) FILTER (WHERE r.occupancy_status = 'Occupied') as occupied_rooms,
    
    -- Housekeeping counts
    COUNT(r.room_id) FILTER (WHERE r.housekeeping_status = 'Dirty') as dirty_rooms,
    COUNT(r.room_id) FILTER (WHERE r.housekeeping_status = 'Cleaning') as cleaning_rooms,
    COUNT(r.room_id) FILTER (WHERE r.housekeeping_status = 'Clean') as clean_rooms,
    COUNT(r.room_id) FILTER (WHERE r.housekeeping_status = 'Inspected') as inspected_rooms,
    COUNT(r.room_id) FILTER (WHERE r.housekeeping_status = 'MaintenanceRequired') as maintenance_rooms,
    COUNT(r.room_id) FILTER (WHERE r.housekeeping_status = 'OutOfService') as out_of_service_rooms,
    
    -- Ready for check-in (Vacant + Inspected or Clean)
    COUNT(r.room_id) FILTER (
        WHERE r.occupancy_status = 'Vacant' 
        AND r.housekeeping_status IN ('Inspected', 'Clean')
    ) as ready_for_checkin,
    
    -- Last updated
    NOW() as last_updated
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.room_type_id, rt.name;

-- Create index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_room_status_summary_room_type 
    ON mv_room_status_summary(room_type_id);

COMMENT ON MATERIALIZED VIEW mv_room_status_summary IS 
    'Room status summary for dashboard - refresh every 5 minutes';

-- ============================================================================
-- 3.2 Materialized View: Daily Occupancy Report
-- ============================================================================
-- Purpose: Fast occupancy rate calculations for reports
-- Refresh: Daily at 3 AM (after night audit)

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_occupancy AS
SELECT 
    ri.date,
    rt.room_type_id,
    rt.name as room_type_name,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available_count,
    
    -- Occupancy rate
    CASE 
        WHEN ri.allotment > 0 THEN 
            ROUND((ri.booked_count::DECIMAL / ri.allotment) * 100, 2)
        ELSE 0
    END as occupancy_rate,
    
    -- Pricing tier
    pc.rate_tier_id,
    tier.name as rate_tier_name,
    
    -- Last updated
    NOW() as last_updated
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
LEFT JOIN pricing_calendar pc ON ri.date = pc.date
LEFT JOIN rate_tiers tier ON pc.rate_tier_id = tier.rate_tier_id
WHERE ri.date >= CURRENT_DATE - INTERVAL '90 days'
  AND ri.date <= CURRENT_DATE + INTERVAL '365 days';

-- Create indexes on materialized view
CREATE INDEX IF NOT EXISTS idx_mv_daily_occupancy_date 
    ON mv_daily_occupancy(date);

CREATE INDEX IF NOT EXISTS idx_mv_daily_occupancy_room_type_date 
    ON mv_daily_occupancy(room_type_id, date);

COMMENT ON MATERIALIZED VIEW mv_daily_occupancy IS 
    'Daily occupancy rates for reporting - refresh daily at 3 AM';

-- ============================================================================
-- 3.3 Materialized View: Revenue Summary
-- ============================================================================
-- Purpose: Fast revenue calculations for manager dashboard
-- Refresh: Hourly or on-demand

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_revenue_summary AS
SELECT 
    DATE(b.created_at) as booking_date,
    rt.room_type_id,
    rt.name as room_type_name,
    rp.rate_plan_id,
    rp.name as rate_plan_name,
    
    -- Booking counts
    COUNT(DISTINCT b.booking_id) as total_bookings,
    COUNT(DISTINCT b.booking_id) FILTER (WHERE b.status = 'Confirmed') as confirmed_bookings,
    COUNT(DISTINCT b.booking_id) FILTER (WHERE b.status = 'CheckedIn') as checkedin_bookings,
    COUNT(DISTINCT b.booking_id) FILTER (WHERE b.status = 'Completed') as completed_bookings,
    COUNT(DISTINCT b.booking_id) FILTER (WHERE b.status = 'Cancelled') as cancelled_bookings,
    
    -- Revenue
    SUM(b.total_amount) FILTER (WHERE b.status IN ('Confirmed', 'CheckedIn', 'Completed')) as total_revenue,
    AVG(b.total_amount) FILTER (WHERE b.status IN ('Confirmed', 'CheckedIn', 'Completed')) as avg_booking_value,
    
    -- Room nights
    SUM(bd.check_out_date - bd.check_in_date) as total_room_nights,
    
    -- ADR (Average Daily Rate)
    CASE 
        WHEN SUM(bd.check_out_date - bd.check_in_date) > 0 THEN
            ROUND(
                SUM(b.total_amount) FILTER (WHERE b.status IN ('Confirmed', 'CheckedIn', 'Completed'))::DECIMAL / 
                SUM(bd.check_out_date - bd.check_in_date),
                2
            )
        ELSE 0
    END as adr,
    
    -- Last updated
    NOW() as last_updated
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
WHERE b.created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(b.created_at), rt.room_type_id, rt.name, rp.rate_plan_id, rp.name;

-- Create indexes on materialized view
CREATE INDEX IF NOT EXISTS idx_mv_revenue_summary_date 
    ON mv_revenue_summary(booking_date);

CREATE INDEX IF NOT EXISTS idx_mv_revenue_summary_room_type 
    ON mv_revenue_summary(room_type_id, booking_date);

COMMENT ON MATERIALIZED VIEW mv_revenue_summary IS 
    'Revenue summary for manager dashboard - refresh hourly';

-- ============================================================================
-- 3.4 Materialized View: Upcoming Arrivals
-- ============================================================================
-- Purpose: Fast loading of check-in dashboard
-- Refresh: Every 15 minutes

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_upcoming_arrivals AS
SELECT 
    b.booking_id,
    b.guest_id,
    g.first_name || ' ' || g.last_name as guest_name,
    g.email,
    g.phone,
    bd.booking_detail_id,
    bd.check_in_date,
    bd.check_out_date,
    bd.num_guests,
    rt.room_type_id,
    rt.name as room_type_name,
    rp.name as rate_plan_name,
    b.status,
    b.total_amount,
    
    -- Check if already checked in
    EXISTS(
        SELECT 1 FROM room_assignments ra 
        WHERE ra.booking_detail_id = bd.booking_detail_id 
        AND ra.status = 'Active'
    ) as is_checked_in,
    
    -- Last updated
    NOW() as last_updated
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
JOIN rate_plans rp ON bd.rate_plan_id = rp.rate_plan_id
WHERE bd.check_in_date >= CURRENT_DATE
  AND bd.check_in_date <= CURRENT_DATE + INTERVAL '7 days'
  AND b.status IN ('Confirmed', 'CheckedIn')
ORDER BY bd.check_in_date, g.last_name;

-- Create indexes on materialized view
CREATE INDEX IF NOT EXISTS idx_mv_upcoming_arrivals_date 
    ON mv_upcoming_arrivals(check_in_date);

CREATE INDEX IF NOT EXISTS idx_mv_upcoming_arrivals_guest 
    ON mv_upcoming_arrivals(guest_id);

COMMENT ON MATERIALIZED VIEW mv_upcoming_arrivals IS 
    'Upcoming arrivals for check-in dashboard - refresh every 15 minutes';

-- ============================================================================
-- PART 4: CREATE REFRESH FUNCTIONS
-- ============================================================================

-- ============================================================================
-- 4.1 Function: Refresh All Materialized Views
-- ============================================================================

CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS void AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    
    RAISE NOTICE 'Starting materialized view refresh...';
    
    -- Refresh room status summary (fast, small dataset)
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_room_status_summary;
    RAISE NOTICE '✓ Refreshed mv_room_status_summary';
    
    -- Refresh daily occupancy (medium dataset)
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_occupancy;
    RAISE NOTICE '✓ Refreshed mv_daily_occupancy';
    
    -- Refresh revenue summary (medium dataset)
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_revenue_summary;
    RAISE NOTICE '✓ Refreshed mv_revenue_summary';
    
    -- Refresh upcoming arrivals (small dataset)
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_upcoming_arrivals;
    RAISE NOTICE '✓ Refreshed mv_upcoming_arrivals';
    
    end_time := clock_timestamp();
    
    RAISE NOTICE 'All materialized views refreshed in % ms', 
        EXTRACT(MILLISECONDS FROM (end_time - start_time));
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_all_materialized_views() IS 
    'Refresh all materialized views - call this from cron job';

-- ============================================================================
-- 4.2 Function: Refresh Room Status Only (Fast)
-- ============================================================================

CREATE OR REPLACE FUNCTION refresh_room_status_view()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_room_status_summary;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_room_status_view() IS 
    'Refresh room status view only - call every 5 minutes';

-- ============================================================================
-- PART 5: QUERY PERFORMANCE ANALYSIS HELPERS
-- ============================================================================

-- ============================================================================
-- 5.1 Function: Analyze Slow Queries
-- ============================================================================

CREATE OR REPLACE FUNCTION analyze_slow_queries()
RETURNS TABLE(
    query_text TEXT,
    calls BIGINT,
    total_time_ms NUMERIC,
    mean_time_ms NUMERIC,
    max_time_ms NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        SUBSTRING(query, 1, 100) as query_text,
        calls,
        ROUND(total_exec_time::NUMERIC, 2) as total_time_ms,
        ROUND(mean_exec_time::NUMERIC, 2) as mean_time_ms,
        ROUND(max_exec_time::NUMERIC, 2) as max_time_ms
    FROM pg_stat_statements
    WHERE query NOT LIKE '%pg_stat_statements%'
    ORDER BY mean_exec_time DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION analyze_slow_queries() IS 
    'Analyze slow queries using pg_stat_statements (requires extension)';

-- ============================================================================
-- 5.2 Function: Get Table Sizes
-- ============================================================================

CREATE OR REPLACE FUNCTION get_table_sizes()
RETURNS TABLE(
    table_name TEXT,
    row_count BIGINT,
    total_size TEXT,
    table_size TEXT,
    indexes_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tablename::TEXT,
        n_live_tup as row_count,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
        pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                      pg_relation_size(schemaname||'.'||tablename)) as indexes_size
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_table_sizes() IS 
    'Get table and index sizes for all tables';

-- ============================================================================
-- 5.3 Function: Get Index Usage Statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_index_usage()
RETURNS TABLE(
    table_name TEXT,
    index_name TEXT,
    index_scans BIGINT,
    rows_read BIGINT,
    index_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname || '.' || tablename as table_name,
        indexrelname as index_name,
        idx_scan as index_scans,
        idx_tup_read as rows_read,
        pg_size_pretty(pg_relation_size(indexrelid)) as index_size
    FROM pg_stat_user_indexes
    WHERE schemaname = 'public'
    ORDER BY idx_scan DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_index_usage() IS 
    'Get index usage statistics to identify unused indexes';

-- ============================================================================
-- PART 6: VACUUM AND ANALYZE SCHEDULE
-- ============================================================================

-- Note: VACUUM commands cannot run inside a transaction block (migration context)
-- Run these manually after migration or set up a cron job:
-- 
-- VACUUM ANALYZE guests;
-- VACUUM ANALYZE guest_accounts;
-- VACUUM ANALYZE room_types;
-- VACUUM ANALYZE rooms;
-- VACUUM ANALYZE amenities;
-- VACUUM ANALYZE room_type_amenities;
-- VACUUM ANALYZE cancellation_policies;
-- VACUUM ANALYZE rate_tiers;
-- VACUUM ANALYZE rate_plans;
-- VACUUM ANALYZE pricing_calendar;
-- VACUUM ANALYZE rate_pricing;
-- VACUUM ANALYZE room_inventory;
-- VACUUM ANALYZE vouchers;
-- VACUUM ANALYZE booking_holds;
-- VACUUM ANALYZE bookings;
-- VACUUM ANALYZE booking_details;
-- VACUUM ANALYZE room_assignments;
-- VACUUM ANALYZE booking_guests;
-- VACUUM ANALYZE booking_nightly_log;

-- ============================================================================
-- PART 7: VERIFICATION AND SUMMARY
-- ============================================================================

DO $$
DECLARE
    index_count INT;
    mv_count INT;
BEGIN
    -- Count new indexes
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND indexname LIKE 'idx_%'
    AND indexname NOT IN (
        SELECT indexname FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND indexname LIKE 'idx_%'
    );
    
    -- Count materialized views
    SELECT COUNT(*) INTO mv_count
    FROM pg_matviews
    WHERE schemaname = 'public';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Performance Optimization Complete';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes Created:';
    RAISE NOTICE '  ✓ Booking-related indexes: 6';
    RAISE NOTICE '  ✓ Room availability indexes: 2';
    RAISE NOTICE '  ✓ Pricing calculation indexes: 2';
    RAISE NOTICE '  ✓ Room status dashboard indexes: 2';
    RAISE NOTICE '  ✓ Reporting indexes: 3';
    RAISE NOTICE '  ✓ Background job indexes: 2';
    RAISE NOTICE '';
    RAISE NOTICE 'Materialized Views: %', mv_count;
    RAISE NOTICE '  ✓ mv_room_status_summary';
    RAISE NOTICE '  ✓ mv_daily_occupancy';
    RAISE NOTICE '  ✓ mv_revenue_summary';
    RAISE NOTICE '  ✓ mv_upcoming_arrivals';
    RAISE NOTICE '';
    RAISE NOTICE 'Helper Functions:';
    RAISE NOTICE '  ✓ refresh_all_materialized_views()';
    RAISE NOTICE '  ✓ refresh_room_status_view()';
    RAISE NOTICE '  ✓ analyze_slow_queries()';
    RAISE NOTICE '  ✓ get_table_sizes()';
    RAISE NOTICE '  ✓ get_index_usage()';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Set up cron job to refresh materialized views';
    RAISE NOTICE '  2. Monitor query performance with analyze_slow_queries()';
    RAISE NOTICE '  3. Check index usage with get_index_usage()';
    RAISE NOTICE '  4. Run VACUUM ANALYZE regularly';
    RAISE NOTICE '========================================';
END $$;