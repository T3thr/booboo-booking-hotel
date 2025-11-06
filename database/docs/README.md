# Database Documentation

> **PostgreSQL Database Documentation Hub**

## 📋 Overview

This directory contains comprehensive documentation for the PostgreSQL database, including schema diagrams, function references, and migration guides.

## 📁 Documentation Structure

```
database/docs/
├── README.md                      # This file
├── schema/                        # Schema documentation
│   ├── overview.md
│   ├── guests.md
│   ├── rooms.md
│   ├── bookings.md
│   ├── pricing.md
│   └── inventory.md
│
├── functions/                     # PL/pgSQL functions
│   ├── booking-hold/
│   ├── confirm-booking/
│   ├── cancel-booking/
│   ├── release-expired-holds/
│   ├── check-in/
│   ├── check-out/
│   └── move-room/
│
├── performance/                   # Performance optimization
│   ├── indexes.md
│   ├── queries.md
│   └── optimization.md
│
└── migrations/                    # Migration guides
    └── guide.md
```

## 🚀 Quick Links

### Getting Started
- [Quick Start Guide](../migrations/QUICK_START.md)
- [Schema Diagram](../migrations/SCHEMA_DIAGRAM.md)
- [Migration Guide](./migrations/guide.md)

### Schema Documentation
- [Guests & Authentication](./schema/guests.md)
- [Room Management](./schema/rooms.md)
- [Bookings](./schema/bookings.md)
- [Pricing & Inventory](./schema/pricing.md)

### Functions
- [Booking Functions](./functions/README.md)
- [Check-in/out Functions](./functions/checkin-checkout.md)
- [Utility Functions](./functions/utilities.md)

### Performance
- [Performance Optimization](./performance/optimization.md)
- [Index Strategy](./performance/indexes.md)
- [Query Optimization](./performance/queries.md)

## 📊 Database Schema

### Core Tables

#### Guests & Authentication
- `guests` - Guest information
- `guest_accounts` - Authentication credentials

#### Room Management
- `room_types` - Room type definitions
- `rooms` - Individual rooms
- `amenities` - Room amenities
- `room_type_amenities` - Room type amenity mapping

#### Bookings
- `bookings` - Main booking records
- `booking_details` - Booking line items
- `room_assignments` - Room assignments
- `booking_guests` - Additional guests
- `booking_nightly_log` - Nightly snapshots

#### Pricing & Inventory
- `room_inventory` - Daily room availability
- `rate_tiers` - Pricing tiers (Low, Medium, High)
- `pricing_calendar` - Daily tier assignments
- `rate_plans` - Rate plan definitions
- `rate_pricing` - Rate pricing matrix

#### Policies & Vouchers
- `cancellation_policies` - Cancellation rules
- `vouchers` - Discount vouchers
- `booking_holds` - Temporary holds

## 🔧 PostgreSQL Functions

### Booking Functions

#### create_booking_hold
Creates a temporary booking hold with inventory check.

```sql
SELECT create_booking_hold(
  p_guest_id := 1,
  p_room_type_id := 1,
  p_check_in_date := '2025-02-10',
  p_check_out_date := '2025-02-12',
  p_num_rooms := 1
);
```

#### confirm_booking
Confirms a booking and moves from tentative to booked.

```sql
SELECT confirm_booking(
  p_booking_id := 1,
  p_payment_method := 'credit_card'
);
```

#### cancel_booking
Cancels a booking and returns inventory.

```sql
SELECT cancel_booking(
  p_booking_id := 1,
  p_cancelled_by := 'guest'
);
```

### Check-in/out Functions

#### check_in
Performs guest check-in and assigns room.

```sql
SELECT check_in(
  p_booking_id := 1,
  p_room_id := 101
);
```

#### check_out
Performs guest check-out.

```sql
SELECT check_out(
  p_booking_id := 1
);
```

#### move_room
Moves guest to different room.

```sql
SELECT move_room(
  p_booking_id := 1,
  p_new_room_id := 102,
  p_reason := 'Guest request'
);
```

### Utility Functions

#### release_expired_holds
Releases expired booking holds (runs every 5 minutes).

```sql
SELECT release_expired_holds();
```

## 📈 Performance Optimization

### Indexes
- Primary keys on all tables
- Foreign key indexes
- Composite indexes for common queries
- Partial indexes for specific conditions

### Query Optimization
- Use of CTEs for complex queries
- Proper JOIN strategies
- Index usage verification with EXPLAIN
- Query result caching where appropriate

### Maintenance
- Regular VACUUM operations
- Index rebuilding
- Statistics updates
- Performance monitoring

## 🧪 Testing

### Run Migrations
```bash
cd database/migrations

# Run specific migration
./run_migration_001.sh

# Verify migration
./verify_schema.sh
```

### Test Functions
```bash
# Test booking hold
./run_test_booking_hold.sh

# Test check-in
./run_test_check_in.sh

# Test all functions
./run_all_tests.sh
```

### Integration Tests
```bash
cd database/tests
./run_integration_tests.sh
```

## 📝 Migration Guide

### Creating New Migration
1. Create SQL file: `XXX_description.sql`
2. Write migration script
3. Create test file: `test_XXX.sql`
4. Create verification file: `verify_XXX.sql`
5. Create run script: `run_migration_XXX.sh`
6. Test migration
7. Document changes

### Migration Best Practices
- Always use transactions
- Include rollback procedures
- Test on development first
- Backup before production migration
- Document all changes
- Version control all migrations

## 🔗 Related Documentation

- [Backend Documentation](../../backend/docs/)
- [Frontend Documentation](../../frontend/docs/)
- [API Reference](../../docs/api/README.md)

## 📞 Need Help?

1. Check [Quick Start Guide](../migrations/QUICK_START.md)
2. Review [Schema Diagram](../migrations/SCHEMA_DIAGRAM.md)
3. See [Function References](./functions/)
4. Check [Performance Guide](./performance/)

---

**Last Updated:** 2025-02-04  
**Database Version:** PostgreSQL 15+  
**Schema Version:** 1.0.0
