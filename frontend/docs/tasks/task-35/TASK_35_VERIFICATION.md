# Task 35: Inventory Management - Verification Checklist

## Overview
This document provides a comprehensive testing checklist for the inventory management page.

## Pre-Testing Setup

### 1. Environment Check
- [ ] Backend server running on port 8080
- [ ] Frontend server running on port 3000
- [ ] PostgreSQL database running
- [ ] Test data seeded (room types, inventory)

### 2. User Authentication
- [ ] Manager user account exists
- [ ] Can log in successfully
- [ ] Session persists across page navigation

### 3. Test Data Verification
```sql
-- Verify room types exist
SELECT * FROM room_types;

-- Verify inventory data exists
SELECT * FROM room_inventory 
WHERE date >= CURRENT_DATE 
LIMIT 10;

-- Check for bookings
SELECT * FROM bookings 
WHERE status IN ('Confirmed', 'CheckedIn');
```

## Feature Testing

### 1. Page Access and Layout

#### Test 1.1: Navigation
- [ ] Navigate to `/manager/inventory`
- [ ] Page loads without errors
- [ ] Manager navigation bar visible
- [ ] "จัดการสต็อก" link highlighted

#### Test 1.2: Initial State
- [ ] Page title displays correctly
- [ ] Room type dropdown shows all types
- [ ] Month picker shows current month
- [ ] "แก้ไขแบบกลุ่ม" button visible but disabled
- [ ] Legend shows all 5 color levels
- [ ] Message prompts to select room type

#### Test 1.3: Responsive Design
- [ ] Layout works on desktop (1920x1080)
- [ ] Layout works on tablet (768x1024)
- [ ] Layout works on mobile (375x667)
- [ ] Table scrolls horizontally on small screens

### 2. Calendar View

#### Test 2.1: Room Type Selection
- [ ] Select first room type from dropdown
- [ ] Calendar loads and displays data
- [ ] Loading spinner shows during fetch
- [ ] All days of month displayed
- [ ] "แก้ไขแบบกลุ่ม" button becomes enabled

#### Test 2.2: Data Display
- [ ] Each row shows correct date
- [ ] Thai date format displays correctly
- [ ] Allotment values display
- [ ] Booked count displays
- [ ] Tentative count displays
- [ ] Available count calculated correctly
- [ ] Occupancy percentage displays
- [ ] Edit button visible for each row

#### Test 2.3: Month Navigation
- [ ] Change to next month
- [ ] Calendar updates with new dates
- [ ] Data loads for new month
- [ ] Change to previous month
- [ ] Data loads correctly
- [ ] Navigate to future month (3 months ahead)
- [ ] Navigate to past month

#### Test 2.4: Room Type Switching
- [ ] Switch to different room type
- [ ] Calendar updates with new data
- [ ] Previous data cleared
- [ ] New data displays correctly
- [ ] Switch back to first room type
- [ ] Data reloads correctly

### 3. Heatmap Visualization

#### Test 3.1: Color Coding
- [ ] Find date with < 30% occupancy
- [ ] Verify light green background
- [ ] Find date with 30-50% occupancy
- [ ] Verify green background
- [ ] Find date with 50-70% occupancy
- [ ] Verify yellow background
- [ ] Find date with 70-90% occupancy
- [ ] Verify orange background
- [ ] Find date with ≥ 90% occupancy
- [ ] Verify red background with white text

#### Test 3.2: Legend Accuracy
- [ ] Legend colors match table colors
- [ ] Legend descriptions accurate
- [ ] All 5 levels represented

#### Test 3.3: Visual Clarity
- [ ] Colors are distinguishable
- [ ] Text readable on all backgrounds
- [ ] Percentage values clear
- [ ] No color accessibility issues

### 4. Single Date Editing

#### Test 4.1: Open Edit Modal
- [ ] Click "แก้ไข" on any date
- [ ] Modal opens
- [ ] Modal shows correct date
- [ ] Current allotment pre-filled
- [ ] Input field focused
- [ ] Cancel and Save buttons visible

#### Test 4.2: Valid Update
- [ ] Enter new allotment value (increase)
- [ ] Click "บันทึก"
- [ ] Loading state shows
- [ ] Modal closes on success
- [ ] Calendar updates with new value
- [ ] Available count recalculated
- [ ] Heatmap color updates if needed

#### Test 4.3: Cancel Operation
- [ ] Open edit modal
- [ ] Change value
- [ ] Click "ยกเลิก"
- [ ] Modal closes
- [ ] No changes saved
- [ ] Original value remains

#### Test 4.4: Validation - Below Bookings
```
Setup: Find date with bookings
Booked: 5, Tentative: 2 (Total: 7)

Test:
- [ ] Try to set allotment to 6
- [ ] Error message displays
- [ ] Message shows minimum required (7)
- [ ] Modal stays open
- [ ] Can correct and retry
```

