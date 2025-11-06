# Task 21 Testing Guide - Booking History Page

## Quick Start Testing

### Prerequisites
1. Backend server running on `http://localhost:8080`
2. Frontend server running on `http://localhost:3000`
3. Database with sample bookings
4. Authenticated guest user

### Test URL
```
http://localhost:3000/bookings
```

## Test Scenarios

### Scenario 1: View Booking History (Basic)
**Objective**: Verify bookings are displayed correctly

**Steps**:
1. Login as a guest user
2. Navigate to `/bookings`
3. Observe the booking list

**Expected Results**:
- ✅ All bookings are displayed
- ✅ Bookings sorted by newest first
- ✅ Each card shows: ID, status, room type, dates, guests, total
- ✅ Status badges have correct colors
- ✅ No console errors

**Test Data Needed**:
- At least 3 bookings with different statuses

---

### Scenario 2: Status Filtering
**Objective**: Verify filtering works correctly

**Steps**:
1. On `/bookings` page
2. Click "All" filter → Note bookings shown
3. Click "Upcoming" filter → Note bookings shown
4. Click "Completed" filter → Note bookings shown
5. Click "Cancelled" filter → Note bookings shown

**Expected Results**:
- ✅ "All" shows all bookings
- ✅ "Upcoming" shows only Confirmed + CheckedIn
- ✅ "Completed" shows only Completed bookings
- ✅ "Cancelled" shows only Cancelled bookings
- ✅ Active filter button is highlighted
- ✅ Empty state shown when no bookings match filter

**Test Data Needed**:
- Bookings with all different statuses

---

### Scenario 3: Expand Booking Details
**Objective**: Verify expanded view shows all information

**Steps**:
1. On `/bookings` page
2. Find a booking card
3. Click "Show More" button
4. Observe expanded content
5. Click "Show Less" button

**Expected Results**:
- ✅ Expanded section appears smoothly
- ✅ Room details displayed (duration, description)
- ✅ Guest information shown with names
- ✅ Primary guest indicated
- ✅ Cancellation policy displayed
- ✅ Nightly breakdown shown (if available)
- ✅ Refund calculation shown (if cancellable)
- ✅ "Show Less" collapses the section

**Test Data Needed**:
- Booking with complete information including guests and nightly logs

---

### Scenario 4: Cancel Confirmed Booking
**Objective**: Verify cancellation flow for confirmed booking

**Steps**:
1. On `/bookings` page
2. Find a booking with status "Confirmed"
3. Click "Show More" to expand
4. Verify "Cancel Booking" button is visible
5. Click "Cancel Booking"
6. Observe confirmation dialog
7. Note the refund amount displayed
8. Click "Keep Booking"
9. Verify dialog closes
10. Click "Cancel Booking" again
11. Click "Yes, Cancel"
12. Wait for processing

**Expected Results**:
- ✅ Cancel button visible for Confirmed booking
- ✅ Dialog appears with warning message
- ✅ Refund amount calculated and displayed
- ✅ "Keep Booking" closes dialog without action
- ✅ "Yes, Cancel" triggers API call
- ✅ Loading state shown during processing
- ✅ Success message appears
- ✅ Booking status updates to "Cancelled"
- ✅ Booking list refreshes automatically
- ✅ Cancel button no longer visible

**Test Data Needed**:
- Confirmed booking with check-in date in future
- Valid cancellation policy

---

### Scenario 5: Cancel Pending Payment Booking
**Objective**: Verify cancellation for pending payment

**Steps**:
1. On `/bookings` page
2. Find a booking with status "PendingPayment"
3. Click "Cancel Booking"
4. Confirm cancellation

**Expected Results**:
- ✅ Cancel button visible
- ✅ Cancellation succeeds
- ✅ Status updates to "Cancelled"
- ✅ Tentative inventory returned (backend)

**Test Data Needed**:
- PendingPayment booking

---

### Scenario 6: Cannot Cancel CheckedIn Booking
**Objective**: Verify cancel button hidden for checked-in bookings

**Steps**:
1. On `/bookings` page
2. Find a booking with status "CheckedIn"
3. Click "Show More"
4. Look for "Cancel Booking" button

**Expected Results**:
- ✅ "Cancel Booking" button NOT visible
- ✅ Only "Show More/Less" and "View Full Details" buttons shown

**Test Data Needed**:
- CheckedIn booking

