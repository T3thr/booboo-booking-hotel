# Bookings Schema Visual Diagram

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         BOOKINGS SCHEMA (Migration 004)                  │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│     guests       │ (from Migration 001)
├──────────────────┤
│ guest_id (PK)    │◄────────────────┐
│ first_name       │                 │
│ last_name        │                 │
│ email            │                 │
│ phone            │                 │
└──────────────────┘                 │
                                     │ 1:N
                                     │
┌──────────────────┐                 │
│    vouchers      │ (from Migration 003)
├──────────────────┤                 │
│ voucher_id (PK)  │◄────────┐       │
│ code             │         │       │
│ discount_type    │         │ 0..1  │
│ discount_value   │         │       │
│ expiry_date      │         │       │
└──────────────────┘         │       │
                             │       │
                    ┌────────┴───────┴────────┐
                    │      bookings           │ ★ Main Table
                    ├─────────────────────────┤
                    │ booking_id (PK)         │
                    │ guest_id (FK)           │
                    │ voucher_id (FK)         │
                    │ total_amount            │
                    │ status ◄────────────────┼─── PendingPayment
                    │ created_at              │    Confirmed
                    │ updated_at              │    CheckedIn
                    │ policy_name ◄───────────┼─── Completed
                    │ policy_description      │    Cancelled
                    └──────────┬──────────────┘    NoShow
                               │ 1:N
                               │
                    ┌──────────▼──────────────┐
                    │   booking_details       │ ★ Multi-room Support
                    ├─────────────────────────┤
                    │ booking_detail_id (PK)  │
                    │ booking_id (FK)         │
                    │ room_type_id (FK) ──────┼───► room_types
                    │ rate_plan_id (FK) ──────┼───► rate_plans
                    │ check_in_date           │
                    │ check_out_date          │
                    │ num_guests              │
                    └──────┬──────────────────┘
                           │ 1:N
                           │
        ┌──────────────────┼──────────────────┬──────────────────┐
        │                  │                  │                  │
        ▼                  ▼                  ▼                  ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│room_assignments│  │booking_guests│  │booking_nightly│  │              │