#### Test 4.5: Validation - Invalid Input
- [ ] Enter negative number
- [ ] Error message displays
- [ ] Enter non-numeric value
- [ ] Error message displays
- [ ] Enter decimal number
- [ ] Handles appropriately

#### Test 4.6: Edge Cases
- [ ] Edit date with no bookings
- [ ] Set allotment to 0
- [ ] Verify saves successfully
- [ ] Edit date with 100% occupancy
- [ ] Try to reduce allotment
- [ ] Verify validation prevents

### 5. Bulk Editing

#### Test 5.1: Open Bulk Edit Modal
- [ ] Ensure room type selected
- [ ] Click "แก้ไขแบบกลุ่ม"
- [ ] Modal opens
- [ ] Start date field visible
- [ ] End date field visible
- [ ] Allotment field visible
- [ ] Start date pre-filled with month start
- [ ] End date pre-filled with month end

#### Test 5.2: Valid Bulk Update
```
Test Case: Update 7 days
- [ ] Set start date: 2025-02-01
- [ ] Set end date: 2025-02-07
- [ ] Set allotment: 20
- [ ] Click "บันทึก"
- [ ] Loading state shows
- [ ] Modal closes on success
- [ ] All 7 dates updated in calendar
- [ ] Heatmap colors update
```

#### Test 5.3: Date Range Validation
- [ ] Set end date before start date
- [ ] Click "บันทึก"
- [ ] Error alert displays
- [ ] Modal stays open
- [ ] Correct dates and retry
- [ ] Saves successfully

#### Test 5.4: Partial Validation Failure
```
Setup: Date range with some dates having bookings

Test:
- [ ] Set range: 2025-02-01 to 2025-02-10
- [ ] Set allotment below some dates' bookings
- [ ] Click "บันทึก"
- [ ] Validation errors display
- [ ] Error box shows all failed dates
- [ ] Each error shows date and reason
- [ ] Valid dates are NOT updated
- [ ] Can review and adjust
```

#### Test 5.5: Large Date Range
```
Test Case: Update entire month
- [ ] Set start: First day of month
- [ ] Set end: Last day of month
- [ ] Set allotment: 25
- [ ] Click "บันทึก"
- [ ] Processing completes
- [ ] All dates updated
- [ ] Performance acceptable (< 3 seconds)
```

#### Test 5.6: Cancel Bulk Edit
- [ ] Open bulk edit modal
- [ ] Fill in all fields
- [ ] Click "ยกเลิก"
- [ ] Modal closes
- [ ] No changes saved
- [ ] Calendar unchanged

### 6. Validation Error Display

#### Test 6.1: Single Error Display
- [ ] Trigger single validation error
- [ ] Red error box appears
- [ ] Error shows date
- [ ] Error shows clear message
- [ ] Error persists until corrected
- [ ] Error clears after successful save

#### Test 6.2: Multiple Errors Display
- [ ] Trigger multiple validation errors
- [ ] All errors listed in box
- [ ] Each error on separate line
- [ ] Dates clearly identified
- [ ] Messages clear and actionable
- [ ] Can scroll if many errors

#### Test 6.3: Error Clearing
- [ ] Display validation errors
- [ ] Close modal
- [ ] Reopen modal
- [ ] Errors cleared
- [ ] Fresh start for new attempt

### 7. Data Consistency

#### Test 7.1: Real-time Updates
- [ ] Open page in two browser tabs
- [ ] Update inventory in tab 1
- [ ] Refresh tab 2
- [ ] Changes reflected in tab 2

#### Test 7.2: Calculation Accuracy
```
For each date:
- [ ] Available = Allotment - Booked - Tentative
- [ ] Percentage = (Booked + Tentative) / Allotment * 100
- [ ] Verify calculations correct
```

#### Test 7.3: Database Verification
```sql
-- After making updates, verify in database
SELECT room_type_id, date, allotment, booked_count, tentative_count
FROM room_inventory
WHERE date = '2025-02-01'
AND room_type_id = 1;

-- Verify values match UI
```

### 8. Performance Testing

#### Test 8.1: Load Time
- [ ] Measure initial page load
- [ ] Should be < 2 seconds
- [ ] Measure calendar data load
- [ ] Should be < 1 second

#### Test 8.2: Update Performance
- [ ] Single update completes < 500ms
- [ ] Bulk update (30 days) < 2 seconds
- [ ] Bulk update (90 days) < 5 seconds
- [ ] UI remains responsive

#### Test 8.3: Large Dataset
- [ ] Test with 365 days of data
- [ ] Navigation smooth
- [ ] No lag when switching months
- [ ] Memory usage acceptable

### 9. Error Handling

#### Test 9.1: Network Errors
- [ ] Stop backend server
- [ ] Try to load calendar
- [ ] Error message displays
- [ ] Try to update inventory
- [ ] Error message displays
- [ ] Restart backend
- [ ] Retry operation
- [ ] Works correctly

