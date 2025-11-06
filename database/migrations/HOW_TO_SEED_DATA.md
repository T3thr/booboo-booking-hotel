# How to Seed Demo Data - Complete Guide

## 🎯 Choose Your Method

### Method 1: Docker (Easiest - Recommended)
✅ Use if you have Docker Desktop installed  
✅ No need to install PostgreSQL separately

### Method 2: Direct psql
✅ Use if you have PostgreSQL installed locally  
✅ psql command available in PATH

### Method 3: Manual SQL
✅ Use if other methods don't work  
✅ Works with any SQL client

---

## 📦 Method 1: Using Docker

### Step 1: Start Docker Desktop
1. Open Docker Desktop application
2. Wait for it to fully start (whale icon in system tray)

### Step 2: Start Database Container
```bash
# From project root
docker-compose up -d db
```

### Step 3: Verify Container is Running
```bash
docker ps
```
You should see `hotel-booking-db` in the list.

### Step 4: Run Seed Script
```bash
# Windows
cd database\migrations
run_seed_demo_data_docker.bat

# Linux/Mac
cd database/migrations
chmod +x run_seed_demo_data_docker.sh
./run_seed_demo_data_docker.sh
```

### Alternative: Manual Docker Command
```bash
# From database/migrations directory
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < 013_seed_demo_data.sql
```

---

## 💻 Method 2: Using psql Directly

### Prerequisites
- PostgreSQL installed
- psql command in PATH
- Database running on localhost:5432

### Step 1: Verify psql is Available
```bash
psql --version
```

### Step 2: Run Seed Script
```bash
# Windows
cd database\migrations
run_seed_demo_data.bat

# Linux/Mac
cd database/migrations
chmod +x run_seed_demo_data.sh
./run_seed_demo_data.sh
```

### Alternative: Manual psql Command
```bash
# From database/migrations directory
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

---

## 📝 Method 3: Manual SQL Execution

### Option A: Using pgAdmin
1. Open pgAdmin
2. Connect to your database
3. Open Query Tool
4. Load file: `database/migrations/013_seed_demo_data.sql`
5. Execute (F5)

### Option B: Using DBeaver
1. Open DBeaver
2. Connect to hotel_booking database
3. Open SQL Editor
4. Load file: `database/migrations/013_seed_demo_data.sql`
5. Execute (Ctrl+Enter)

### Option C: Using DataGrip
1. Open DataGrip
2. Connect to hotel_booking database
3. Open SQL file: `database/migrations/013_seed_demo_data.sql`
4. Execute (Ctrl+Enter)

### Option D: Copy-Paste
1. Open `database/migrations/013_seed_demo_data.sql` in text editor
2. Copy all content
3. Paste into your SQL client
4. Execute

---

## ✅ Verification

After seeding, verify the data was created:

### Using Docker
```bash
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking -c "SELECT COUNT(*) FROM guests;"
```

### Using psql
```bash
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) FROM guests;"
```

### Expected Results
```sql
SELECT COUNT(*) FROM guests;        -- 5
SELECT COUNT(*) FROM rooms;         -- 50
SELECT COUNT(*) FROM bookings;      -- 30
SELECT COUNT(*) FROM vouchers;      -- 5
SELECT COUNT(*) FROM room_inventory; -- 270
```

---

## 🔑 Demo Credentials

After successful seeding:

| Role | Email | Password |
|------|-------|----------|
| Guest | somchai@example.com | password123 |
| Staff | staff@hotel.com | staff123 |
| Housekeeper | housekeeper@hotel.com | housekeeper123 |
| Manager | manager@hotel.com | manager123 |

---

## 🐛 Troubleshooting

### Problem: "psql command not found"
**Solution:** Use Docker method or install PostgreSQL client

### Problem: "Docker is not running"
**Solution:**
1. Start Docker Desktop
2. Wait for it to fully start
3. Try again

### Problem: "Container not found"
**Solution:**
```bash
# Check container name
docker ps

# Start database
docker-compose up -d db

