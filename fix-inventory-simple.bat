@echo off
echo Fixing room inventory...
echo.

set PGPASSWORD=postgres
psql -h localhost -p 5432 -U postgres -d hotel_booking -f fix-inventory-simple.sql

echo.
echo Done! Now restart backend and try booking.
pause