#### Test 9.2: Invalid Data
- [ ] Send invalid room_type_id
- [ ] Handles gracefully
- [ ] Send invalid date format
- [ ] Handles gracefully

#### Test 9.3: Session Expiry
- [ ] Let session expire
- [ ] Try to update inventory
- [ ] Redirects to login
- [ ] After login, returns to page

### 10. Accessibility

#### Test 10.1: Keyboard Navigation
- [ ] Tab through all controls
- [ ] Focus visible on all elements
- [ ] Can open modal with keyboard
- [ ] Can close modal with keyboard
- [ ] Can submit form with Enter

#### Test 10.2: Screen Reader
- [ ] Labels properly associated
- [ ] Error messages announced
- [ ] Status updates announced
- [ ] Table structure semantic

#### Test 10.3: Color Contrast
- [ ] All text meets WCAG AA standards
- [ ] Heatmap colors distinguishable
- [ ] Focus indicators visible

## Integration Testing

### Test 11: Booking Impact

#### Test 11.1: After Booking Created
```
Steps:
1. [ ] Note current inventory for a date
2. [ ] Create a booking for that date
3. [ ] Return to inventory page
4. [ ] Verify booked_count increased
5. [ ] Verify available decreased
6. [ ] Verify heatmap color updated
```

#### Test 11.2: After Booking Cancelled
```
Steps:
1. [ ] Note current inventory
2. [ ] Cancel a booking
3. [ ] Return to inventory page
4. [ ] Verify booked_count decreased
5. [ ] Verify available increased
6. [ ] Verify heatmap color updated
```

### Test 12: Cross-Module Integration

#### Test 12.1: With Room Search
```
Steps:
1. [ ] Set low allotment for a date
2. [ ] Go to room search
3. [ ] Search for that date
4. [ ] Verify limited availability shown
5. [ ] Return to inventory
6. [ ] Increase allotment
7. [ ] Search again
8. [ ] Verify increased availability
```

#### Test 12.2: With Pricing
```
Steps:
1. [ ] View inventory for date range
2. [ ] Go to pricing calendar
3. [ ] Note tier assignments
4. [ ] Return to inventory
5. [ ] Verify data consistency
```

## Browser Compatibility

### Test 13: Cross-Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

## Security Testing

### Test 14: Authorization
- [ ] Log out
- [ ] Try to access `/manager/inventory`
- [ ] Redirects to login
- [ ] Log in as guest
- [ ] Try to access page
- [ ] Redirects to unauthorized
- [ ] Log in as receptionist
- [ ] Try to access page
- [ ] Redirects to unauthorized
- [ ] Log in as manager
- [ ] Can access page

### Test 15: Data Validation
- [ ] Try to inject SQL in inputs
- [ ] Properly sanitized
- [ ] Try XSS in inputs
- [ ] Properly escaped
- [ ] Try invalid API calls
- [ ] Properly rejected

## Final Verification

### Checklist Summary
- [ ] All page access tests passed
- [ ] All calendar view tests passed
- [ ] All heatmap tests passed
- [ ] All single edit tests passed
- [ ] All bulk edit tests passed
- [ ] All validation tests passed
- [ ] All data consistency tests passed
- [ ] All performance tests passed
- [ ] All error handling tests passed
- [ ] All accessibility tests passed
- [ ] All integration tests passed
- [ ] All browser tests passed
- [ ] All security tests passed

### Requirements Verification

#### Requirement 13.1: Manager Access
- [ ] ✅ Manager can access inventory management

#### Requirement 13.2: Display Inventory
- [ ] ✅ Shows RoomInventory for selected date range
- [ ] ✅ Can view up to 365 days ahead

#### Requirement 13.3: Validation
- [ ] ✅ Validates Allotment >= (BookedCount + TentativeCount)

#### Requirement 13.4: Error Messages
- [ ] ✅ Rejects invalid updates
- [ ] ✅ Shows clear error messages

#### Requirement 13.5: Update Operations
- [ ] ✅ INSERT or UPDATE RoomInventory
- [ ] ✅ Single and bulk updates work

#### Requirement 13.6: Data Display
- [ ] ✅ Shows Allotment
- [ ] ✅ Shows BookedCount
- [ ] ✅ Shows TentativeCount
- [ ] ✅ Shows Available (calculated)

#### Requirement 13.7: Heatmap Calendar
- [ ] ✅ Calendar view implemented
- [ ] ✅ Heatmap with color coding
- [ ] ✅ Visual indication of booking levels

## Sign-off

### Testing Completed By
- Name: ________________
- Date: ________________
- Role: ________________

### Issues Found
| # | Description | Severity | Status |
|---|-------------|----------|--------|
| 1 |             |          |        |
| 2 |             |          |        |

### Approval
- [ ] All critical tests passed
- [ ] All requirements met
- [ ] Ready for production

**Approved By:** ________________  
**Date:** ________________
