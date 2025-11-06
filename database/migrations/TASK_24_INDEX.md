# Task 24 Index: Move Room Function

## 📋 Overview

This directory contains all files related to Task 24: Creating the PostgreSQL `move_room` function for moving guests between rooms during their stay.

**Status:** ✅ Complete  
**Requirements:** 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7

## 📁 File Structure

### Core Files

| File | Purpose | Type |
|------|---------|------|
| `011_create_move_room_function.sql` | Main migration script | SQL Migration |
| `test_move_room_function.sql` | Comprehensive test suite | SQL Test |
| `verify_move_room.sql` | Verification script | SQL Verification |

### Execution Scripts

| File | Purpose | Platform |
|------|---------|----------|
| `run_migration_011.bat` | Run migration | Windows |
| `run_migration_011.sh` | Run migration | Linux/Mac |
| `run_test_move_room.bat` | Run tests | Windows |
| `run_test_move_room.sh` | Run tests | Linux/Mac |

### Documentation

| File | Purpose | Audience |
|------|---------|----------|
| `TASK_24_QUICKSTART.md` | Quick setup guide | Developers |
| `TASK_24_SUMMARY.md` | Complete task summary | Project managers |
| `MOVE_ROOM_REFERENCE.md` | Detailed function reference | Backend developers |
| `TASK_24_INDEX.md` | This file - navigation | Everyone |

## 🚀 Quick Start

### For First-Time Setup

1. **Read the quickstart guide:**
   ```
   TASK_24_QUICKSTART.md
   ```

2. **Run the migration:**
   ```bash
   # Windows
   run_migration_011.bat
   
   # Linux/Mac
   ./run_migration_011.sh
   ```

3. **Verify installation:**
   ```bash
   # Windows
   run_migration_011.bat verify
   
   # Linux/Mac
   ./run_migration_011.sh verify
   ```

4. **Run tests:**
   ```bash
   # Windows
   run_test_move_room.bat
   
   # Linux/Mac
   ./run_test_move_room.sh
   ```

### For Backend Integration

1. **Read the reference guide:**
   ```
   MOVE_ROOM_REFERENCE.md
   ```

2. **Implement repository method:**
   ```go
   func (r *Repository) MoveRoom(assignmentID int64, newRoomID int, reason string) (*Result, error)
   ```

3. **Implement handler:**
   ```go
   func (h *Handler) MoveRoom(c *gin.Context)
   ```

### For Testing

1. **Run automated tests:**
   ```bash
   run_test_move_room.bat  # or .sh
   ```

2. **Manual testing:**
   ```sql
   SELECT * FROM move_room(
       <assignment_id>,
       <new_room_id>,
       'Test reason'
   );
   ```

## 📖 Documentation Guide

### By Role

#### Project Manager / Team Lead
Start here:
1. `TASK_24_SUMMARY.md` - Complete overview
2. `TASK_24_INDEX.md` - This file

#### Backend Developer
Start here:
1. `MOVE_ROOM_REFERENCE.md` - Detailed API reference
2. `TASK_24_QUICKSTART.md` - Setup instructions
3. `011_create_move_room_function.sql` - Implementation details

#### Database Administrator
Start here:
1. `011_create_move_room_function.sql` - Migration script
2. `verify_move_room.sql` - Verification queries
3. `test_move_room_function.sql` - Test cases

#### QA / Tester
Start here:
1. `test_move_room_function.sql` - Test scenarios
2. `MOVE_ROOM_REFERENCE.md` - Expected behaviors
3. `TASK_24_QUICKSTART.md` - Setup for testing

### By Task

#### Installing the Function
1. Read: `TASK_24_QUICKSTART.md`
2. Run: `run_migration_011.bat` or `.sh`
3. Verify: `run_migration_011.bat verify`

#### Testing the Function
1. Read: `MOVE_ROOM_REFERENCE.md` (Error Scenarios section)
2. Run: `run_test_move_room.bat` or `.sh`
3. Review: Test output

#### Integrating with Backend
1. Read: `MOVE_ROOM_REFERENCE.md` (Integration section)
2. Implement: Repository and handler
3. Test: Using examples from reference