# Try again
```

### Problem: "Database does not exist"
**Solution:**
```bash
# Create database
docker exec -it hotel-booking-db psql -U postgres -c "CREATE DATABASE hotel_booking;"

# Run migrations first
cd backend/scripts
run-migrations.bat  # or .sh

# Then seed data
cd ../../database/migrations
run_seed_demo_data_docker.bat
```

### Problem: "Permission denied"
**Solution (Linux/Mac):**
```bash
chmod +x run_seed_demo_data_docker.sh
./run_seed_demo_data_docker.sh
```

### Problem: "Connection refused"
**Solution:**
```bash
# Check if database is running
docker ps | grep hotel-booking-db

# Check database logs
docker logs hotel-booking-db

# Restart database
docker-compose restart db
```

---

## 🔄 Resetting Demo Data

To clear and re-seed:

```bash
# Using Docker
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking << EOF
TRUNCATE TABLE booking_nightly_log CASCADE;
TRUNCATE TABLE room_assignments CASCADE;
TRUNCATE TABLE booking_guests CASCADE;
TRUNCATE TABLE booking_details CASCADE;
TRUNCATE TABLE bookings CASCADE;
TRUNCATE TABLE booking_holds CASCADE;
TRUNCATE TABLE room_inventory CASCADE;
TRUNCATE TABLE pricing_calendar CASCADE;
TRUNCATE TABLE vouchers CASCADE;
TRUNCATE TABLE rate_pricing CASCADE;
TRUNCATE TABLE room_type_amenities CASCADE;
TRUNCATE TABLE amenities CASCADE;
TRUNCATE TABLE rooms CASCADE;
TRUNCATE TABLE guest_accounts CASCADE;
TRUNCATE TABLE guests CASCADE;
EOF

# Then re-run seed script
run_seed_demo_data_docker.bat
```

---

## 📊 What Gets Created

The seed script creates **200+ records**:

### Users & Authentication
- 5 guest accounts with hashed passwords
- 5 guest profiles

### Rooms & Amenities
- 50 rooms (20 Standard, 20 Deluxe, 10 Suite)
- 10 amenities
- 23 room-amenity mappings

### Pricing Structure
- 4 rate tiers (Low, Standard, High, Peak)
- 4 rate plans
- 48 pricing points (rate matrix)
- 4 cancellation policies
- 90-day pricing calendar
- 270 inventory records (90 days × 3 room types)

### Bookings
- 30 bookings with various statuses:
  - 15 Confirmed (future)
  - 5 CheckedIn (current)
  - 8 Completed (past)
  - 2 Cancelled
- 30+ booking details
- 35+ guest information records
- 80+ nightly pricing logs
- 5 active room assignments

### Marketing
- 5 active vouchers with different discount types

---

## 🚀 Next Steps

After seeding:

1. **Start the application:**
   ```bash
   # Option A: Using Docker
   docker-compose up -d
   
   # Option B: Manual
   # Terminal 1: Backend
   cd backend && go run cmd/server/main.go
   
   # Terminal 2: Frontend
   cd frontend && npm run dev
   ```

2. **Access the system:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080
   - API Docs: http://localhost:8080/swagger

3. **Try demo scenarios:**
   - See `docs/DEMO_SCENARIOS.md`
   - See `docs/DEMO_QUICK_REFERENCE.md`

---

## 📚 Additional Resources

- **Demo Guide:** `docs/DEMO_README.md`
- **Quick Reference:** `docs/DEMO_QUICK_REFERENCE.md`
- **Scenarios:** `docs/DEMO_SCENARIOS.md`
- **Presentation:** `docs/PRESENTATION_OUTLINE.md`
- **Video Script:** `docs/VIDEO_DEMO_SCRIPT.md`

---

## 💡 Tips

1. **First time?** Use Docker method - it's the easiest
2. **Having issues?** Check Docker Desktop is running
3. **Need help?** See troubleshooting section above
4. **Want to reset?** Use the reset commands above
5. **Ready to demo?** Check out `docs/DEMO_QUICK_REFERENCE.md`

---

**Need more help?** Check `docs/DEMO_MATERIALS_INDEX.md` for complete navigation.