---

### Scenario 7: Cannot Cancel Completed Booking
**Objective**: Verify cancel button hidden for completed bookings

**Steps**:
1. On `/bookings` page
2. Find a booking with status "Completed"
3. Click "Show More"
4. Look for "Cancel Booking" button

**Expected Results**:
- ✅ "Cancel Booking" button NOT visible
- ✅ Booking displayed in gray color

**Test Data Needed**:
- Completed booking

---

### Scenario 8: View Full Details
**Objective**: Verify navigation to confirmation page

**Steps**:
1. On `/bookings` page
2. Find any booking
3. Click "View Full Details" button
4. Observe navigation

**Expected Results**:
- ✅ Navigates to `/booking/confirmation/[id]`
- ✅ Full booking details displayed
- ✅ Guest information section shown
- ✅ Nightly breakdown displayed
- ✅ Cancellation policy shown

**Test Data Needed**:
- Any booking with complete data

---

### Scenario 9: Refund Calculation Accuracy
**Objective**: Verify refund calculation is correct

**Test Cases**:

#### Case A: 100% Refund (7+ days before)
- Policy: "Cancel 7 days before check-in for 100% refund"
- Check-in: 10 days from today
- Total: ฿5,000
- Expected Refund: ฿5,000 (100%)

#### Case B: 50% Refund (3-7 days before)
- Policy: "Cancel 3 days before check-in for 50% refund"
- Check-in: 5 days from today
- Total: ฿5,000
- Expected Refund: ฿2,500 (50%)

#### Case C: No Refund (< 3 days)
- Policy: "Non-refundable - 0% refund"
- Check-in: 1 day from today
- Total: ฿5,000
- Expected Refund: ฿0 (0%)

**Steps**:
1. Create bookings with different policies
2. Expand booking details
3. Check "Estimated Refund" section
4. Verify calculation matches expected

**Expected Results**:
- ✅ Days until check-in calculated correctly
- ✅ Refund percentage parsed from policy
- ✅ Refund amount calculated correctly
- ✅ Display shows both percentage and amount

---

### Scenario 10: Empty State
**Objective**: Verify empty state when no bookings

**Steps**:
1. Login as new guest with no bookings
2. Navigate to `/bookings`

**Expected Results**:
- ✅ Empty state card displayed
- ✅ Friendly message shown
- ✅ "Search for Rooms" button visible
- ✅ Button navigates to `/rooms/search`

---

### Scenario 11: Error Handling
**Objective**: Verify error states are handled gracefully

**Test Cases**:

#### Case A: Network Error
1. Stop backend server
2. Navigate to `/bookings`
3. Observe error state

**Expected**:
- ✅ Error message displayed
- ✅ "Try Again" button shown
- ✅ No crash or blank page

#### Case B: Cancellation Error
1. Mock API to return error
2. Try to cancel booking
3. Observe error handling

**Expected**:
- ✅ Error message shown in alert
- ✅ Dialog remains open
- ✅ User can retry or close

---

### Scenario 12: Responsive Design
**Objective**: Verify layout works on all screen sizes

**Steps**:
1. Open `/bookings` on desktop (1920x1080)
2. Resize to tablet (768x1024)
3. Resize to mobile (375x667)

**Expected Results**:

**Desktop**:
- ✅ Four-column grid for booking info
- ✅ Horizontal button layout
- ✅ Max-width container centered

**Tablet**:
- ✅ Two-column grid
- ✅ Side-by-side buttons
- ✅ Readable text sizes

**Mobile**:
- ✅ Single column layout
- ✅ Stacked buttons
- ✅ Full-width cards
- ✅ Touch-friendly button sizes

---

### Scenario 13: Dark Mode
**Objective**: Verify dark mode styling

**Steps**:
1. Navigate to `/bookings`
2. Toggle dark mode
3. Observe all elements

**Expected Results**:
- ✅ Background colors inverted
- ✅ Text remains readable
- ✅ Status badges have dark variants
- ✅ Cards have proper contrast
- ✅ Buttons styled correctly
- ✅ No white flashes

---

### Scenario 14: Multiple Bookings Performance
**Objective**: Verify performance with many bookings

**Steps**:
1. Create 50+ bookings in database
2. Navigate to `/bookings`
3. Observe loading and rendering

