# Task 36 Testing Script

## Quick Test Commands

### 1. Start the Application
```bash
# Terminal 1: Start Backend
cd backend
make run

# Terminal 2: Start Frontend
cd frontend
npm run dev
```

### 2. Access URLs
- Dashboard: http://localhost:3000/manager
- Reports: http://localhost:3000/manager/reports

## Manual Testing Checklist

### ✅ Test 1: Dashboard Summary
```
1. Navigate to http://localhost:3000/manager
2. Verify 4 summary cards display
3. Check metrics show numbers (not loading)
4. Verify feature cards grid displays
5. Click "รายงานและการวิเคราะห์" card
```

**Expected:** Dashboard loads with 30-day summary, all cards visible

### ✅ Test 2: Reports Page Load
```
1. Navigate to http://localhost:3000/manager/reports
2. Verify page loads without errors
3. Check filter controls are visible
4. Verify default date range is set
5. Check summary cards display
```

**Expected:** Reports page loads with default occupancy report

### ✅ Test 3: Date Range Selection
```
1. Click start date picker
2. Select date 60 days ago
3. Click end date picker
4. Select date 30 days ago
5. Verify data updates
```

**Expected:** Report refreshes with new date range

### ✅ Test 4: Report Type Switching
```
1. Select "การเข้าพัก" (Occupancy)
2. Verify occupancy table displays
3. Select "รายได้" (Revenue)
4. Verify revenue table displays
5. Select "คูปอง" (Vouchers)
6. Verify voucher table displays
```

**Expected:** Each report type shows appropriate columns and data

### ✅ Test 5: View Mode Switching
```
1. Select "รายวัน" (Daily)
2. Count rows (should be ~30 for 30-day range)
3. Select "รายสัปดาห์" (Weekly)
4. Count rows (should be ~4-5 for 30-day range)
5. Select "รายเดือน" (Monthly)
6. Count rows (should be 1-2 for 30-day range)
```

**Expected:** Data aggregates correctly for each view mode

### ✅ Test 6: Year-over-Year Comparison
```
1. Check "เปรียบเทียบกับปีก่อน" checkbox
2. Wait for data to load
3. Verify trend indicators appear (↑ or ↓)
4. Check percentage changes display
5. Uncheck to disable
```

**Expected:** Comparison data loads and displays correctly

### ✅ Test 7: CSV Export
```
1. Select date range
2. Choose report type
3. Click "📥 ส่งออก CSV" button
4. Verify file downloads
5. Open CSV file
6. Check data matches screen
```

**Expected:** CSV file downloads with correct data

### ✅ Test 8: Occupancy Report Details
```
1. Select "การเข้าพัก" report
2. Find row with high occupancy (≥80%)
3. Verify green badge
4. Find row with medium occupancy (50-79%)
5. Verify yellow badge
6. Find row with low occupancy (<50%)
7. Verify red badge
```

**Expected:** Color coding works correctly

### ✅ Test 9: Revenue Report Details
```
1. Select "รายได้" report
2. Verify revenue column shows currency
3. Check booking count is integer
4. Verify room nights is integer
5. Check ADR calculation (Revenue ÷ Nights)
```

**Expected:** All calculations are accurate

### ✅ Test 10: Voucher Report Details
```
1. Select "คูปอง" report
2. Find percentage discount voucher
3. Verify shows "XX%"
4. Find fixed amount voucher
5. Verify shows "฿X,XXX.XX"
6. Check conversion rate calculation
```

**Expected:** Voucher data displays correctly

### ✅ Test 11: Responsive Design
```
1. Resize browser to mobile width (< 768px)
2. Verify cards stack vertically
3. Check table scrolls horizontally
4. Resize to tablet width (768-1024px)
5. Verify 2-column layout
6. Resize to desktop width (> 1024px)
7. Verify 4-column layout
```

**Expected:** Layout adapts to screen size

### ✅ Test 12: Error Handling
```
1. Set end date before start date
2. Verify validation message
3. Stop backend server
4. Try to load reports
5. Verify error message
6. Restart backend
7. Verify recovery
```

**Expected:** Errors handled gracefully

## API Testing

### Test Occupancy Endpoint
```bash
curl -X GET "http://localhost:8080/api/reports/occupancy?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
[
  {
    "date": "2024-01-01T00:00:00Z",
    "total_rooms": 50,
    "booked_rooms": 45,
    "available_rooms": 5,
    "occupancy_rate": 90.0
  }
]
```

### Test Revenue Endpoint
```bash
curl -X GET "http://localhost:8080/api/reports/revenue?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
[
  {
    "date": "2024-01-01T00:00:00Z",
    "total_revenue": 45000.00,
    "booking_count": 15,
    "room_nights": 45,
    "adr": 1000.00
  }
]
```

### Test Voucher Endpoint
```bash
curl -X GET "http://localhost:8080/api/reports/vouchers?start_date=2024-01-01&end_date=2024-01-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
[
  {
    "voucher_id": 1,
    "code": "SUMMER2024",
    "discount_type": "Percentage",
    "discount_value": 20.00,
    "total_uses": 50,
    "total_discount": 10000.00,
    "total_revenue": 40000.00,
    "conversion_rate": 25.0
  }
]
```

## Database Validation

### Verify Occupancy Calculation
```sql
-- Check occupancy for a specific date
SELECT 
  date,
  allotment as total_rooms,
  booked_count as booked_rooms,
  (allotment - booked_count) as available_rooms,
  ROUND((booked_count::numeric / allotment * 100), 1) as occupancy_rate
FROM room_inventory
WHERE date = '2024-01-01'
ORDER BY date;
```

