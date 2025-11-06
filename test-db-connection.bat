@echo off
echo ============================================================================
echo TEST DATABASE CONNECTION AND QUERY
echo ============================================================================
echo.
echo Testing database query...
echo.
psql -U postgres -d hotel_booking -f test-db-query.sql
echo.
echo ============================================================================
echo If you see results above: Database is OK!
echo If you see error: Check database connection or table structure
echo ============================================================================
pause
