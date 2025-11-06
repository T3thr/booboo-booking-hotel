# Task 36: Manager Dashboard & Reports - Quick Start Guide

## Quick Access

**Dashboard:** http://localhost:3000/manager
**Reports:** http://localhost:3000/manager/reports

## Prerequisites

1. Backend server running on port 8080
2. Database with sample data
3. Manager account credentials
4. At least 30 days of booking history for meaningful reports

## Getting Started

### Step 1: Access the Manager Dashboard

1. Navigate to http://localhost:3000/manager
2. Log in with manager credentials
3. View the 30-day performance summary

**Dashboard Metrics:**
- **Total Revenue:** Sum of all bookings in last 30 days
- **Average Occupancy:** Percentage of rooms occupied
- **ADR:** Average Daily Rate (revenue per room night)
- **RevPAR:** Revenue Per Available Room

### Step 2: Navigate to Reports

Click on "รายงานและการวิเคราะห์" (Reports and Analytics) card or navigate to `/manager/reports`

### Step 3: Select Report Parameters

#### Date Range
```
Start Date: [Select from calendar]
End Date: [Select from calendar]
```

**Common Ranges:**
- Last 7 days
- Last 30 days
- Last 90 days
- Current month
- Previous month
- Custom range

#### Report Type
```
Options:
- Occupancy (การเข้าพัก)
- Revenue (รายได้)
- Vouchers (คูปอง)
```

#### View Mode
```
Options:
- Daily (รายวัน)
- Weekly (รายสัปดาห์)
- Monthly (รายเดือน)
```

### Step 4: Enable Year-over-Year Comparison (Optional)

Check the "เปรียบเทียบกับปีก่อน" checkbox to see:
- Revenue change percentage
- Occupancy change percentage
- ADR change percentage

### Step 5: View Report Data

The report will display:
1. **Summary Cards** (top of page)
   - Key metrics for selected period
   - Comparison indicators if enabled

2. **Detailed Table** (main content)
   - Row-by-row data
   - Aggregated by selected view mode
   - Color-coded performance indicators

### Step 6: Export Data (Optional)

Click "📥 ส่งออก CSV" button to download report as CSV file

**File naming:** `{report_type}_report_{start_date}_{end_date}.csv`

## Report Types Explained

### 1. Occupancy Report

**Shows:**
- Date/Period
- Total Rooms Available
- Booked Rooms
- Available Rooms
- Occupancy Rate (%)

**Use Cases:**
- Identify high/low demand periods
- Plan maintenance schedules
- Optimize inventory allocation

**Color Coding:**
- 🟢 Green (≥80%): Excellent occupancy
- 🟡 Yellow (50-79%): Good occupancy
- 🔴 Red (<50%): Low occupancy

### 2. Revenue Report

**Shows:**
- Date/Period
- Total Revenue
- Number of Bookings
- Room Nights
- ADR (Average Daily Rate)

**Use Cases:**
- Track revenue trends
- Evaluate pricing strategies
- Forecast future revenue

**Key Metrics:**
- **ADR:** Revenue ÷ Room Nights
- **Total Revenue:** Sum of all bookings
- **Booking Count:** Number of reservations

### 3. Voucher Report

**Shows:**
- Voucher Code
- Discount Type (Percentage/Fixed)
- Discount Value
- Total Uses
- Total Discount Given
- Total Revenue Generated
- Conversion Rate

**Use Cases:**
- Evaluate marketing campaigns
- Track voucher effectiveness
- Calculate ROI on promotions

**Metrics:**
- **Conversion Rate:** (Uses ÷ Total Bookings) × 100
- **Total Discount:** Sum of all discounts applied
- **Revenue Impact:** Revenue generated with voucher

## View Modes Explained

### Daily View
- Shows data for each individual day
- Most detailed view
- Best for short date ranges (≤30 days)

### Weekly View
- Aggregates data by week (Sunday-Saturday)
- Smooths out daily fluctuations
- Best for medium date ranges (1-3 months)

### Monthly View
- Aggregates data by calendar month
- Shows long-term trends
- Best for long date ranges (3+ months)

## Understanding Summary Cards

### Card 1: Total Revenue
```
฿XXX,XXX.XX
↑ X.X% จากปีก่อน
XX การจอง
```
- Top number: Total revenue in period
- Arrow: Trend vs. previous year
- Bottom: Number of bookings

