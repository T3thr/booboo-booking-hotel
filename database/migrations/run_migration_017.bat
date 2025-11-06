@echo off
echo Running Migration 017: Add phone to booking_guests...
echo Using Neon PostgreSQL database...
set PGPASSWORD=npg_8kHamXSLKg1x
psql -h ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech -p 5432 -U neondb_owner -d neondb -f 017_add_phone_to_booking_guests.sql
echo Migration 017 completed!
pause
