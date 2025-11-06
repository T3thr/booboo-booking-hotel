# Migration 004 Quick Start Guide

## Overview

This guide will help you quickly run Migration 004 (Bookings Schema) and verify it's working correctly.

## Prerequisites

Before running this migration, ensure:

1. ✅ PostgreSQL 15+ is installed and running
2. ✅ Database `hotel_booking` exists
3. ✅ Migrations 001, 002, and 003 are completed
4. ✅ `.env` file exists with database credentials

## Quick Start (5 minutes)

### Step 1: Verify Prerequisites

Check if previous migrations are complete:

```bash
psql -h localhost -U postgres -d hotel_booking -c "\dt"
```

You should see these tables:
- `guests`
- `guest_accounts`
- `room_types`
- `rooms`
- `amenities`
- `room_type_amenities`
- `room_inventory`
- `rate_tiers`
- `pricing_calendar`
- `rate_plans`
- `rate_pricing`
- `cancellation_policies`
- `vouchers`
- `booking_holds`

### Step 2: Run Migration

**Option A: Using Script (Recommended)**

Linux/Mac:
```bash
cd database/migrations
chmod +x run_migration_004.sh
./run_migration_004.sh
```

Windows:
```cmd
cd database\migrations
run_migration_004.bat
```

**Option B: Manual**

```bash
cd database/migrations
psql -h localhost -U postgres -d hotel_booking -f 004_create_bookings_tables.sql
```

### Step 3: Verify Installation

```bash
psql -h localhost -U postgres -d hotel_booking -f verify_bookings.sql
```

Expected output:
```
✓ All 5 booking tables exist
✓ Created 15+ indexes for booking tables
✓ Created 9 foreign key constraints
```

### Step 4: Run Tests (Optional but Recommended)

```bash
psql -h localhost -U postgres -d hotel_booking -f test_migration_004.sql
```

Expected output:
```
✓ Created booking_id: 1
✓ Created booking detail
✓ Added booking guests
✓ Created 3 nightly log entries
✓ Booking confirmed
✓ Created room assignment
✓ All constraint validations passed
✓ All Tests Passed Successfully!
```

## What Gets Created

### Tables (5)
1. **bookings** - Main booking records
2. **booking_details** - Individual room bookings
3. **room_assignments** - Physical room assignments
4. **booking_guests** - Guest information
5. **booking_nightly_log** - Nightly price snapshots

### Indexes (15+)
- Performance indexes on all foreign keys
- Composite indexes for date ranges
- Partial indexes for filtered queries

### Constraints
- 8 check constraints
- 9 foreign key constraints
- 1 unique constraint

### Triggers (1)
- Auto-update `updated_at` on bookings

## Verify Tables Exist

Quick check:

```bash
psql -h localhost -U postgres -d hotel_booking -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('bookings', 'booking_details', 'room_assignments', 
                   'booking_guests', 'booking_nightly_log')
ORDER BY table_name;
"
```

Expected output:
```
     table_name      
---------------------
 booking_details
 booking_guests
 booking_nightly_log
 bookings
 room_assignments
(5 rows)
```

## Test with Sample Data

Create a test booking:

```sql
BEGIN;

-- Create booking
INSERT INTO bookings (guest_id, total_amount, status, policy_name, policy_description)
SELECT guest_id, 1500.00, 'PendingPayment', 'Standard', 'Free cancellation up to 7 days'
FROM guests LIMIT 1
RETURNING booking_id;

-- Add booking detail
INSERT INTO booking_details (booking_id, room_type_id, rate_plan_id, 
                             check_in_date, check_out_date, num_guests)
SELECT 
    (SELECT booking_id FROM bookings ORDER BY booking_id DESC LIMIT 1),
    room_type_id,
    (SELECT rate_plan_id FROM rate_plans LIMIT 1),
    CURRENT_DATE + 7,
    CURRENT_DATE + 10,
    2
FROM room_types LIMIT 1;

-- View result
SELECT 
    b.booking_id,
    b.status,
    b.total_amount,
    bd.check_in_date,
    bd.check_out_date
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
ORDER BY b.booking_id DESC
LIMIT 1;

ROLLBACK;  -- Remove test data
```

## Troubleshooting

### Error: "relation does not exist"

**Problem**: Previous migrations not run

**Solution**: Run migrations in order:
```bash
psql -h localhost -U postgres -d hotel_booking -f 001_create_guests_tables.sql
psql -h localhost -U postgres -d hotel_booking -f 002_create_room_management_tables.sql
psql -h localhost -U postgres -d hotel_booking -f 003_create_pricing_inventory_tables.sql
psql -h localhost -U postgres -d hotel_booking -f 004_create_bookings_tables.sql
```

### Error: "database does not exist"

**Problem**: Database not created

**Solution**:
```bash
psql -h localhost -U postgres -c "CREATE DATABASE hotel_booking;"
```

### Error: "permission denied"

**Problem**: User doesn't have permissions

**Solution**: Grant permissions:
```bash
psql -h localhost -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE hotel_booking TO postgres;"
```

### Error: "constraint violation"

**Problem**: Test data conflicts

**Solution**: Drop and recreate tables:
```bash
psql -h localhost -U postgres -d hotel_booking -f 004_create_bookings_tables.sql
```

## Next Steps

After successful migration:

1. ✅ Review the reference documentation: `BOOKINGS_REFERENCE.md`
2. ✅ Proceed to Phase 2, Task 7: Set up Go project structure
3. ✅ Start implementing booking functions in Phase 3

## Environment Variables

Ensure your `.env` file has:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hotel_booking
DB_USER=postgres
DB_PASSWORD=your_password_here
```

Or use `DATABASE_URL`:

```env
DATABASE_URL=postgres://postgres:your_password@localhost:5432/hotel_booking?sslmode=disable
```

## Docker Setup (Alternative)

If using Docker:

```bash
# Start PostgreSQL container
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
sleep 5

# Run migration
docker-compose exec postgres psql -U postgres -d hotel_booking -f /migrations/004_create_bookings_tables.sql
```

## Verification Checklist

- [ ] All 5 tables created
- [ ] 15+ indexes created
- [ ] 9 foreign key constraints active
- [ ] 8 check constraints working
- [ ] 1 unique constraint enforced
- [ ] 1 trigger functioning
- [ ] Test script passes
- [ ] Sample booking can be created

## Support

For issues or questions:
- Check `BOOKINGS_REFERENCE.md` for detailed documentation
- Review `test_migration_004.sql` for usage examples
- See `TASK_6_COMPLETION.md` for complete implementation details

## Summary

Migration 004 creates the complete bookings schema with:
- ✅ 5 tables
- ✅ 15+ indexes
- ✅ 18 constraints
- ✅ 1 trigger
- ✅ Complete audit trail
- ✅ Multi-room support
- ✅ Room move tracking
- ✅ Price protection

**Estimated time**: 5 minutes  
**Complexity**: Medium  
**Dependencies**: Migrations 001, 002, 003

---

**Ready to proceed?** Run the migration and move on to Phase 2!
