# Task 31: Inventory Management Module - Quick Start Guide

## Overview

This guide will help you quickly test the Inventory Management Module.

## Prerequisites

1. Backend server running on `http://localhost:8080`
2. Database with seed data
3. Manager account credentials

## Quick Test (PowerShell)

```powershell
# Run the automated test script
cd backend
.\test_inventory_module.ps1
```

## Manual Testing

### Step 1: Login as Manager

```powershell
$loginResponse = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/auth/login" `
  -ContentType "application/json" `
  -Body '{"email":"manager@hotel.com","password":"manager123"}'

$token = $loginResponse.data.access_token
```

### Step 2: Get Inventory for Next 30 Days

```powershell
$startDate = (Get-Date).ToString("yyyy-MM-dd")
$endDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

$inventory = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/inventory?start_date=$startDate&end_date=$endDate" `
  -Headers @{Authorization="Bearer $token"}

$inventory.data | Format-Table
```

### Step 3: Get Inventory for Specific Room Type

```powershell
$roomInventory = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/inventory?room_type_id=1&start_date=$startDate&end_date=$endDate" `
  -Headers @{Authorization="Bearer $token"}

$roomInventory.data | Format-Table
```

### Step 4: Update Single Date

```powershell
$updateDate = (Get-Date).AddDays(10).ToString("yyyy-MM-dd")

$updateBody = @{
    room_type_id = 1
    date = $updateDate
    allotment = 15
} | ConvertTo-Json

$result = Invoke-RestMethod -Method PUT `
  -Uri "http://localhost:8080/api/inventory" `
  -Headers @{Authorization="Bearer $token"} `
  -ContentType "application/json" `
  -Body $updateBody

Write-Host $result.message
```

### Step 5: Bulk Update Date Range

```powershell
$bulkStartDate = (Get-Date).AddDays(20).ToString("yyyy-MM-dd")
$bulkEndDate = (Get-Date).AddDays(25).ToString("yyyy-MM-dd")

$bulkBody = @{
    room_type_id = 1
    start_date = $bulkStartDate
    end_date = $bulkEndDate
    allotment = 20
} | ConvertTo-Json

$bulkResult = Invoke-RestMethod -Method POST `
  -Uri "http://localhost:8080/api/inventory/bulk" `
  -Headers @{Authorization="Bearer $token"} `
  -ContentType "application/json" `
  -Body $bulkBody

Write-Host $bulkResult.message
```

### Step 6: Get Specific Date Inventory

```powershell
$specificDate = (Get-Date).AddDays(5).ToString("yyyy-MM-dd")

$dateInventory = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/inventory/1/$specificDate" `
  -Headers @{Authorization="Bearer $token"}

$dateInventory.data | Format-List
```

## Using cURL (Bash/Linux)

### Login

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"manager123"}' \
  | jq -r '.data.access_token')
```

### Get All Inventory

```bash
START_DATE=$(date +%Y-%m-%d)
END_DATE=$(date -d "+30 days" +%Y-%m-%d)

curl -X GET "http://localhost:8080/api/inventory?start_date=$START_DATE&end_date=$END_DATE" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Update Single Date

```bash
UPDATE_DATE=$(date -d "+10 days" +%Y-%m-%d)

curl -X PUT http://localhost:8080/api/inventory \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"room_type_id\": 1,
    \"date\": \"$UPDATE_DATE\",
    \"allotment\": 15
  }" | jq
```

### Bulk Update

```bash
BULK_START=$(date -d "+20 days" +%Y-%m-%d)
BULK_END=$(date -d "+25 days" +%Y-%m-%d)

curl -X POST http://localhost:8080/api/inventory/bulk \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"room_type_id\": 1,
    \"start_date\": \"$BULK_START\",
    \"end_date\": \"$BULK_END\",
    \"allotment\": 20
  }" | jq
```

## Expected Results

### Successful Update

```json
{
  "success": true,
  "message": "Inventory updated successfully"
}
```

### Validation Error

```json
{
  "success": false,
  "error": "Failed to update inventory",
  "details": "cannot reduce allotment to 5, current bookings: 8 (booked: 6, tentative: 2)"
}
```

### Bulk Validation Errors

```json
{
  "success": false,
  "error": "Cannot update inventory for some dates due to existing bookings",
  "validation_errors": [
    {
      "date": "2024-01-15",
      "message": "Cannot reduce allotment to 10. Current bookings: 12 (booked: 8, tentative: 4)"
    }
  ]
}
```

## Common Issues

### 1. Unauthorized Error

**Problem:** `{"success": false, "error": "Insufficient permissions"}`

**Solution:** Make sure you're logged in as a manager:
```powershell
# Check your role
$profile = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/auth/me" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Role: $($profile.data.role)"
```

### 2. Invalid Date Format

**Problem:** `"invalid start date format"`

**Solution:** Use YYYY-MM-DD format:
```powershell
$correctDate = (Get-Date).ToString("yyyy-MM-dd")  # Correct
$wrongDate = (Get-Date).ToString("MM/dd/yyyy")    # Wrong
```

### 3. Room Type Not Found

**Problem:** `"invalid room type ID"`

**Solution:** Check available room types:
```powershell
$roomTypes = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/rooms/types"

$roomTypes.data | Select-Object room_type_id, name
```

### 4. Cannot Reduce Allotment

**Problem:** `"cannot reduce allotment below current bookings"`

**Solution:** Check current bookings first:
```powershell
$date = "2024-01-15"
$current = Invoke-RestMethod -Method GET `
  -Uri "http://localhost:8080/api/inventory/1/$date" `
  -Headers @{Authorization="Bearer $token"}

Write-Host "Current bookings: $($current.data.booked_count + $current.data.tentative_count)"
Write-Host "Minimum allotment: $($current.data.booked_count + $current.data.tentative_count)"
```

## Verification Steps

After running tests, verify:

1. **Data Persistence**
   ```powershell
   # Update a date
   # Then retrieve it again to verify
   $verify = Invoke-RestMethod -Method GET `
     -Uri "http://localhost:8080/api/inventory/1/$updateDate" `
     -Headers @{Authorization="Bearer $token"}
   
   Write-Host "Allotment: $($verify.data.allotment)"
   ```

2. **Validation Working**
   ```powershell
   # Try to set allotment to 0 (should fail if bookings exist)
   try {
       $invalid = Invoke-RestMethod -Method PUT `
         -Uri "http://localhost:8080/api/inventory" `
         -Headers @{Authorization="Bearer $token"} `
         -ContentType "application/json" `
         -Body '{"room_type_id":1,"date":"2024-01-15","allotment":0}'
   } catch {
       Write-Host "✓ Validation working: $($_.Exception.Message)"
   }
   ```

3. **Bulk Update Working**
   ```powershell
   # Bulk update then verify all dates
   $verifyBulk = Invoke-RestMethod -Method GET `
     -Uri "http://localhost:8080/api/inventory?room_type_id=1&start_date=$bulkStartDate&end_date=$bulkEndDate" `
     -Headers @{Authorization="Bearer $token"}
   
   $allCorrect = $verifyBulk.data | Where-Object { $_.allotment -eq 20 }
   Write-Host "Updated dates: $($allCorrect.Count) / $($verifyBulk.data.Count)"
   ```

## Next Steps

1. Test with different room types
2. Test with various date ranges
3. Test validation with actual bookings
4. Integrate with frontend
5. Test concurrent updates

## Additional Resources

- Full API Documentation: `INVENTORY_MODULE_REFERENCE.md`
- Task Summary: `TASK_31_SUMMARY.md`
- Test Script: `test_inventory_module.ps1`
