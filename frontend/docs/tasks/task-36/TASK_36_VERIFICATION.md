# Task 36: Manager Dashboard & Reports - Verification Guide

## Verification Checklist

### ✅ Phase 1: Dashboard Summary (Manager Home Page)

#### Test 1.1: Dashboard Loads Successfully
- [ ] Navigate to `/manager`
- [ ] Page loads without errors
- [ ] Summary cards are visible
- [ ] All metrics display numbers

**Expected Result:**
```
✓ 4 summary cards displayed
✓ Revenue, Occupancy, ADR, RevPAR shown
✓ 30-day period data loaded
✓ Feature cards grid displayed
```

#### Test 1.2: Summary Metrics Accuracy
- [ ] Check Total Revenue calculation
- [ ] Verify Average Occupancy percentage
- [ ] Confirm ADR calculation
- [ ] Validate RevPAR formula

**Validation:**
```sql
-- Verify revenue (last 30 days)
SELECT SUM(total_amount) 
FROM bookings 
WHERE status IN ('Confirmed', 'CheckedIn', 'Completed')
  AND created_at >= CURRENT_DATE - INTERVAL '30 days';

-- Verify occupancy
SELECT AVG(booked_count::float / allotment * 100)
FROM room_inventory
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
  AND date < CURRENT_DATE;
```

**Expected Result:**
```
✓ Revenue matches database sum
✓ Occupancy rate is accurate
✓ ADR = Total Revenue / Room Nights
✓ RevPAR = ADR × Occupancy Rate / 100
```

#### Test 1.3: Feature Cards Navigation
- [ ] Click "จัดการระดับราคา" → `/manager/pricing/tiers`
- [ ] Click "ปฏิทินราคา" → `/manager/pricing/calendar`
- [ ] Click "เมทริกซ์ราคา" → `/manager/pricing/matrix`
- [ ] Click "จัดการสต็อก" → `/manager/inventory`
- [ ] Click "รายงานและการวิเคราะห์" → `/manager/reports`

**Expected Result:**
```
✓ All links navigate correctly
✓ No 404 errors
✓ Pages load successfully
```

### ✅ Phase 2: Reports Page Basic Functionality

#### Test 2.1: Reports Page Loads
- [ ] Navigate to `/manager/reports`
- [ ] Page loads without errors
- [ ] Filter controls are visible
- [ ] Default date range is set (last 30 days)

**Expected Result:**
```
✓ Page renders successfully
✓ Start date = 30 days ago
✓ End date = today
✓ Default report type = "occupancy"
✓ Default view mode = "daily"
```

#### Test 2.2: Date Range Selection
- [ ] Click start date picker
- [ ] Select a date
- [ ] Click end date picker
- [ ] Select a date after start date
- [ ] Verify data updates

**Expected Result:**
```
✓ Date pickers open correctly
✓ Selected dates are applied
✓ Report data refreshes
✓ Summary cards update
```

#### Test 2.3: Report Type Switching
- [ ] Select "Occupancy" report
- [ ] Select "Revenue" report
- [ ] Select "Vouchers" report
- [ ] Verify correct data displays

**Expected Result:**
```
✓ Occupancy report shows room data
✓ Revenue report shows financial data
✓ Voucher report shows discount data
✓ Table columns change appropriately
```

#### Test 2.4: View Mode Switching
- [ ] Select "Daily" view
- [ ] Select "Weekly" view
- [ ] Select "Monthly" view
- [ ] Verify aggregation works

**Expected Result:**
```
✓ Daily shows individual days
✓ Weekly groups by week (Sun-Sat)
✓ Monthly groups by calendar month
✓ Totals are accurate for each mode
```

### ✅ Phase 3: Occupancy Report Testing

#### Test 3.1: Occupancy Report Data
- [ ] Select date range with bookings
- [ ] Choose "Occupancy" report type
- [ ] Verify table displays correctly

**Expected Columns:**
```
- วันที่ (Date)
- ห้องทั้งหมด (Total Rooms)
- ห้องที่จอง (Booked Rooms)
- ห้องว่าง (Available Rooms)
- อัตราการเข้าพัก (Occupancy Rate)
```

