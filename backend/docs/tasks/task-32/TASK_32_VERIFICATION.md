# Task 32: Policy & Voucher Management - Verification Checklist

## Overview

This document provides a comprehensive checklist to verify that Task 32 (Policy & Voucher Management) has been implemented correctly and meets all requirements.

## Pre-Verification Setup

- [ ] Backend server is running on `http://localhost:8080`
- [ ] Database is initialized with seed data
- [ ] Manager account exists (`manager@hotel.com`)
- [ ] PowerShell or curl is available for testing

## Component Verification

### 1. Models (`internal/models/policy.go`)

- [ ] `CancellationPolicy` struct defined with all fields
- [ ] `CreateCancellationPolicyRequest` with validation tags
- [ ] `UpdateCancellationPolicyRequest` with optional fields
- [ ] `Voucher` struct defined with all fields
- [ ] `CreateVoucherRequest` with validation tags
- [ ] `UpdateVoucherRequest` with optional fields
- [ ] `ValidateVoucherRequest` defined
- [ ] `ValidateVoucherResponse` defined with all fields

### 2. Repository Layer (`internal/repository/policy_repository.go`)

**Cancellation Policy Methods:**
- [ ] `GetAllCancellationPolicies()` implemented
- [ ] `GetCancellationPolicyByID()` implemented
- [ ] `CreateCancellationPolicy()` implemented
- [ ] `UpdateCancellationPolicy()` with dynamic query building
- [ ] `DeleteCancellationPolicy()` implemented
- [ ] `CheckPolicyInUse()` implemented

**Voucher Methods:**
- [ ] `GetAllVouchers()` implemented
- [ ] `GetVoucherByID()` implemented
- [ ] `GetVoucherByCode()` implemented
- [ ] `CreateVoucher()` implemented
- [ ] `UpdateVoucher()` with dynamic query building
- [ ] `DeleteVoucher()` implemented
- [ ] `CheckVoucherInUse()` implemented

### 3. Service Layer (`internal/service/policy_service.go`)

**Cancellation Policy Logic:**
- [ ] Validates refund percentage (0-100)
- [ ] Validates days before check-in (>= 0)
- [ ] Prevents deletion of policies in use
- [ ] All CRUD operations work correctly

**Voucher Logic:**
- [ ] Validates discount type (Percentage/FixedAmount)
- [ ] Validates discount value (> 0, <= 100 for percentage)
- [ ] Validates expiry date format (YYYY-MM-DD)
- [ ] Checks expiry date is in future
- [ ] Validates max_uses >= 1
- [ ] Prevents max_uses < current_uses
- [ ] Normalizes code to uppercase
- [ ] Prevents deletion of vouchers in use
- [ ] Validates voucher (code, active, expiry, usage)
- [ ] Calculates discount correctly (percentage and fixed)
- [ ] Ensures discount doesn't exceed total amount

### 4. Handler Layer (`internal/handlers/policy_handler.go`)

**Cancellation Policy Endpoints:**
- [ ] `GetAllCancellationPolicies` returns 200 with data
- [ ] `GetCancellationPolicyByID` returns 200 or 404
- [ ] `CreateCancellationPolicy` returns 201 with created policy
- [ ] `UpdateCancellationPolicy` returns 200 with updated policy
- [ ] `DeleteCancellationPolicy` returns 200 or error
- [ ] All endpoints handle errors properly
- [ ] All endpoints return consistent JSON format

**Voucher Endpoints:**
- [ ] `GetAllVouchers` returns 200 with data
- [ ] `GetVoucherByID` returns 200 or 404
- [ ] `CreateVoucher` returns 201 with created voucher
- [ ] `UpdateVoucher` returns 200 with updated voucher
- [ ] `DeleteVoucher` returns 200 or error
- [ ] `ValidateVoucher` returns validation result
- [ ] All endpoints handle errors properly
- [ ] All endpoints return consistent JSON format

### 5. Router Integration (`internal/router/router.go`)

- [ ] Policy repository initialized
- [ ] Policy service initialized
- [ ] Policy handler initialized
- [ ] Policy routes registered under `/api/policies`
- [ ] Voucher routes registered under `/api/vouchers`
- [ ] Manager authentication middleware applied
- [ ] Validate endpoint is public (no auth)
- [ ] All routes follow RESTful conventions

## Functional Testing

### Cancellation Policy Tests

#### Test 1: Get All Policies
```powershell
# Should return list of policies
GET /api/policies/cancellation
```
- [ ] Returns 200 status
- [ ] Returns array of policies
- [ ] Each policy has all required fields
- [ ] Policies are ordered by name

