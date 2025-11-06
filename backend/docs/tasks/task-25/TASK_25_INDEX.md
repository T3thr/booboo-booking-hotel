# Task 25: Check-in/Check-out Module - Documentation Index

## 📚 Documentation Overview

This index provides quick access to all documentation related to Task 25: Check-in/Check-out Module Backend Implementation.

## 🚀 Quick Links

### Getting Started
- **[Quick Start Guide](TASK_25_QUICKSTART.md)** - Get up and running in 5 minutes
- **[API Reference](CHECKIN_CHECKOUT_REFERENCE.md)** - Complete API documentation
- **[Test Script](test_checkin_module.ps1)** - Automated testing

### Implementation Details
- **[Implementation Summary](TASK_25_SUMMARY.md)** - Complete implementation overview
- **[Verification Checklist](TASK_25_VERIFICATION.md)** - Testing and verification guide

## 📖 Document Descriptions

### 1. TASK_25_QUICKSTART.md
**Purpose:** Get started quickly with the module

**Contents:**
- Prerequisites
- 5-minute quick test
- Common operations
- Troubleshooting
- Test data setup

**Best for:** Developers who want to test the module immediately

---

### 2. CHECKIN_CHECKOUT_REFERENCE.md
**Purpose:** Complete API reference and usage guide

**Contents:**
- All API endpoints with examples
- Request/response formats
- Business rules
- Error handling
- PostgreSQL functions used
- Testing with cURL
- Integration guidelines

**Best for:** Frontend developers, API consumers, integration work

---

### 3. TASK_25_SUMMARY.md
**Purpose:** Comprehensive implementation documentation

**Contents:**
- Implementation details
- Code structure
- Requirements coverage
- Security implementation
- Performance considerations
- Future enhancements

**Best for:** Code reviewers, maintainers, architects

---

### 4. TASK_25_VERIFICATION.md
**Purpose:** Testing and quality assurance guide

**Contents:**
- Implementation verification checklist
- Testing procedures
- Database verification queries
- Performance benchmarks
- Code quality checks
- Deployment readiness

**Best for:** QA engineers, testers, deployment teams

---

### 5. test_checkin_module.ps1
**Purpose:** Automated testing script

**Contents:**
- PowerShell script for testing all endpoints
- Automated test flow
- Response validation
- Error reporting

**Best for:** Automated testing, CI/CD pipelines

---

## 🎯 Use Cases

### I want to...

#### ...test the module quickly
→ Start with **[TASK_25_QUICKSTART.md](TASK_25_QUICKSTART.md)**

#### ...integrate with frontend
→ Read **[CHECKIN_CHECKOUT_REFERENCE.md](CHECKIN_CHECKOUT_REFERENCE.md)**

#### ...understand the implementation
→ Review **[TASK_25_SUMMARY.md](TASK_25_SUMMARY.md)**

#### ...verify the code quality
→ Use **[TASK_25_VERIFICATION.md](TASK_25_VERIFICATION.md)**

#### ...run automated tests
→ Execute **[test_checkin_module.ps1](test_checkin_module.ps1)**

## 📁 Code Files

### Source Code Locations

```
backend/
├── internal/
│   ├── handlers/
│   │   └── checkin_handler.go          ← HTTP handlers
│   ├── models/
│   │   └── booking.go                  ← Data models (updated)
│   ├── repository/
│   │   └── booking_repository.go       ← Database operations (updated)
│   ├── service/
│   │   └── booking_service.go          ← Business logic (updated)
│   └── router/
│       └── router.go                   ← Route definitions (updated)
```

### Key Functions

**Handler Functions:**
- `CheckIn()` - POST /api/checkin
- `CheckOut()` - POST /api/checkout
- `MoveRoom()` - POST /api/checkin/move-room
- `MarkNoShow()` - POST /api/bookings/:id/no-show
- `GetArrivals()` - GET /api/checkin/arrivals
- `GetDepartures()` - GET /api/checkout/departures
- `GetAvailableRooms()` - GET /api/checkin/available-rooms/:roomTypeId

**Service Functions:**
- `CheckIn(ctx, bookingDetailID, roomID)`
- `CheckOut(ctx, bookingID)`
- `MoveRoom(ctx, assignmentID, newRoomID)`
- `MarkNoShow(ctx, bookingID)`
- `GetArrivals(ctx, dateStr)`
- `GetDepartures(ctx, dateStr)`
- `GetAvailableRoomsForCheckIn(ctx, roomTypeID)`

**Repository Functions:**
- `CheckIn(ctx, bookingDetailID, roomID)`
- `CheckOut(ctx, bookingID)`
- `MoveRoom(ctx, assignmentID, newRoomID)`
- `MarkNoShow(ctx, bookingID)`
- `GetArrivals(ctx, date)`
- `GetDepartures(ctx, date)`
- `GetAvailableRoomsForCheckIn(ctx, roomTypeID)`

## 🔗 Related Documentation

### Prerequisites (Must Read First)
- **Task 22:** Check-in Function (`database/migrations/TASK_22_*.md`)
- **Task 23:** Check-out Function (`database/migrations/TASK_23_*.md`)
- **Task 24:** Move Room Function (`database/migrations/TASK_24_*.md`)

