# Task 34: Pricing Management - Testing Guide

## Overview
This guide provides instructions for testing the Pricing Management features for hotel managers.

## Features Implemented

### 1. Manager Layout
- **File**: `frontend/src/app/(manager)/layout.tsx`
- **Features**:
  - Authentication check (manager role only)
  - Navigation menu with links to all manager features
  - Responsive design

### 2. Rate Tiers Management
- **File**: `frontend/src/app/(manager)/pricing/tiers/page.tsx`
- **Features**:
  - View all rate tiers
  - Create new rate tier
  - Edit existing rate tier
  - Real-time updates using React Query
  - Inline editing with validation

### 3. Pricing Calendar
- **File**: `frontend/src/app/(manager)/pricing/calendar/page.tsx`
- **Features**:
  - Calendar view showing full month
  - Color-coded tiers for easy visualization
  - Single date or date range selection
  - Apply tier to selected dates
  - Month/year navigation
  - Copy from previous year (placeholder for backend implementation)

### 4. Rate Pricing Matrix
- **File**: `frontend/src/app/(manager)/pricing/matrix/page.tsx`
- **Features**:
  - Table view with room types as rows and rate tiers as columns
  - Rate plan selector
  - Edit mode for updating prices
  - Bulk update feature (increase/decrease by percentage)
  - Highlights empty prices in red
  - Real-time validation

### 5. Manager Dashboard
- **File**: `frontend/src/app/(manager)/page.tsx`
- **Features**:
  - Overview of all manager features
  - Quick navigation cards
  - Getting started guide

## Testing Instructions

### Prerequisites
1. Backend server must be running on `http://localhost:8080`
2. Database must have:
   - At least one manager user account
   - Room types configured
   - Rate plans configured

### Test Scenarios

#### 1. Authentication & Authorization
```
1. Try to access /manager/pricing/tiers without logging in
   Expected: Redirect to /auth/signin

2. Log in as a guest user and try to access /manager/pricing/tiers
   Expected: Redirect to /unauthorized

3. Log in as a manager user
   Expected: Access granted to all manager pages
```

#### 2. Rate Tiers Management
```
Test Case 1: Create Rate Tier
1. Navigate to /manager/pricing/tiers
2. Click "+ เพิ่มระดับราคา"
3. Enter "Low Season" and click "บันทึก"
   Expected: New tier appears in the list

Test Case 2: Edit Rate Tier
1. Click "แก้ไข" on an existing tier
2. Change the name to "Peak Season"
3. Click "บันทึก"
   Expected: Tier name updates

Test Case 3: Validation
1. Try to create a tier with empty name
   Expected: Button disabled

Test Case 4: Create Multiple Tiers
1. Create the following tiers:
   - Low Season
   - High Season
   - Peak Season
   - Holiday
   Expected: All tiers appear with different colors
```

#### 3. Pricing Calendar
```
Test Case 1: View Calendar
1. Navigate to /manager/pricing/calendar
2. Observe current month display
   Expected: Calendar shows all days with assigned tiers (if any)

Test Case 2: Single Date Selection
1. Select "เลือกวันเดียว" mode
2. Click on a date
3. Select a tier from the list
4. Click "ใช้ระดับราคา"
   Expected: Date updates with selected tier color

Test Case 3: Date Range Selection
1. Select "เลือกช่วงวันที่" mode
2. Click on start date (e.g., 1st of month)
3. Click on end date (e.g., 15th of month)
4. Select "High Season" tier
5. Click "ใช้ระดับราคา"
   Expected: All dates in range update to High Season

Test Case 4: Month Navigation
1. Click "→" to go to next month
2. Click "←" to go to previous month
   Expected: Calendar updates correctly

Test Case 5: Visual Feedback
1. Assign different tiers to different dates
   Expected: Each tier shows with distinct color
```

#### 4. Rate Pricing Matrix
```
Test Case 1: View Matrix
1. Navigate to /manager/pricing/matrix
2. Observe the pricing table
   Expected: Table shows room types × rate tiers grid

Test Case 2: Rate Plan Selection
1. Select different rate plans from dropdown
   Expected: Prices update for selected plan

Test Case 3: Edit Single Price
1. Click "แก้ไขราคา"
2. Change a price value (e.g., 1000 to 1500)
3. Click "บันทึก"
   Expected: Price updates successfully

Test Case 4: Empty Price Warning
1. Leave some prices at 0
   Expected: Red background on empty cells
   Expected: Warning message at top

Test Case 5: Bulk Update - Increase
1. Click "แก้ไขราคา"
2. Click "Bulk Update"
3. Select "เพิ่ม" and enter "10" (%)
4. Click "ใช้กับทุกราคา"
   Expected: All prices increase by 10%

Test Case 6: Bulk Update - Decrease
1. Click "Bulk Update"
2. Select "ลด" and enter "5" (%)
3. Click "ใช้กับทุกราคา"
   Expected: All prices decrease by 5%

Test Case 7: Cancel Edit
1. Click "แก้ไขราคา"
2. Make some changes
3. Click "ยกเลิก"
   Expected: Changes are reverted
```

