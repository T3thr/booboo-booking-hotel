# Room Management Schema Diagram

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ROOM MANAGEMENT SCHEMA                          │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐
│      room_types          │
├──────────────────────────┤
│ PK room_type_id          │
│    name (UNIQUE)         │
│    description           │
│    max_occupancy         │
│    default_allotment     │
│    base_price            │
│    size_sqm              │
│    bed_type              │
│    created_at            │
│    updated_at            │
└──────────────────────────┘
           │
           │ 1
           │
           │ N
           ▼
┌──────────────────────────┐
│         rooms            │
├──────────────────────────┤
│ PK room_id               │
│ FK room_type_id          │
│    room_number (UNIQUE)  │
│    floor                 │
│    occupancy_status      │◄─── Vacant, Occupied
│    housekeeping_status   │◄─── Dirty, Cleaning, Clean, Inspected,
│    notes                 │     MaintenanceRequired, OutOfService
│    created_at            │
│    updated_at            │
└──────────────────────────┘


┌──────────────────────────┐
│      amenities           │
├──────────────────────────┤
│ PK amenity_id            │
│    name (UNIQUE)         │
│    description           │
│    icon                  │
│    category              │
│    created_at            │
└──────────────────────────┘
           │
           │ N
           │
           │ N
           ▼
┌──────────────────────────┐
│  room_type_amenities     │
├──────────────────────────┤
│ PK,FK room_type_id       │◄─── Composite Primary Key
│ PK,FK amenity_id         │
│       created_at         │
└──────────────────────────┘
           │
           │ N
           │
           │ 1
           ▼
     (room_types)
```

## 2-Axis Status Model

```
                    HOUSEKEEPING STATUS
                    ═══════════════════
        Dirty  Cleaning  Clean  Inspected  Maintenance  OutOfService
        ─────  ────────  ─────  ─────────  ───────────  ────────────
Vacant    🟠      🔵      🟡       🟢          🟣            ⚫
                                  ↑
                              BEST FOR
                              CHECK-IN
Occupied  🔴      🔴      🔴       🔴          🔴            🔴

Legend:
🟢 Green  - Ready to sell (Vacant + Inspected)
🟡 Yellow - Available (Vacant + Clean)
🟠 Orange - Needs cleaning (Vacant + Dirty)
🔵 Blue   - Being cleaned (Vacant + Cleaning)
🔴 Red    - Occupied
🟣 Purple - Maintenance needed
⚫ Gray   - Out of service
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      ROOM LIFECYCLE                             │
└─────────────────────────────────────────────────────────────────┘

1. INITIAL STATE
   ┌─────────────────┐
   │ Vacant + Dirty  │
   └────────┬────────┘
            │
            ▼
2. HOUSEKEEPING STARTS
   ┌──────────────────┐
   │ Vacant + Cleaning│
   └────────┬─────────┘
            │
            ▼
3. CLEANING COMPLETE
   ┌─────────────────┐
   │ Vacant + Clean  │
   └────────┬────────┘
            │
            ▼
4. INSPECTION
   ┌──────────────────┐
   │ Vacant + Inspected│◄─── READY FOR CHECK-IN
   └────────┬─────────┘
            │
            ▼
5. CHECK-IN
   ┌──────────────────┐
   │ Occupied + ?     │
   └────────┬─────────┘
            │
            ▼
6. NIGHT AUDIT (02:00)
   ┌──────────────────┐
   │ Occupied + Dirty │
   └────────┬─────────┘
            │
            ▼
7. CHECK-OUT
   ┌─────────────────┐
   │ Vacant + Dirty  │◄─── BACK TO STEP 1
   └─────────────────┘

SPECIAL CASES:
   ┌──────────────────────────┐
   │ Vacant + MaintenanceReq  │◄─── Issue reported
   └──────────┬───────────────┘
              │
              ▼ (After repair)
   ┌──────────────────┐
   │ Vacant + Dirty   │◄─── Back to normal flow
   └──────────────────┘

   ┌──────────────────┐
   │ ? + OutOfService │◄─── Long-term unavailable
   └──────────────────┘
```

## Index Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                         INDEXES                                 │
└─────────────────────────────────────────────────────────────────┘

rooms table:
├── idx_rooms_occupancy_status
│   └── Used for: Finding vacant rooms
│
├── idx_rooms_housekeeping_status
│   └── Used for: Housekeeping task lists
│
├── idx_rooms_status_combined (occupancy_status, housekeeping_status)
│   └── Used for: Dashboard queries, available room search
│
├── idx_rooms_room_type
│   └── Used for: Filtering by room type
│
└── idx_rooms_floor
    └── Used for: Floor-based queries

room_type_amenities table:
├── idx_room_type_amenities_room_type
│   └── Used for: Getting amenities for a room type
│
└── idx_room_type_amenities_amenity
    └── Used for: Finding room types with specific amenity
```

## Sample Queries