#### Test 2: Create Policy
```powershell
# Should create new policy
POST /api/policies/cancellation
{
  "name": "Test Policy",
  "description": "Test description",
  "days_before_check_in": 7,
  "refund_percentage": 100
}
```
- [ ] Returns 201 status
- [ ] Returns created policy with ID
- [ ] Policy is saved in database
- [ ] Timestamps are set correctly

#### Test 3: Get Policy by ID
```powershell
# Should return specific policy
GET /api/policies/cancellation/:id
```
- [ ] Returns 200 for valid ID
- [ ] Returns 404 for invalid ID
- [ ] Returns complete policy data

#### Test 4: Update Policy
```powershell
# Should update policy
PUT /api/policies/cancellation/:id
{
  "refund_percentage": 90
}
```
- [ ] Returns 200 status
- [ ] Returns updated policy
- [ ] Only specified fields are updated
- [ ] Updated_at timestamp is updated

#### Test 5: Delete Policy
```powershell
# Should delete policy
DELETE /api/policies/cancellation/:id
```
- [ ] Returns 200 for unused policy
- [ ] Returns error for policy in use
- [ ] Policy is removed from database

#### Test 6: Validation Tests
- [ ] Rejects negative refund percentage
- [ ] Rejects refund percentage > 100
- [ ] Rejects negative days before check-in
- [ ] Requires all mandatory fields

### Voucher Tests

#### Test 7: Get All Vouchers
```powershell
# Should return list of vouchers
GET /api/vouchers
```
- [ ] Returns 200 status
- [ ] Returns array of vouchers
- [ ] Each voucher has all required fields
- [ ] Vouchers are ordered by created_at DESC

#### Test 8: Create Voucher
```powershell
# Should create new voucher
POST /api/vouchers
{
  "code": "TEST2024",
  "discount_type": "Percentage",
  "discount_value": 20,
  "expiry_date": "2024-12-31",
  "max_uses": 100
}
```
- [ ] Returns 201 status
- [ ] Returns created voucher with ID
- [ ] Code is normalized to uppercase
- [ ] Voucher is saved in database
- [ ] Timestamps are set correctly

#### Test 9: Get Voucher by ID
```powershell
# Should return specific voucher
GET /api/vouchers/:id
```
- [ ] Returns 200 for valid ID
- [ ] Returns 404 for invalid ID
- [ ] Returns complete voucher data

#### Test 10: Update Voucher
```powershell
# Should update voucher
PUT /api/vouchers/:id
{
  "discount_value": 25,
  "max_uses": 150
}
```
- [ ] Returns 200 status
- [ ] Returns updated voucher
- [ ] Only specified fields are updated
- [ ] Updated_at timestamp is updated

#### Test 11: Delete Voucher
```powershell
# Should delete voucher
DELETE /api/vouchers/:id
```
- [ ] Returns 200 for unused voucher
- [ ] Returns error for voucher in use
- [ ] Voucher is removed from database

#### Test 12: Validate Voucher - Valid
```powershell
# Should validate successfully
POST /api/vouchers/validate
{
  "code": "TEST2024",
  "total_amount": 5000
}
```
- [ ] Returns 200 status
- [ ] Returns valid = true
- [ ] Calculates discount correctly
- [ ] Returns final amount
- [ ] No authentication required

#### Test 13: Validate Voucher - Invalid Code
```powershell
# Should reject invalid code
POST /api/vouchers/validate
{
  "code": "INVALID",
  "total_amount": 5000
}
```
- [ ] Returns 200 status
- [ ] Returns valid = false
- [ ] Returns appropriate error message

#### Test 14: Validate Voucher - Expired
```powershell
# Should reject expired voucher
```
- [ ] Returns valid = false
- [ ] Returns "expired" message

#### Test 15: Validate Voucher - Max Uses Reached
```powershell
# Should reject voucher at limit
```
- [ ] Returns valid = false
- [ ] Returns "usage limit" message

#### Test 16: Validate Voucher - Inactive
```powershell
# Should reject inactive voucher
```
- [ ] Returns valid = false
- [ ] Returns "not active" message

#### Test 17: Discount Calculation - Percentage
```powershell
# 20% discount on 5000 THB
```
- [ ] Calculates 1000 THB discount
- [ ] Returns 4000 THB final amount

#### Test 18: Discount Calculation - Fixed Amount
```powershell
# 500 THB discount on 5000 THB
```
- [ ] Calculates 500 THB discount
- [ ] Returns 4500 THB final amount

