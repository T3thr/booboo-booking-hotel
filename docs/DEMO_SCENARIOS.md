# Demo Scenarios - Hotel Reservation System

## Overview
This document outlines realistic demo scenarios that showcase all major features of the hotel reservation system. These scenarios are designed for presentations and demonstrations.

---

## Demo Credentials

### Guest Account
- **Email:** somchai@example.com
- **Password:** password123
- **Role:** Guest

### Staff Account (Receptionist)
- **Email:** staff@hotel.com
- **Password:** staff123
- **Role:** Receptionist

### Housekeeper Account
- **Email:** housekeeper@hotel.com
- **Password:** housekeeper123
- **Role:** Housekeeper

### Manager Account
- **Email:** manager@hotel.com
- **Password:** manager123
- **Role:** Manager

---

## Scenario 1: Guest Booking Flow (5 minutes)

### Objective
Demonstrate the complete guest booking experience from search to confirmation.

### Steps

1. **Search for Rooms**
   - Navigate to homepage
   - Enter dates: Check-in (7 days from today), Check-out (10 days from today)
   - Number of guests: 2
   - Click "Search"
   - **Expected:** Display available room types with prices

2. **Select Room**
   - Review room options (Standard, Deluxe, Suite)
   - Click "Book Now" on Deluxe Room
   - **Expected:** Create 15-minute hold, redirect to guest info page

3. **Enter Guest Information**
   - Fill in guest details:
     - Primary Guest: John Doe
     - Secondary Guest: Jane Doe
   - Click "Continue to Summary"
   - **Expected:** Display booking summary with countdown timer

4. **Apply Voucher**
   - Enter voucher code: `WELCOME10`
   - Click "Apply"
   - **Expected:** 10% discount applied, total updated

5. **Confirm Booking**
   - Review booking details
   - Click "Confirm & Pay"
   - **Expected:** Booking confirmed, confirmation email sent

6. **View Booking History**
   - Navigate to "My Bookings"
   - **Expected:** See newly created booking with status "Confirmed"

### Key Features Demonstrated
- Room availability search
- Real-time pricing calculation
- Booking hold mechanism with countdown
- Voucher application
- Booking confirmation
- Email notifications

---

## Scenario 2: Check-in Process (3 minutes)

### Objective
Show how reception staff handles guest check-in.

### Steps

1. **Login as Receptionist**
   - Use staff credentials
   - Navigate to Staff Dashboard

2. **View Arrivals**
   - Click "Today's Arrivals"
   - **Expected:** List of guests checking in today

3. **Select Guest for Check-in**
   - Find booking for "Somchai Suksawat"
   - Click "Check In"

4. **Assign Room**
   - View available rooms (filtered by room type)
   - Select room 302 (Deluxe, Inspected status)
   - Click "Confirm Check-in"
   - **Expected:** 
     - Booking status → CheckedIn
     - Room 302 status → Occupied
     - Room assignment created

5. **Verify Dashboard Update**
   - Return to Room Status Dashboard
   - **Expected:** Room 302 now shows as Occupied

### Key Features Demonstrated
- Staff authentication and authorization
- Arrivals list
- Room assignment
- Real-time status updates
- Two-axis room status model

---


## Scenario 3: Room Move (2 minutes)

### Objective
Demonstrate handling guest complaints by moving them to a different room.

### Steps

1. **Identify Guest to Move**
   - From Staff Dashboard, find occupied room 103
   - Guest: Niran Pattana
   - Reason: Air conditioning issue

2. **Initiate Room Move**
   - Click "Move Room" button
   - **Expected:** Show available rooms of same or higher category

3. **Select New Room**
   - Choose room 105 (Standard, Inspected)
   - Enter reason: "AC malfunction in 103"
   - Click "Confirm Move"

4. **Verify Changes**
   - **Expected:**
     - Old assignment (103) → Status: Moved
     - New assignment (105) → Status: Active
     - Room 103 → Vacant, Dirty
     - Room 105 → Occupied
     - Housekeeping notified to clean 103

### Key Features Demonstrated
- Room move functionality
- Audit trail maintenance
- Automatic status updates
- Housekeeping integration

---

## Scenario 4: Housekeeping Workflow (3 minutes)

### Objective
Show the housekeeping task management and room status updates.

### Steps

1. **Login as Housekeeper**
   - Use housekeeper credentials
   - Navigate to Housekeeping Dashboard

2. **View Task List**
   - **Expected:** List of rooms needing cleaning
   - Priority: Dirty rooms for today's arrivals first

3. **Start Cleaning Room 107**
   - Click "Start Cleaning" on room 107
   - **Expected:** Status changes to "Cleaning"

4. **Complete Cleaning**
   - After demonstration, click "Mark as Clean"
   - **Expected:** Status changes to "Clean"