### Verify Revenue Calculation
```sql
-- Check revenue for a date range
SELECT 
  DATE(created_at) as date,
  SUM(total_amount) as total_revenue,
  COUNT(*) as booking_count,
  SUM(
    EXTRACT(DAY FROM (
      SELECT MAX(check_out_date - check_in_date)
      FROM booking_details bd
      WHERE bd.booking_id = b.booking_id
    ))
  ) as room_nights
FROM bookings b
WHERE status IN ('Confirmed', 'CheckedIn', 'Completed')
  AND created_at >= '2024-01-01'
  AND created_at < '2024-02-01'
GROUP BY DATE(created_at)
ORDER BY date;
```

### Verify Voucher Statistics
```sql
-- Check voucher usage
SELECT 
  v.voucher_id,
  v.code,
  v.discount_type,
  v.discount_value,
  COUNT(b.booking_id) as total_uses,
  SUM(
    CASE 
      WHEN v.discount_type = 'Percentage' 
      THEN b.total_amount * (v.discount_value / 100)
      ELSE v.discount_value
    END
  ) as total_discount,
  SUM(b.total_amount) as total_revenue
FROM vouchers v
LEFT JOIN bookings b ON v.voucher_id = b.voucher_id
WHERE b.created_at >= '2024-01-01'
  AND b.created_at < '2024-02-01'
GROUP BY v.voucher_id, v.code, v.discount_type, v.discount_value;
```

## Performance Testing

### Test Load Time
```javascript
// In browser console
console.time('Page Load');
// Navigate to /manager/reports
console.timeEnd('Page Load');
// Should be < 2 seconds
```

### Test Data Fetch Time
```javascript
// In browser console
console.time('Data Fetch');
// Change date range
console.timeEnd('Data Fetch');
// Should be < 3 seconds
```

### Test Large Date Range
```
1. Select date range of 1 year
2. Choose daily view
3. Measure load time
4. Check browser responsiveness
```

**Expected:** Page remains responsive, no freezing

## Browser Compatibility

### Test in Chrome
- [ ] Dashboard loads correctly
- [ ] Reports display properly
- [ ] Export works
- [ ] Responsive design functions

### Test in Firefox
- [ ] Dashboard loads correctly
- [ ] Reports display properly
- [ ] Export works
- [ ] Responsive design functions

### Test in Safari
- [ ] Dashboard loads correctly
- [ ] Reports display properly
- [ ] Export works
- [ ] Responsive design functions

### Test in Edge
- [ ] Dashboard loads correctly
- [ ] Reports display properly
- [ ] Export works
- [ ] Responsive design functions

## Accessibility Testing

### Keyboard Navigation
```
1. Tab through all controls
2. Verify focus indicators
3. Test Enter key on buttons
4. Test Escape on date pickers
```

**Expected:** All controls accessible via keyboard

### Screen Reader Testing
```
1. Enable screen reader
2. Navigate through page
3. Verify labels are read
4. Check table headers
```

**Expected:** Content is accessible to screen readers

## Common Issues and Solutions

### Issue 1: No Data Displayed
**Solution:**
1. Check backend is running
2. Verify database has data
3. Check browser console for errors
4. Verify API endpoints are accessible

### Issue 2: Export Not Working
**Solution:**
1. Check browser popup blocker
2. Verify API endpoint
3. Check network tab for errors
4. Try different browser

### Issue 3: Incorrect Calculations
**Solution:**
1. Verify date range selection
2. Check booking statuses
3. Review aggregation logic
4. Compare with database directly

### Issue 4: Slow Loading
**Solution:**
1. Reduce date range
2. Use weekly/monthly view
3. Check backend performance
4. Optimize database queries

## Test Data Setup

### Create Test Bookings
```sql
-- Insert test bookings for last 90 days
INSERT INTO bookings (guest_id, total_amount, status, created_at)
SELECT 
  1,
  RANDOM() * 5000 + 1000,
  'Confirmed',
  CURRENT_DATE - (RANDOM() * 90)::int
FROM generate_series(1, 100);
```

### Create Test Vouchers
```sql
-- Insert test vouchers
INSERT INTO vouchers (code, discount_type, discount_value, expiry_date, max_uses)
VALUES 
  ('SUMMER2024', 'Percentage', 20, '2024-12-31', 100),
  ('EARLY500', 'FixedAmount', 500, '2024-12-31', 50);
```

### Update Inventory
```sql
-- Update inventory for last 90 days
INSERT INTO room_inventory (room_type_id, date, allotment, booked_count)
SELECT 
  1,
  CURRENT_DATE - n,
  50,
  FLOOR(RANDOM() * 40)
FROM generate_series(0, 90) n;
```

## Final Verification

### Checklist
- [ ] Dashboard displays 30-day summary
- [ ] All 4 metric cards show data
- [ ] Reports page loads without errors
- [ ] Date range selection works
- [ ] All 3 report types display correctly
- [ ] View mode switching functions
- [ ] Year comparison calculates correctly
- [ ] CSV export downloads file
- [ ] Color coding is accurate
- [ ] Responsive design works
- [ ] Error handling is graceful
- [ ] Performance is acceptable

### Sign-Off
```
Tested By: _______________
Date: _______________
Status: ☐ PASS ☐ FAIL
Notes: _______________
```

---

**Testing Script Version:** 1.0
**Last Updated:** Task 36 Implementation
