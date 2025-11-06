# Task 32: Policy & Voucher Management - Index

## Quick Links

### Documentation
- [📖 Quick Start Guide](./TASK_32_QUICKSTART.md) - Get started quickly
- [📚 API Reference](./POLICY_VOUCHER_MODULE_REFERENCE.md) - Complete API documentation
- [📝 Implementation Summary](./TASK_32_SUMMARY.md) - What was implemented
- [✅ Verification Checklist](./TASK_32_VERIFICATION.md) - Testing checklist

### Code Files
- [Models](./internal/models/policy.go) - Data models
- [Repository](./internal/repository/policy_repository.go) - Database layer
- [Service](./internal/service/policy_service.go) - Business logic
- [Handler](./internal/handlers/policy_handler.go) - HTTP handlers
- [Router](./internal/router/router.go) - Route configuration

### Testing
- [Test Script](./test_policy_module.ps1) - Automated testing

## Overview

Task 32 implements comprehensive management of cancellation policies and discount vouchers for the hotel booking system.

## Features

### Cancellation Policy Management
- Create, read, update, and delete policies
- Define refund percentages based on days before check-in
- Prevent deletion of policies in use
- Policy snapshots at booking time

### Voucher Management
- Create and manage discount vouchers
- Support percentage and fixed amount discounts
- Expiry date and usage limit validation
- Public voucher validation endpoint
- Automatic code normalization

## API Endpoints

### Cancellation Policies (Manager Only)
```
GET    /api/policies/cancellation      - List all policies
GET    /api/policies/cancellation/:id  - Get policy by ID
POST   /api/policies/cancellation      - Create policy
PUT    /api/policies/cancellation/:id  - Update policy
DELETE /api/policies/cancellation/:id  - Delete policy
```

### Vouchers
```
POST   /api/vouchers/validate          - Validate voucher (Public)
GET    /api/vouchers                   - List all vouchers (Manager)
GET    /api/vouchers/:id               - Get voucher by ID (Manager)
POST   /api/vouchers                   - Create voucher (Manager)
PUT    /api/vouchers/:id               - Update voucher (Manager)
DELETE /api/vouchers/:id               - Delete voucher (Manager)
```

## Quick Start

### 1. Run the test script
```powershell
cd backend
.\test_policy_module.ps1
```

### 2. Create a cancellation policy
```bash
POST /api/policies/cancellation
Authorization: Bearer <manager_token>

{
  "name": "Flexible",
  "description": "Full refund if cancelled 7 days before check-in",
  "days_before_check_in": 7,
  "refund_percentage": 100
}
```

### 3. Create a voucher
```bash
POST /api/vouchers
Authorization: Bearer <manager_token>

{
  "code": "SUMMER2024",
  "discount_type": "Percentage",
  "discount_value": 20,
  "expiry_date": "2024-12-31",
  "max_uses": 100
}
```

### 4. Validate a voucher (no auth required)
```bash
POST /api/vouchers/validate

{
  "code": "SUMMER2024",
  "total_amount": 5000
}
```

## Requirements Covered

- ✅ Requirement 16.1-16.7: Cancellation Policy Management
- ✅ Requirement 17.1-17.7: Voucher Management

## Key Features

### Validation
- Refund percentage: 0-100%
- Days before check-in: >= 0
- Discount types: Percentage or FixedAmount
- Expiry dates must be in future
- Usage limits enforced
- Code normalization (uppercase)

### Business Rules
- Cannot delete policies/vouchers in use
- Policies snapshotted at booking time
- Voucher usage tracked atomically
- Discount capped at total amount
- Max uses cannot be less than current uses

### Security
- Manager role required for management
- Public validation endpoint
- JWT authentication
- Input validation
- SQL injection prevention

## Testing

The test script covers:
- ✅ Policy CRUD operations
- ✅ Voucher CRUD operations
- ✅ Voucher validation (valid, invalid, expired)
- ✅ Business rule enforcement
- ✅ Error handling
- ✅ Cleanup operations

## Integration

### With Pricing Module
- Rate plans link to cancellation policies
- Policy details in rate plan responses

### With Booking Module
- Voucher validation during checkout
- Discount calculation
- Usage increment on confirmation
- Policy snapshot storage

## Files Created

**Code:**
- `internal/models/policy.go`
- `internal/repository/policy_repository.go`
- `internal/service/policy_service.go`
- `internal/handlers/policy_handler.go`

**Documentation:**
- `TASK_32_INDEX.md` (this file)
- `TASK_32_QUICKSTART.md`
- `TASK_32_SUMMARY.md`
- `TASK_32_VERIFICATION.md`
- `POLICY_VOUCHER_MODULE_REFERENCE.md`

**Testing:**
- `test_policy_module.ps1`

**Modified:**
- `internal/router/router.go`

## Status

✅ **COMPLETED** - All requirements implemented and tested

## Next Steps

1. Run the test script to verify implementation
2. Review the API reference for detailed documentation
3. Integrate with booking flow
4. Test with frontend application

## Support

For questions or issues:
1. Check the [Quick Start Guide](./TASK_32_QUICKSTART.md)
2. Review the [API Reference](./POLICY_VOUCHER_MODULE_REFERENCE.md)
3. Run the [Verification Checklist](./TASK_32_VERIFICATION.md)
4. Check the [Implementation Summary](./TASK_32_SUMMARY.md)