### 1. Find Available Rooms for Check-in
```sql
SELECT r.room_number, rt.name, r.housekeeping_status
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.occupancy_status = 'Vacant'
  AND r.housekeeping_status IN ('Clean', 'Inspected')
ORDER BY 
  CASE r.housekeeping_status 
    WHEN 'Inspected' THEN 1 
    WHEN 'Clean' THEN 2 
  END;
```

### 2. Housekeeping Task List
```sql
SELECT r.room_number, rt.name, r.housekeeping_status
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

### 3. Room Status Dashboard
```sql
SELECT 
  occupancy_status,
  housekeeping_status,
  COUNT(*) as count
FROM rooms
GROUP BY occupancy_status, housekeeping_status
ORDER BY occupancy_status, housekeeping_status;
```

### 4. Room Type with Amenities
```sql
SELECT 
  rt.name,
  rt.base_price,
  rt.max_occupancy,
  STRING_AGG(a.name, ', ' ORDER BY a.name) as amenities
FROM room_types rt
LEFT JOIN room_type_amenities rta ON rt.room_type_id = rta.room_type_id
LEFT JOIN amenities a ON rta.amenity_id = a.amenity_id
GROUP BY rt.room_type_id, rt.name, rt.base_price, rt.max_occupancy;
```

## Seed Data Distribution

```
┌─────────────────────────────────────────────────────────────────┐
│                    ROOM DISTRIBUTION                            │
└─────────────────────────────────────────────────────────────────┘

Floor 3 (Suite)
├── 301 [Vacant + Inspected]
├── 302 [Vacant + Clean]
└── 303 [Vacant + Dirty]

Floor 2 (Deluxe)
├── 201 [Occupied + Dirty]
├── 202 [Vacant + Inspected]
├── 203 [Vacant + Inspected]
├── 204 [Vacant + Inspected]
├── 205 [Vacant + Clean]
├── 206 [Vacant + Clean]
└── 207 [Vacant + Clean]

Floor 1 (Standard)
├── 101 [Occupied + Dirty]
├── 102 [Occupied + Dirty]
├── 103 [Vacant + Inspected]
├── 104 [Vacant + Inspected]
├── 105 [Vacant + Inspected]
├── 106 [Vacant + Clean]
├── 107 [Vacant + Clean]
├── 108 [Vacant + Clean]
├── 109 [Vacant + Dirty]
└── 110 [Vacant + Dirty]

Summary:
- Total Rooms: 20
- Occupied: 3 (15%)
- Vacant + Ready: 10 (50%)
- Vacant + Needs Cleaning: 7 (35%)
```

```
┌─────────────────────────────────────────────────────────────────┐
│                  AMENITIES DISTRIBUTION                         │
└─────────────────────────────────────────────────────────────────┘

Standard Room (6 amenities):
├── Free WiFi
├── Air Conditioning
├── Flat-screen TV
├── Private Bathroom
├── Hair Dryer
└── Work Desk

Deluxe Room (8 amenities):
├── Free WiFi
├── Air Conditioning
├── Flat-screen TV
├── Mini Bar          ◄─── Added
├── Safe Box          ◄─── Added
├── Private Bathroom
├── Hair Dryer
└── Work Desk

Suite Room (10 amenities):
├── Free WiFi
├── Air Conditioning
├── Flat-screen TV
├── Mini Bar
├── Safe Box
├── Private Bathroom
├── Hair Dryer
├── Work Desk
├── Coffee Maker      ◄─── Added
└── Balcony           ◄─── Added
```

## Constraints Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        CONSTRAINTS                              │
└─────────────────────────────────────────────────────────────────┘

room_types:
├── PK: room_type_id
├── UNIQUE: name
├── CHECK: max_occupancy > 0
├── CHECK: default_allotment >= 0
└── CHECK: base_price >= 0

rooms:
├── PK: room_id
├── FK: room_type_id → room_types(room_type_id) ON DELETE RESTRICT
├── UNIQUE: room_number
├── CHECK: floor > 0
├── CHECK: occupancy_status IN ('Vacant', 'Occupied')
└── CHECK: housekeeping_status IN (6 valid values)

amenities:
├── PK: amenity_id
└── UNIQUE: name

room_type_amenities:
├── PK: (room_type_id, amenity_id)
├── FK: room_type_id → room_types ON DELETE CASCADE
└── FK: amenity_id → amenities ON DELETE CASCADE
```

## Triggers

```
┌─────────────────────────────────────────────────────────────────┐
│                         TRIGGERS                                │
└─────────────────────────────────────────────────────────────────┘

Function: update_updated_at_column()
├── Language: PL/pgSQL
└── Action: SET NEW.updated_at = CURRENT_TIMESTAMP

Triggers:
├── update_room_types_updated_at
│   ├── Table: room_types
│   ├── Event: BEFORE UPDATE
│   └── For Each: ROW
│
└── update_rooms_updated_at
    ├── Table: rooms
    ├── Event: BEFORE UPDATE
    └── For Each: ROW
```

---

**Note**: This schema is designed to be extended in future tasks with:
- Pricing & Inventory (Task 5)
- Bookings (Task 6)
- Room Assignments (Task 7-9)
