# API Documentation Index

## Quick Links

- **View Documentation:** http://localhost:8080/docs (when server is running)
- **OpenAPI Spec:** [swagger.yaml](./swagger.yaml)
- **Testing Guide:** [TESTING_GUIDE.md](./TESTING_GUIDE.md)
- **Completion Summary:** [API_DOCUMENTATION_SUMMARY.md](./API_DOCUMENTATION_SUMMARY.md)

## Documentation Files

### Core Documentation
- **[swagger.yaml](./swagger.yaml)** - Complete OpenAPI 3.0 specification
- **[README.md](./README.md)** - Documentation overview and usage instructions

### Examples
- **[auth-examples.md](./examples/auth-examples.md)** - Authentication endpoint examples
- **[booking-examples.md](./examples/booking-examples.md)** - Booking flow examples
- **[room-examples.md](./examples/room-examples.md)** - Room search examples

### Setup & Testing
- **[setup-swagger-ui.sh](./setup-swagger-ui.sh)** - Setup script for Linux/Mac
- **[setup-swagger-ui.bat](./setup-swagger-ui.bat)** - Setup script for Windows
- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Comprehensive testing guide
- **[verify-documentation.sh](./verify-documentation.sh)** - Verification script (Linux/Mac)
- **[verify-documentation.bat](./verify-documentation.bat)** - Verification script (Windows)

### Summary
- **[API_DOCUMENTATION_SUMMARY.md](./API_DOCUMENTATION_SUMMARY.md)** - Task completion summary

## Quick Start

### 1. View Documentation

```bash
# Start the backend server
cd backend
go run cmd/server/main.go

# Open browser to:
# http://localhost:8080/docs
```

### 2. Test an Endpoint

```bash
# Register a new user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "firstName": "Test",
    "lastName": "User",
    "phone": "0812345678"
  }'
```

### 3. Verify Documentation

```bash
# Linux/Mac
chmod +x backend/docs/verify-documentation.sh
./backend/docs/verify-documentation.sh

# Windows
backend\docs\verify-documentation.bat
```

## API Modules

### 1. Authentication (`/api/auth`)
- User registration and login
- Profile management
- JWT token authentication

**Examples:** [auth-examples.md](./examples/auth-examples.md)

### 2. Rooms (`/api/rooms`)
- Search available rooms
- Get room types and details
- Calculate pricing
- Room status dashboard (Receptionist)

**Examples:** [room-examples.md](./examples/room-examples.md)

### 3. Bookings (`/api/bookings`)
- Create booking holds
- Create and confirm bookings
- View booking history
- Cancel bookings

**Examples:** [booking-examples.md](./examples/booking-examples.md)

### 4. Check-in/Check-out (`/api/checkin`, `/api/checkout`)
- Check-in guests
- Check-out guests
- Move rooms
- View arrivals/departures

**Role:** Receptionist only

### 5. Housekeeping (`/api/housekeeping`)
- View cleaning tasks
- Update room status
- Inspect rooms
- Report maintenance issues

**Role:** Housekeeper only

### 6. Pricing Management (`/api/pricing`)
- Manage rate tiers
- Configure pricing calendar
- Set rate pricing matrix
- Bulk pricing updates

**Role:** Manager only

### 7. Inventory Management (`/api/inventory`)
- View room inventory
- Update allotments
- Bulk inventory updates

**Role:** Manager only

### 8. Policies & Vouchers (`/api/policies`, `/api/vouchers`)
- Manage cancellation policies
- Create and manage vouchers
- Validate voucher codes

**Role:** Manager only (except voucher validation)

### 9. Reports (`/api/reports`)
- Occupancy reports
- Revenue reports
- Voucher usage reports
- No-show reports
- Export to CSV

**Role:** Manager only

### 10. Admin (`/api/admin`)
- Trigger night audit
- Trigger hold cleanup
- View job status

**Role:** Manager only

## Authentication

All protected endpoints require a JWT token:

```bash
# Get token from login/register
TOKEN="your-jwt-token"

# Use in requests
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/auth/me
```

## Rate Limiting

- **Auth endpoints:** 5 requests/minute
- **Search endpoints:** 20 requests/minute
- **Booking endpoints:** 10 requests/minute
- **General endpoints:** 100 requests/minute

## Response Format

### Success
```json
{
  "data": { ... },
  "message": "Success"
}
```

### Error
```json
{
  "error": "Error message"
}
```

## Status Codes

- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

## Tools

### Swagger UI
Interactive API documentation and testing interface.

**Access:** http://localhost:8080/docs

### Postman
Import the collection: `backend/BOOKING_MODULE_POSTMAN.json`

### cURL
All examples include cURL commands for easy testing.

## Support

### Documentation Issues
- Check [TESTING_GUIDE.md](./TESTING_GUIDE.md)
- Review example files in `examples/`
- See test files in `backend/internal/handlers/*_test.go`

### API Issues
- Check quick reference guides: `backend/*_QUICK_REFERENCE.md`
- Review module documentation: `backend/*_MODULE_REFERENCE.md`
- See verification checklists: `backend/*_VERIFICATION_CHECKLIST.md`

## Related Documentation

### Backend Documentation
- [Architecture](../ARCHITECTURE.md)
- [Quick Start](../QUICK_START.md)
- [Project Structure](../PROJECT_STRUCTURE.md)

### Module-Specific Guides
- [Authentication](../AUTH_QUICK_REFERENCE.md)
- [Booking Module](../BOOKING_QUICK_REFERENCE.md)
- [Room Search](../ROOM_SEARCH_QUICK_REFERENCE.md)
- [Check-in/Check-out](../CHECKIN_CHECKOUT_REFERENCE.md)
- [Housekeeping](../HOUSEKEEPING_MODULE_REFERENCE.md)
- [Pricing](../PRICING_MODULE_REFERENCE.md)
- [Inventory](../INVENTORY_MODULE_REFERENCE.md)
- [Policies & Vouchers](../POLICY_VOUCHER_MODULE_REFERENCE.md)
- [Reports](../REPORTING_MODULE_REFERENCE.md)
- [Night Audit](../NIGHT_AUDIT_REFERENCE.md)
- [Hold Cleanup](../HOLD_CLEANUP_REFERENCE.md)

### Testing Documentation
- [Unit Tests](../TASK_39_UNIT_TESTS.md)
- [Integration Tests](../../database/tests/INTEGRATION_TESTS_README.md)
- [E2E Tests](../../e2e/README.md)
- [Load Tests](../../load-tests/README.md)

### Security Documentation
- [Security Audit](../SECURITY_AUDIT.md)
- [Security Checklist](../SECURITY_CHECKLIST.md)
- [Security Quick Reference](../SECURITY_QUICK_REFERENCE.md)

## Version

**API Version:** 1.0.0  
**OpenAPI Version:** 3.0.3  
**Last Updated:** November 3, 2025

---

**Task 46: API Documentation** - ✅ Completed
