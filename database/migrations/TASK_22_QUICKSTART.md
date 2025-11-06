# Task 22 Quick Start Guide - Check-in Function

## Overview

Task 22 implements the PostgreSQL function for guest check-in, including comprehensive validation, atomic operations, and error handling.

## What Was Implemented

### 1. Check-in Function (`check_in`)
- ✅ Validates room status (Vacant + Clean/Inspected)
- ✅ Validates booking status (Confirmed)
- ✅ Validates room type matching
- ✅ Prevents duplicate check-ins
- ✅ Creates room assignment atomically
- ✅ Updates booking status to CheckedIn
- ✅ Updates room status to Occupied
- ✅ Complete error handling with rollback

### 2. Test Suite
- ✅ 6 comprehensive test cases
- ✅ Happy path testing
- ✅ Edge case validation
- ✅ Error scenario testing
- ✅ Automatic cleanup

### 3. Documentation
- ✅ Function reference guide
- ✅ Usage examples
- ✅ Integration guide
- ✅ Error handling documentation

## Quick Start

### Step 1: Run the Migration

**Windows:**
```cmd
cd database/migrations
run_migration_009.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_migration_009.sh
./run_migration_009.sh
```

### Step 2: Verify Installation

```bash
psql -h localhost -U postgres -d hotel_booking -f verify_check_in.sql
```

Expected output:
```
✓ Function check_in exists
✓ Function has correct number of parameters (2)
✓ Function returns correct structure
✓ Function has description
✓ Function handles invalid input correctly
```

### Step 3: Run Tests

**Windows:**
```cmd
run_test_check_in.bat
```

**Linux/Mac:**
```bash
chmod +x run_test_check_in.sh
./run_test_check_in.sh
```

Expected output:
```
=== Test 1: เช็คอินสำเร็จ (Happy Path) ===
✓ PASS: เช็คอินสำเร็จ - ห้อง TEST-901 (Assignment ID: ...)
  ✓ Booking status: CheckedIn
  ✓ Room occupancy: Occupied
  ✓ Room assignment created

=== Test 2: ห้องไม่ว่าง (Occupied) ===
✓ PASS: ห้อง TEST-902 ไม่ว่าง (สถานะ: Occupied)

=== Test 3: ห้องยังไม่สะอาด (Dirty) ===
✓ PASS: ห้อง TEST-903 ยังไม่พร้อมสำหรับเช็คอิน...

=== Test 4: การจองไม่ใช่สถานะ Confirmed ===
✓ PASS: ไม่สามารถเช็คอินได้ สถานะการจองปัจจุบัน: PendingPayment...

=== Test 5: Room type ไม่ตรงกับที่จอง ===
✓ PASS: ห้องนี้ไม่ตรงกับประเภทห้องที่จอง...

=== Test 6: เช็คอินซ้ำ (Duplicate Check-in) ===
✓ First check-in successful
✓ PASS: การจองนี้ได้ทำการเช็คอินแล้ว
```

## Usage Examples

### Basic Check-in

```sql
-- Check in booking detail 1 to room 101
SELECT * FROM check_in(1, 101);

-- Result:
-- success | message                                    | room_assignment_id
-- --------|--------------------------------------------|-----------------
-- TRUE    | เช็คอินสำเร็จ - ห้อง 101 (Assignment ID: 1) | 1
```

### Check Available Rooms for Check-in

```sql
-- Find available rooms for a specific room type
SELECT 
    r.room_id,
    r.room_number,
    r.occupancy_status,
    r.housekeeping_status
FROM rooms r
WHERE r.room_type_id = 1
  AND r.occupancy_status = 'Vacant'
  AND r.housekeeping_status IN ('Clean', 'Inspected')
ORDER BY 
    CASE r.housekeeping_status 
        WHEN 'Inspected' THEN 1 
        WHEN 'Clean' THEN 2 
    END,
    r.room_number;
```

### Check Booking Details Ready for Check-in

```sql
-- Find bookings ready for check-in today
SELECT 
    b.booking_id,
    bd.booking_detail_id,
    g.first_name || ' ' || g.last_name as guest_name,
    rt.name as room_type,
    bd.check_in_date,
    bd.num_guests
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN guests g ON b.guest_id = g.guest_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
WHERE b.status = 'Confirmed'
  AND bd.check_in_date = CURRENT_DATE
  AND NOT EXISTS (
      SELECT 1 FROM room_assignments ra 
      WHERE ra.booking_detail_id = bd.booking_detail_id 
        AND ra.status = 'Active'
  )
ORDER BY bd.check_in_date, g.last_name;
```

## Integration with Backend

### Go Service Layer

