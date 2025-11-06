# Task 35: Inventory Management - Quick Start Guide

## Overview
This guide provides step-by-step instructions for using the inventory management page to control room allotments.

## Prerequisites
- Backend server running on port 8080
- Frontend server running on port 3000
- Logged in as a manager user
- Room types and inventory data seeded in database

## Accessing the Page

1. Navigate to: `http://localhost:3000/manager/inventory`
2. Or click "จัดการสต็อก" in the manager navigation menu

## Basic Operations

### 1. Viewing Inventory

#### Select Room Type
```
1. Click the "ประเภทห้อง" dropdown
2. Select a room type (e.g., "Deluxe Room")
3. The calendar will automatically load inventory data
```

#### Navigate Months
```
1. Use the month picker to select different months
2. Calendar updates automatically
3. Data loads for the entire selected month
```

#### Understanding the Display
Each row shows:
- **วันที่**: Date with day of week
- **จำนวนห้อง**: Total allotment
- **จองแล้ว**: Confirmed bookings
- **กำลังจอง**: Tentative holds
- **ว่าง**: Available rooms (calculated)
- **สถานะ**: Occupancy percentage with color
- **จัดการ**: Edit button

### 2. Understanding the Heatmap

The heatmap uses 5 colors to show booking pressure:

| Color | Occupancy Rate | Meaning |
|-------|---------------|---------|
| 🟢 Light Green | < 30% | Very available |
| 🟢 Green | 30-50% | Good availability |
| 🟡 Yellow | 50-70% | Moderate |
| 🟠 Orange | 70-90% | High demand |
| 🔴 Red | ≥ 90% | Nearly full |

### 3. Single Date Editing

#### Edit One Date
```
1. Find the date you want to edit
2. Click "แก้ไข" button in that row
3. Modal opens with current allotment
4. Enter new allotment value
5. Click "บันทึก"
```

#### Example: Increase Allotment
```
Current: 10 rooms
Booked: 5 rooms
Tentative: 2 rooms
Available: 3 rooms

Action: Change allotment to 15
Result: Available becomes 8 rooms
```

#### Example: Validation Error
```
Current: 10 rooms
Booked: 5 rooms
Tentative: 2 rooms

Action: Try to change allotment to 6
Result: ❌ Error - "ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน (7 ห้อง)"
```

### 4. Bulk Editing

#### Edit Multiple Dates
```
1. Select a room type first
2. Click "แก้ไขแบบกลุ่ม" button
3. Modal opens with date range fields
4. Set start date (e.g., 2025-02-01)
5. Set end date (e.g., 2025-02-28)
6. Enter allotment value (e.g., 20)
7. Click "บันทึก"
```

#### Use Cases

**Weekend Increase**
```
Start Date: 2025-02-07 (Friday)
End Date: 2025-02-09 (Sunday)
Allotment: 25
→ Increases weekend capacity
```

**Holiday Season**
```
Start Date: 2025-12-20
End Date: 2025-12-31
Allotment: 30
→ Prepares for high season
```

**Low Season Reduction**
```
Start Date: 2025-06-01
End Date: 2025-06-30
Allotment: 15
→ Reduces capacity during low season
```

### 5. Handling Validation Errors

#### Single Error
```
If one date fails validation:
1. Error message appears in red box
2. Shows specific date and reason
3. Fix the issue and try again
```

#### Multiple Errors (Bulk Update)
```
If multiple dates fail:
1. All errors listed in red box
2. Each shows date and reason
3. Only valid dates are updated
4. Review errors and adjust
```

#### Common Validation Errors

**Error 1: Below Current Bookings**
```
Message: "ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน (X ห้อง)"
Solution: Increase allotment to at least X rooms
```

**Error 2: Invalid Number**
```
Message: "จำนวนห้องต้องเป็นตัวเลขที่มากกว่าหรือเท่ากับ 0"
Solution: Enter a valid positive number
```

**Error 3: Invalid Date Range**
```
Message: "วันที่สิ้นสุดต้องมากกว่าหรือเท่ากับวันที่เริ่มต้น"
Solution: Ensure end date is after start date
```

## Common Workflows

### Workflow 1: Prepare for High Season

```
Goal: Increase capacity for December holidays

Steps:
1. Select room type: "Deluxe Room"
2. Navigate to December 2025
3. Click "แก้ไขแบบกลุ่ม"
4. Start Date: 2025-12-20
5. End Date: 2025-12-31
6. Allotment: 30
7. Click "บันทึก"
8. Verify green success message
9. Check calendar shows updated values
```

### Workflow 2: Adjust Single Overbooked Date

```
Goal: Fix a date that's showing red (90%+ occupancy)

Steps:
1. Select room type
2. Find the red date in calendar
3. Click "แก้ไข" for that date
4. Increase allotment (e.g., from 10 to 15)
5. Click "บันทึก"
6. Verify color changes from red to orange/yellow
```

### Workflow 3: Review and Adjust Inventory

```
Goal: Monthly inventory review

Steps:
1. Select first room type
2. Review current month calendar
3. Look for red/orange dates (high occupancy)
4. Decide if capacity increase needed
5. Use bulk edit for date ranges
6. Or single edit for specific dates
7. Repeat for each room type
8. Navigate to next month
9. Repeat process
```

## Tips and Best Practices

### Planning Ahead
- Review inventory at least 90 days in advance
- Adjust for known events and holidays
- Monitor booking trends weekly

### Using the Heatmap
- Red dates need immediate attention
- Orange dates should be monitored
- Green dates have good availability

### Bulk Updates
- Use for seasonal adjustments
- Apply to weekends vs weekdays
- Adjust for special events

### Validation
- Always check current bookings before reducing
- System prevents overbooking automatically
- Review error messages carefully

### Performance
- Calendar loads one month at a time
- Bulk updates process in single transaction
- Changes reflect immediately after save

## Troubleshooting

### Issue: Calendar Not Loading
```
Symptoms: Spinner keeps spinning
Solution: 
1. Check backend is running
2. Check browser console for errors
3. Verify room type is selected
4. Refresh the page
```

### Issue: Can't Reduce Allotment
```
Symptoms: Validation error when trying to reduce
Solution:
1. Check "จองแล้ว" + "กำลังจอง" columns
2. Allotment must be >= sum of these
3. Wait for bookings to complete or cancel
```

### Issue: Bulk Update Partially Fails
```
Symptoms: Some dates updated, some show errors
Solution:
1. Review error list
2. Note which dates failed
3. Adjust those dates individually
4. Or increase allotment value
```

### Issue: Changes Not Saving
```
Symptoms: Click save but nothing happens
Solution:
1. Check for validation errors
2. Ensure all fields filled
3. Check network tab for API errors
4. Try again or refresh page
```

## Keyboard Shortcuts

- **Tab**: Navigate between fields
- **Enter**: Submit form (in modals)
- **Escape**: Close modal (planned feature)

## Next Steps

After mastering inventory management:
1. Learn about pricing management (Task 34)
2. Explore reports and analytics (Task 36)
3. Understand how inventory affects room search

## Related Documentation

- [Task 35 Index](./TASK_35_INDEX.md)
- [Task 35 Verification](./TASK_35_VERIFICATION.md)
- [Task 35 Summary](./TASK_35_SUMMARY.md)
- [Backend Inventory API](../backend/INVENTORY_MODULE_REFERENCE.md)