#### Understanding Requirements
1. Read: `TASK_24_SUMMARY.md` (Requirements Compliance section)
2. Reference: `.kiro/specs/hotel-reservation-system/requirements.md`
3. Cross-check: Design document

## 🔍 Key Concepts

### Function Purpose
Move a guest from one room to another during their stay while maintaining data integrity and audit trail.

### Key Features
- ✅ Atomic operations (all-or-nothing)
- ✅ Complete validation
- ✅ Audit trail maintenance
- ✅ Automatic room status updates
- ✅ Optional reason logging

### Business Rules
1. Assignment must be Active
2. New room must be Vacant
3. New room must be Clean or Inspected
4. Cannot move to same room
5. Old room becomes Vacant + Dirty
6. New room becomes Occupied

## 🔗 Related Tasks

### Prerequisites
- ✅ Task 22: Check-in function
- ✅ Task 23: Check-out function
- ✅ Tasks 1-6: Database schema

### Next Steps
- ⏭️ Task 25: Backend Check-in/out Module
- ⏭️ Task 26: Housekeeping Module
- ⏭️ Task 27: Room Status Dashboard

### Related Functions
- `check_in()` - Initial room assignment
- `check_out()` - Complete stay
- Room status management

## 📊 Test Coverage

The test suite covers:

1. ✅ **Happy Path**
   - Successful room move
   - Correct status updates
   - Audit trail creation

2. ✅ **Validation Tests**
   - Same room prevention
   - Occupied room prevention
   - Dirty room prevention
   - Non-active assignment prevention
   - Non-existent assignment prevention

3. ✅ **Data Integrity**
   - Atomic operations
   - Rollback on error
   - Status consistency

## 🎯 Requirements Mapping

| Requirement | Description | Status |
|-------------|-------------|--------|
| 8.1 | Show available rooms | ✅ |
| 8.2 | Call SP_MoveRoom | ✅ |
| 8.3 | Close old, create new assignment | ✅ |
| 8.4 | Update room statuses | ✅ |
| 8.5 | Maintain audit trail | ✅ |
| 8.6 | Reject if room not ready | ✅ |
| 8.7 | Log reason, notify housekeeping | ✅ |

## 💡 Usage Examples

### Basic Move
```sql
SELECT * FROM move_room(12345, 205);
```

### Move with Reason
```sql
SELECT * FROM move_room(
    12345,
    205,
    'Air conditioning malfunction'
);
```

### Find Active Assignment
```sql
SELECT room_assignment_id
FROM room_assignments
WHERE booking_detail_id = 100
  AND status = 'Active';
```

### Find Available Rooms
```sql
SELECT room_id, room_number
FROM rooms
WHERE occupancy_status = 'Vacant'
  AND housekeeping_status IN ('Clean', 'Inspected');
```

## 🐛 Troubleshooting

### Common Issues

1. **Function not found**
   - Solution: Run migration script

2. **Tests fail**
   - Solution: Check prerequisites, ensure test data exists

3. **Permission denied**
   - Solution: Grant execute permission

4. **Validation errors**
   - Solution: Check room and assignment status

See `TASK_24_QUICKSTART.md` for detailed troubleshooting.

## 📞 Support

For issues or questions:
1. Check `TASK_24_QUICKSTART.md` - Common Issues section
2. Review `MOVE_ROOM_REFERENCE.md` - Error Scenarios
3. Check test output for specific errors
4. Review PostgreSQL logs

## 📝 Change Log

### Version 1.0 (2025-11-03)
- ✅ Initial implementation
- ✅ Complete test suite
- ✅ Full documentation
- ✅ Execution scripts
- ✅ Verification tools

## 🔐 Security Notes

- Function uses row-level locking (FOR UPDATE)
- All operations are atomic
- Input validation prevents SQL injection
- Audit trail maintained for compliance

## 🎓 Learning Resources

### For Understanding the Code
1. Read: `011_create_move_room_function.sql` with comments
2. Study: `test_move_room_function.sql` test cases
3. Review: PL/pgSQL documentation

### For Integration
1. Read: `MOVE_ROOM_REFERENCE.md` integration examples
2. Study: Go repository pattern
3. Review: Backend architecture docs

---

**Last Updated:** 2025-11-03  
**Task Status:** ✅ Complete  
**Version:** 1.0  
**Maintainer:** Development Team