├───────────────┤  ├──────────────┤  │     _log     │  │   Future:    │
│assignment_id  │  │guest_id (PK) │  ├──────────────┤  │  - payments  │
│booking_det(FK)│  │booking_det(FK│  │log_id (PK)   │  │  - extras    │
│room_id (FK)───┼──┤first_name    │  │booking_det(FK│  │  - charges   │
│check_in_dt    │  │last_name     │  │date          │  │              │
│check_out_dt   │  │type ◄────────┼──┤quoted_price  │  └──────────────┘
│status ◄───────┼──┤is_primary    │  └──────────────┘
└───────────────┘  └──────────────┘         │
       │                  │                 │
       │                  │                 │
       ▼                  ▼                 ▼
   Active              Adult          Immutable
   Moved               Child          Price
   Completed                          Snapshot
```

## Table Relationships

### Primary Relationships

```
guests (1) ──────────< (N) bookings
                            │
                            │ CASCADE DELETE
                            │
vouchers (0..1) ─────< (N) bookings
                            │
                            │ 1:N
                            │
                            ├──< (N) booking_details
                                      │
                                      │ CASCADE DELETE
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
            room_assignments   booking_guests   booking_nightly_log
                    │
                    │ N:1
                    │
                    ▼
                  rooms
```

### Foreign Key Cascade Rules

```
bookings
  └─► booking_details (CASCADE DELETE)
        ├─► room_assignments (CASCADE DELETE)
        ├─► booking_guests (CASCADE DELETE)
        └─► booking_nightly_log (CASCADE DELETE)

When a booking is deleted:
  ✓ All booking_details are deleted
  ✓ All room_assignments are deleted
  ✓ All booking_guests are deleted
  ✓ All booking_nightly_log entries are deleted
```

## Booking Lifecycle State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                    BOOKING STATUS FLOW                           │
└─────────────────────────────────────────────────────────────────┘

    [Create Booking]
           │
           ▼
    ┌──────────────┐
    │ PendingPayment│ ◄─── Initial state
    └──────┬───────┘      (15 min hold)
           │
           │ [Payment Success]
           │
           ▼
    ┌──────────────┐
    │  Confirmed   │ ◄─── Payment received
    └──────┬───────┘      (Inventory updated)
           │
           │ [Guest Arrives]
           │
           ▼
    ┌──────────────┐
    │  CheckedIn   │ ◄─── Room assigned
    └──────┬───────┘      (Guest in room)
           │
           │ [Guest Departs]
           │
           ▼
    ┌──────────────┐
    │  Completed   │ ◄─── Final state
    └──────────────┘      (Room released)

    Alternative Paths:
    
    PendingPayment ──[Cancel]──► Cancelled
    Confirmed ──────[Cancel]──► Cancelled
    Confirmed ──────[No Show]─► NoShow
```

## Room Assignment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  ROOM ASSIGNMENT LIFECYCLE                       │
└─────────────────────────────────────────────────────────────────┘

[Check-In]
    │
    ▼
┌─────────────────┐
│ Create Assignment│
│ status: Active  │
│ room_id: 101    │
└────────┬────────┘
         │
         │ [Guest Requests Move]
         │
         ▼
┌─────────────────┐      ┌─────────────────┐
│ Update Old      │      │ Create New      │
│ status: Moved   │      │ status: Active  │
│ room_id: 101    │      │ room_id: 205    │
└─────────────────┘      └────────┬────────┘
                                  │
                                  │ [Check-Out]
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ Update          │
                         │ status: Complete│
                         │ room_id: 205    │
                         └─────────────────┘

Result: Complete audit trail of all room assignments
```

## Data Flow: Creating a Booking

```
┌─────────────────────────────────────────────────────────────────┐
│              COMPLETE BOOKING CREATION FLOW                      │
└─────────────────────────────────────────────────────────────────┘

Step 1: Create Booking Hold (15 minutes)
┌──────────────────────────────────────┐
│ booking_holds                        │
│ - session_id                         │
│ - room_type_id                       │
│ - date (for each night)              │
│ - hold_expiry = NOW() + 15 min      │
└──────────────────────────────────────┘
         │
         │ Update inventory
         ▼
┌──────────────────────────────────────┐
│ room_inventory                       │
│ tentative_count = tentative_count + 1│
└──────────────────────────────────────┘

Step 2: Create Booking Record
┌──────────────────────────────────────┐
│ bookings                             │
│ - guest_id                           │
│ - total_amount                       │
│ - status = 'PendingPayment'         │
│ - policy_name (snapshot)            │
│ - policy_description (snapshot)     │
└──────────────────────────────────────┘

Step 3: Add Booking Details
┌──────────────────────────────────────┐
│ booking_details                      │
│ - booking_id                         │
│ - room_type_id                       │
│ - rate_plan_id                       │
│ - check_in_date                      │
│ - check_out_date                     │
│ - num_guests                         │
└──────────────────────────────────────┘

Step 4: Add Guest Information
┌──────────────────────────────────────┐
│ booking_guests                       │
│ - booking_detail_id                  │
│ - first_name, last_name              │
│ - type (Adult/Child)                 │
│ - is_primary (TRUE for main guest)  │
└──────────────────────────────────────┘

Step 5: Record Nightly Prices (Immutable)
┌──────────────────────────────────────┐
│ booking_nightly_log                  │
│ - booking_detail_id                  │
│ - date (2025-01-15)                  │
│ - quoted_price (500.00)              │
│ - date (2025-01-16)                  │
│ - quoted_price (500.00)              │
│ - date (2025-01-17)                  │
│ - quoted_price (600.00) ← weekend    │
└──────────────────────────────────────┘

Step 6: Payment & Confirmation
┌──────────────────────────────────────┐
│ bookings                             │
│ status = 'Confirmed'                 │
└──────────────────────────────────────┘
         │
         │ Update inventory
         ▼
┌──────────────────────────────────────┐
│ room_inventory                       │
│ booked_count = booked_count + 1     │
│ tentative_count = tentative_count - 1│
└──────────────────────────────────────┘

Step 7: Check-In (Assign Physical Room)
┌──────────────────────────────────────┐
│ room_assignments                     │
│ - booking_detail_id                  │
│ - room_id (101)                      │
│ - check_in_datetime = NOW()         │
│ - status = 'Active'                  │
└──────────────────────────────────────┘
         │
         │ Update room status
         ▼
┌──────────────────────────────────────┐
│ rooms                                │
│ occupancy_status = 'Occupied'       │
└──────────────────────────────────────┘
         │
         │ Update booking status
         ▼
┌──────────────────────────────────────┐
│ bookings                             │
│ status = 'CheckedIn'                 │
└──────────────────────────────────────┘
```

## Index Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                      INDEX OPTIMIZATION                          │
└─────────────────────────────────────────────────────────────────┘

bookings
├─ idx_bookings_guest (guest_id)
│  └─ Use: Find all bookings for a guest
├─ idx_bookings_status (status)
│  └─ Use: Filter by booking status
├─ idx_bookings_created_at (created_at)
│  └─ Use: Date range queries, recent bookings
└─ idx_bookings_voucher (voucher_id) WHERE voucher_id IS NOT NULL
   └─ Use: Track voucher usage (partial index)

booking_details
├─ idx_booking_details_booking (booking_id)
│  └─ Use: Get all details for a booking
├─ idx_booking_details_room_type (room_type_id)
│  └─ Use: Room type availability queries
└─ idx_booking_details_dates (check_in_date, check_out_date)
   └─ Use: Date range searches, arrivals/departures

room_assignments
├─ idx_room_assignments_booking_detail (booking_detail_id)
│  └─ Use: Get assignments for a booking
├─ idx_room_assignments_room (room_id)
│  └─ Use: Room occupancy history
├─ idx_room_assignments_status (status)
│  └─ Use: Filter by assignment status
└─ idx_room_assignments_active (booking_detail_id, status) WHERE status = 'Active'
   └─ Use: Find current room assignment (partial index)

booking_guests
├─ idx_booking_guests_booking_detail (booking_detail_id)
│  └─ Use: Get all guests for a booking
└─ idx_booking_guests_primary (booking_detail_id, is_primary) WHERE is_primary = TRUE
   └─ Use: Find primary guest (partial index)

booking_nightly_log
├─ idx_booking_nightly_log_booking_detail (booking_detail_id)
│  └─ Use: Get all nights for a booking
└─ idx_booking_nightly_log_date (date)
   └─ Use: Revenue reports by date
```

## Constraint Protection

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONSTRAINT VALIDATION                         │
└─────────────────────────────────────────────────────────────────┘

CHECK Constraints (Data Integrity)
├─ bookings.total_amount >= 0
│  └─ Prevents negative booking amounts
├─ bookings.status IN (valid values)
│  └─ Ensures only valid status transitions
├─ booking_details.check_out_date > check_in_date
│  └─ Prevents invalid date ranges
├─ booking_details.num_guests > 0
│  └─ Requires at least one guest
├─ room_assignments.check_out_datetime > check_in_datetime
│  └─ Validates check-out after check-in
├─ booking_guests.type IN ('Adult', 'Child')
│  └─ Enforces valid guest types
├─ booking_guests.first_name not empty
│  └─ Requires guest name
└─ booking_nightly_log.quoted_price >= 0
   └─ Prevents negative prices

UNIQUE Constraints (Prevent Duplicates)
└─ booking_nightly_log (booking_detail_id, date)
   └─ One price entry per night per booking

FOREIGN KEY Constraints (Referential Integrity)
├─ bookings → guests (RESTRICT)
├─ bookings → vouchers (SET NULL)
├─ booking_details → bookings (CASCADE)
├─ booking_details → room_types (RESTRICT)
├─ booking_details → rate_plans (RESTRICT)
├─ room_assignments → booking_details (CASCADE)
├─ room_assignments → rooms (RESTRICT)
├─ booking_guests → booking_details (CASCADE)
└─ booking_nightly_log → booking_details (CASCADE)
```

## Key Features Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                      KEY FEATURES                                │
└─────────────────────────────────────────────────────────────────┘

1. POLICY SNAPSHOTS (Immutability)
   ┌──────────────────────────────────┐
   │ At Booking Time:                 │
   │ policy_name = "Standard"         │
   │ policy_description = "Free..."   │
   └──────────────────────────────────┘
   Even if hotel changes policy later,
   guest is protected by original terms

2. MULTI-ROOM SUPPORT
   Booking #123
   ├─ Detail #1: Deluxe Room (2 guests)
   ├─ Detail #2: Standard Room (1 guest)
   └─ Detail #3: Suite (4 guests)

3. ROOM MOVE TRACKING
   Assignment History for Booking Detail #456:
   ├─ Assignment #1: Room 101 (Active → Moved)
   └─ Assignment #2: Room 205 (Active)
   Complete audit trail maintained

4. PRICE PROTECTION
   Nightly Log for Booking Detail #789:
   ├─ 2025-01-15: $500.00 (locked)
   ├─ 2025-01-16: $500.00 (locked)
   └─ 2025-01-17: $600.00 (locked)
   Prices never change after booking
```

## Summary Statistics

```
┌─────────────────────────────────────────────────────────────────┐
│                    MIGRATION 004 SUMMARY                         │
└─────────────────────────────────────────────────────────────────┘

Tables Created:        5
Indexes Created:       15+
Constraints:           18 (8 CHECK, 9 FK, 1 UNIQUE)
Triggers:              1
Lines of Code:         ~350
Documentation:         ~2,000 lines
Test Coverage:         7 scenarios

Features:
✓ Policy snapshots (immutability)
✓ Multi-room booking support
✓ Room move tracking
✓ Price protection
✓ Complete audit trail
✓ Cascade delete rules
✓ Performance optimization
✓ Data integrity validation
```

---

**Migration 004**: Complete bookings schema with full lifecycle support  
**Status**: ✅ Production Ready  
**Next**: Phase 2 - Backend Core (Go API Setup)
