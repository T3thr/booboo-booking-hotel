# Task 35: Inventory Management - Testing Guide

## Overview
This guide provides step-by-step instructions for testing the inventory management page.

## Prerequisites

### 1. Environment Setup
```bash
# Backend running
cd backend
go run cmd/server/main.go

# Frontend running
cd frontend
npm run dev
```

### 2. Test User
```
Role: Manager
Email: manager@test.com
Password: [your test password]
```

### 3. Test Data
Ensure database has:
- At least 2 room types
- Inventory data for current and next month
- Some bookings to test validation

## Test Scenarios

### Scenario 1: Basic Navigation

**Objective:** Verify page loads and navigation works

**Steps:**
1. Log in as manager
2. Navigate to `/manager/inventory`
3. Verify page loads without errors
4. Check navigation bar shows "จัดการสต็อก" highlighted
5. Verify all UI elements visible

**Expected Results:**
- ✅ Page loads in < 2 seconds
- ✅ No console errors
- ✅ All controls visible
- ✅ Legend displayed
- ✅ Prompt to select room type shown

### Scenario 2: View Inventory

**Objective:** Test calendar view functionality

**Steps:**
1. Select "Deluxe Room" from dropdown
2. Observe calendar loading
3. Verify data displays
4. Check all columns populated
5. Verify heatmap colors

**Expected Results:**
- ✅ Loading spinner shows briefly
- ✅ Calendar displays all days of month
- ✅ All metrics shown (allotment, booked, tentative, available)
- ✅ Occupancy percentages calculated correctly
- ✅ Colors match occupancy levels

**Test Data:**
```
Date: 2025-02-01
Allotment: 20
Booked: 5
Tentative: 2
Expected Available: 13
Expected Percentage: 35%
Expected Color: Green (bg-green-200)
```

### Scenario 3: Month Navigation

**Objective:** Test month switching

**Steps:**
1. With room type selected
2. Change month to next month
3. Verify calendar updates
4. Change to previous month
5. Verify data loads

**Expected Results:**
- ✅ Calendar updates immediately
- ✅ Correct dates shown
- ✅ Data loads for new month
- ✅ No errors in console

### Scenario 4: Single Date Edit - Success

**Objective:** Test successful single date update

**Steps:**
1. Find date with low occupancy
2. Click "แก้ไข" button
3. Modal opens
4. Note current allotment (e.g., 20)
5. Change to 25
6. Click "บันทึก"
7. Wait for save

**Expected Results:**
- ✅ Modal opens with current value
- ✅ Can edit value
- ✅ Save button works
- ✅ Modal closes on success
- ✅ Calendar updates with new value (25)
- ✅ Available count increases by 5
- ✅ Heatmap color may change

**Verification:**
```sql
SELECT * FROM room_inventory 
WHERE room_type_id = 1 
AND date = '2025-02-01';
-- Verify allotment = 25
```

### Scenario 5: Single Date Edit - Validation Error

**Objective:** Test validation prevents invalid updates

**Setup:**
Find a date with bookings:
- Allotment: 20
- Booked: 8
- Tentative: 3
- Total: 11 (minimum required)

**Steps:**
1. Click "แก้ไข" on that date
2. Try to change allotment to 10
3. Click "บันทึก"
4. Observe error

**Expected Results:**
- ✅ Error message displays
- ✅ Message shows: "ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน (11 ห้อง)"
- ✅ Modal stays open
- ✅ Can correct value
- ✅ Change to 15 and save successfully

### Scenario 6: Bulk Edit - Success

**Objective:** Test bulk update functionality

**Steps:**
1. Select room type
2. Click "แก้ไขแบบกลุ่ม"
3. Set start date: 2025-02-10
4. Set end date: 2025-02-15
5. Set allotment: 30
6. Click "บันทึก"
7. Wait for completion

