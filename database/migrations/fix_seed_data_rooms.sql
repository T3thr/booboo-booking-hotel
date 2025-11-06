-- Quick fix: Add missing rooms that seed script references
-- This ensures bookings can be assigned to these specific rooms

-- Add room 103 if it doesn't exist (Standard room, Floor 1)
INSERT INTO rooms (room_id, room_type_id, room_number, floor, occupancy_status, housekeeping_status)
VALUES (103, 1, '103', 1, 'Vacant', 'Inspected')
ON CONFLICT (room_id) DO NOTHING;

-- Add room 302 if it doesn't exist (Deluxe room, Floor 3)
INSERT INTO rooms (room_id, room_type_id, room_number, floor, occupancy_status, housekeeping_status)
VALUES (302, 2, '302', 3, 'Vacant', 'Inspected')
ON CONFLICT (room_id) DO NOTHING;

\echo 'Added missing rooms 103 and 302 for demo bookings'
