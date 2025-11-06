# Task 29: Housekeeper Task List - Verification Checklist

## Pre-Verification Setup

### Backend Requirements
- [ ] Backend server is running on port 8080
- [ ] Database is running with all migrations applied
- [ ] Housekeeping endpoints are functional (Task 26)
- [ ] Test data exists (rooms with various statuses)

### Frontend Requirements
- [ ] Frontend is running on port 3000
- [ ] NextAuth is configured
- [ ] Test housekeeper account exists
- [ ] Environment variables are set

### Test Accounts
Create test accounts with these roles:
```sql
-- Housekeeper account
INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Test', 'Housekeeper', 'housekeeper@test.com', '0812345678');

INSERT INTO guest_accounts (guest_id, hashed_password, role)
VALUES (
  (SELECT guest_id FROM guests WHERE email = 'housekeeper@test.com'),
  '$2a$10$...', -- bcrypt hash of 'password123'
  'housekeeper'
);
```

## Functional Testing

### 1. Task List Page Access
- [ ] Navigate to `/housekeeping`
- [ ] Page loads without errors
- [ ] Summary cards display correctly
- [ ] Task list displays rooms

### 2. Summary Dashboard
- [ ] "รอทำความสะอาด" count is correct
- [ ] "กำลังทำความสะอาด" count is correct
- [ ] "สะอาดแล้ว" count is correct
- [ ] "ตรวจสอบแล้ว" count is correct
- [ ] "ต้องซ่อมบำรุง" count is correct
- [ ] Counts update after status changes

### 3. Task List Display
- [ ] Room cards show room number
- [ ] Room cards show room type
- [ ] Status badges display with correct colors
- [ ] Priority badges show for urgent tasks (priority > 5)
- [ ] Occupancy status displays correctly
- [ ] Estimated time displays (if available)

### 4. Filtering
- [ ] "ทั้งหมด" button shows all tasks
- [ ] "รอทำความสะอาด" button filters Dirty rooms
- [ ] "กำลังทำความสะอาด" button filters Cleaning rooms
- [ ] "สะอาดแล้ว" button filters Clean rooms
- [ ] Active filter button is highlighted
- [ ] Filter changes update task list immediately

### 5. Search Functionality
- [ ] Search by room number works (e.g., "101")
- [ ] Search by room type works (e.g., "Deluxe")
- [ ] Search is case-insensitive
- [ ] Search updates results in real-time
- [ ] Clear search shows all tasks again
- [ ] Search works with filters combined

### 6. Status Update Workflow

#### Dirty → Cleaning
- [ ] Find a room with "Dirty" status
- [ ] Click "→ กำลังทำความสะอาด" button
- [ ] Button shows "กำลังอัปเดต..." during update
- [ ] Status updates to "Cleaning"
- [ ] Task list refreshes
- [ ] Summary counts update

#### Cleaning → Clean
- [ ] Find a room with "Cleaning" status
- [ ] Click "→ สะอาดแล้ว" button
- [ ] Button shows "กำลังอัปเดต..." during update
- [ ] Status updates to "Clean"
- [ ] Task list refreshes
- [ ] Summary counts update

#### Invalid Transitions
- [ ] Clean rooms don't show status update button
- [ ] Inspected rooms don't show status update button
- [ ] MaintenanceRequired rooms don't show status update button

### 7. Maintenance Reporting

#### Open Modal
- [ ] Click "รายงานปัญหา" button on any room
- [ ] Modal opens with correct room number
- [ ] Description textarea is empty
- [ ] "บันทึก" button is present
- [ ] "ยกเลิก" button is present

#### Submit Report
- [ ] Enter maintenance description
- [ ] Click "บันทึก" button
- [ ] Modal shows "กำลังบันทึก..." during submission
- [ ] Success alert appears
- [ ] Modal closes
- [ ] Room status changes to "MaintenanceRequired"
- [ ] Task list refreshes

#### Validation
- [ ] Empty description shows alert
- [ ] "บันทึก" button disabled when empty
- [ ] "ยกเลิก" button closes modal without saving

#### Cancel
- [ ] Click "ยกเลิก" button
- [ ] Modal closes without saving
- [ ] Room status unchanged

### 8. Auto-Refresh
- [ ] Wait 30 seconds
- [ ] Task list refreshes automatically
- [ ] No page reload occurs
- [ ] Current filter/search persists
- [ ] Summary counts update if changed