**Expected Results:**
- ✅ Modal opens
- ✅ Date fields work
- ✅ Save processes
- ✅ Modal closes
- ✅ All 6 dates updated to 30
- ✅ Calendar reflects changes
- ✅ Heatmap colors update

**Verification:**
```sql
SELECT date, allotment 
FROM room_inventory 
WHERE room_type_id = 1 
AND date BETWEEN '2025-02-10' AND '2025-02-15'
ORDER BY date;
-- All should show allotment = 30
```

### Scenario 7: Bulk Edit - Partial Validation Failure

**Objective:** Test bulk validation with some failures

**Setup:**
Date range where some dates have high bookings:
- 2025-02-20: Booked 5, Tentative 2 (Total: 7)
- 2025-02-21: Booked 12, Tentative 3 (Total: 15)
- 2025-02-22: Booked 3, Tentative 1 (Total: 4)

**Steps:**
1. Click "แก้ไขแบบกลุ่ม"
2. Set range: 2025-02-20 to 2025-02-22
3. Set allotment: 10
4. Click "บันทึก"
5. Observe errors

**Expected Results:**
- ✅ Validation error box appears
- ✅ Shows error for 2025-02-21: "ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน (15 ห้อง)"
- ✅ Other dates (20, 22) NOT updated
- ✅ Modal stays open
- ✅ Can adjust and retry

**Retry:**
1. Change allotment to 20
2. Click "บันทึก"
3. All dates update successfully

### Scenario 8: Heatmap Accuracy

**Objective:** Verify heatmap colors are correct

**Test Cases:**

**Case 1: < 30% Occupancy**
```
Allotment: 20
Booked: 3
Tentative: 2
Occupancy: 25%
Expected Color: bg-green-100 (light green)
```

**Case 2: 30-50% Occupancy**
```
Allotment: 20
Booked: 6
Tentative: 2
Occupancy: 40%
Expected Color: bg-green-200 (green)
```

**Case 3: 50-70% Occupancy**
```
Allotment: 20
Booked: 10
Tentative: 2
Occupancy: 60%
Expected Color: bg-yellow-300 (yellow)
```

**Case 4: 70-90% Occupancy**
```
Allotment: 20
Booked: 14
Tentative: 2
Occupancy: 80%
Expected Color: bg-orange-400 (orange) with white text
```

**Case 5: >= 90% Occupancy**
```
Allotment: 20
Booked: 18
Tentative: 1
Occupancy: 95%
Expected Color: bg-red-500 (red) with white text
```

**Steps:**
1. For each case, find or create matching data
2. Verify color matches expected
3. Verify percentage displays correctly
4. Verify text is readable

### Scenario 9: Responsive Design

**Objective:** Test on different screen sizes

**Desktop (1920x1080):**
- ✅ Full layout visible
- ✅ No horizontal scroll
- ✅ All columns fit
- ✅ Controls in single row

**Tablet (768x1024):**
- ✅ Layout adjusts
- ✅ Table may scroll horizontally
- ✅ Controls may wrap
- ✅ Touch targets adequate

**Mobile (375x667):**
- ✅ Controls stack vertically
- ✅ Table scrolls horizontally
- ✅ Modals fit screen
- ✅ Text readable
- ✅ Buttons touch-friendly

### Scenario 10: Error Handling

**Test 10.1: Network Error**

**Steps:**
1. Stop backend server
2. Try to load calendar
3. Observe error
4. Try to update inventory
5. Observe error

**Expected Results:**
- ✅ Error message displays
- ✅ User-friendly message
- ✅ No crash
- ✅ Can retry after backend restart

**Test 10.2: Session Expiry**

**Steps:**
1. Let session expire (or clear token)
2. Try to update inventory
3. Observe redirect

**Expected Results:**
- ✅ Redirects to login
- ✅ After login, returns to inventory page
- ✅ Can continue working

### Scenario 11: Keyboard Navigation

**Objective:** Test keyboard accessibility

**Steps:**
1. Use Tab key to navigate
2. Verify focus visible on all elements
3. Open modal with keyboard
4. Navigate modal fields
5. Submit with Enter key