### Card 2: Total Bookings
```
XXX
XXX คืน
```
- Top number: Number of bookings
- Bottom: Total room nights

### Card 3: Average Occupancy
```
XX.X%
↑ X.X% จากปีก่อน
```
- Top number: Average occupancy rate
- Arrow: Trend vs. previous year

### Card 4: ADR
```
฿X,XXX.XX
↑ X.X% จากปีก่อน
```
- Top number: Average daily rate
- Arrow: Trend vs. previous year

## Common Use Cases

### Use Case 1: Monthly Performance Review
```
1. Set date range to previous month
2. Select "Revenue" report
3. Use "Monthly" view
4. Enable year comparison
5. Review summary cards
6. Export for records
```

### Use Case 2: Identify Peak Seasons
```
1. Set date range to full year
2. Select "Occupancy" report
3. Use "Weekly" view
4. Look for patterns in occupancy rates
5. Plan pricing strategies accordingly
```

### Use Case 3: Evaluate Promotion Campaign
```
1. Set date range to campaign period
2. Select "Vouchers" report
3. Review conversion rates
4. Calculate ROI
5. Decide on future campaigns
```

### Use Case 4: Weekly Revenue Tracking
```
1. Set date range to last 7 days
2. Select "Revenue" report
3. Use "Daily" view
4. Monitor daily performance
5. Identify trends early
```

## Tips and Best Practices

### Date Selection
- ✅ Use consistent periods for comparison
- ✅ Include full weeks/months for accurate aggregation
- ✅ Consider seasonality when comparing
- ❌ Avoid partial periods for monthly view

### Report Interpretation
- ✅ Look for trends, not just absolute numbers
- ✅ Compare with previous periods
- ✅ Consider external factors (holidays, events)
- ✅ Use multiple report types together

### Export Usage
- ✅ Export regularly for record keeping
- ✅ Use CSV for further analysis in Excel
- ✅ Archive reports for historical reference
- ✅ Share with stakeholders

### Performance Optimization
- ✅ Use shorter date ranges for faster loading
- ✅ Cache frequently accessed reports
- ✅ Export large datasets instead of viewing
- ✅ Use appropriate view mode for date range

## Troubleshooting

### No Data Displayed
**Problem:** Report shows "กำลังโหลดข้อมูล..." indefinitely

**Solutions:**
1. Check date range is valid
2. Verify backend is running
3. Check browser console for errors
4. Ensure database has data for period

### Export Not Working
**Problem:** CSV export button doesn't download file

**Solutions:**
1. Check browser popup blocker
2. Verify API endpoint is accessible
3. Check network tab for errors
4. Try different browser

### Incorrect Calculations
**Problem:** Numbers don't match expectations

**Solutions:**
1. Verify date range selection
2. Check booking statuses included
3. Review aggregation logic
4. Compare with backend data directly

### Slow Loading
**Problem:** Reports take long time to load

**Solutions:**
1. Reduce date range
2. Use weekly/monthly view instead of daily
3. Check backend performance
4. Optimize database queries

## Keyboard Shortcuts

- `Tab` - Navigate between fields
- `Enter` - Submit date selection
- `Esc` - Close date picker
- `Ctrl/Cmd + Click` - Open report in new tab

## Next Steps

After reviewing reports:
1. **Adjust Pricing:** Use insights to optimize rate tiers
2. **Manage Inventory:** Allocate rooms based on demand
3. **Plan Marketing:** Create targeted campaigns
4. **Forecast Revenue:** Project future performance
5. **Improve Operations:** Identify areas for improvement

## Related Documentation

- [Task 36 Index](./TASK_36_INDEX.md) - Complete implementation details
- [Task 36 Verification](./TASK_36_VERIFICATION.md) - Testing guide
- [Backend Reporting Reference](../backend/REPORTING_MODULE_REFERENCE.md) - API documentation
- [Requirements Document](../.kiro/specs/hotel-reservation-system/requirements.md) - Original requirements

## Support

For issues or questions:
1. Check this guide first
2. Review error messages in browser console
3. Check backend logs
4. Verify database connectivity
5. Contact system administrator

---

**Last Updated:** Task 36 Implementation
**Version:** 1.0
