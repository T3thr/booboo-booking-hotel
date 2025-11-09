@echo off
echo ========================================
echo Quick Fix: Reset Room Availability
echo ========================================
echo.
echo This will reset all tentative_count to 0
echo and make all rooms available again.
echo.
pause

psql -U postgres -d hotel_reservation -c "UPDATE room_inventory SET tentative_count = 0, updated_at = NOW() WHERE tentative_count > 0;"

echo.
echo ========================================
echo Checking results...
echo ========================================

psql -U postgres -d hotel_reservation -c "SELECT rt.name as room_type, ri.date, ri.allotment as total, ri.booked_count as booked, ri.tentative_count as on_hold, (ri.allotment - ri.booked_count - ri.tentative_count) as available FROM room_inventory ri JOIN room_types rt ON ri.room_type_id = rt.room_type_id WHERE ri.date >= CURRENT_DATE AND ri.date <= CURRENT_DATE + INTERVAL '7 days' ORDER BY ri.date, rt.name;"

echo.
echo ========================================
echo Done! Rooms should be available now.
echo ========================================
pause
