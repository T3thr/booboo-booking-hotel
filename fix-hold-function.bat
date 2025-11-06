@echo off
echo ========================================
echo Fixing create_booking_hold Function
echo ========================================
echo.
echo Re-creating function with alias fix...
echo.

psql "postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require" -f database/migrations/005_create_booking_hold_function.sql

echo.
echo ========================================
echo Function recreated successfully!
echo ========================================
echo.
echo Now restart backend server
pause
