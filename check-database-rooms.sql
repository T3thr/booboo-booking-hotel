-- Check if room types exist
SELECT 'Room Types:' as info;
SELECT room_type_id, name, base_price, max_occupancy FROM room_types;

-- Check if rooms exist
SELECT 'Rooms:' as info;
SELECT COUNT(*) as total_rooms, room_type_id, occupancy_status 
FROM rooms 
GROUP BY room_type_id, occupancy_status
ORDER BY room_type_id;

-- Check if pricing calendar exists for today
SELECT 'Pricing Calendar (Today):' as info;
SELECT * FROM pricing_calendar 
WHERE date = CURRENT_DATE;

-- Check if room inventory exists for today
SELECT 'Room Inventory (Today):' as info;
SELECT * FROM room_inventory 
WHERE date = CURRENT_DATE;

-- Check if rate pricing exists
SELECT 'Rate Pricing:' as info;
SELECT COUNT(*) as total_rate_pricing FROM rate_pricing;