**Validation:**
```
✓ Total Rooms = Allotment from inventory
✓ Booked Rooms = booked_count
✓ Available = Total - Booked
✓ Occupancy Rate = (Booked / Total) × 100
```

#### Test 3.2: Occupancy Color Coding
- [ ] Find row with ≥80% occupancy
- [ ] Find row with 50-79% occupancy
- [ ] Find row with <50% occupancy

**Expected Result:**
```
✓ ≥80% shows green badge
✓ 50-79% shows yellow badge
✓ <50% shows red badge
```

#### Test 3.3: Occupancy Aggregation
- [ ] Set view to "Weekly"
- [ ] Verify weekly totals
- [ ] Set view to "Monthly"
- [ ] Verify monthly totals

**Validation:**
```
✓ Weekly sums are correct
✓ Monthly sums are correct
✓ Occupancy rates recalculated properly
```

### ✅ Phase 4: Revenue Report Testing

#### Test 4.1: Revenue Report Data
- [ ] Select date range with bookings
- [ ] Choose "Revenue" report type
- [ ] Verify table displays correctly

**Expected Columns:**
```
- วันที่ (Date)
- รายได้ (Revenue)
- จำนวนการจอง (Booking Count)
- จำนวนคืน (Room Nights)
- ADR (Average Daily Rate)
```

**Validation:**
```sql
-- Verify revenue by date
SELECT 
  DATE(created_at) as date,
  SUM(total_amount) as revenue,
  COUNT(*) as bookings,
  SUM(EXTRACT(DAY FROM (check_out_date - check_in_date))) as nights
FROM bookings b
JOIN booking_details bd ON b.booking_id = bd.booking_id
WHERE status IN ('Confirmed', 'CheckedIn', 'Completed')
  AND created_at >= '2024-01-01'
GROUP BY DATE(created_at);
```

**Expected Result:**
```
✓ Revenue matches database
✓ Booking count is accurate
✓ Room nights calculated correctly
✓ ADR = Revenue / Room Nights
```

#### Test 4.2: Revenue Aggregation
- [ ] Set view to "Weekly"
- [ ] Verify weekly revenue sums
- [ ] Set view to "Monthly"
- [ ] Verify monthly revenue sums

**Expected Result:**
```
✓ Weekly revenue totals correct
✓ Monthly revenue totals correct
✓ ADR recalculated for period
```

### ✅ Phase 5: Voucher Report Testing

#### Test 5.1: Voucher Report Data
- [ ] Select date range with voucher usage
- [ ] Choose "Vouchers" report type
- [ ] Verify table displays correctly

**Expected Columns:**
```
- รหัสคูปอง (Voucher Code)
- ประเภท (Type)
- มูลค่าส่วนลด (Discount Value)
- จำนวนการใช้ (Total Uses)
- ส่วนลดรวม (Total Discount)
- รายได้รวม (Total Revenue)
- อัตราการแปลง (Conversion Rate)
```

**Validation:**
```sql
-- Verify voucher statistics
SELECT 
  v.code,
  v.discount_type,
  v.discount_value,
  COUNT(b.booking_id) as uses,
  SUM(CASE 
    WHEN v.discount_type = 'Percentage' 
    THEN b.total_amount * (v.discount_value / 100)
    ELSE v.discount_value
  END) as total_discount,
  SUM(b.total_amount) as revenue
FROM vouchers v
LEFT JOIN bookings b ON v.voucher_id = b.voucher_id
WHERE b.created_at >= '2024-01-01'
GROUP BY v.voucher_id;
```

**Expected Result:**
```
✓ Voucher codes displayed
✓ Discount types correct
✓ Total uses accurate
✓ Discount calculations correct
✓ Revenue totals match
```

#### Test 5.2: Voucher Type Display
- [ ] Find percentage discount voucher
- [ ] Find fixed amount discount voucher
- [ ] Verify display format

**Expected Result:**
```
✓ Percentage shows "XX%"
✓ Fixed amount shows "฿X,XXX.XX"
✓ Type column shows correct label
```

### ✅ Phase 6: Year-over-Year Comparison

#### Test 6.1: Enable Comparison
- [ ] Check "เปรียบเทียบกับปีก่อน" checkbox
- [ ] Verify previous year data loads
- [ ] Check summary cards update

