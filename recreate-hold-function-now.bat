@echo off
cd database\migrations
echo Recreating create_booking_hold function...
psql "postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require" -f 005_create_booking_hold_function.sql
cd ..\..
echo.
echo Function recreated! Now test booking.
pause