#### 5. Integration Testing
```
Test Case 1: Complete Pricing Setup Flow
1. Create rate tiers: Low, High, Peak
2. Go to calendar and assign:
   - Jan-Mar: Low Season
   - Apr-Jun: High Season
   - Jul-Sep: Peak Season
   - Oct-Dec: Low Season
3. Go to matrix and set prices for all combinations
4. Verify all prices are saved

Test Case 2: Guest Booking with Pricing
1. As manager, set up pricing
2. Log out and log in as guest
3. Search for rooms in different date ranges
4. Verify prices match the configured rates
```

## API Endpoints Used

### Rate Tiers
- `GET /api/pricing/tiers` - Get all tiers
- `POST /api/pricing/tiers` - Create tier
- `PUT /api/pricing/tiers/:id` - Update tier

### Pricing Calendar
- `GET /api/pricing/calendar?start_date=X&end_date=Y` - Get calendar
- `PUT /api/pricing/calendar` - Update calendar

### Rate Pricing
- `GET /api/pricing/plans` - Get all rate plans
- `GET /api/pricing/rates/plan/:planId` - Get pricing for plan
- `PUT /api/pricing/rates` - Update pricing

### Room Types
- `GET /api/rooms/types` - Get all room types

## Expected Response Formats

### Rate Tier Response
```json
{
  "success": true,
  "data": [
    {
      "rate_tier_id": 1,
      "name": "Low Season"
    }
  ]
}
```

### Pricing Calendar Response
```json
{
  "success": true,
  "data": [
    {
      "date": "2024-01-01",
      "rate_tier_id": 1,
      "rate_tier": {
        "rate_tier_id": 1,
        "name": "Low Season"
      }
    }
  ]
}
```

### Rate Pricing Response
```json
{
  "success": true,
  "data": [
    {
      "rate_plan_id": 1,
      "room_type_id": 1,
      "rate_tier_id": 1,
      "price": 1000
    }
  ]
}
```

## Known Issues & Limitations

1. **Copy from Previous Year**: Backend endpoint not yet implemented
2. **Rate Plan Management**: Currently uses existing rate plans, no CRUD operations
3. **Validation**: Some edge cases may need additional validation
4. **Mobile Responsiveness**: Calendar view may need optimization for mobile devices

## Performance Considerations

1. **React Query Caching**: Data is cached for 5 minutes to reduce API calls
2. **Optimistic Updates**: UI updates immediately, then syncs with backend
3. **Bulk Operations**: Large date ranges may take time to process

## Troubleshooting

### Issue: "ยังไม่มีระดับราคา" message
**Solution**: Create rate tiers first at /manager/pricing/tiers

### Issue: Prices not saving
**Solution**: 
1. Check browser console for errors
2. Verify backend is running
3. Check authentication token is valid

### Issue: Calendar not showing colors
**Solution**: 
1. Ensure rate tiers are created
2. Assign tiers to dates in calendar
3. Refresh the page

### Issue: Matrix shows all zeros
**Solution**: 
1. Select a rate plan from dropdown
2. Enter prices in edit mode
3. Save changes

## Success Criteria

✅ Manager can create and edit rate tiers
✅ Manager can assign tiers to calendar dates
✅ Manager can set prices in matrix
✅ All changes persist to database
✅ UI provides clear feedback
✅ Validation prevents invalid data
✅ Bulk operations work correctly
✅ Navigation between pages works smoothly

## Next Steps

After testing this task, proceed to:
- Task 35: Inventory Management UI
- Task 36: Manager Dashboard & Reports
- Task 37-38: Background Jobs

## Requirements Covered

This implementation covers:
- **Requirement 14.1-14.7**: Rate Tier & Pricing Calendar management
- **Requirement 15.1-15.7**: Rate Plan & Pricing Configuration

All EARS requirements from the requirements document are addressed through the UI workflows.
