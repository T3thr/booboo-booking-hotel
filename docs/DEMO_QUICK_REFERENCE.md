# Demo Quick Reference Card
## Hotel Reservation System

---

## 🔑 Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| **Guest** | somchai@example.com | password123 |
| **Staff** | staff@hotel.com | staff123 |
| **Housekeeper** | housekeeper@hotel.com | housekeeper123 |
| **Manager** | manager@hotel.com | manager123 |

---

## 🎯 5-Minute Quick Demo

### Minute 1: Guest Booking
1. Search: Check-in +7 days, Check-out +10 days, 2 guests
2. Select Deluxe Room → Book Now
3. Fill guest info → Continue
4. Apply voucher: `WELCOME10`
5. Confirm booking

### Minute 2: Staff Check-in
1. Login as staff
2. View Today's Arrivals
3. Select guest → Check In
4. Assign room 302 → Confirm

### Minute 3: Housekeeping
1. View task list
2. Room 107: Start Cleaning → Mark as Clean
3. Inspect room → Status: Inspected

### Minute 4: Manager Pricing
1. View Pricing Calendar
2. Select next weekend → Change to High Season
3. View Pricing Matrix

### Minute 5: Reports
1. Occupancy Report → Show graph
2. Revenue Report → Show metrics
3. Export to CSV

---

## 💾 Quick Commands

### Seed Demo Data
```bash
# Windows
database\migrations\run_seed_demo_data.bat

# Linux/Mac
database/migrations/run_seed_demo_data.sh
```

### Start System
```bash
# Backend
cd backend && go run cmd/server/main.go

# Frontend
cd frontend && npm run dev
```

### Reset Demo Data
```sql
-- Reset inventory
UPDATE room_inventory SET booked_count = 0, tentative_count = 0;

-- Reset vouchers
UPDATE vouchers SET current_uses = 0;

-- Clear holds
DELETE FROM booking_holds;
```

---

## 🎬 Demo Scenarios

| # | Scenario | Duration | Key Features |
|---|----------|----------|--------------|
| 1 | Guest Booking | 5 min | Search, Hold, Voucher, Confirm |
| 2 | Check-in | 3 min | Arrivals, Room Assignment |
| 3 | Room Move | 2 min | Move Guest, Audit Trail |
| 4 | Housekeeping | 3 min | Tasks, Status Updates, Inspection |
| 5 | Check-out | 2 min | Departures, Billing |
| 6 | Cancellation | 2 min | Policy, Refund Calculation |
| 7 | Pricing | 3 min | Calendar, Tiers, Matrix |
| 8 | Inventory | 2 min | Heatmap, Allotment |
| 9 | Reports | 3 min | Occupancy, Revenue, Export |
| 10 | No-Show | 2 min | Mark, Handle Late Arrival |

---

## 🎨 Room Status Colors

| Status | Color | Meaning |
|--------|-------|---------|
| Vacant + Inspected | 🟢 Green | Ready for check-in |
| Vacant + Clean | 🟡 Yellow | Needs inspection |
| Vacant + Dirty | 🔴 Red | Needs cleaning |
| Occupied | 🔵 Blue | Guest staying |
| Maintenance | ⚫ Gray | Out of service |

---

## 💰 Active Vouchers

| Code | Type | Value | Expiry |
|------|------|-------|--------|
| WELCOME10 | Percentage | 10% | +30 days |
| SUMMER20 | Percentage | 20% | +60 days |
| SAVE500 | Fixed | ฿500 | +45 days |
| WEEKEND15 | Percentage | 15% | +90 days |
| EARLYBIRD | Percentage | 25% | +15 days |

---

## 🏨 Room Inventory

| Room Type | Total | Available | Price Range |
|-----------|-------|-----------|-------------|
| Standard | 20 | 15 | ฿800-1,500 |
| Deluxe | 20 | 16 | ฿1,200-2,200 |
| Suite | 10 | 8 | ฿2,000-3,500 |

---

## 📊 Key Metrics (Demo Data)

- **Total Bookings:** 30
- **Occupancy Rate:** 65%
- **Average Daily Rate:** ฿1,500
- **Revenue (30 days):** ฿450,000
- **Active Vouchers:** 5
- **Total Discount Given:** ฿15,000

---

## 🔧 Troubleshooting

### Problem: Hold expires
**Fix:** Work faster or increase duration

### Problem: No rooms available
**Fix:** Use future dates or reset inventory

### Problem: Voucher maxed out
**Fix:** Reset current_uses to 0

### Problem: Status not updating
**Fix:** Refresh page

---

## 📱 URLs

- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:8080
- **API Docs:** http://localhost:8080/swagger
- **Database:** localhost:5432/hotel_booking

---

## 🎓 Key Talking Points

### Technical Highlights
- ✅ Race condition prevention (database locks)
- ✅ Policy immutability (snapshots)
- ✅ Two-axis room status model
- ✅ Atomic operations (transactions)
- ✅ Real-time synchronization

### Business Benefits
- ✅ Prevents overbooking
- ✅ Reduces manual errors
- ✅ Improves guest satisfaction
- ✅ Increases operational efficiency
- ✅ Provides actionable insights

### Technology Stack
- ✅ Next.js 16 (Frontend)
- ✅ Go (Backend)
- ✅ PostgreSQL (Database)
- ✅ Docker (Deployment)

---

## 📋 Pre-Demo Checklist

- [ ] Seed data loaded
- [ ] All services running
- [ ] Credentials tested
- [ ] Browser cache cleared
- [ ] Backup plan ready
- [ ] Demo script reviewed
- [ ] Questions prepared
- [ ] Time allocated

---

## 🎤 Opening Lines

**Option 1 (Problem-focused):**
"Hotels lose millions annually due to overbooking, manual errors, and system failures. Let me show you how we solved these problems."

**Option 2 (Solution-focused):**
"This is a hotel management system that prevents overbooking, ensures data integrity, and provides real-time insights. Let me demonstrate."

**Option 3 (Technical):**
"Built with Next.js, Go, and PostgreSQL, this system uses database-level locking and stored procedures to ensure bulletproof operations."

---

## 🎬 Closing Lines

**Option 1:**
"As you've seen, this system handles complex hotel operations with reliability and ease. All code and documentation are available in the repository."

**Option 2:**
"From guest bookings to manager analytics, every feature is designed for real-world use. Thank you for your time!"

**Option 3:**
"This demonstrates how proper architecture and database design can solve real business problems. Questions?"

---

## 📞 Contact & Resources

- **Documentation:** `/docs`
- **GitHub:** [repository-url]
- **Email:** [your-email]
- **Demo Video:** [video-url]

---

**Print this card and keep it handy during demos!**

