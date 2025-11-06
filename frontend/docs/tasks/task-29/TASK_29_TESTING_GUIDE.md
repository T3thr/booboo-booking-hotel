# Task 29: Housekeeper Task List - Testing Guide

## Quick Start Testing

### 1. Setup Test Environment

```bash
# Terminal 1: Start Backend
cd backend
make run

# Terminal 2: Start Frontend
cd frontend
npm run dev
```

### 2. Create Test Data

```sql
-- Connect to PostgreSQL
psql -U postgres -d hotel_booking

-- Create test housekeeper account
INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Test', 'Housekeeper', 'housekeeper@test.com', '0812345678')
ON CONFLICT (email) DO NOTHING;

INSERT INTO guest_accounts (guest_id, hashed_password)
VALUES (
  (SELECT guest_id FROM guests WHERE email = 'housekeeper@test.com'),
  '$2a$10$YourHashedPasswordHere'
)
ON CONFLICT (guest_id) DO NOTHING;

-- Set some rooms to different statuses for testing
UPDATE rooms SET housekeeping_status = 'Dirty' WHERE room_id IN (1, 2, 3);
UPDATE rooms SET housekeeping_status = 'Cleaning' WHERE room_id IN (4, 5);
UPDATE rooms SET housekeeping_status = 'Clean' WHERE room_id IN (6, 7);
UPDATE rooms SET housekeeping_status = 'Inspected' WHERE room_id IN (8, 9);
UPDATE rooms SET housekeeping_status = 'MaintenanceRequired' WHERE room_id = 10;
```

### 3. Login as Housekeeper

1. Navigate to http://localhost:3000/auth/signin
2. Login with: housekeeper@test.com / password123
3. Should redirect to housekeeping page

## Test Scenarios

### Scenario 1: View Task List

**Objective:** Verify task list displays correctly

**Steps:**
1. Navigate to `/housekeeping`
2. Observe the page layout

**Expected Results:**
- ✅ Summary cards show counts for each status
- ✅ Task list displays rooms
- ✅ Each task card shows:
  - Room number
  - Room type
  - Status badge
  - Occupancy status
  - Action buttons

**Pass Criteria:**
- All elements visible
- Data loads correctly
- No console errors

---

### Scenario 2: Filter Tasks by Status

**Objective:** Verify filtering works correctly

**Steps:**
1. Click "รอทำความสะอาด" filter button
2. Observe filtered results
3. Click "กำลังทำความสะอาด" filter button
4. Observe filtered results
5. Click "ทั้งหมด" to reset

**Expected Results:**
- ✅ Only rooms with selected status show
- ✅ Active filter button is highlighted
- ✅ Summary counts remain accurate
- ✅ "ทั้งหมด" shows all tasks

**Pass Criteria:**
- Filtering works for all statuses
- UI updates immediately
- No data loss

---

### Scenario 3: Search for Rooms

**Objective:** Verify search functionality

**Steps:**
1. Enter "101" in search box
2. Observe results
3. Clear search
4. Enter room type (e.g., "Deluxe")
5. Observe results

**Expected Results:**
- ✅ Search filters by room number
- ✅ Search filters by room type
- ✅ Search is case-insensitive
- ✅ Results update in real-time
- ✅ Clear search shows all tasks

**Pass Criteria:**
- Search works for both fields
- Instant filtering
- No lag

---

### Scenario 4: Update Room Status (Dirty → Cleaning)

**Objective:** Verify status update workflow

**Steps:**
1. Find a room with "Dirty" status
2. Note the room number
3. Click "→ กำลังทำความสะอาด" button
4. Wait for update

**Expected Results:**
- ✅ Button shows "กำลังอัปเดต..." during update
- ✅ Button is disabled during update
- ✅ Status changes to "Cleaning"
- ✅ Status badge color changes to yellow
- ✅ Summary counts update
- ✅ Task list refreshes

**Pass Criteria:**
- Status updates successfully
- UI reflects change immediately
- No errors

---

### Scenario 5: Update Room Status (Cleaning → Clean)

**Objective:** Verify completion workflow

**Steps:**
1. Find a room with "Cleaning" status
2. Note the room number
3. Click "→ สะอาดแล้ว" button
4. Wait for update

**Expected Results:**
- ✅ Button shows "กำลังอัปเดต..." during update
- ✅ Status changes to "Clean"
- ✅ Status badge color changes to green
- ✅ Room appears in inspection queue
- ✅ Summary counts update