### 9. Inspection Page Access
- [ ] Navigate to `/housekeeping/inspection`
- [ ] Page loads without errors
- [ ] Summary card displays
- [ ] Room list displays Clean rooms only

### 10. Inspection Page Display
- [ ] Summary card shows correct count
- [ ] Only Clean status rooms appear
- [ ] Room cards show room details
- [ ] "✓ อนุมัติ" button is present
- [ ] "✗ ปฏิเสธ" button is present

### 11. Room Approval

#### Open Approval Modal
- [ ] Click "✓ อนุมัติ" button
- [ ] Modal opens with correct room number
- [ ] Title shows "อนุมัติห้อง [number]"
- [ ] Notes textarea is optional
- [ ] "ยืนยันการอนุมัติ" button is present

#### Submit Approval
- [ ] Add optional notes
- [ ] Click "ยืนยันการอนุมัติ" button
- [ ] Modal shows "กำลังบันทึก..." during submission
- [ ] Success alert appears
- [ ] Modal closes
- [ ] Room removed from inspection list
- [ ] Room status changes to "Inspected"

### 12. Room Rejection

#### Open Rejection Modal
- [ ] Click "✗ ปฏิเสธ" button
- [ ] Modal opens with correct room number
- [ ] Title shows "ปฏิเสธห้อง [number]"
- [ ] Notes textarea for reason
- [ ] "ยืนยันการปฏิเสธ" button is present

#### Submit Rejection
- [ ] Enter rejection reason
- [ ] Click "ยืนยันการปฏิเสธ" button
- [ ] Modal shows "กำลังบันทึก..." during submission
- [ ] Success alert appears
- [ ] Modal closes
- [ ] Room removed from inspection list
- [ ] Room status changes back to "Dirty"
- [ ] Housekeeper notified (if implemented)

### 13. Inspection Search
- [ ] Search by room number works
- [ ] Search by room type works
- [ ] Search is case-insensitive
- [ ] Search updates results in real-time
- [ ] Clear search shows all clean rooms

### 14. Empty States

#### No Tasks
- [ ] Filter to status with no rooms
- [ ] Empty state message displays
- [ ] Message is clear and helpful

#### No Clean Rooms
- [ ] Go to inspection page when no clean rooms
- [ ] Empty state displays
- [ ] Icon and message show

#### No Search Results
- [ ] Search for non-existent room
- [ ] "ไม่มีห้องที่ตรงกับเงื่อนไขการค้นหา" displays

### 15. Navigation

#### Staff Layout
- [ ] "งานทำความสะอาด" link visible for housekeeper
- [ ] "ตรวจสอบห้อง" link visible for housekeeper
- [ ] Links navigate correctly
- [ ] Active page is highlighted (if implemented)

#### Between Pages
- [ ] Navigate from task list to inspection
- [ ] Navigate from inspection to task list
- [ ] State persists appropriately
- [ ] No data loss on navigation

## Error Handling

### Network Errors
- [ ] Disconnect network
- [ ] Error message displays
- [ ] Retry mechanism works (if implemented)
- [ ] Graceful degradation

### API Errors
- [ ] Backend returns 400 error
- [ ] Error alert shows with message
- [ ] User can retry action

### Invalid Status Transitions
- [ ] Try invalid transition via API
- [ ] Error message displays
- [ ] Room status unchanged

### Authentication Errors
- [ ] Token expires
- [ ] Redirects to login
- [ ] Returns to page after login

## UI/UX Testing

### Responsive Design

#### Mobile (< 640px)
- [ ] Summary cards stack (2 columns)
- [ ] Task cards stack vertically
- [ ] Buttons are full-width
- [ ] Text is readable
- [ ] Touch targets are adequate (44x44px)

#### Tablet (640px - 1024px)
- [ ] Layout adjusts appropriately
- [ ] Summary cards in grid
- [ ] Task cards use available space
- [ ] Buttons are appropriately sized

#### Desktop (> 1024px)
- [ ] Summary cards in 5-column grid
- [ ] Task cards use horizontal layout
- [ ] Maximum width container (7xl)
- [ ] Proper spacing and alignment

### Color Coding
- [ ] Dirty status: Red background
- [ ] Cleaning status: Yellow background
- [ ] Clean status: Green background
- [ ] Inspected status: Blue background
- [ ] MaintenanceRequired status: Orange background
- [ ] Colors are consistent across pages