5. **Report Maintenance Issue**
   - For room 308, click "Report Issue"
   - Select issue type: "Plumbing"
   - Add notes: "Leaking faucet in bathroom"
   - **Expected:** Status changes to "MaintenanceRequired"

6. **Inspect Room (Supervisor)**
   - Switch to supervisor view
   - Find room 107 (Clean status)
   - Click "Inspect"
   - **Expected:** Status changes to "Inspected" (ready for check-in)

### Key Features Demonstrated
- Task prioritization
- Real-time status updates
- Maintenance reporting
- Quality control (inspection)
- Cross-department communication

---

## Scenario 5: Check-out Process (2 minutes)

### Objective
Demonstrate guest check-out and billing.

### Steps

1. **View Departures**
   - From Staff Dashboard, click "Today's Departures"
   - Find guest checking out today

2. **Initiate Check-out**
   - Select booking
   - Click "Check Out"

3. **Review Bill**
   - **Expected:** Display:
     - Room charges per night
     - Total amount
     - Payment method
     - Cancellation policy applied

4. **Confirm Check-out**
   - Click "Confirm Check-out"
   - **Expected:**
     - Booking status → Completed
     - Room assignment closed
     - Room status → Vacant, Dirty
     - Receipt emailed to guest
     - Housekeeping notified

### Key Features Demonstrated
- Departure management
- Billing summary
- Status transitions
- Email notifications
- Housekeeping integration

---

## Scenario 6: Cancellation with Refund (2 minutes)

### Objective
Show cancellation policy enforcement and refund calculation.

### Steps

1. **Login as Guest**
   - Use guest credentials
   - Navigate to "My Bookings"

2. **Select Booking to Cancel**
   - Find confirmed booking (7 days from now)
   - Click "View Details"

3. **Review Cancellation Policy**
   - **Expected:** Display policy snapshot from booking time
   - Policy: "Flexible - Free cancellation up to 1 day before"

4. **Calculate Refund**
   - Click "Cancel Booking"
   - **Expected:** Show refund amount (100% since > 1 day before)

5. **Confirm Cancellation**
   - Click "Confirm Cancellation"
   - **Expected:**
     - Booking status → Cancelled
     - Inventory released (booked_count decreased)
     - Refund processed
     - Confirmation email sent

### Key Features Demonstrated
- Policy immutability (snapshot)
- Refund calculation
- Inventory management
- Atomic operations

---

## Scenario 7: Manager - Pricing Management (3 minutes)

### Objective
Demonstrate dynamic pricing configuration.

### Steps

1. **Login as Manager**
   - Use manager credentials
   - Navigate to Manager Dashboard

2. **View Pricing Calendar**
   - Click "Pricing Management" → "Calendar"
   - **Expected:** 90-day calendar with color-coded tiers

3. **Update Rate Tier**
   - Select date range: Next weekend (Fri-Sun)
   - Change tier from "Standard" to "High Season"
   - Click "Apply"
   - **Expected:** Calendar updates, prices recalculated

4. **View Pricing Matrix**
   - Click "Pricing Matrix"
   - **Expected:** Table showing all rate combinations
   - Rows: Room Types
   - Columns: Rate Tiers

5. **Bulk Update Prices**
   - Select "Deluxe Room" row
   - Apply 10% increase
   - Click "Update"
   - **Expected:** All Deluxe prices increased by 10%

### Key Features Demonstrated
- Dynamic pricing
- Rate tier management
- Bulk operations
- Visual calendar interface
- Price matrix management

---


## Scenario 8: Manager - Inventory Management (2 minutes)

### Objective
Show room inventory control and overbooking prevention.

### Steps

1. **View Inventory Dashboard**
   - Navigate to "Inventory Management"
   - **Expected:** Heatmap showing availability for 90 days

2. **Adjust Allotment**
   - Select "Standard Room" for next month
   - Current allotment: 18
   - Try to reduce to 5
   - **Expected:** Error - "Cannot reduce below current bookings (12 booked)"

3. **Valid Adjustment**
   - Increase allotment to 20
   - Click "Update"
   - **Expected:** Success, more rooms available for booking

4. **View Booking Heatmap**
   - **Expected:** Color gradient showing:
     - Green: High availability
     - Yellow: Medium availability
     - Red: Low availability
     - Dark Red: Fully booked

### Key Features Demonstrated
- Inventory constraints
- Overbooking prevention
- Visual availability tracking
- Data validation

---

## Scenario 9: Manager - Reports & Analytics (3 minutes)

### Objective
Demonstrate reporting capabilities and business insights.

### Steps

1. **Occupancy Report**
   - Navigate to "Reports" → "Occupancy"
   - Select date range: Last 30 days
   - **Expected:** Display:
     - Daily occupancy rate graph
     - Average occupancy: 65%
     - Peak days highlighted

