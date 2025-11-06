# Backend Scripts

## 🚀 Production Scripts

### run-migrations.bat / run-migrations.sh

รัน database migrations ทั้งหมดบน production database

**Usage**:
```bash
# Windows
set DATABASE_URL=postgresql://user:password@host:port/database
cd backend\scripts
run-migrations.bat

# Linux/Mac
export DATABASE_URL=postgresql://user:password@host:port/database
cd backend/scripts
./run-migrations.sh
```

**What it does**:
1. รัน migrations ทั้งหมดตามลำดับ (001-012)
2. สร้าง tables, functions, indexes
3. ตรวจสอบว่า functions สำคัญถูกสร้างแล้ว

**Requirements**:
- PostgreSQL client (`psql`) ต้องติดตั้งแล้ว
- `DATABASE_URL` environment variable ต้องตั้งค่าแล้ว

---

## 📋 Migration Files

```
database/migrations/
├── 001_create_guests_tables.sql              - Guest accounts
├── 002_create_room_management_tables.sql     - Rooms & types
├── 003_create_pricing_inventory_tables.sql   - Pricing & inventory
├── 004_create_bookings_tables.sql            - Bookings
├── 005_create_booking_hold_function.sql      - Hold rooms
├── 006_create_confirm_booking_function.sql   - Confirm booking
├── 007_create_cancel_booking_function.sql    - Cancel booking
├── 008_create_release_expired_holds_function.sql - Release holds
├── 009_create_check_in_function.sql          - Check-in
├── 010_create_check_out_function.sql         - Check-out
├── 011_create_move_room_function.sql         - Move room
└── 012_performance_optimization.sql          - Indexes & optimization
```

---

## 🔧 Troubleshooting

### Error: psql command not found

**Solution**:
```bash
# Windows (Chocolatey)
choco install postgresql

# Or download from
# https://www.postgresql.org/download/windows/
```

### Error: DATABASE_URL not set

**Solution**:
```bash
# Get URL from Render Dashboard → Database → External Database URL
set DATABASE_URL=postgresql://user:password@host:port/database
```

### Error: Connection refused

**Solution**:
1. ตรวจสอบ DATABASE_URL format
2. ตรวจสอบ database status
3. ตรวจสอบ network/firewall

---

## 📚 Related Documentation

- [QUICK_FIX_RENDER.md](../../QUICK_FIX_RENDER.md) - Fix migration issues
- [RENDER_PRODUCTION_SETUP.md](../../RENDER_PRODUCTION_SETUP.md) - Complete setup
- [database/migrations/README.md](../../database/migrations/README.md) - Migration details
