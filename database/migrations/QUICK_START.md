# Quick Start Guide - Room Management Schema

## 🚀 Getting Started in 5 Minutes

### Step 1: Start the Database (30 seconds)
```bash
# Make sure Docker Desktop is running, then:
docker-compose up -d db

# Wait for database to be ready
docker-compose logs -f db
# Look for: "database system is ready to accept connections"
```

### Step 2: Run the Migration (1 minute)

**Windows:**
```cmd
cd database\migrations
run_migration_002.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_migration_002.sh
./run_migration_002.sh
```

**Manual (if scripts don't work):**
```bash
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/002_create_room_management_tables.sql
```

### Step 3: Verify (30 seconds)
```bash
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking
```

Then run:
```sql
-- Check tables
\dt

-- Count data
SELECT 'room_types' as table_name, COUNT(*) FROM room_types
UNION ALL
SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'amenities', COUNT(*) FROM amenities
UNION ALL
SELECT 'room_type_amenities', COUNT(*) FROM room_type_amenities;

-- Expected output:
-- room_types: 3
-- rooms: 20
-- amenities: 10
-- room_type_amenities: 24
```

### Step 4: Try Some Queries (2 minutes)

```sql
-- 1. View all room types
SELECT name, max_occupancy, base_price, size_sqm 
FROM room_types 
ORDER BY base_price;

-- 2. Find available rooms
SELECT r.room_number, rt.name, r.housekeeping_status
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.occupancy_status = 'Vacant'
  AND r.housekeeping_status IN ('Clean', 'Inspected')
ORDER BY r.room_number;

-- 3. View room status dashboard
SELECT 
  occupancy_status,
  housekeeping_status,
  COUNT(*) as count
FROM rooms
GROUP BY occupancy_status, housekeeping_status
ORDER BY occupancy_status, housekeeping_status;

-- 4. See amenities by room type
SELECT 
  rt.name as room_type,
  STRING_AGG(a.name, ', ' ORDER BY a.name) as amenities
FROM room_types rt
LEFT JOIN room_type_amenities rta ON rt.room_type_id = rta.room_type_id
LEFT JOIN amenities a ON rta.amenity_id = a.amenity_id
GROUP BY rt.name
ORDER BY rt.name;
```

## 📊 What You Get

### Room Types (3)
- **Standard Room**: 1,500 THB, 2 guests, 28 sqm, 6 amenities
- **Deluxe Room**: 2,500 THB, 3 guests, 38 sqm, 8 amenities
- **Suite Room**: 4,500 THB, 4 guests, 55 sqm, 10 amenities

### Rooms (20)
- Floor 1: Rooms 101-110 (Standard)
- Floor 2: Rooms 201-207 (Deluxe)
- Floor 3: Rooms 301-303 (Suite)

### Status Distribution
- 3 rooms occupied
- 10 rooms ready for check-in (Vacant + Inspected/Clean)
- 7 rooms need cleaning

## 🎯 Common Use Cases

### Use Case 1: Find Rooms for Check-in
```sql
-- Get best available rooms (Inspected first, then Clean)
SELECT 
  r.room_number,
  rt.name as room_type,
  rt.base_price,
  r.housekeeping_status
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.occupancy_status = 'Vacant'
  AND r.housekeeping_status IN ('Clean', 'Inspected')
ORDER BY 
  CASE r.housekeeping_status 
    WHEN 'Inspected' THEN 1 
    WHEN 'Clean' THEN 2 
  END,
  r.room_number;
```

### Use Case 2: Housekeeping Task List
```sql
-- Get rooms that need cleaning
SELECT 
  r.room_number,
  rt.name as room_type,
  r.floor,
  r.housekeeping_status,
  r.updated_at as last_updated
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.housekeeping_status IN ('Dirty', 'Cleaning')
ORDER BY 
  CASE r.housekeeping_status 
    WHEN 'Dirty' THEN 1 
    WHEN 'Cleaning' THEN 2 
  END,
  r.floor,
  r.room_number;
```

### Use Case 3: Update Room Status
```sql
-- Start cleaning
UPDATE rooms 
SET housekeeping_status = 'Cleaning' 
WHERE room_number = '101';

-- Finish cleaning
UPDATE rooms 
SET housekeeping_status = 'Clean' 
WHERE room_number = '101';

-- Inspect and approve
UPDATE rooms 
SET housekeeping_status = 'Inspected' 
WHERE room_number = '101';

-- Check updated_at was automatically updated
SELECT room_number, housekeeping_status, updated_at 
FROM rooms 
WHERE room_number = '101';
```

### Use Case 4: Search Rooms by Amenity
```sql
-- Find room types with WiFi and TV
SELECT DISTINCT rt.name, rt.base_price
FROM room_types rt
JOIN room_type_amenities rta ON rt.room_type_id = rta.room_type_id
JOIN amenities a ON rta.amenity_id = a.amenity_id
WHERE a.name IN ('Free WiFi', 'Flat-screen TV')
GROUP BY rt.room_type_id, rt.name, rt.base_price
HAVING COUNT(DISTINCT a.name) = 2;
```

### Use Case 5: Room Availability by Type
```sql
-- Check availability for each room type
SELECT 
  rt.name as room_type,
  COUNT(r.room_id) as total_rooms,
  SUM(CASE WHEN r.occupancy_status = 'Occupied' THEN 1 ELSE 0 END) as occupied,
  SUM(CASE WHEN r.occupancy_status = 'Vacant' 
           AND r.housekeeping_status IN ('Clean', 'Inspected') THEN 1 ELSE 0 END) as ready_to_sell,
  SUM(CASE WHEN r.occupancy_status = 'Vacant' 
           AND r.housekeeping_status = 'Dirty' THEN 1 ELSE 0 END) as needs_cleaning
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.name
ORDER BY rt.name;
```

## 🔧 Testing

### Run All Tests
```bash
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/test_migration_002.sql
```

### Quick Manual Tests

```sql
-- Test 1: Try to insert invalid occupancy status (should fail)
INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
VALUES (1, 'TEST001', 1, 'InvalidStatus', 'Clean');
-- Expected: ERROR: check constraint violation

-- Test 2: Try to insert duplicate room number (should fail)
INSERT INTO rooms (room_type_id, room_number, floor, occupancy_status, housekeeping_status)
VALUES (1, '101', 1, 'Vacant', 'Clean');
-- Expected: ERROR: duplicate key value violates unique constraint

-- Test 3: Update room and check trigger
SELECT room_number, updated_at FROM rooms WHERE room_number = '101';
UPDATE rooms SET notes = 'Test update' WHERE room_number = '101';
SELECT room_number, updated_at FROM rooms WHERE room_number = '101';
-- Expected: updated_at should be different

-- Clean up test
UPDATE rooms SET notes = NULL WHERE room_number = '101';
```

## 📚 Documentation

- **Full Summary**: `TASK_4_SUMMARY.md`
- **Quick Reference**: `ROOM_MANAGEMENT_REFERENCE.md`
- **Schema Diagram**: `SCHEMA_DIAGRAM.md`
- **Completion Report**: `../TASK_4_COMPLETION.md`

## 🐛 Troubleshooting

### Problem: Docker not running
```bash
# Start Docker Desktop, then:
docker-compose up -d db
```

### Problem: Container not found
```bash
# Check container name
docker ps -a | grep hotel

# If different name, update scripts or use:
docker exec -i <actual-container-name> psql -U postgres -d hotel_booking < ...
```

### Problem: Permission denied (Linux/Mac)
```bash
chmod +x database/migrations/run_migration_002.sh
```

### Problem: Migration already applied
This is OK! The migration uses `IF NOT EXISTS` and `ON CONFLICT DO NOTHING`, so it's safe to run multiple times.

### Problem: Can't connect to database
```bash
# Check if database is ready
docker exec hotel-booking-db pg_isready -U postgres

# Check logs
docker-compose logs db

# Restart if needed
docker-compose restart db
```

## 🎨 Status Color Guide

When building UI, use these colors:

| Status | Color | Hex | Use Case |
|--------|-------|-----|----------|
| Vacant + Inspected | 🟢 Green | #4CAF50 | Best for check-in |
| Vacant + Clean | 🟡 Yellow | #FFEB3B | Available |
| Vacant + Dirty | 🟠 Orange | #FF9800 | Needs cleaning |
| Vacant + Cleaning | 🔵 Blue | #2196F3 | In progress |
| Occupied | 🔴 Red | #F44336 | Not available |
| MaintenanceRequired | 🟣 Purple | #9C27B0 | Needs repair |
| OutOfService | ⚫ Gray | #9E9E9E | Closed |

## 🔗 Next Steps

After this migration:
1. ✅ You have room types, rooms, and amenities
2. ⏳ Next: Task 5 - Pricing & Inventory Schema
3. ⏳ Then: Task 6 - Bookings Schema
4. ⏳ Then: Task 10 - Room Search API (Backend)

## 💡 Pro Tips

1. **Use Inspected rooms first**: They're quality-checked
2. **Index usage**: The composite index on (occupancy_status, housekeeping_status) is your friend
3. **Triggers**: updated_at updates automatically - don't set it manually
4. **Seed data**: Designed for testing - includes various status combinations
5. **Room numbers**: Follow pattern XXY (XX=floor, Y=sequence)

## 📞 Need Help?

Check these files:
- `ROOM_MANAGEMENT_REFERENCE.md` - Common queries
- `TASK_4_SUMMARY.md` - Complete documentation
- `test_migration_002.sql` - Test examples

## ⚡ Quick Commands Cheat Sheet

```bash
# Start database
docker-compose up -d db

# Connect to database
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking

# Run migration
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/002_create_room_management_tables.sql

# Run tests
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/test_migration_002.sql

# Check logs
docker-compose logs -f db

# Stop database
docker-compose stop db

# Reset database (WARNING: deletes all data)
docker-compose down -v
docker-compose up -d db
```

---

**Ready to go!** 🚀

Start with Step 1 above and you'll have a working room management system in 5 minutes.
