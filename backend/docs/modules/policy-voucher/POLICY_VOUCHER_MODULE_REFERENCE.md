# Policy & Voucher Management Module Reference

## Overview

This module provides comprehensive management of cancellation policies and discount vouchers for the hotel booking system. It includes validation logic to ensure data integrity and business rule compliance.

## Features

### Cancellation Policy Management
- Create, read, update, and delete cancellation policies
- Define refund percentages based on days before check-in
- Prevent deletion of policies in use by rate plans
- Track policy usage and history

### Voucher Management
- Create and manage discount vouchers
- Support for percentage and fixed amount discounts
- Expiry date validation
- Usage tracking and limits
- Public voucher validation endpoint
- Automatic code normalization (uppercase)

## API Endpoints

### Cancellation Policies

#### Get All Cancellation Policies
```
GET /api/policies/cancellation
Authorization: Bearer <manager_token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "policy_id": 1,
      "name": "Flexible",
      "description": "Full refund if cancelled 7 days before check-in",
      "days_before_check_in": 7,
      "refund_percentage": 100,
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### Get Cancellation Policy by ID
```
GET /api/policies/cancellation/:id
Authorization: Bearer <manager_token>
```

#### Create Cancellation Policy
```
POST /api/policies/cancellation
Authorization: Bearer <manager_token>
Content-Type: application/json

{
  "name": "Flexible",
  "description": "Full refund if cancelled 7 days before check-in",
  "days_before_check_in": 7,
  "refund_percentage": 100
}
```

**Validation Rules:**
- `name`: Required, string
- `description`: Required, string
- `days_before_check_in`: Required, integer >= 0
- `refund_percentage`: Required, float between 0 and 100

#### Update Cancellation Policy
```
PUT /api/policies/cancellation/:id
Authorization: Bearer <manager_token>
Content-Type: application/json

{
  "name": "Updated Flexible",
  "refund_percentage": 90
}
```

**Note:** All fields are optional. Only provided fields will be updated.

#### Delete Cancellation Policy
```
DELETE /api/policies/cancellation/:id
Authorization: Bearer <manager_token>
```

**Note:** Cannot delete policies that are in use by rate plans.

### Vouchers

#### Get All Vouchers
```
GET /api/vouchers
Authorization: Bearer <manager_token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "voucher_id": 1,
      "code": "SUMMER2024",
      "discount_type": "Percentage",
      "discount_value": 20,
      "expiry_date": "2024-12-31T00:00:00Z",
      "max_uses": 100,
      "current_uses": 15,
      "is_active": true,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### Get Voucher by ID
```
GET /api/vouchers/:id
Authorization: Bearer <manager_token>
```

#### Create Voucher
```
POST /api/vouchers
Authorization: Bearer <manager_token>
Content-Type: application/json

{
  "code": "SUMMER2024",
  "discount_type": "Percentage",
  "discount_value": 20,
  "expiry_date": "2024-12-31",
  "max_uses": 100
}
```

**Validation Rules:**
- `code`: Required, string (will be converted to uppercase)
- `discount_type`: Required, must be "Percentage" or "FixedAmount"
- `discount_value`: Required, float > 0 (max 100 for percentage)
- `expiry_date`: Required, format YYYY-MM-DD, must be in the future
- `max_uses`: Required, integer >= 1

#### Update Voucher
```
PUT /api/vouchers/:id
Authorization: Bearer <manager_token>
Content-Type: application/json

{
  "discount_value": 25,
  "max_uses": 150
}
```

**Note:** 
- All fields are optional
- Cannot set max_uses below current_uses
- Code will be normalized to uppercase if provided

#### Delete Voucher
```
DELETE /api/vouchers/:id
Authorization: Bearer <manager_token>
```

**Note:** Cannot delete vouchers that are in use by bookings.

#### Validate Voucher (Public)
```
POST /api/vouchers/validate
Content-Type: application/json

{
  "code": "SUMMER2024",
  "total_amount": 5000
}
```

