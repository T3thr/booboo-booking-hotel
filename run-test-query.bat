@echo off
echo Testing SQL Query for Available Rooms...
echo.
psql "postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require" -f test-query-available-rooms.sql
echo.
pause
