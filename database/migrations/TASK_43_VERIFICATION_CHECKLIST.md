# Task 43: Performance Optimization - Verification Checklist

## Pre-Installation Checklist

- [ ] PostgreSQL 15+ installed and running
- [ ] Database `hotel_booking` exists
- [ ] All previous migrations (001-011) completed successfully
- [ ] Backup of database created (recommended)
- [ ] psql command-line tool available

## Installation Steps

### Step 1: Run Migration

- [ ] Navigate to `database/migrations` directory
- [ ] Run migration script:
  ```bash
  # Linux/Mac
  ./run_migration_012.sh
  
  # Windows
  run_migration_012.bat
  ```
- [ ] Verify no errors in output
- [ ] Check for success message

### Step 2: Verify Indexes Created

- [ ] Connect to database:
  ```bash
  psql -h localhost -U postgres -d hotel_booking
  ```

- [ ] Count total indexes:
  ```sql
  SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public';
  ```
  Expected: Should show increased count (17 new indexes)

- [ ] List new performance indexes:
  ```sql
  SELECT tablename, indexname 
  FROM pg_indexes 
  WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
  ORDER BY tablename, indexname;
  ```
  Expected: Should see all 17 new indexes

- [ ] Verify specific indexes exist:
  ```sql
  SELECT indexname FROM pg_indexes 
  WHERE schemaname = 'public'
  AND indexname IN (
    'idx_bookings_guest_status_created',
    'idx_booking_details_checkin_date',
    'idx_room_inventory_availability_search',
    'idx_rooms_dashboard',
    'idx_bookings_revenue_report'
  );
  ```
  Expected: All 5 indexes should be listed

### Step 3: Verify Materialized Views Created

- [ ] List materialized views:
  ```sql
  SELECT matviewname FROM pg_matviews WHERE schemaname = 'public';
  ```
  Expected: 4 views (mv_room_status_summary, mv_daily_occupancy, mv_revenue_summary, mv_upcoming_arrivals)

- [ ] Check row counts:
  ```sql
  SELECT 'mv_room_status_summary' as view_name, COUNT(*) FROM mv_room_status_summary
  UNION ALL
  SELECT 'mv_daily_occupancy', COUNT(*) FROM mv_daily_occupancy
  UNION ALL
  SELECT 'mv_revenue_summary', COUNT(*) FROM mv_revenue_summary
  UNION ALL
  SELECT 'mv_upcoming_arrivals', COUNT(*) FROM mv_upcoming_arrivals;
  ```
  Expected: All views should have data (counts > 0)

- [ ] Verify view indexes:
  ```sql
  SELECT indexname FROM pg_indexes 
  WHERE schemaname = 'public'
  AND indexname LIKE 'idx_mv_%';
  ```
  Expected: Indexes on materialized views

### Step 4: Verify Helper Functions Created

- [ ] List functions:
  ```sql
  SELECT proname FROM pg_proc 
  WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'refresh_all_materialized_views',
    'refresh_room_status_view',
    'analyze_slow_queries',
    'get_table_sizes',
    'get_index_usage'
  );
  ```
  Expected: All 5 functions listed

- [ ] Test refresh function:
  ```sql
  SELECT refresh_room_status_view();
  ```
  Expected: No errors

- [ ] Test table sizes function:
  ```sql
  SELECT * FROM get_table_sizes() LIMIT 5;
  ```
  Expected: Table size information displayed

- [ ] Test index usage function:
  ```sql
  SELECT * FROM get_index_usage() LIMIT 5;
  ```
  Expected: Index usage statistics displayed

## Performance Testing

### Step 5: Run Performance Tests

- [ ] Run test script:
  ```bash
  # Linux/Mac
  ./run_test_performance.sh
  
  # Windows
  run_test_performance.bat
  ```

- [ ] Verify all tests pass
- [ ] Check timing output (should show improvements)
- [ ] Review EXPLAIN ANALYZE output

### Step 6: Verify Query Performance

- [ ] Test guest booking history query:
  ```sql
  \timing on
  SELECT * FROM bookings 
  WHERE guest_id = 1 
  AND status IN ('Confirmed', 'CheckedIn')
  ORDER BY created_at DESC
  LIMIT 10;
  ```
  Expected: < 5ms execution time

- [ ] Test room availability search:
  ```sql
  SELECT rt.room_type_id, rt.name, COUNT(DISTINCT ri.date)
  FROM room_types rt
  JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
  WHERE ri.date >= CURRENT_DATE
  AND ri.date < CURRENT_DATE + INTERVAL '7 days'
  AND (ri.allotment - ri.booked_count - ri.tentative_count) > 0
  GROUP BY rt.room_type_id, rt.name;
  ```
  Expected: < 10ms execution time

- [ ] Test room status dashboard:
  ```sql
  SELECT * FROM mv_room_status_summary;
  ```
  Expected: < 3ms execution time

- [ ] Test revenue report:
  ```sql
  SELECT * FROM mv_revenue_summary
  WHERE booking_date >= CURRENT_DATE - INTERVAL '30 days'
  ORDER BY booking_date DESC;
  ```
  Expected: < 10ms execution time

### Step 7: Verify Index Usage

- [ ] Check if indexes are being used:
  ```sql
  EXPLAIN ANALYZE
  SELECT * FROM bookings 
  WHERE guest_id = 1 
  ORDER BY created_at DESC;
  ```
  Expected: Should show "Index Scan using idx_bookings_guest_status_created"

- [ ] Check index usage statistics:
  ```sql
  SELECT * FROM get_index_usage()
  WHERE index_name LIKE 'idx_bookings_guest%';
  ```
  Expected: Should show index_scans > 0 after running queries

## Functional Testing