**Pass Criteria:**
- Status updates successfully
- Room ready for inspection
- No errors

---

### Scenario 6: Report Maintenance Issue

**Objective:** Verify maintenance reporting

**Steps:**
1. Find any room (except MaintenanceRequired)
2. Click "รายงานปัญหา" button
3. Modal opens
4. Enter description: "Air conditioning not working"
5. Click "บันทึก"

**Expected Results:**
- ✅ Modal opens with correct room number
- ✅ Description field is empty initially
- ✅ Can enter text in description
- ✅ "บันทึก" button submits form
- ✅ Modal shows "กำลังบันทึก..." during submission
- ✅ Success alert appears
- ✅ Modal closes
- ✅ Room status changes to "MaintenanceRequired"
- ✅ Status badge color changes to orange

**Pass Criteria:**
- Maintenance report submitted
- Status updated correctly
- Modal closes properly

---

### Scenario 7: Cancel Maintenance Report

**Objective:** Verify cancel functionality

**Steps:**
1. Click "รายงานปัญหา" on any room
2. Enter some text
3. Click "ยกเลิก" button

**Expected Results:**
- ✅ Modal closes
- ✅ No changes saved
- ✅ Room status unchanged

**Pass Criteria:**
- Cancel works correctly
- No side effects

---

### Scenario 8: Validation - Empty Maintenance Description

**Objective:** Verify validation works

**Steps:**
1. Click "รายงานปัญหา" on any room
2. Leave description empty
3. Try to click "บันทึก"

**Expected Results:**
- ✅ Alert shows "กรุณากรอกรายละเอียดปัญหา"
- ✅ Modal remains open
- ✅ No submission occurs

**Pass Criteria:**
- Validation prevents empty submission
- User feedback is clear

---

### Scenario 9: View Inspection Queue

**Objective:** Verify inspection page

**Steps:**
1. Navigate to `/housekeeping/inspection`
2. Observe the page

**Expected Results:**
- ✅ Summary card shows count of clean rooms
- ✅ Only rooms with "Clean" status appear
- ✅ Each room has "✓ อนุมัติ" and "✗ ปฏิเสธ" buttons
- ✅ Room details display correctly

**Pass Criteria:**
- Page loads correctly
- Only clean rooms shown
- UI is clear

---

### Scenario 10: Approve Room

**Objective:** Verify room approval

**Steps:**
1. On inspection page, find a clean room
2. Click "✓ อนุมัติ" button
3. Modal opens
4. Add optional notes: "Room is perfect"
5. Click "ยืนยันการอนุมัติ"

**Expected Results:**
- ✅ Modal opens with correct room number
- ✅ Title shows "อนุมัติห้อง [number]"
- ✅ Notes field is optional
- ✅ Button shows "กำลังบันทึก..." during submission
- ✅ Success alert appears
- ✅ Modal closes
- ✅ Room removed from inspection list
- ✅ Room status changes to "Inspected"

**Pass Criteria:**
- Approval works correctly
- Room status updated
- UI updates properly

---

### Scenario 11: Reject Room

**Objective:** Verify room rejection

**Steps:**
1. On inspection page, find a clean room
2. Click "✗ ปฏิเสธ" button
3. Modal opens
4. Enter reason: "Bathroom needs more cleaning"
5. Click "ยืนยันการปฏิเสธ"

**Expected Results:**
- ✅ Modal opens with correct room number
- ✅ Title shows "ปฏิเสธห้อง [number]"
- ✅ Reason field available
- ✅ Button shows "กำลังบันทึก..." during submission
- ✅ Success alert appears
- ✅ Modal closes
- ✅ Room removed from inspection list
- ✅ Room status changes back to "Dirty"
- ✅ Room appears in task list again

**Pass Criteria:**
- Rejection works correctly
- Room sent back for cleaning
- Reason recorded

---

### Scenario 12: Auto-Refresh

**Objective:** Verify auto-refresh works

**Steps:**
1. Open task list page
2. In another browser tab, update a room status via API or backend
3. Wait 30 seconds
4. Observe task list

**Expected Results:**
- ✅ Task list refreshes automatically
- ✅ No page reload occurs
- ✅ Updated data appears
- ✅ Current filter/search persists

**Pass Criteria:**
- Auto-refresh works
- No disruption to user
- Data stays current

---

### Scenario 13: Concurrent Updates

**Objective:** Test race conditions

**Steps:**
1. Open task list in two browser windows
2. In window 1, start updating a room status
3. In window 2, try to update the same room
4. Observe results

