# Bookings Schema Reference

## Overview

This document provides a comprehensive reference for the bookings schema (Migration 004), which manages the complete booking lifecycle from reservation to check-out.

## Table of Contents

1. [Tables](#tables)
2. [Relationships](#relationships)
3. [Key Features](#key-features)
4. [Booking Lifecycle](#booking-lifecycle)
5. [Usage Examples](#usage-examples)

## Tables

### 1. bookings

Main booking records with status tracking and policy snapshots.

**Columns:**
- `booking_id` (SERIAL, PK) - Unique booking identifier
- `guest_id` (INT, FK → guests) - Guest who made the booking
- `voucher_id` (INT, FK → vouchers, nullable) - Applied voucher/discount
- `total_amount` (DECIMAL(10,2)) - Total booking amount
- `status` (VARCHAR(50)) - Booking status
- `created_at` (TIMESTAMP) - Booking creation time
- `updated_at` (TIMESTAMP) - Last update time
- `policy_name` (VARCHAR(100)) - Snapshot of cancellation policy name
- `policy_description` (TEXT) - Snapshot of cancellation policy description

**Status Values:**
- `PendingPayment` - Booking created, awaiting payment
- `Confirmed` - Payment received, booking confirmed
- `CheckedIn` - Guest has checked in
- `Completed` - Guest has checked out
- `Cancelled` - Booking cancelled
- `NoShow` - Guest did not arrive

**Indexes:**
- `idx_bookings_guest` - On guest_id
- `idx_bookings_status` - On status
- `idx_bookings_created_at` - On created_at
- `idx_bookings_voucher` - On voucher_id (partial, WHERE voucher_id IS NOT NULL)

**Key Features:**
- Immutable policy snapshot (captured at booking time)
- Automatic updated_at timestamp via trigger
- Positive amount constraint

### 2. booking_details

Individual room bookings within a booking (supports multi-room bookings).

**Columns:**
- `booking_detail_id` (SERIAL, PK) - Unique detail identifier
- `booking_id` (INT, FK → bookings) - Parent booking
- `room_type_id` (INT, FK → room_types) - Type of room booked
- `rate_plan_id` (INT, FK → rate_plans) - Rate plan used
- `check_in_date` (DATE) - Check-in date
- `check_out_date` (DATE) - Check-out date
- `num_guests` (INT) - Number of guests

**Indexes:**
- `idx_booking_details_booking` - On booking_id
- `idx_booking_details_room_type` - On room_type_id
- `idx_booking_details_dates` - On (check_in_date, check_out_date)

**Constraints:**
- `chk_date_order` - check_out_date > check_in_date
- `chk_num_guests_positive` - num_guests > 0

**Key Features:**
- One booking can have multiple booking_details (multi-room support)
- Links to room_type (not specific room - assigned at check-in)
- Stores rate plan for pricing calculation

### 3. room_assignments

Tracks which physical room is assigned to each booking detail.

**Columns:**
- `room_assignment_id` (BIGSERIAL, PK) - Unique assignment identifier
- `booking_detail_id` (INT, FK → booking_details) - Booking detail
- `room_id` (INT, FK → rooms) - Physical room assigned
- `check_in_datetime` (TIMESTAMP) - Actual check-in time
- `check_out_datetime` (TIMESTAMP, nullable) - Actual check-out time
- `status` (VARCHAR(20)) - Assignment status

**Status Values:**
- `Active` - Currently assigned
- `Moved` - Guest moved to another room
- `Completed` - Check-out completed

**Indexes:**
- `idx_room_assignments_booking_detail` - On booking_detail_id
- `idx_room_assignments_room` - On room_id
- `idx_room_assignments_status` - On status
- `idx_room_assignments_active` - On (booking_detail_id, status) WHERE status = 'Active'

**Key Features:**
- Created during check-in process
- Supports room moves (maintains complete audit trail)
- Multiple assignments per booking_detail possible (for room moves)

### 4. booking_guests

Information about all guests in a booking.

**Columns:**
- `booking_guest_id` (BIGSERIAL, PK) - Unique guest record identifier
- `booking_detail_id` (INT, FK → booking_details) - Associated booking detail
- `first_name` (VARCHAR(100)) - Guest first name
- `last_name` (VARCHAR(100), nullable) - Guest last name
- `type` (VARCHAR(10)) - Guest type (Adult/Child)
- `is_primary` (BOOLEAN) - Primary guest flag

**Type Values:**
- `Adult` - Adult guest
- `Child` - Child guest

**Indexes:**
- `idx_booking_guests_booking_detail` - On booking_detail_id
- `idx_booking_guests_primary` - On (booking_detail_id, is_primary) WHERE is_primary = TRUE

**Key Features:**
- Captures all guest names for a booking
- Distinguishes between adults and children
- Identifies primary guest per booking detail

### 5. booking_nightly_log

Immutable snapshot of quoted prices for each night.

**Columns:**
- `booking_nightly_log_id` (SERIAL, PK) - Unique log entry identifier
- `booking_detail_id` (INT, FK → booking_details) - Associated booking detail
- `date` (DATE) - Night date
- `quoted_price` (DECIMAL(10,2)) - Price quoted at booking time

**Indexes:**
- `idx_booking_nightly_log_booking_detail` - On booking_detail_id
- `idx_booking_nightly_log_date` - On date

**Constraints:**
- `uq_booking_nightly_log` - UNIQUE (booking_detail_id, date)
- `chk_quoted_price_positive` - quoted_price >= 0

**Key Features:**
- One record per night per booking detail
- Immutable price snapshot (protects against future price changes)
- Used for accurate revenue reporting

## Relationships

```
guests (1) ──────< (N) bookings
                        │
                        │ (1)
                        │
                        ├──< (N) booking_details
                        │         │
                        │         │ (1)
                        │         │
                        │         ├──< (N) room_assignments ──> (1) rooms
                        │         │
                        │         ├──< (N) booking_guests
                        │         │
                        │         └──< (N) booking_nightly_log
                        │
vouchers (1) ──────< (N) bookings

room_types (1) ──────< (N) booking_details
rate_plans (1) ──────< (N) booking_details
```

## Key Features

### 1. Policy Snapshots (Immutability)

When a booking is created, the cancellation policy is captured as a snapshot:

```sql
-- Policy is stored in bookings table
policy_name VARCHAR(100) NOT NULL,
policy_description TEXT NOT NULL
```

**Why?** This ensures that if the hotel changes its cancellation policy, existing bookings are not affected. The guest is protected by the policy that was in effect when they booked.

### 2. Multi-Room Booking Support

A single booking can have multiple booking_details:

```sql
-- One booking, multiple rooms
Booking #123
  ├── Booking Detail #1 (Deluxe Room, 2 guests)
  ├── Booking Detail #2 (Standard Room, 1 guest)
  └── Booking Detail #3 (Suite, 4 guests)
```

### 3. Room Move Tracking

Complete audit trail when guests move rooms:

```sql
-- Original assignment
room_assignment_id: 1, status: 'Moved', room_id: 101

-- New assignment
room_assignment_id: 2, status: 'Active', room_id: 205
```

### 4. Price Protection

Nightly prices are captured at booking time:

```sql
-- Prices locked in booking_nightly_log
2025-01-15: $500.00
2025-01-16: $500.00
2025-01-17: $600.00 (weekend rate)
```

Even if the hotel changes prices later, the guest pays the quoted price.

## Booking Lifecycle

### State Diagram

```
PendingPayment ──[payment]──> Confirmed ──[check-in]──> CheckedIn ──[check-out]──> Completed
       │                           │                          │
       │                           │                          │
       └──[cancel]──> Cancelled    └──[cancel]──> Cancelled   └──[no arrival]──> NoShow
```

### Typical Flow

1. **Create Booking** (PendingPayment)
   ```sql
   INSERT INTO bookings (guest_id, total_amount, status, policy_name, policy_description)
   VALUES (1, 1500.00, 'PendingPayment', 'Standard', 'Free cancellation...');
   ```

2. **Add Booking Details**
   ```sql
   INSERT INTO booking_details (booking_id, room_type_id, rate_plan_id, ...)
   VALUES (1, 2, 1, '2025-01-15', '2025-01-18', 2);
   ```

3. **Add Guests**
   ```sql
   INSERT INTO booking_guests (booking_detail_id, first_name, last_name, type, is_primary)
   VALUES (1, 'John', 'Doe', 'Adult', TRUE);
   ```

4. **Record Nightly Prices**
   ```sql
   INSERT INTO booking_nightly_log (booking_detail_id, date, quoted_price)
   VALUES (1, '2025-01-15', 500.00);
   ```

5. **Confirm Booking** (after payment)
   ```sql
   UPDATE bookings SET status = 'Confirmed' WHERE booking_id = 1;
   ```

6. **Check-In** (assign physical room)
   ```sql
   INSERT INTO room_assignments (booking_detail_id, room_id, check_in_datetime, status)
   VALUES (1, 101, NOW(), 'Active');
   
   UPDATE bookings SET status = 'CheckedIn' WHERE booking_id = 1;
   ```

7. **Check-Out**
   ```sql
   UPDATE room_assignments 
   SET check_out_datetime = NOW(), status = 'Completed'
   WHERE booking_detail_id = 1 AND status = 'Active';
   
   UPDATE bookings SET status = 'Completed' WHERE booking_id = 1;
   ```

## Usage Examples

### Query 1: Get Complete Booking Information

```sql
SELECT 
    b.booking_id,
    b.status,
    b.total_amount,
    g.first_name || ' ' || g.last_name AS guest_name,
    bd.check_in_date,
    bd.check_out_date,
    rt.name AS room_type,
    r.room_number,
    COUNT(DISTINCT bg.booking_guest_id) AS total_guests
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
LEFT JOIN room_assignments ra ON bd.booking_detail_id = ra.booking_detail_id 
    AND ra.status = 'Active'
LEFT JOIN rooms r ON ra.room_id = r.room_id
LEFT JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
WHERE b.booking_id = 123
GROUP BY b.booking_id, b.status, b.total_amount, g.first_name, g.last_name,
         bd.check_in_date, bd.check_out_date, rt.name, r.room_number;
```

### Query 2: Get Arrivals for Today

```sql
SELECT 
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    g.phone,
    bd.check_in_date,
    rt.name AS room_type,
    bd.num_guests
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
WHERE b.status = 'Confirmed'
AND bd.check_in_date = CURRENT_DATE
ORDER BY bd.check_in_date, g.last_name;
```

### Query 3: Get Departures for Today

```sql
SELECT 
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    r.room_number,
    bd.check_out_date,
    b.total_amount
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_assignments ra ON bd.booking_detail_id = ra.booking_detail_id 
    AND ra.status = 'Active'
JOIN rooms r ON ra.room_id = r.room_id
WHERE b.status = 'CheckedIn'
AND bd.check_out_date = CURRENT_DATE
ORDER BY r.room_number;
```

### Query 4: Calculate Revenue for Date Range

```sql
SELECT 
    DATE_TRUNC('day', bnl.date) AS date,
    SUM(bnl.quoted_price) AS daily_revenue,
    COUNT(DISTINCT bd.booking_detail_id) AS room_nights
FROM booking_nightly_log bnl
JOIN booking_details bd ON bnl.booking_detail_id = bd.booking_detail_id
JOIN bookings b ON bd.booking_id = b.booking_id
WHERE b.status IN ('Confirmed', 'CheckedIn', 'Completed')
AND bnl.date BETWEEN '2025-01-01' AND '2025-01-31'
GROUP BY DATE_TRUNC('day', bnl.date)
ORDER BY date;
```

### Query 5: Get Room Move History

```sql
SELECT 
    ra.room_assignment_id,
    r.room_number,
    ra.check_in_datetime,
    ra.check_out_datetime,
    ra.status
FROM room_assignments ra
JOIN rooms r ON ra.room_id = r.room_id
WHERE ra.booking_detail_id = 456
ORDER BY ra.check_in_datetime;
```

## Best Practices

### 1. Always Use Transactions

```sql
BEGIN;
    -- Create booking
    INSERT INTO bookings (...) VALUES (...);
    -- Add details
    INSERT INTO booking_details (...) VALUES (...);
    -- Add guests
    INSERT INTO booking_guests (...) VALUES (...);
    -- Add nightly log
    INSERT INTO booking_nightly_log (...) VALUES (...);
COMMIT;
```

### 2. Capture Policy Snapshots

```sql
-- Get policy details at booking time
INSERT INTO bookings (policy_name, policy_description, ...)
SELECT cp.name, cp.description, ...
FROM cancellation_policies cp
WHERE cp.policy_id = ...;
```

### 3. Validate Before Insert

```sql
-- Check room availability before creating booking
SELECT (allotment - booked_count - tentative_count) AS available
FROM room_inventory
WHERE room_type_id = ? AND date BETWEEN ? AND ?;
```

### 4. Maintain Audit Trail

```sql
-- Don't delete, update status instead
UPDATE bookings SET status = 'Cancelled' WHERE booking_id = ?;

-- Keep all room assignments (even 'Moved' ones)
UPDATE room_assignments SET status = 'Moved' WHERE ...;
INSERT INTO room_assignments (status = 'Active') VALUES (...);
```

## Common Pitfalls

1. **Don't update nightly log prices** - They are immutable snapshots
2. **Don't delete room assignments** - Keep for audit trail
3. **Don't skip policy snapshots** - Always capture at booking time
4. **Don't forget to update inventory** - When confirming/cancelling bookings
5. **Don't allow check-out before check-in** - Use date constraints

## Related Migrations

- **Migration 001**: Guests tables (required)
- **Migration 002**: Room types and rooms (required)
- **Migration 003**: Pricing and inventory (required)
- **Migration 005**: Booking functions (next step)

## Support

For questions or issues with this schema, refer to:
- Design document: `.kiro/specs/hotel-reservation-system/design.md`
- Requirements: `.kiro/specs/hotel-reservation-system/requirements.md`
- Test script: `test_migration_004.sql`