**Expected Results**:
- ✅ Page loads within 2 seconds
- ✅ Smooth scrolling
- ✅ No lag when expanding cards
- ✅ Filters respond instantly
- ✅ No memory leaks

---

### Scenario 15: Concurrent Cancellation
**Objective**: Verify handling of concurrent cancellations

**Steps**:
1. Open `/bookings` in two browser tabs
2. In tab 1, start cancelling a booking
3. In tab 2, try to cancel the same booking
4. Complete cancellation in tab 1
5. Try to complete in tab 2

**Expected Results**:
- ✅ Tab 1 cancellation succeeds
- ✅ Tab 2 shows error (already cancelled)
- ✅ Both tabs refresh to show updated status
- ✅ No data corruption

---

## Automated Testing

### Unit Tests
```bash
# Run unit tests
npm test -- bookings.test.tsx

# Tests to include:
- Status filtering logic
- Refund calculation
- Cancel button visibility
- Date formatting
```

### Integration Tests
```bash
# Run integration tests
npm test -- bookings.integration.test.tsx

# Tests to include:
- API integration
- State management
- Error handling
- Cache invalidation
```

### E2E Tests
```bash
# Run E2E tests with Playwright
npx playwright test bookings.spec.ts

# Tests to include:
- Full booking history flow
- Cancel booking flow
- Filter and search
- Navigation
```

## Performance Benchmarks

### Target Metrics
- **Initial Load**: < 2 seconds
- **Filter Change**: < 100ms
- **Expand Card**: < 50ms
- **Cancel Booking**: < 3 seconds
- **Memory Usage**: < 50MB

### Monitoring
```javascript
// Add to component for performance monitoring
useEffect(() => {
  const start = performance.now();
  // Component logic
  const end = performance.now();
  console.log(`Render time: ${end - start}ms`);
}, []);
```

## Accessibility Testing

### Checklist
- [ ] Keyboard navigation works
- [ ] Screen reader announces all content
- [ ] Focus indicators visible
- [ ] Color contrast meets WCAG AA
- [ ] Alt text for all images
- [ ] ARIA labels where needed
- [ ] Semantic HTML structure

### Tools
```bash
# Run accessibility audit
npm run lighthouse -- --only-categories=accessibility

# Use axe DevTools in browser
# Check with NVDA/JAWS screen reader
```

## Browser Compatibility

### Test Browsers
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

## Security Testing

### Checklist
- [ ] Authentication required
- [ ] User can only see own bookings
- [ ] CSRF protection enabled
- [ ] XSS prevention in place
- [ ] SQL injection prevented
- [ ] Rate limiting on cancel API

## Bug Report Template

```markdown
### Bug Description
[Clear description of the issue]

### Steps to Reproduce
1. [First step]
2. [Second step]
3. [...]

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happens]

### Environment
- Browser: [e.g., Chrome 120]
- OS: [e.g., Windows 11]
- Screen Size: [e.g., 1920x1080]
- User Role: [e.g., Guest]

### Screenshots
[Attach screenshots if applicable]

### Console Errors
[Paste any console errors]

### Additional Context
[Any other relevant information]
```

## Test Data Setup

### SQL Script to Create Test Bookings
```sql
-- Create test guest
INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Test', 'User', 'test@example.com', '0812345678');

-- Create confirmed booking (cancellable)
INSERT INTO bookings (guest_id, total_amount, status, policy_name, policy_description)
VALUES (1, 5000, 'Confirmed', 'Standard', 'Cancel 7 days before check-in for 100% refund');

-- Create checked-in booking (not cancellable)
INSERT INTO bookings (guest_id, total_amount, status, policy_name, policy_description)
VALUES (1, 3000, 'CheckedIn', 'Standard', 'Cancel 7 days before check-in for 100% refund');

-- Create completed booking
INSERT INTO bookings (guest_id, total_amount, status, policy_name, policy_description)
VALUES (1, 4000, 'Completed', 'Standard', 'Cancel 7 days before check-in for 100% refund');

-- Create cancelled booking
INSERT INTO bookings (guest_id, total_amount, status, policy_name, policy_description)
VALUES (1, 2000, 'Cancelled', 'Standard', 'Cancel 7 days before check-in for 100% refund');
```

## Conclusion

This testing guide covers all aspects of the Booking History page functionality. Follow the scenarios in order for comprehensive testing. Report any issues using the bug report template.

**Happy Testing! 🧪**
