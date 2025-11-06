# Task 24: Move Room Function

> **Status:** ✅ Complete | **Requirements:** 8.1-8.7 | **Date:** 2025-11-03

## 🚀 Quick Start

```bash
# 1. Run migration
run_migration_011.bat  # Windows
./run_migration_011.sh # Linux/Mac

# 2. Verify
run_migration_011.bat verify

# 3. Test
run_test_move_room.bat  # Windows
./run_test_move_room.sh # Linux/Mac
```

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [TASK_24_INDEX.md](TASK_24_INDEX.md) | 📑 Start here - Complete navigation |
| [TASK_24_QUICKSTART.md](TASK_24_QUICKSTART.md) | ⚡ Quick setup guide |
| [MOVE_ROOM_REFERENCE.md](MOVE_ROOM_REFERENCE.md) | 📚 Detailed API reference |
| [TASK_24_SUMMARY.md](TASK_24_SUMMARY.md) | 📊 Complete task summary |
| [TASK_24_COMPLETION_SUMMARY.md](TASK_24_COMPLETION_SUMMARY.md) | ✅ Completion report |

## 💡 Quick Example

```sql
-- Move guest from room 201 to room 205
SELECT * FROM move_room(
    12345,  -- room_assignment_id
    205,    -- new_room_id
    'Air conditioning malfunction'  -- reason (optional)
);
```

## 📁 Files

### Core
- `011_create_move_room_function.sql` - Migration
- `test_move_room_function.sql` - Tests
- `verify_move_room.sql` - Verification

### Scripts
- `run_migration_011.bat` / `.sh` - Run migration
- `run_test_move_room.bat` / `.sh` - Run tests

## ✅ Features

- ✅ Move guests between rooms
- ✅ Atomic operations
- ✅ Complete validation
- ✅ Audit trail
- ✅ Error handling
- ✅ Concurrent-safe

## 🎯 Requirements

Implements requirements 8.1-8.7:
- Show available rooms
- Call move_room function
- Close old, create new assignment
- Update room statuses
- Maintain audit trail
- Validate room availability
- Log reason, notify housekeeping

## 🧪 Testing

6 test cases covering:
- ✅ Successful move
- ✅ Same room prevention
- ✅ Occupied room prevention
- ✅ Dirty room prevention
- ✅ Non-active assignment prevention
- ✅ Non-existent assignment prevention

## 🔗 Integration

### Backend (Go)
```go
func (r *Repository) MoveRoom(assignmentID int64, newRoomID int, reason string) (*Result, error)
```

See [MOVE_ROOM_REFERENCE.md](MOVE_ROOM_REFERENCE.md) for complete examples.

## 📞 Need Help?

1. Check [TASK_24_QUICKSTART.md](TASK_24_QUICKSTART.md) - Common Issues
2. Review [MOVE_ROOM_REFERENCE.md](MOVE_ROOM_REFERENCE.md) - Error Scenarios
3. Run verification: `verify_move_room.sql`

## 🎓 Learn More

- [TASK_24_INDEX.md](TASK_24_INDEX.md) - Complete navigation
- [MOVE_ROOM_REFERENCE.md](MOVE_ROOM_REFERENCE.md) - Detailed reference
- [TASK_24_SUMMARY.md](TASK_24_SUMMARY.md) - Full summary

---

**Next Task:** 25. สร้าง Check-in/out Module - Backend
