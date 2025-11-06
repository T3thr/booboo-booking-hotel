# Task 32: Policy & Voucher Management - Quick Start Guide

## Overview

This guide helps you quickly test the Policy & Voucher Management module.

## Prerequisites

1. Backend server running on `http://localhost:8080`
2. Database with seed data (including manager account)
3. PowerShell (for Windows) or curl (for Linux/Mac)

## Quick Test (PowerShell)

### 1. Run the automated test script

```powershell
cd backend
.\test_policy_module.ps1
```

This script will:
- Login as manager
- Test all cancellation policy endpoints
- Test all voucher endpoints
- Validate vouchers (including edge cases)
- Clean up test data

## Manual Testing

### 1. Login as Manager

```powershell
$loginResponse = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/auth/login" `
  -ContentType "application/json" `
  -Body '{"email":"manager@hotel.com","password":"password123"}'

$token = $loginResponse.data.accessToken
```

### 2. Create a Cancellation Policy

```powershell
$policy = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/policies/cancellation" `
  -Headers @{Authorization="Bearer $token"} `
  -ContentType "application/json" `
  -Body '{
    "name": "Flexible",
    "description": "Full refund if cancelled 7 days before check-in",
    "days_before_check_in": 7,
    "refund_percentage": 100
  }'

Write-Host "Created policy ID: $($policy.data.policy_id)"
```

### 3. Get All Cancellation Policies

```powershell
$policies = Invoke-RestMethod -Method GET -Uri "http://localhost:8080/api/policies/cancellation" `
  -Headers @{Authorization="Bearer $token"}

$policies.data | Format-Table name, days_before_check_in, refund_percentage
```

### 4. Create a Voucher

```powershell
$futureDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

$voucher = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/vouchers" `
  -Headers @{Authorization="Bearer $token"} `
  -ContentType "application/json" `
  -Body "{
    `"code`": `"SUMMER2024`",
    `"discount_type`": `"Percentage`",
    `"discount_value`": 20,
    `"expiry_date`": `"$futureDate`",
    `"max_uses`": 100
  }"

Write-Host "Created voucher: $($voucher.data.code)"
```

### 5. Validate a Voucher (Public Endpoint - No Auth Required)

```powershell
$validation = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/vouchers/validate" `
  -ContentType "application/json" `
  -Body '{
    "code": "SUMMER2024",
    "total_amount": 5000
  }'

if ($validation.data.valid) {
    Write-Host "Voucher is valid!"
    Write-Host "Original Amount: 5000 THB"
    Write-Host "Discount: $($validation.data.discount_amount) THB"
    Write-Host "Final Amount: $($validation.data.final_amount) THB"
} else {
    Write-Host "Voucher is invalid: $($validation.data.message)"
}
```

### 6. Get All Vouchers

```powershell
$vouchers = Invoke-RestMethod -Method GET -Uri "http://localhost:8080/api/vouchers" `
  -Headers @{Authorization="Bearer $token"}

$vouchers.data | Format-Table code, discount_type, discount_value, current_uses, max_uses
```

### 7. Update a Voucher

```powershell
$voucherId = 1  # Replace with actual voucher ID

$updated = Invoke-RestMethod -Method PUT -Uri "http://localhost:8080/api/vouchers/$voucherId" `
  -Headers @{Authorization="Bearer $token"} `
  -ContentType "application/json" `
  -Body '{
    "discount_value": 25,
    "max_uses": 150
  }'

Write-Host "Updated voucher: $($updated.data.code)"
```

## Testing with curl (Linux/Mac)

### 1. Login

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"password123"}' \
  | jq -r '.data.accessToken')
```

### 2. Create Cancellation Policy

```bash
curl -X POST http://localhost:8080/api/policies/cancellation \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Flexible",
    "description": "Full refund if cancelled 7 days before check-in",
    "days_before_check_in": 7,
    "refund_percentage": 100
  }'
```

### 3. Create Voucher

```bash
FUTURE_DATE=$(date -d "+30 days" +%Y-%m-%d)

curl -X POST http://localhost:8080/api/vouchers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"code\": \"SUMMER2024\",
    \"discount_type\": \"Percentage\",
    \"discount_value\": 20,
    \"expiry_date\": \"$FUTURE_DATE\",
    \"max_uses\": 100
  }"
```

### 4. Validate Voucher

```bash
curl -X POST http://localhost:8080/api/vouchers/validate \
  -H "Content-Type: application/json" \
  -d '{
    "code": "SUMMER2024",
    "total_amount": 5000
  }'
```

## Common Test Scenarios

### Scenario 1: Percentage Discount Voucher

```json
{
  "code": "SAVE20",
  "discount_type": "Percentage",
  "discount_value": 20,
  "expiry_date": "2024-12-31",
  "max_uses": 100
}
```

For a 5000 THB booking:
- Discount: 1000 THB (20%)
- Final: 4000 THB

### Scenario 2: Fixed Amount Discount Voucher

```json
{
  "code": "FLAT500",
  "discount_type": "FixedAmount",
  "discount_value": 500,
  "expiry_date": "2024-12-31",
  "max_uses": 50
}
```

For a 5000 THB booking:
- Discount: 500 THB
- Final: 4500 THB

### Scenario 3: Flexible Cancellation Policy

```json
{
  "name": "Flexible",
  "description": "Full refund if cancelled 7 days before check-in",
  "days_before_check_in": 7,
  "refund_percentage": 100
}
```

### Scenario 4: Non-Refundable Policy

```json
{
  "name": "Non-Refundable",
  "description": "No refund for cancellations",
  "days_before_check_in": 0,
  "refund_percentage": 0
}
```

## Validation Tests

### Test Invalid Voucher Code

```powershell
$result = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/vouchers/validate" `
  -ContentType "application/json" `
  -Body '{"code": "INVALID", "total_amount": 5000}'

# Should return: valid = false, message = "Invalid voucher code"
```

### Test Expired Voucher

Create a voucher with past expiry date (will fail validation):
```powershell
$pastDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
# This should fail at creation time
```

### Test Voucher at Max Uses

1. Create voucher with max_uses = 1
2. Use it in a booking
3. Try to validate again - should fail with "reached usage limit"

## Troubleshooting

### Issue: "Failed to login"
**Solution:** Ensure manager account exists in database. Run seed data script.

### Issue: "Authorization header missing"
**Solution:** Include the Bearer token in Authorization header for protected endpoints.

### Issue: "Invalid date format"
**Solution:** Use YYYY-MM-DD format for dates (e.g., "2024-12-31").

### Issue: "Cannot delete policy: in use"
**Solution:** Policy is linked to rate plans. Update rate plans first or deactivate instead of deleting.

### Issue: "Voucher code already exists"
**Solution:** Voucher codes must be unique. Use a different code.

## Next Steps

1. ✅ Test all endpoints with the automated script
2. ✅ Verify validation logic works correctly
3. ✅ Test integration with booking flow
4. ✅ Check error handling for edge cases
5. ✅ Review documentation

## Related Documentation

- [Policy & Voucher Module Reference](./POLICY_VOUCHER_MODULE_REFERENCE.md)
- [Requirements Document](../.kiro/specs/hotel-reservation-system/requirements.md) - Requirements 16.1-16.7, 17.1-17.7
- [Design Document](../.kiro/specs/hotel-reservation-system/design.md)