### Related Modules
- **Task 8-9:** Authentication Module (`backend/AUTH_QUICK_REFERENCE.md`)
- **Task 10:** Room Search Module (`backend/ROOM_SEARCH_QUICK_REFERENCE.md`)
- **Task 15:** Booking Module (`backend/BOOKING_QUICK_REFERENCE.md`)

### Architecture
- **Project Structure:** `backend/PROJECT_STRUCTURE.md`
- **Architecture Overview:** `backend/ARCHITECTURE.md`
- **Middleware Reference:** `backend/MIDDLEWARE_QUICK_REFERENCE.md`

## 📊 API Endpoints Summary

| Endpoint | Method | Auth | Role | Description |
|----------|--------|------|------|-------------|
| `/api/checkin` | POST | ✓ | receptionist | Check in guest |
| `/api/checkout` | POST | ✓ | receptionist | Check out guest |
| `/api/checkin/move-room` | POST | ✓ | receptionist | Move room |
| `/api/bookings/:id/no-show` | POST | ✓ | receptionist | Mark no-show |
| `/api/checkin/arrivals` | GET | ✓ | receptionist | Get arrivals |
| `/api/checkout/departures` | GET | ✓ | receptionist | Get departures |
| `/api/checkin/available-rooms/:id` | GET | ✓ | receptionist | Get rooms |

## 🧪 Testing Resources

### Manual Testing
1. **Quick Test:** Follow [TASK_25_QUICKSTART.md](TASK_25_QUICKSTART.md)
2. **Comprehensive Test:** Use [TASK_25_VERIFICATION.md](TASK_25_VERIFICATION.md)

### Automated Testing
1. **PowerShell Script:** Run `test_checkin_module.ps1`
2. **cURL Examples:** See [CHECKIN_CHECKOUT_REFERENCE.md](CHECKIN_CHECKOUT_REFERENCE.md)

### Test Data
- SQL scripts in [TASK_25_QUICKSTART.md](TASK_25_QUICKSTART.md)
- Database verification queries in [TASK_25_VERIFICATION.md](TASK_25_VERIFICATION.md)

## 🔐 Security

### Authentication
- All endpoints require JWT token
- Token must be valid and not expired

### Authorization
- All endpoints require 'receptionist' role
- Role checked via middleware

### Input Validation
- Request body validation
- ID validation
- Date format validation

## 🎓 Learning Path

### For New Developers
1. Read [TASK_25_QUICKSTART.md](TASK_25_QUICKSTART.md)
2. Run the test script
3. Review [CHECKIN_CHECKOUT_REFERENCE.md](CHECKIN_CHECKOUT_REFERENCE.md)
4. Study the code in `internal/handlers/checkin_handler.go`

### For Frontend Developers
1. Read [CHECKIN_CHECKOUT_REFERENCE.md](CHECKIN_CHECKOUT_REFERENCE.md)
2. Test endpoints with cURL
3. Review request/response formats
4. Check error handling

### For QA Engineers
1. Read [TASK_25_VERIFICATION.md](TASK_25_VERIFICATION.md)
2. Run automated tests
3. Execute manual test cases
4. Verify database changes

### For DevOps Engineers
1. Review [TASK_25_SUMMARY.md](TASK_25_SUMMARY.md)
2. Check deployment requirements
3. Review performance considerations
4. Set up monitoring

## 📝 Requirements Traceability

This module implements:
- **Requirement 7:** Check-in Process (7.1-7.8)
- **Requirement 8:** Room Move (8.1-8.7)
- **Requirement 9:** Check-out Process (9.1-9.7)
- **Requirement 20:** No-Show Handling (20.1-20.7)

See [TASK_25_SUMMARY.md](TASK_25_SUMMARY.md) for detailed requirement mapping.

## 🚦 Status

- **Implementation:** ✅ Complete
- **Testing:** ✅ Test script provided
- **Documentation:** ✅ Complete
- **Code Review:** ⏳ Pending
- **Deployment:** ⏳ Ready

## 📞 Support

### Common Issues
See troubleshooting section in [TASK_25_QUICKSTART.md](TASK_25_QUICKSTART.md)

### Questions
1. Check the relevant documentation above
2. Review code comments
3. Check related tasks documentation

## 🔄 Version History

- **v1.0.0** (Current) - Initial implementation
  - All endpoints implemented
  - Complete documentation
  - Test script provided

## 📌 Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│ Check-in/Check-out Module - Quick Reference            │
├─────────────────────────────────────────────────────────┤
│ Base URL: http://localhost:8080/api                    │
│ Auth: Bearer Token (Receptionist role required)        │
├─────────────────────────────────────────────────────────┤
│ POST   /checkin                    - Check in          │
│ POST   /checkout                   - Check out         │
│ POST   /checkin/move-room          - Move room         │
│ POST   /bookings/:id/no-show       - Mark no-show      │
│ GET    /checkin/arrivals           - Get arrivals      │
│ GET    /checkout/departures        - Get departures    │
│ GET    /checkin/available-rooms/:id - Get rooms        │
└─────────────────────────────────────────────────────────┘
```

## 🎉 Conclusion

Task 25 is complete with comprehensive documentation. Choose the document that best fits your needs from the links above.

**Happy coding!** 🚀