### Loading States
- [ ] Initial page load shows spinner
- [ ] Button shows loading text during action
- [ ] Buttons disabled during loading
- [ ] Loading states are clear

### Accessibility
- [ ] Tab navigation works
- [ ] Focus indicators visible
- [ ] Buttons have descriptive labels
- [ ] Status changes announced (if screen reader tested)
- [ ] Color is not the only indicator

## Performance Testing

### Load Time
- [ ] Page loads in < 2 seconds
- [ ] Task list renders quickly
- [ ] No layout shift during load

### Interaction Speed
- [ ] Status updates respond quickly
- [ ] Modals open/close smoothly
- [ ] Search filters instantly
- [ ] No lag in UI interactions

### Memory Usage
- [ ] No memory leaks after extended use
- [ ] Auto-refresh doesn't accumulate memory
- [ ] Modal cleanup works properly

## Integration Testing

### With Backend
- [ ] All API calls succeed
- [ ] Data format matches expectations
- [ ] Error responses handled correctly
- [ ] Authentication works

### With Database
- [ ] Status changes persist
- [ ] Maintenance reports saved
- [ ] Inspection results recorded
- [ ] Timestamps updated

### With Other Pages
- [ ] Dashboard reflects housekeeping changes
- [ ] Receptionist sees updated room status
- [ ] Real-time sync works across roles

## Requirements Verification

### Requirement 10.1-10.7 (Housekeeping Status Management)
- [ ] 10.1: Display task list with status filtering ✓
- [ ] 10.2: Update status (Dirty → Cleaning) ✓
- [ ] 10.3: Update status (Cleaning → Clean) ✓
- [ ] 10.4: Report maintenance issues ✓
- [ ] 10.5: Real-time status reflection ✓
- [ ] 10.6: Timestamp tracking ✓
- [ ] 10.7: Estimated cleaning time display ✓

### Requirement 11.1-11.6 (Room Inspection)
- [ ] 11.1: Display rooms ready for inspection ✓
- [ ] 11.2: Approve rooms (Clean → Inspected) ✓
- [ ] 11.3: Reject rooms (Clean → Dirty) ✓
- [ ] 11.4: Inspected rooms prioritized ✓
- [ ] 11.5: Inspected status visible ✓
- [ ] 11.6: Rejection reason recorded ✓

## Browser Compatibility

### Chrome
- [ ] All features work
- [ ] No console errors
- [ ] Styling correct

### Firefox
- [ ] All features work
- [ ] No console errors
- [ ] Styling correct

### Safari
- [ ] All features work
- [ ] No console errors
- [ ] Styling correct

### Edge
- [ ] All features work
- [ ] No console errors
- [ ] Styling correct

## Security Testing

### Authentication
- [ ] Unauthenticated users redirected
- [ ] Only housekeeper role can access
- [ ] Token validation works
- [ ] Session timeout handled

### Authorization
- [ ] Cannot access other roles' pages
- [ ] Cannot update rooms without permission
- [ ] API calls include auth token

### Input Validation
- [ ] XSS prevention in text inputs
- [ ] SQL injection prevention (backend)
- [ ] Input sanitization works

## Final Checklist

### Code Quality
- [ ] No console errors
- [ ] No TypeScript errors
- [ ] Code follows project conventions
- [ ] Comments where needed

### Documentation
- [ ] TASK_29_SUMMARY.md complete
- [ ] TASK_29_QUICK_REFERENCE.md complete
- [ ] TASK_29_VERIFICATION.md complete
- [ ] Code comments adequate

### Deployment Ready
- [ ] Build succeeds without errors
- [ ] Environment variables documented
- [ ] No hardcoded values
- [ ] Production-ready

## Sign-off

### Developer
- [ ] All features implemented
- [ ] Self-testing complete
- [ ] Documentation complete
- [ ] Code committed

### QA
- [ ] Functional testing complete
- [ ] UI/UX testing complete
- [ ] Performance acceptable
- [ ] No critical bugs

### Product Owner
- [ ] Requirements met
- [ ] User experience acceptable
- [ ] Ready for deployment

## Notes

### Known Issues
- Document any known issues or limitations

### Future Improvements
- Document any planned enhancements

### Testing Environment
- OS: _______________
- Browser: _______________
- Screen Resolution: _______________
- Date Tested: _______________
- Tester: _______________

## Conclusion

Task 29 verification status: ⬜ PENDING / ✅ PASSED / ❌ FAILED

Comments:
_____________________________________________
_____________________________________________
_____________________________________________
