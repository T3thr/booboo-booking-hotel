# Task 31: Inventory Management Module - Index

## Quick Links

- [Quick Start Guide](TASK_31_QUICKSTART.md) - Get started quickly
- [API Reference](INVENTORY_MODULE_REFERENCE.md) - Complete API documentation
- [Summary](TASK_31_SUMMARY.md) - Implementation summary
- [Verification Checklist](TASK_31_VERIFICATION.md) - Testing checklist
- [Test Script](test_inventory_module.ps1) - Automated testing

## Overview

The Inventory Management Module allows hotel managers to view and manage room inventory (allotment) across dates. It includes comprehensive validation to prevent overbooking and maintain data integrity.

## What Was Implemented

### Backend Components

1. **Models** (`internal/models/inventory.go`)
   - Data structures for inventory management
   - Request/response models
   - Validation error structures

2. **Repository** (`internal/repository/inventory_repository.go`)
   - Database operations
   - Query optimization
   - Validation logic

3. **Service** (`internal/service/inventory_service.go`)
   - Business logic
   - Date validation
   - Room type verification

4. **Handler** (`internal/handlers/inventory_handler.go`)
   - HTTP request handling
   - Response formatting
   - Error handling

5. **Router** (`internal/router/router.go`)
   - Route registration
   - Middleware integration
   - Authorization setup

### API Endpoints

All endpoints require manager authentication:

```
GET  /api/inventory                      - Get inventory (all or filtered)
GET  /api/inventory/:roomTypeId/:date    - Get specific date inventory
PUT  /api/inventory                      - Update single date
POST /api/inventory/bulk                 - Bulk update date range
```

### Key Features

- ✅ View inventory for all room types
- ✅ Filter by specific room type
- ✅ Query by date range (up to 1 year)
- ✅ Update single date allotment
- ✅ Bulk update date ranges
- ✅ Validation against existing bookings
- ✅ Detailed error messages
- ✅ Atomic bulk operations

## Requirements Covered

| Requirement | Description | Status |
|-------------|-------------|--------|
| 13.1 | Manager can access inventory management | ✅ Complete |
| 13.2 | Display inventory for 365 days | ✅ Complete |
| 13.3 | Update allotment for specific dates | ✅ Complete |
| 13.4 | Validate allotment >= bookings | ✅ Complete |
| 13.5 | Reject invalid updates with error | ✅ Complete |
| 13.6 | Bulk update for date ranges | ✅ Complete |
| 13.7 | Display with heatmap (backend ready) | ✅ Complete |

## Getting Started

### 1. Quick Test

```powershell
cd backend
.\test_inventory_module.ps1
```

### 2. Manual Test

See [Quick Start Guide](TASK_31_QUICKSTART.md) for detailed examples.

### 3. API Documentation

See [API Reference](INVENTORY_MODULE_REFERENCE.md) for complete endpoint documentation.

## File Structure

```
backend/
├── internal/
│   ├── models/
│   │   └── inventory.go                    # Data models
│   ├── repository/
│   │   └── inventory_repository.go         # Database layer
│   ├── service/
│   │   └── inventory_service.go            # Business logic
│   ├── handlers/
│   │   └── inventory_handler.go            # HTTP handlers
│   └── router/
│       └── router.go                        # Routes (updated)
├── test_inventory_module.ps1               # Test script
├── INVENTORY_MODULE_REFERENCE.md           # API documentation
├── TASK_31_INDEX.md                        # This file
├── TASK_31_QUICKSTART.md                   # Quick start guide
├── TASK_31_SUMMARY.md                      # Implementation summary
└── TASK_31_VERIFICATION.md                 # Verification checklist
```

## Common Tasks

### View Inventory

```bash
# Get all inventory for next 30 days
curl -X GET "http://localhost:8080/api/inventory?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer $TOKEN"
```

### Update Single Date

```bash
# Update allotment for specific date
curl -X PUT http://localhost:8080/api/inventory \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "date": "2024-01-15",
    "allotment": 20
  }'
```

### Bulk Update

```bash
# Update entire month
curl -X POST http://localhost:8080/api/inventory/bulk \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_type_id": 1,
    "start_date": "2024-02-01",
    "end_date": "2024-02-29",
    "allotment": 25
  }'
```

## Validation Rules

The module enforces this critical business rule:

```
allotment >= booked_count + tentative_count
```

This prevents:
- Reducing inventory below existing bookings
- Overbooking situations
- Data integrity issues

## Integration Points

### Booking Module
- Checks inventory during booking creation
- Updates counts on booking confirmation
- Updates counts on booking cancellation

### Room Module
- Validates room type IDs
- Provides room type details
- Integrates with room search

### Pricing Module
- Can be displayed alongside pricing calendar
- Helps inform pricing decisions
- Complementary manager tools

## Testing

### Automated Testing

Run the PowerShell test script:
```powershell
.\test_inventory_module.ps1
```

### Manual Testing

Follow the [Quick Start Guide](TASK_31_QUICKSTART.md).

### Verification

Use the [Verification Checklist](TASK_31_VERIFICATION.md) to ensure all features work correctly.

## Troubleshooting

### Common Issues

1. **Unauthorized Error**
   - Ensure you're logged in as manager
   - Check token is valid and not expired

2. **Validation Error**
   - Check current booking counts
   - Ensure new allotment >= (booked + tentative)

3. **Date Format Error**
   - Use YYYY-MM-DD format
   - Ensure dates are valid

4. **Room Type Not Found**
   - Verify room type ID exists
   - Check database has room types

See [Quick Start Guide](TASK_31_QUICKSTART.md) for detailed troubleshooting.

## Next Steps

1. ✅ Backend implementation complete
2. ⏭️ Frontend implementation (separate task)
3. ⏭️ Integration testing with booking flow
4. ⏭️ Performance optimization if needed

## Related Tasks

- **Task 30**: Pricing Management Module (completed)
- **Task 31**: Inventory Management Module (this task)
- **Task 32**: Policy & Voucher Management (next)

## Documentation

- [API Reference](INVENTORY_MODULE_REFERENCE.md) - Complete API documentation
- [Quick Start](TASK_31_QUICKSTART.md) - Get started quickly
- [Summary](TASK_31_SUMMARY.md) - Implementation details
- [Verification](TASK_31_VERIFICATION.md) - Testing checklist

## Support

For issues or questions:
1. Check the [API Reference](INVENTORY_MODULE_REFERENCE.md)
2. Review the [Quick Start Guide](TASK_31_QUICKSTART.md)
3. Run the test script to verify setup
4. Check the [Verification Checklist](TASK_31_VERIFICATION.md)

## Status

✅ **COMPLETE** - All requirements implemented and documented

- All endpoints implemented
- Validation working correctly
- Documentation complete
- Test script provided
- Ready for frontend integration
