@echo off
echo ========================================
echo Fix Inventory After Manual Delete
echo ========================================

REM ตั้งค่า database connection
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=hotel_reservation
set PGUSER=postgres

echo.
echo Running fix script...
psql -f fix_inventory_after_manual_delete.sql

echo.
echo ========================================
echo Fix completed!
echo ========================================
pause
