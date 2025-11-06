# Demo Data Seed Guide

## Quick Start

### Option 1: Using Docker (Recommended)

**Windows:**
```bash
cd database\migrations
run_seed_demo_data_docker.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_seed_demo_data_docker.sh
./run_seed_demo_data_docker.sh
```

### Option 2: Using psql directly (if installed)

**Windows:**
```bash
cd database\migrations
run_seed_demo_data.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_seed_demo_data.sh
./run_seed_demo_data.sh
```

### Option 3: Manual execution

**Using Docker:**
```bash
# From database/migrations directory
docker exec -i booking-hotel-postgres-1 psql -U postgres -d hotel_booking < 013_seed_demo_data.sql
```

**Using psql:**
```bash
# From database/migrations directory
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

---

## Prerequisites

### For Docker Method
1. Docker Desktop installed and running
2. PostgreSQL container running:
   ```bash
   docker-compose up -d postgres
   ```
3. Verify container is running:
   ```bash
   docker ps | grep postgres
   ```

### For psql Method
1. PostgreSQL client installed
2. psql command in PATH
3. Database connection configured

---

## Troubleshooting

### Error: "psql command not found"
**Solution:** Use the Docker method instead:
```bash
run_seed_demo_data_docker.bat  # Windows
./run_seed_demo_data_docker.sh # Linux/Mac
```

### Error: "Docker is not running"
**Solution:** 
1. Start Docker Desktop
2. Wait for it to fully start
3. Try again

### Error: "PostgreSQL container is not running"
**Solution:**
```bash
# Start the database
docker-compose up -d postgres

# Verify it's running
docker ps

# Then run seed script
run_seed_demo_data_docker.bat
```

### Error: "Container name not found"
**Solution:** Check your container name:
```bash
# List all containers
docker ps

# Find the postgres container name
# It might be: booking-hotel-postgres-1, postgres, or hotel_booking_postgres

# Update the script with correct name, or run manually:
docker exec -i YOUR_CONTAINER_NAME psql -U postgres -d hotel_booking < 013_seed_demo_data.sql
```

### Error: "Database does not exist"
**Solution:** Create the database first:
```bash
# Using Docker
docker exec -it booking-hotel-postgres-1 psql -U postgres -c "CREATE DATABASE hotel_booking;"

# Then run migrations
cd backend/scripts
run-migrations.bat  # Windows
./run-migrations.sh # Linux/Mac

# Then seed data
cd ../../database/migrations
run_seed_demo_data_docker.bat
```

---

## Verification

After seeding, verify the data:

```bash
# Using Docker
docker exec -it booking-hotel-postgres-1 psql -U postgres -d hotel_booking

# Then in psql:
SELECT COUNT(*) FROM guests;        -- Should return 5
SELECT COUNT(*) FROM rooms;         -- Should return 50
SELECT COUNT(*) FROM bookings;      -- Should return 30
SELECT COUNT(*) FROM vouchers;      -- Should return 5
```

Expected output:
```
guests:    5
rooms:     50
bookings:  30
vouchers:  5
```

---

## Demo Credentials

After successful seeding, use these credentials:

### Guest Account
- Email: somchai@example.com
- Password: password123

### Staff Account (Receptionist)
- Email: staff@hotel.com
- Password: staff123

### Housekeeper Account
- Email: housekeeper@hotel.com
- Password: housekeeper123

### Manager Account
- Email: manager@hotel.com
- Password: manager123

---

## What Gets Created

The seed script creates:

- **5 guest accounts** with authentication
- **50 rooms** (20 Standard, 20 Deluxe, 10 Suite)
- **10 amenities** with room mappings
- **4 rate tiers** (Low, Standard, High, Peak)
- **4 rate plans** with pricing
- **90-day pricing calendar**
- **270 inventory records** (90 days × 3 room types)
- **5 active vouchers**
- **30 bookings** with various statuses
- **Complete relational data** (guests, details, logs, assignments)

**Total: 200+ records**

---

## Resetting Demo Data

To reset and re-seed:

```bash
# 1. Clear existing data (optional)
docker exec -it booking-hotel-postgres-1 psql -U postgres -d hotel_booking -c "
DELETE FROM booking_nightly_log;
DELETE FROM room_assignments;
DELETE FROM booking_guests;
DELETE FROM booking_details;
DELETE FROM bookings;
DELETE FROM booking_holds;
DELETE FROM room_inventory;
DELETE FROM pricing_calendar;
DELETE FROM vouchers;
DELETE FROM rate_pricing;
DELETE FROM room_type_amenities;
DELETE FROM amenities;
DELETE FROM rooms;
DELETE FROM guest_accounts;
DELETE FROM guests;
"

# 2. Re-run seed script
run_seed_demo_data_docker.bat
```

---

## Next Steps

After seeding:

1. **Start the application:**
   ```bash
   # Backend
   cd backend
   go run cmd/server/main.go
   
   # Frontend (new terminal)
   cd frontend
   npm run dev
   ```

2. **Access the system:**
   - Frontend: http://localhost:3000
   - Backend: http://localhost:8080

3. **Try demo scenarios:**
   - See `docs/DEMO_SCENARIOS.md` for detailed scenarios
   - See `docs/DEMO_QUICK_REFERENCE.md` for quick reference

---

## Support

For more help:
- **Main Demo Guide:** `docs/DEMO_README.md`
- **Quick Reference:** `docs/DEMO_QUICK_REFERENCE.md`
- **All Materials:** `docs/DEMO_MATERIALS_INDEX.md`