**Expected Result:**
```
✓ Checkbox toggles state
✓ Previous year API calls made
✓ Comparison indicators appear
✓ Percentage changes calculated
```

#### Test 6.2: Comparison Calculations
- [ ] Verify revenue change percentage
- [ ] Verify occupancy change percentage
- [ ] Verify ADR change percentage

**Formula:**
```
Change % = ((Current - Previous) / Previous) × 100
```

**Expected Result:**
```
✓ Positive changes show green with ↑
✓ Negative changes show red with ↓
✓ Percentages are accurate
✓ Zero change handled correctly
```

#### Test 6.3: No Previous Year Data
- [ ] Select date range with no previous year data
- [ ] Enable comparison
- [ ] Verify graceful handling

**Expected Result:**
```
✓ No errors thrown
✓ Comparison indicators hidden
✓ Current data still displays
✓ User informed if needed
```

### ✅ Phase 7: Export Functionality

#### Test 7.1: CSV Export
- [ ] Select date range
- [ ] Choose report type
- [ ] Click "📥 ส่งออก CSV" button
- [ ] Verify file downloads

**Expected Result:**
```
✓ File downloads automatically
✓ Filename format: {type}_report_{start}_{end}.csv
✓ File contains correct data
✓ CSV format is valid
```

#### Test 7.2: Export Content Validation
- [ ] Open downloaded CSV file
- [ ] Verify headers are present
- [ ] Check data matches screen
- [ ] Verify encoding (UTF-8)

**Expected Result:**
```
✓ All columns included
✓ Data matches displayed report
✓ Thai characters display correctly
✓ Numbers formatted properly
```

#### Test 7.3: Export Error Handling
- [ ] Disconnect from backend
- [ ] Try to export
- [ ] Verify error message

**Expected Result:**
```
✓ Error message displayed
✓ No file downloaded
✓ User can retry
```

### ✅ Phase 8: Summary Cards Testing

#### Test 8.1: Summary Card Display
- [ ] Verify all 4 cards display
- [ ] Check formatting
- [ ] Verify colors

**Expected Cards:**
```
1. Total Revenue (Blue gradient)
2. Total Bookings (Green gradient)
3. Average Occupancy (Purple gradient)
4. ADR (Orange gradient)
```

**Expected Result:**
```
✓ All cards visible
✓ Gradients applied correctly
✓ Numbers formatted with currency/percentage
✓ Sub-text displays correctly
```

#### Test 8.2: Summary Card Updates
- [ ] Change date range
- [ ] Verify cards update
- [ ] Change report type
- [ ] Verify cards remain consistent

**Expected Result:**
```
✓ Cards update with new date range
✓ Calculations remain accurate
✓ Loading states shown during fetch
```

### ✅ Phase 9: Responsive Design

#### Test 9.1: Mobile View (< 768px)
- [ ] Resize browser to mobile width
- [ ] Verify layout adapts
- [ ] Check table scrolling

**Expected Result:**
```
✓ Cards stack vertically
✓ Filters stack vertically
✓ Table scrolls horizontally
✓ All content accessible
```

#### Test 9.2: Tablet View (768px - 1024px)
- [ ] Resize to tablet width
- [ ] Verify 2-column layout
- [ ] Check readability

**Expected Result:**
```
✓ Cards in 2 columns
✓ Filters in 2 columns
✓ Table fits width
✓ Text remains readable
```

#### Test 9.3: Desktop View (> 1024px)
- [ ] Resize to desktop width
- [ ] Verify 4-column layout
- [ ] Check spacing

**Expected Result:**
```
✓ Cards in 4 columns
✓ Filters in 4 columns
✓ Optimal spacing
✓ No horizontal scroll
```

### ✅ Phase 10: Performance Testing

#### Test 10.1: Load Time
- [ ] Clear cache
- [ ] Navigate to reports page
- [ ] Measure load time

**Expected Result:**
```
✓ Initial load < 2 seconds
✓ Data fetch < 3 seconds
✓ No blocking operations
```

#### Test 10.2: Large Date Ranges
- [ ] Select 1-year date range
- [ ] Choose daily view
- [ ] Verify performance

