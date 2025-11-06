# Database Migrations

This directory contains PostgreSQL migration scripts for the Hotel Booking System.

## Structure

```
database/
├── migrations/          # SQL migration files
│   ├── 001_create_guests_tables.sql
│   ├── 002_create_room_management_tables.sql
│   ├── test_migration.sql
│   ├── test_migration_002.sql
│   ├── verify_room_management.sql
│   ├── run_migration_002.bat
│   ├── run_migration_002.sh
│   ├── TASK_3_SUMMARY.md
│   ├── TASK_4_SUMMARY.md
│   └── ROOM_MANAGEMENT_REFERENCE.md
└── queries/            # Complex queries (future use)
```

## Migration Files

### 001_create_guests_tables.sql

Creates the foundation for guest management and authentication:

**Tables:**
- `guests` - Stores guest personal information
- `guest_accounts` - Stores authentication credentials

**Features:**
- Email uniqueness constraint
- Foreign key with CASCADE delete
- Indexes for performance
- Seed data with 10 test guests
- All test accounts use password: `password123`

**Test Accounts:**
| Email | Password | Name |
|-------|----------|------|
| test.user1@example.com | password123 | ทดสอบ ระบบหนึ่ง |
| demo.user2@example.com | password123 | ผู้ใช้ ตัวอย่างสอง |
| guest.sample3@example.com | password123 | แขก ทดลองสาม |
| yingluck@example.com | password123 | ยิ่งลักษณ์ ชินวัตร |
| abhisit@example.com | password123 | อภิสิทธิ์ เวชชาชีวะ |
| thaksin@example.com | password123 | ทักษิณ ชินวัตร |
| pitha@example.com | password123 | พิธา ลิ้มเจริญรัตน์ |
| srettha@example.com | password123 | เศรษฐา ทวีสิน |
| jurin@example.com | password123 | จุรินทร์ ลักษณวิศิษฏ์ |
| anutin@example.com | password123 | อนุทิน ชาญวีรกูล |

## Running Migrations

### Using Docker Compose (Automatic)

Migrations in the `migrations/` directory are automatically executed when the database container starts:

```bash
# Start the database
docker-compose up -d db

# Check logs to verify migration
docker-compose logs db
```

### Manual Execution

If you need to run migrations manually:

```bash
# Connect to the database
docker-compose exec db psql -U postgres -d hotel_booking

# Run a specific migration
docker-compose exec db psql -U postgres -d hotel_booking -f /docker-entrypoint-initdb.d/001_create_guests_tables.sql
```

### Using psql directly

```bash
psql -h localhost -p 5432 -U postgres -d hotel_booking -f database/migrations/001_create_guests_tables.sql
```

## Testing Migrations

Run the test script to verify the migration:

```bash
# Using Docker
docker-compose exec db psql -U postgres -d hotel_booking -f /docker-entrypoint-initdb.d/test_migration.sql

# Or copy and paste into psql
docker-compose exec db psql -U postgres -d hotel_booking
\i /docker-entrypoint-initdb.d/test_migration.sql
```

## Verification Queries

Quick verification queries you can run:

```sql
-- Check if tables exist
\dt

-- Count records
SELECT COUNT(*) FROM guests;
SELECT COUNT(*) FROM guest_accounts;

-- View all guests with account status
SELECT 
    g.guest_id,
    g.first_name,
    g.last_name,
    g.email,
    CASE 
        WHEN ga.guest_account_id IS NOT NULL THEN 'Has Account'
        ELSE 'No Account'
    END as account_status
FROM guests g
LEFT JOIN guest_accounts ga ON g.guest_id = ga.guest_id
ORDER BY g.guest_id;
```

## Troubleshooting

### Migration doesn't run automatically

1. Check if the volume is mounted correctly in `docker-compose.yml`:
   ```yaml
   volumes:
     - ./database/migrations:/docker-entrypoint-initdb.d
   ```

2. If the database already exists, migrations won't run automatically. You need to:
   ```bash
   # Stop and remove the database container and volume
   docker-compose down -v
   
   # Start fresh
   docker-compose up -d db
   ```

### Duplicate key errors

If you see duplicate key errors, the migration has already been applied. This is expected behavior due to `ON CONFLICT DO NOTHING` clauses.

### Connection refused

Make sure Docker Desktop is running and the database container is healthy:

```bash
docker-compose ps
docker-compose logs db
```

## Database Connection Info

- **Host:** localhost
- **Port:** 5432
- **Database:** hotel_booking
- **User:** postgres
- **Password:** postgres123

### 002_create_room_management_tables.sql

Creates the room management system with 2-axis status model:

**Tables:**
- `room_types` - Room categories (Standard, Deluxe, Suite)
- `rooms` - Physical rooms with dual status tracking
- `amenities` - Room features and facilities
- `room_type_amenities` - Many-to-many relationship

**Features:**
- 2-axis status model (Occupancy + Housekeeping)
- 7 custom indexes for performance
- Automatic updated_at triggers
- Seed data: 3 room types, 20 rooms, 10 amenities
- Comprehensive constraints and validations

**Room Status Model:**
- Occupancy: Vacant, Occupied
- Housekeeping: Dirty, Cleaning, Clean, Inspected, MaintenanceRequired, OutOfService

**Seed Data:**
- Standard Room: 10 rooms (101-110), 6 amenities, 1,500 THB
- Deluxe Room: 7 rooms (201-207), 8 amenities, 2,500 THB
- Suite Room: 3 rooms (301-303), 10 amenities, 4,500 THB

See `TASK_4_SUMMARY.md` and `ROOM_MANAGEMENT_REFERENCE.md` for detailed documentation.

## Next Steps

After verifying migrations:
1. ✅ Task 3: Guest & Authentication schema (Complete)
2. ✅ Task 4: Room Management schema (Complete)
3. ⏳ Task 5: Pricing & Inventory schema
4. ⏳ Task 6: Bookings schema

## Requirements Covered

This migration satisfies requirements:
- 1.1: Guest registration with email and password
- 1.2: Email uniqueness validation
- 1.3: Login with credentials
- 1.4: Profile updates (UpdatedAt timestamp)
- 1.5: Email format validation (enforced at application level)
- 1.6: Password reset capability (structure in place)