#### Test 19: Discount Cap
```powershell
# 1000 THB discount on 500 THB booking
```
- [ ] Caps discount at 500 THB
- [ ] Returns 0 THB final amount

#### Test 20: Validation Tests
- [ ] Rejects invalid discount type
- [ ] Rejects negative discount value
- [ ] Rejects percentage > 100
- [ ] Rejects past expiry date
- [ ] Rejects max_uses < 1
- [ ] Rejects max_uses < current_uses
- [ ] Requires all mandatory fields
- [ ] Normalizes code to uppercase

## Security Testing

### Authentication Tests
- [ ] Policy endpoints require manager token
- [ ] Voucher management requires manager token
- [ ] Validate endpoint is public (no token)
- [ ] Invalid token returns 401
- [ ] Non-manager token returns 403

### Authorization Tests
- [ ] Guest cannot access policy endpoints
- [ ] Receptionist cannot access policy endpoints
- [ ] Housekeeper cannot access policy endpoints
- [ ] Only manager can manage policies/vouchers

### Input Validation Tests
- [ ] SQL injection attempts are blocked
- [ ] XSS attempts are sanitized
- [ ] Invalid JSON returns 400
- [ ] Missing required fields returns 400
- [ ] Invalid data types return 400

## Integration Testing

### With Pricing Module
- [ ] Policies can be linked to rate plans
- [ ] Policy details appear in rate plan responses

### With Booking Module
- [ ] Voucher validation works during checkout
- [ ] Discount is applied correctly
- [ ] Current uses increments on booking
- [ ] Policy snapshot is stored in booking

## Performance Testing

- [ ] Get all policies completes in < 100ms
- [ ] Get all vouchers completes in < 100ms
- [ ] Voucher validation completes in < 50ms
- [ ] Create operations complete in < 200ms
- [ ] Update operations complete in < 200ms

## Error Handling

- [ ] Database errors return 500 with message
- [ ] Validation errors return 400 with details
- [ ] Not found errors return 404
- [ ] Conflict errors return 409
- [ ] All errors have consistent format

## Documentation

- [ ] API reference document exists
- [ ] Quick start guide exists
- [ ] Summary document exists
- [ ] Verification checklist exists (this document)
- [ ] All endpoints are documented
- [ ] Request/response examples provided
- [ ] Error codes documented
- [ ] Business logic explained

## Code Quality

- [ ] Code follows Go conventions
- [ ] Proper error handling throughout
- [ ] No hardcoded values
- [ ] Consistent naming conventions
- [ ] Comments for complex logic
- [ ] No code duplication
- [ ] Proper use of interfaces
- [ ] Type safety maintained

## Test Script

- [ ] `test_policy_module.ps1` exists
- [ ] Script runs without errors
- [ ] All test cases pass
- [ ] Cleanup works correctly
- [ ] Script is well-documented

## Requirements Coverage

### Requirement 16: Cancellation Policy Management
- [ ] 16.1: Create cancellation policies ✓
- [ ] 16.2: Link policies to rate plans ✓
- [ ] 16.3: Display policies to guests ✓
- [ ] 16.4: Snapshot policies at booking ✓
- [ ] 16.5: Updates don't affect existing bookings ✓
- [ ] 16.6: Use snapshotted policy for refunds ✓
- [ ] 16.7: Show policy examples ✓

### Requirement 17: Voucher Management
- [ ] 17.1: Create vouchers with codes ✓
- [ ] 17.2: Validate voucher codes ✓
- [ ] 17.3: Check code, expiry, usage ✓
- [ ] 17.4: Increment uses atomically ✓
- [ ] 17.5: Calculate discounts ✓
- [ ] 17.6: Show discount breakdown ✓
- [ ] 17.7: View usage reports ✓

## Final Verification

Run the automated test script:
```powershell
cd backend
.\test_policy_module.ps1
```

Expected output:
- ✅ All policy operations succeed
- ✅ All voucher operations succeed
- ✅ Validation logic works correctly
- ✅ Error handling works as expected
- ✅ Cleanup completes successfully

## Sign-off

- [ ] All functional tests pass
- [ ] All security tests pass
- [ ] All integration tests pass
- [ ] Documentation is complete
- [ ] Code review completed
- [ ] Ready for production deployment

## Notes

Document any issues or observations during verification:

```
[Add notes here]
```

## Verification Date

Date: _______________

Verified by: _______________

Status: [ ] PASSED  [ ] FAILED  [ ] NEEDS REVIEW