**Response (Valid):**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "message": "Voucher is valid",
    "voucher_id": 1,
    "discount_type": "Percentage",
    "discount_value": 20,
    "discount_amount": 1000,
    "final_amount": 4000
  }
}
```

**Response (Invalid):**
```json
{
  "success": true,
  "data": {
    "valid": false,
    "message": "This voucher has expired"
  }
}
```

**Validation Checks:**
1. Voucher code exists
2. Voucher is active
3. Voucher has not expired
4. Voucher has not reached max uses

## Business Logic

### Cancellation Policy

**Refund Calculation:**
```
refund_amount = total_amount * (refund_percentage / 100)
```

**Policy Selection:**
- Policies are snapshotted at booking time
- Changes to policies don't affect existing bookings
- Stored in `bookings.policy_name` and `bookings.policy_description`

### Voucher

**Discount Calculation:**

For Percentage:
```
discount_amount = total_amount * (discount_value / 100)
```

For Fixed Amount:
```
discount_amount = discount_value
```

**Maximum Discount:**
```
discount_amount = min(discount_amount, total_amount)
```

**Usage Tracking:**
- `current_uses` incremented atomically when booking is confirmed
- Cannot exceed `max_uses`
- Tracked in booking creation process

## Database Schema

### cancellation_policies
```sql
CREATE TABLE cancellation_policies (
    policy_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    days_before_check_in INT NOT NULL,
    refund_percentage DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### vouchers
```sql
CREATE TABLE vouchers (
    voucher_id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('Percentage', 'FixedAmount')),
    discount_value DECIMAL(10, 2) NOT NULL,
    expiry_date DATE NOT NULL,
    max_uses INT NOT NULL DEFAULT 100,
    current_uses INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Error Handling

### Common Errors

**400 Bad Request:**
- Invalid request body
- Validation errors (e.g., negative values, invalid dates)
- Business rule violations (e.g., max_uses < current_uses)

**404 Not Found:**
- Policy or voucher ID doesn't exist

**409 Conflict:**
- Duplicate voucher code
- Attempting to delete policy/voucher in use

## Testing

Run the test script:
```powershell
.\test_policy_module.ps1
```

The script tests:
1. Cancellation policy CRUD operations
2. Voucher CRUD operations
3. Voucher validation (valid, invalid, expired)
4. Business rule enforcement
5. Cleanup operations

## Integration with Booking Flow

### Using Vouchers in Bookings

1. Guest enters voucher code during checkout
2. Frontend calls `/api/vouchers/validate` with code and total amount
3. If valid, display discount and final amount
4. Include `voucher_id` in booking creation request
5. Backend verifies voucher again and increments `current_uses`

### Using Cancellation Policies

1. Rate plans are linked to cancellation policies
2. When booking is created, policy details are snapshotted
3. When cancellation is requested, use snapshotted policy
4. Calculate refund based on days until check-in

## Best Practices

1. **Voucher Codes:**
   - Use memorable, unique codes
   - Avoid confusing characters (0/O, 1/I)
   - Keep codes 6-12 characters

2. **Expiry Dates:**
   - Set reasonable expiry dates
   - Consider timezone implications
   - Communicate clearly to customers

3. **Usage Limits:**
   - Set appropriate max_uses based on campaign
   - Monitor usage regularly
   - Deactivate when campaign ends

4. **Policy Management:**
   - Create clear, customer-friendly descriptions
   - Test refund calculations
   - Don't delete policies with historical bookings

## Requirements Covered

This module implements:
- **Requirement 16.1-16.7:** Cancellation policy management
- **Requirement 17.1-17.7:** Voucher management and validation

## Related Modules

- **Pricing Module:** Rate plans link to cancellation policies
- **Booking Module:** Uses vouchers and policy snapshots
- **Reporting Module:** Tracks voucher usage statistics