**Expected Results:**
- ✅ Tab order logical
- ✅ Focus indicators visible
- ✅ Can reach all controls
- ✅ Enter submits forms
- ✅ Escape closes modals (if implemented)

### Scenario 12: Cross-Browser Testing

**Browsers to Test:**
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

**For Each Browser:**
1. Load page
2. Select room type
3. View calendar
4. Edit single date
5. Perform bulk edit
6. Verify all features work

**Expected Results:**
- ✅ Consistent appearance
- ✅ All features functional
- ✅ No browser-specific bugs

### Scenario 13: Performance Testing

**Test 13.1: Load Time**

**Steps:**
1. Clear cache
2. Navigate to page
3. Measure load time
4. Select room type
5. Measure data load time

**Expected Results:**
- ✅ Initial load < 2 seconds
- ✅ Data load < 1 second
- ✅ No lag or freeze

**Test 13.2: Large Dataset**

**Steps:**
1. Create inventory for 365 days
2. Navigate through months
3. Perform bulk update for 90 days
4. Measure performance

**Expected Results:**
- ✅ Month navigation smooth
- ✅ Bulk update (90 days) < 5 seconds
- ✅ No memory leaks
- ✅ UI remains responsive

### Scenario 14: Integration Testing

**Test 14.1: After Booking Created**

**Steps:**
1. Note inventory for 2025-03-01
2. Create a booking for that date
3. Return to inventory page
4. Refresh if needed
5. Check inventory

**Expected Results:**
- ✅ Booked count increased by 1
- ✅ Available decreased by 1
- ✅ Heatmap color updated if needed

**Test 14.2: After Booking Cancelled**

**Steps:**
1. Note inventory for a date
2. Cancel a booking for that date
3. Return to inventory page
4. Check inventory

**Expected Results:**
- ✅ Booked count decreased by 1
- ✅ Available increased by 1
- ✅ Heatmap color updated

## Regression Testing

After any code changes, run these quick checks:

### Quick Smoke Test (5 minutes)
1. ✅ Page loads
2. ✅ Select room type
3. ✅ Calendar displays
4. ✅ Edit single date
5. ✅ Bulk edit works
6. ✅ Validation works

### Full Regression (30 minutes)
Run all scenarios 1-14

## Bug Reporting Template

```markdown
**Bug Title:** [Brief description]

**Severity:** Critical / High / Medium / Low

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**


**Actual Result:**


**Environment:**
- Browser: 
- OS: 
- Screen Size: 

**Screenshots:**
[Attach if applicable]

**Console Errors:**
[Copy any errors]
```

## Test Data Setup

### SQL Script for Test Data
```sql
-- Create test room types if not exist
INSERT INTO room_types (name, description, max_occupancy, default_allotment)
VALUES 
  ('Deluxe Room', 'Spacious room with city view', 2, 20),
  ('Suite', 'Luxury suite with separate living area', 4, 10)
ON CONFLICT DO NOTHING;

-- Create inventory for next 90 days
INSERT INTO room_inventory (room_type_id, date, allotment, booked_count, tentative_count)
SELECT 
  rt.room_type_id,
  CURRENT_DATE + (n || ' days')::interval,
  rt.default_allotment,
  floor(random() * 10)::int, -- Random bookings
  floor(random() * 3)::int   -- Random tentative
FROM room_types rt
CROSS JOIN generate_series(0, 89) n
ON CONFLICT (room_type_id, date) DO NOTHING;
```

## Success Criteria

All scenarios must pass:
- ✅ All 14 scenarios completed
- ✅ No critical bugs found
- ✅ Performance targets met
- ✅ Accessibility verified
- ✅ Cross-browser compatible

## Sign-off

**Tester:** ________________  
**Date:** ________________  
**Status:** Pass / Fail  
**Notes:** ________________

---

**Testing Complete:** ✅  
**Ready for Production:** ✅