```go
// internal/service/checkin_service.go
package service

type CheckInService struct {
    db *sql.DB
}

type CheckInResult struct {
    Success          bool   `db:"success"`
    Message          string `db:"message"`
    RoomAssignmentID *int64 `db:"room_assignment_id"`
}

func (s *CheckInService) CheckIn(bookingDetailID, roomID int) (*CheckInResult, error) {
    var result CheckInResult
    
    err := s.db.QueryRow(
        "SELECT * FROM check_in($1, $2)",
        bookingDetailID,
        roomID,
    ).Scan(&result.Success, &result.Message, &result.RoomAssignmentID)
    
    if err != nil {
        return nil, fmt.Errorf("check-in query failed: %w", err)
    }
    
    return &result, nil
}

func (s *CheckInService) GetAvailableRooms(roomTypeID int) ([]Room, error) {
    query := `
        SELECT room_id, room_number, housekeeping_status
        FROM rooms
        WHERE room_type_id = $1
          AND occupancy_status = 'Vacant'
          AND housekeeping_status IN ('Clean', 'Inspected')
        ORDER BY 
            CASE housekeeping_status 
                WHEN 'Inspected' THEN 1 
                WHEN 'Clean' THEN 2 
            END,
            room_number
    `
    
    rows, err := s.db.Query(query, roomTypeID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var rooms []Room
    for rows.Next() {
        var room Room
        if err := rows.Scan(&room.RoomID, &room.RoomNumber, &room.HousekeepingStatus); err != nil {
            return nil, err
        }
        rooms = append(rooms, room)
    }
    
    return rooms, nil
}
```

### Go Handler

```go
// internal/handlers/checkin_handler.go
package handlers

func (h *CheckInHandler) CheckIn(c *gin.Context) {
    var req struct {
        BookingDetailID int `json:"booking_detail_id" binding:"required"`
        RoomID          int `json:"room_id" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    result, err := h.checkInService.CheckIn(req.BookingDetailID, req.RoomID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Check-in failed"})
        return
    }
    
    if !result.Success {
        c.JSON(http.StatusBadRequest, gin.H{"error": result.Message})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "message": result.Message,
        "room_assignment_id": result.RoomAssignmentID,
    })
}

func (h *CheckInHandler) GetAvailableRooms(c *gin.Context) {
    roomTypeID, _ := strconv.Atoi(c.Query("room_type_id"))
    
    rooms, err := h.checkInService.GetAvailableRooms(roomTypeID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch rooms"})
        return
    }
    
    c.JSON(http.StatusOK, rooms)
}
```

### API Endpoints

```go
// internal/router/router.go
func SetupRouter(db *sql.DB) *gin.Engine {
    r := gin.Default()
    
    checkInService := service.NewCheckInService(db)
    checkInHandler := handlers.NewCheckInHandler(checkInService)
    
    api := r.Group("/api")
    {
        checkin := api.Group("/checkin")
        checkin.Use(middleware.AuthMiddleware())
        checkin.Use(middleware.RequireRole("receptionist"))
        {
            checkin.POST("", checkInHandler.CheckIn)
            checkin.GET("/available-rooms", checkInHandler.GetAvailableRooms)
            checkin.GET("/arrivals", checkInHandler.GetArrivals)
        }
    }
    
    return r
}
```

## Validation Rules Summary

| Validation | Check | Error Message |
|------------|-------|---------------|
| Booking exists | booking_detail_id in database | "ไม่พบข้อมูลการจองนี้" |
| No duplicate | No active assignment exists | "การจองนี้ได้ทำการเช็คอินแล้ว" |
| Booking status | status = 'Confirmed' or 'CheckedIn' | "ไม่สามารถเช็คอินได้ สถานะการจองปัจจุบัน: X" |
| Room exists | room_id in database | "ไม่พบห้องนี้ในระบบ" |
| Room type match | room.room_type_id = booking.room_type_id | "ห้องนี้ไม่ตรงกับประเภทห้องที่จอง" |
| Room vacant | occupancy_status = 'Vacant' | "ห้อง X ไม่ว่าง" |
| Room clean | housekeeping_status IN ('Clean', 'Inspected') | "ห้อง X ยังไม่พร้อมสำหรับเช็คอิน" |

## Files Created

```
database/migrations/
├── 009_create_check_in_function.sql      # Main migration
├── test_check_in_function.sql            # Test suite
├── verify_check_in.sql                   # Verification script
├── run_migration_009.bat                 # Windows migration runner
├── run_migration_009.sh                  # Linux/Mac migration runner
├── run_test_check_in.bat                 # Windows test runner
├── run_test_check_in.sh                  # Linux/Mac test runner
├── CHECK_IN_REFERENCE.md                 # Complete reference guide
└── TASK_22_QUICKSTART.md                 # This file
```

## Next Steps

After completing this task:

1. ✅ Task 22 is complete - Check-in function implemented
2. ⏭️ Task 23 - Implement check-out function
3. ⏭️ Task 24 - Implement room move function
4. ⏭️ Task 25 - Create check-in/out backend module
5. ⏭️ Task 26 - Create housekeeping backend module

## Troubleshooting

### Migration fails with "function already exists"
```sql
-- Drop and recreate
DROP FUNCTION IF EXISTS check_in(INT, INT);
-- Then run migration again
```

### Tests fail with "relation does not exist"
```bash
# Ensure all previous migrations are run
cd database/migrations
./run_migration_001.sh
./run_migration_002.sh
./run_migration_003.sh
./run_migration_004.sh
# ... etc
```

### Permission denied on shell scripts
```bash
chmod +x run_migration_009.sh
chmod +x run_test_check_in.sh
```

## Support

For issues or questions:
1. Check `CHECK_IN_REFERENCE.md` for detailed documentation
2. Review test cases in `test_check_in_function.sql`
3. Verify function exists with `verify_check_in.sql`
4. Check requirements in `.kiro/specs/hotel-reservation-system/requirements.md` (7.1-7.8)