**Expected Results:**
- ✅ Both updates process correctly
- ✅ Final state is consistent
- ✅ No data corruption
- ✅ Both windows refresh

**Pass Criteria:**
- No race conditions
- Data integrity maintained

---

### Scenario 14: Mobile Responsive

**Objective:** Verify mobile layout

**Steps:**
1. Open browser dev tools
2. Switch to mobile view (375px width)
3. Navigate through pages
4. Test all interactions

**Expected Results:**
- ✅ Layout adapts to mobile
- ✅ Summary cards stack (2 columns)
- ✅ Task cards stack vertically
- ✅ Buttons are full-width
- ✅ Text is readable
- ✅ Touch targets are adequate
- ✅ Modals fit screen

**Pass Criteria:**
- Fully functional on mobile
- Good UX on small screens

---

### Scenario 15: Error Handling

**Objective:** Verify error handling

**Steps:**
1. Stop backend server
2. Try to update room status
3. Observe error handling
4. Restart backend
5. Try again

**Expected Results:**
- ✅ Error message displays
- ✅ User informed of issue
- ✅ No app crash
- ✅ Can retry after backend restart

**Pass Criteria:**
- Graceful error handling
- Clear user feedback
- App remains stable

---

## Performance Testing

### Load Time Test

**Steps:**
1. Clear browser cache
2. Navigate to `/housekeeping`
3. Measure load time

**Expected:**
- Page loads in < 2 seconds
- No layout shift

---

### Large Dataset Test

**Steps:**
1. Create 100+ rooms in database
2. Load task list
3. Test filtering and search

**Expected:**
- Page remains responsive
- No lag in interactions
- Smooth scrolling

---

### Memory Leak Test

**Steps:**
1. Open task list
2. Let auto-refresh run for 10 minutes
3. Check browser memory usage

**Expected:**
- Memory usage stable
- No continuous growth
- No performance degradation

---

## Integration Testing

### Backend Integration

**Test API Calls:**
```bash
# Get tasks
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/api/housekeeping/tasks

# Update status
curl -X PUT \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"Cleaning"}' \
  http://localhost:8080/api/housekeeping/rooms/1/status

# Inspect room
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"approved":true,"notes":"Good"}' \
  http://localhost:8080/api/housekeeping/rooms/1/inspect

# Report maintenance
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"AC broken"}' \
  http://localhost:8080/api/housekeeping/rooms/1/maintenance
```

---

## Regression Testing

### After Code Changes

**Checklist:**
- [ ] All scenarios still pass
- [ ] No new console errors
- [ ] Performance unchanged
- [ ] UI still responsive
- [ ] No broken features

---

## Automated Testing (Future)

### Unit Tests
```typescript
// Example test structure
describe('HousekeepingPage', () => {
  it('should display task list', () => {});
  it('should filter by status', () => {});
  it('should update room status', () => {});
  it('should report maintenance', () => {});
});
```

### E2E Tests
```typescript
// Example Playwright test
test('complete housekeeping workflow', async ({ page }) => {
  await page.goto('/housekeeping');
  await page.click('text=→ กำลังทำความสะอาด');
  await expect(page.locator('.status-badge')).toContainText('กำลังทำความสะอาด');
});
```

---

## Bug Report Template

```markdown
### Bug Description
[Clear description of the issue]

### Steps to Reproduce
1. 
2. 
3. 

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happens]

### Environment
- Browser: 
- OS: 
- Screen Size: 

### Screenshots
[If applicable]

### Console Errors
[Any errors from browser console]

### Severity
[ ] Critical
[ ] High
[ ] Medium
[ ] Low
```

---

## Test Results Template

```markdown
## Test Session: [Date]

### Environment
- Backend: Running / Not Running
- Frontend: Running / Not Running
- Database: Connected / Not Connected

### Test Results
- Scenario 1: ✅ Pass / ❌ Fail
- Scenario 2: ✅ Pass / ❌ Fail
- Scenario 3: ✅ Pass / ❌ Fail
[... continue for all scenarios]

### Issues Found
1. [Issue description]
2. [Issue description]

### Notes
[Any additional observations]

### Tester
[Name]
```

---

## Conclusion

This testing guide covers:
- ✅ 15 detailed test scenarios
- ✅ Performance testing
- ✅ Integration testing
- ✅ Regression testing
- ✅ Error handling
- ✅ Mobile responsiveness

Follow these scenarios to ensure Task 29 is fully functional and ready for production.