### Step 8: Test Materialized View Refresh

- [ ] Refresh all views:
  ```sql
  SELECT refresh_all_materialized_views();
  ```
  Expected: Success message, no errors

- [ ] Refresh single view:
  ```sql
  SELECT refresh_room_status_view();
  ```
  Expected: Success, no errors

- [ ] Verify data updated:
  ```sql
  SELECT last_updated FROM mv_room_status_summary;
  ```
  Expected: Recent timestamp

### Step 9: Test Monitoring Functions

- [ ] Get table sizes:
  ```sql
  SELECT * FROM get_table_sizes();
  ```
  Expected: List of tables with sizes

- [ ] Get index usage:
  ```sql
  SELECT * FROM get_index_usage()
  ORDER BY index_scans DESC
  LIMIT 10;
  ```
  Expected: List of indexes with usage stats

- [ ] Check slow queries (if pg_stat_statements enabled):
  ```sql
  SELECT * FROM analyze_slow_queries();
  ```
  Expected: List of queries or error if extension not installed

## Documentation Review

### Step 10: Verify Documentation

- [ ] TASK_43_PERFORMANCE_OPTIMIZATION.md exists and is complete
- [ ] TASK_43_QUICKSTART.md exists and is complete
- [ ] TASK_43_INDEX.md exists and is complete
- [ ] TASK_43_COMPLETION_SUMMARY.md exists and is complete
- [ ] TASK_43_VERIFICATION_CHECKLIST.md exists (this file)

## Integration Testing

### Step 11: Backend Integration (Optional)

- [ ] Update Go repositories to use materialized views
- [ ] Test API endpoints for performance improvement
- [ ] Verify dashboard loads faster
- [ ] Verify reports generate faster

### Step 12: Set Up Cron Jobs (Recommended)

- [ ] Create cron job for room status refresh (every 5 min):
  ```bash
  */5 * * * * psql -U postgres -d hotel_booking -c "SELECT refresh_room_status_view();"
  ```

- [ ] Create cron job for all views refresh (hourly):
  ```bash
  0 * * * * psql -U postgres -d hotel_booking -c "SELECT refresh_all_materialized_views();"
  ```

- [ ] Verify cron jobs are running
- [ ] Check logs for errors

## Performance Benchmarks

### Step 13: Verify Performance Improvements

Compare these metrics before and after optimization:

| Query Type | Target | Actual | Status |
|------------|--------|--------|--------|
| Guest booking history | < 5ms | ___ms | [ ] |
| Room availability search | < 10ms | ___ms | [ ] |
| Room status dashboard | < 3ms | ___ms | [ ] |
| Revenue report | < 10ms | ___ms | [ ] |
| Upcoming arrivals | < 5ms | ___ms | [ ] |
| Housekeeping tasks | < 5ms | ___ms | [ ] |

## Final Verification

### Step 14: Complete System Check

- [ ] All indexes created successfully (17 indexes)
- [ ] All materialized views created successfully (4 views)
- [ ] All helper functions working (5 functions)
- [ ] Query performance improved (5-50x faster)
- [ ] No errors in logs
- [ ] Documentation complete
- [ ] Cron jobs set up (recommended)
- [ ] Team notified of changes

## Rollback Plan (If Needed)

If issues occur, rollback steps:

1. [ ] Drop materialized views:
   ```sql
   DROP MATERIALIZED VIEW IF EXISTS mv_upcoming_arrivals;
   DROP MATERIALIZED VIEW IF EXISTS mv_revenue_summary;
   DROP MATERIALIZED VIEW IF EXISTS mv_daily_occupancy;
   DROP MATERIALIZED VIEW IF EXISTS mv_room_status_summary;
   ```

2. [ ] Drop helper functions:
   ```sql
   DROP FUNCTION IF EXISTS refresh_all_materialized_views();
   DROP FUNCTION IF EXISTS refresh_room_status_view();
   DROP FUNCTION IF EXISTS analyze_slow_queries();
   DROP FUNCTION IF EXISTS get_table_sizes();
   DROP FUNCTION IF EXISTS get_index_usage();
   ```

3. [ ] Drop indexes (if causing issues):
   ```sql
   DROP INDEX IF EXISTS idx_bookings_guest_status_created;
   -- Repeat for other indexes as needed
   ```

4. [ ] Restore from backup if necessary

## Sign-Off

### Verification Completed By

- Name: _______________
- Date: _______________
- Signature: _______________

### Checklist Summary

- Total Items: 50+
- Completed: _____ / _____
- Status: [ ] Pass [ ] Fail
- Notes: _______________________________________________

## Next Steps After Verification

1. [ ] Mark Task 43 as complete in tasks.md
2. [ ] Update team on performance improvements
3. [ ] Schedule regular maintenance (weekly VACUUM, monthly index review)
4. [ ] Monitor query performance in production
5. [ ] Consider Task 44: Caching (Redis) for further optimization

## Support and Troubleshooting

If any verification step fails:

1. Check error messages in PostgreSQL logs
2. Review TASK_43_QUICKSTART.md for common issues
3. Use helper functions to diagnose:
   - `SELECT * FROM get_index_usage();`
   - `SELECT * FROM get_table_sizes();`
4. Verify all previous migrations completed successfully
5. Check PostgreSQL version (requires 15+)

## Additional Resources

- Full Documentation: TASK_43_PERFORMANCE_OPTIMIZATION.md
- Quick Reference: TASK_43_QUICKSTART.md
- Index Reference: TASK_43_INDEX.md
- Completion Summary: TASK_43_COMPLETION_SUMMARY.md

---

**Verification Status**: [ ] Complete [ ] Incomplete  
**Date**: _______________  
**Verified By**: _______________
