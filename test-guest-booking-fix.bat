@echo off
echo Testing guest booking fix...
echo.

powershell -ExecutionPolicy Bypass -Command "$env:PGPASSWORD='npg_8kHamXSLKg1x'; psql -h ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech -p 5432 -U neondb_owner -d neondb -f test-guest-booking-fix.sql"

pause
