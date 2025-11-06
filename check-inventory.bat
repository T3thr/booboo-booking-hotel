@echo off
echo ตรวจสอบ Room Inventory
echo ========================
echo.
psql -U postgres -d hotel_booking -f check-inventory.sql
pause