2. **Revenue Report**
   - Click "Revenue Report"
   - Select date range: Last 30 days
   - **Expected:** Display:
     - Total revenue: ฿450,000
     - Revenue by room type (pie chart)
     - ADR (Average Daily Rate): ฿1,500
     - RevPAR: ฿975

3. **Voucher Usage Report**
   - Click "Voucher Report"
   - **Expected:** Display:
     - Active vouchers
     - Usage statistics
     - Total discount given: ฿15,000
     - Conversion rate: 35%

4. **Export Report**
   - Click "Export to CSV"
   - **Expected:** Download CSV file with detailed data

5. **Year-over-Year Comparison**
   - Toggle "Compare with last year"
   - **Expected:** Show growth metrics:
     - Occupancy: +12%
     - Revenue: +18%
     - ADR: +5%

### Key Features Demonstrated
- Comprehensive reporting
- Data visualization
- Export functionality
- Comparative analysis
- Key performance indicators

---

## Scenario 10: No-Show Handling (2 minutes)

### Objective
Show how staff handles guests who don't arrive.

### Steps

1. **Identify No-Show**
   - From Staff Dashboard, view "Today's Arrivals"
   - Guest hasn't arrived by 6 PM
   - Booking: Apinya Chaiyaporn, Room Type: Suite

2. **Mark as No-Show**
   - Click "Mark as No-Show"
   - Add notes: "No contact from guest"
   - **Expected:**
     - Booking status → NoShow
     - Inventory NOT automatically released (manager decision)
     - Charge applied per policy

3. **Late Arrival (Optional)**
   - Guest arrives at 8 PM
   - Click "Revert No-Show"
   - Proceed with normal check-in
   - **Expected:** Status changes back to Confirmed

### Key Features Demonstrated
- No-show management
- Policy enforcement
- Flexible handling
- Audit trail

---

## Scenario 11: Race Condition Prevention (2 minutes)

### Objective
Demonstrate system's ability to prevent overbooking under concurrent load.

### Steps

1. **Setup**
   - Identify room type with only 1 room available
   - Open two browser windows (Guest A and Guest B)

2. **Simultaneous Booking Attempt**
   - Both users search for same dates
   - Both see 1 room available
   - Both click "Book Now" at same time

3. **Hold Creation**
   - **Expected:**
     - First user: Hold created successfully
     - Second user: "Room no longer available" error

4. **Verify Inventory**
   - Check database: tentative_count = 1
   - Only one hold exists
   - **Expected:** No overbooking occurred

### Key Features Demonstrated
- Atomic operations
- Database-level locking
- Race condition prevention
- Data integrity

---

## Scenario 12: Background Jobs (1 minute)

### Objective
Show automated system maintenance.

### Steps

1. **Night Audit**
   - Demonstrate scheduled job (runs at 2 AM)
   - **Expected:**
     - All Occupied rooms → housekeeping_status = Dirty
     - Daily report generated
     - Logs created

2. **Hold Cleanup**
   - Show expired holds (runs every 5 minutes)
   - **Expected:**
     - Expired holds deleted
     - tentative_count decreased
     - Inventory released

### Key Features Demonstrated
- Automated maintenance
- Scheduled jobs
- System reliability
- Data consistency

---

## Quick Demo Script (5 minutes total)

For time-constrained presentations, use this condensed script:

### Minute 1: Guest Booking
- Search rooms → Select → Book → Confirm

### Minute 2: Staff Check-in
- View arrivals → Assign room → Confirm

### Minute 3: Housekeeping
- View tasks → Update status → Inspect

### Minute 4: Manager Pricing
- View calendar → Update tier → View matrix

### Minute 5: Reports
- Occupancy report → Revenue report → Export

---

## Demo Tips

### Before Demo
1. Run seed data script to populate database
2. Clear browser cache
3. Test all credentials
4. Prepare backup scenarios
5. Have database viewer ready (optional)

### During Demo
1. Explain context before each action
2. Highlight key features as they appear
3. Show real-time updates
4. Point out error handling
5. Emphasize data integrity

### After Demo
1. Show database state (optional)
2. Discuss architecture decisions
3. Answer questions
4. Provide documentation links

---

## Troubleshooting

### Common Issues

**Issue:** Booking hold expires during demo
- **Solution:** Increase hold duration in config or work quickly

**Issue:** No available rooms
- **Solution:** Reset inventory or use future dates

**Issue:** Voucher already used max times
- **Solution:** Create new voucher or increase max_uses

**Issue:** Room status not updating
- **Solution:** Refresh page or check WebSocket connection

---

## Additional Resources

- **API Documentation:** `/backend/docs/swagger.yaml`
- **User Guides:** `/docs/user-guides/`
- **Architecture:** `/docs/architecture/DESIGN.md`
- **Requirements:** `/docs/architecture/REQUIREMENTS.md`