**Expected Result:**
```
✓ Page remains responsive
✓ Table renders efficiently
✓ No browser freezing
✓ Consider pagination if needed
```

#### Test 10.3: Multiple Report Switches
- [ ] Switch between report types rapidly
- [ ] Verify no memory leaks
- [ ] Check React Query caching

**Expected Result:**
```
✓ Smooth transitions
✓ Cached data reused
✓ No duplicate API calls
✓ Memory usage stable
```

### ✅ Phase 11: Error Handling

#### Test 11.1: Invalid Date Range
- [ ] Set end date before start date
- [ ] Verify validation

**Expected Result:**
```
✓ Error message displayed
✓ Report doesn't load
✓ User can correct dates
```

#### Test 11.2: Backend Unavailable
- [ ] Stop backend server
- [ ] Try to load reports
- [ ] Verify error handling

**Expected Result:**
```
✓ Error message displayed
✓ No console errors
✓ Graceful degradation
✓ Retry option available
```

#### Test 11.3: No Data Available
- [ ] Select date range with no bookings
- [ ] Verify empty state

**Expected Result:**
```
✓ "No data" message shown
✓ No errors thrown
✓ Summary cards show zeros
✓ Table shows empty state
```

### ✅ Phase 12: Integration Testing

#### Test 12.1: End-to-End Flow
```
1. Login as manager
2. Navigate to dashboard
3. View 30-day summary
4. Click reports link
5. Select custom date range
6. Switch report types
7. Enable year comparison
8. Export CSV
9. Verify downloaded file
```

**Expected Result:**
```
✓ Complete flow works without errors
✓ All features function correctly
✓ Data is consistent throughout
```

#### Test 12.2: Cross-Feature Consistency
- [ ] Check revenue in dashboard
- [ ] Check revenue in reports
- [ ] Verify numbers match

**Expected Result:**
```
✓ Dashboard and reports show same data
✓ Calculations are consistent
✓ No discrepancies
```

## Test Data Requirements

### Minimum Test Data
```sql
-- At least 90 days of inventory data
-- At least 50 bookings (various statuses)
-- At least 5 vouchers with usage
-- Data spanning multiple months
-- Data from previous year for comparison
```

### Sample Test Scenarios

#### Scenario 1: High Season Analysis
```
Date Range: Dec 20 - Jan 5
Expected: High occupancy (>80%)
Expected: High ADR
Expected: High revenue
```

#### Scenario 2: Low Season Analysis
```
Date Range: May 1 - May 31
Expected: Lower occupancy (<60%)
Expected: Lower ADR
Expected: Moderate revenue
```

#### Scenario 3: Promotion Campaign
```
Date Range: Campaign period
Report: Vouchers
Expected: High usage
Expected: Good conversion rate
```

## Automated Testing

### Unit Tests
```typescript
// Test summary calculations
describe('Summary Calculations', () => {
  test('calculates total revenue correctly', () => {
    // Test implementation
  });
  
  test('calculates average occupancy correctly', () => {
    // Test implementation
  });
  
  test('calculates ADR correctly', () => {
    // Test implementation
  });
});
```

### Integration Tests
```typescript
// Test API integration
describe('Reports API', () => {
  test('fetches occupancy data', async () => {
    // Test implementation
  });
  
  test('fetches revenue data', async () => {
    // Test implementation
  });
});
```

## Sign-Off Checklist

- [ ] All Phase 1 tests passed
- [ ] All Phase 2 tests passed
- [ ] All Phase 3 tests passed
- [ ] All Phase 4 tests passed
- [ ] All Phase 5 tests passed
- [ ] All Phase 6 tests passed
- [ ] All Phase 7 tests passed
- [ ] All Phase 8 tests passed
- [ ] All Phase 9 tests passed
- [ ] All Phase 10 tests passed
- [ ] All Phase 11 tests passed
- [ ] All Phase 12 tests passed
- [ ] Documentation complete
- [ ] Code reviewed
- [ ] Performance acceptable
- [ ] No critical bugs

## Verification Complete

**Verified By:** _________________
**Date:** _________________
**Status:** ☐ PASS ☐ FAIL ☐ NEEDS WORK

**Notes:**
```
[Add any additional notes or observations here]
```
