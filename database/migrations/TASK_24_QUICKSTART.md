# Task 24 Quickstart: Move Room Function

## Quick Setup

### Prerequisites
- PostgreSQL database running
- Database `hotel_booking` exists
- Previous migrations (001-010) completed
- Tables: `room_assignments`, `rooms`, `booking_details` exist

### Installation Steps

#### Option 1: Using Docker (Recommended)

```bash
# 1. Make sure Docker containers are running
docker-compose up -d

# 2. Run migration
docker exec -i <postgres-container-name> psql -U postgres -d hotel_booking < database/migrations/011_create_move_room_function.sql

# 3. Verify installation
docker exec -i <postgres-container-name> psql -U postgres -d hotel_booking < database/migrations/verify_move_room.sql

# 4. Run tests
docker exec -i <postgres-container-name> psql -U postgres -d hotel_booking < database/migrations/test_move_room_function.sql
```

#### Option 2: Using Local PostgreSQL (Windows)

```cmd
cd database\migrations

REM Run migration
psql -h localhost -p 5432 -U postgres -d hotel_booking -f 011_create_move_room_function.sql

REM Verify
psql -h localhost -p 5432 -U postgres -d hotel_booking -f verify_move_room.sql

REM Test
psql -h localhost -p 5432 -U postgres -d hotel_booking -f test_move_room_function.sql
```

#### Option 3: Using Scripts

```bash
# Windows
run_migration_011.bat
run_migration_011.bat verify
run_test_move_room.bat

# Linux/Mac
chmod +x run_migration_011.sh run_test_move_room.sh
./run_migration_011.sh
./run_migration_011.sh verify
./run_test_move_room.sh
```

## Quick Test

After installation, test the function:

```sql
-- 1. Find an active assignment
SELECT 
    ra.room_assignment_id,
    r.room_number as current_room,
    bd.booking_id
FROM room_assignments ra
JOIN rooms r ON ra.room_id = r.room_id
JOIN booking_details bd ON ra.booking_detail_id = bd.booking_detail_id
WHERE ra.status = 'Active'
LIMIT 1;

-- 2. Find an available room
SELECT room_id, room_number, room_type_id
FROM rooms
WHERE occupancy_status = 'Vacant'
  AND housekeeping_status IN ('Clean', 'Inspected')
LIMIT 1;

-- 3. Test move_room function
SELECT * FROM move_room(
    <room_assignment_id>,  -- from step 1
    <new_room_id>,         -- from step 2
    'Testing room move function'
);
```

Expected output:
```
success | message                                                    | new_assignment_id
--------|------------------------------------------------------------|-----------------
true    | ย้ายห้องสำเร็จ - จากห้อง XXX ไปห้อง YYY (Assignment ID: ...) | <new_id>
```

## Quick Usage Examples

### Example 1: Move due to maintenance

```sql
SELECT * FROM move_room(
    12345,
    205,
    'Air conditioning malfunction'
);
```

### Example 2: Move for upgrade

```sql
SELECT * FROM move_room(
    12345,
    301,
    'Room upgrade - guest request'
);
```

### Example 3: Move due to complaint

```sql
SELECT * FROM move_room(
    12345,
    210,
    'Noise complaint from neighboring room'
);
```

## Verification Checklist

After installation, verify:

- [ ] Function `move_room` exists
  ```sql
  SELECT proname FROM pg_proc WHERE proname = 'move_room';
  ```

- [ ] Function has correct signature
  ```sql
  \df move_room
  ```

- [ ] All tests pass (6 tests)
  - ✓ Successful room move
  - ✓ Cannot move to same room
  - ✓ Cannot move to occupied room
  - ✓ Cannot move to dirty room
  - ✓ Cannot move non-active assignment
  - ✓ Cannot move non-existent assignment

- [ ] Function returns expected columns
  ```sql
  SELECT * FROM move_room(NULL, NULL) LIMIT 0;
  -- Should show: success, message, new_assignment_id
  ```

## Common Issues

### Issue 1: Function already exists

**Error:** `function "move_room" already exists`

**Solution:**
```sql
DROP FUNCTION IF EXISTS move_room;
-- Then re-run migration
```

### Issue 2: Tables not found

**Error:** `relation "room_assignments" does not exist`

**Solution:** Run previous migrations first (001-010)

### Issue 3: No test data

**Error:** Tests fail due to missing data

**Solution:** Ensure you have:
- At least one room type
- At least two vacant, clean rooms
- Seed data from previous migrations

### Issue 4: Permission denied

**Error:** `permission denied for function move_room`

**Solution:**
```sql
GRANT EXECUTE ON FUNCTION move_room TO <your_user>;
```

## Next Steps

After successful installation:

1. ✅ Mark Task 24 as complete in tasks.md
2. ⏭️ Proceed to Task 25: Backend Check-in/out Module
3. 📖 Read `MOVE_ROOM_REFERENCE.md` for detailed usage
4. 🔗 Integrate with backend API

## Quick Reference

**Function Signature:**
```sql
move_room(
    p_room_assignment_id BIGINT,
    p_new_room_id INT,
    p_reason TEXT DEFAULT NULL
)
```

**Returns:**
- `success` (BOOLEAN)
- `message` (TEXT)
- `new_assignment_id` (BIGINT)

**Key Validations:**
- Assignment must be Active
- New room must be Vacant
- New room must be Clean or Inspected
- Cannot move to same room

**Atomic Operations:**
1. Close old assignment (Moved)
2. Create new assignment (Active)
3. Update old room (Vacant + Dirty)
4. Update new room (Occupied)

## Documentation

- **Detailed Reference:** `MOVE_ROOM_REFERENCE.md`
- **Summary:** `TASK_24_SUMMARY.md`
- **Requirements:** `.kiro/specs/hotel-reservation-system/requirements.md` (Requirement 8)
- **Design:** `.kiro/specs/hotel-reservation-system/design.md`

## Support

If you encounter issues:
1. Check the verification script output
2. Review test results
3. Check PostgreSQL logs
4. Ensure all prerequisites are met
5. Refer to `MOVE_ROOM_REFERENCE.md` for detailed examples

---

**Task Status:** ✅ Ready for use  
**Last Updated:** 2025-11-03  
**Version:** 1.0
