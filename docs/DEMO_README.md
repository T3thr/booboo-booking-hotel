# Demo Materials - Hotel Reservation System

## Overview
This directory contains all materials needed for demonstrating the Hotel Reservation System, including demo data, scenarios, presentation outlines, and video scripts.

---

## Quick Start

### 1. Seed Demo Data

**Windows:**
```bash
cd database/migrations
run_seed_demo_data.bat
```

**Linux/Mac:**
```bash
cd database/migrations
chmod +x run_seed_demo_data.sh
./run_seed_demo_data.sh
```

**Manual:**
```bash
psql -U postgres -d hotel_booking -f database/migrations/013_seed_demo_data.sql
```

### 2. Start the Application

```bash
# Terminal 1: Start Backend
cd backend
go run cmd/server/main.go

# Terminal 2: Start Frontend
cd frontend
npm run dev
```

### 3. Access the System

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080
- **API Docs:** http://localhost:8080/swagger

---

## Demo Credentials

### Guest Account
- **Email:** somchai@example.com
- **Password:** password123
- **Use for:** Booking flow, viewing history, cancellations

### Staff Account (Receptionist)
- **Email:** staff@hotel.com
- **Password:** staff123
- **Use for:** Check-in, check-out, room moves, no-shows

### Housekeeper Account
- **Email:** housekeeper@hotel.com
- **Password:** housekeeper123
- **Use for:** Task management, status updates, inspections

### Manager Account
- **Email:** manager@hotel.com
- **Password:** manager123
- **Use for:** Pricing, inventory, reports, analytics

---

## Demo Data Summary

### Records Created
- **Guests:** 5 accounts
- **Rooms:** 50 rooms (20 Standard, 20 Deluxe, 10 Suite)
- **Amenities:** 10 amenities
- **Rate Tiers:** 4 tiers (Low, Standard, High, Peak)
- **Rate Plans:** 4 plans
- **Pricing Points:** 48 rate combinations
- **Pricing Calendar:** 90 days
- **Room Inventory:** 270 records (90 days × 3 room types)
- **Vouchers:** 5 active vouchers
- **Bookings:** 30 bookings (various statuses)
- **Total Records:** 200+

### Booking Status Distribution
- **Confirmed:** 15 bookings (future stays)
- **CheckedIn:** 5 bookings (current guests)
- **Completed:** 8 bookings (past stays)
- **Cancelled:** 2 bookings

### Room Status Distribution
- **Vacant + Inspected:** 35 rooms (ready for check-in)
- **Vacant + Clean:** 5 rooms (needs inspection)
- **Vacant + Dirty:** 3 rooms (needs cleaning)
- **Vacant + Cleaning:** 2 rooms (being cleaned)
- **Occupied + Clean:** 5 rooms (guests staying)

---

## Available Documents

### 1. Demo Scenarios (`DEMO_SCENARIOS.md`)
**Purpose:** Step-by-step scenarios for live demonstrations

**Contents:**
- 12 detailed scenarios covering all features
- 5-minute quick demo script
- Troubleshooting guide
- Demo tips and best practices

**Use for:**
- Live presentations
- Training sessions
- User acceptance testing
- Feature showcases

### 2. Presentation Outline (`PRESENTATION_OUTLINE.md`)
**Purpose:** Complete slide deck outline for presentations

**Contents:**
- 22 slides with speaker notes
- Technical deep dives
- Architecture explanations
- Q&A preparation
- Alternative formats (5/10/30 min)

**Use for:**
- Formal presentations
- Stakeholder meetings
- Academic presentations
- Conference talks

### 3. Video Demo Script (`VIDEO_DEMO_SCRIPT.md`)
**Purpose:** Script for recording demonstration videos

**Contents:**
- 5-minute video script
- Scene-by-scene breakdown
- Recording tips
- Post-production guide
- Distribution checklist

**Use for:**
- Creating demo videos
- YouTube tutorials
- Marketing materials
- Documentation videos

---

## Demo Scenarios Quick Reference

### Scenario 1: Guest Booking (5 min)
- Search rooms
- Create booking with hold
- Apply voucher
- Confirm booking
- View history

### Scenario 2: Check-in (3 min)
- View arrivals
- Assign room
- Verify status updates

### Scenario 3: Room Move (2 min)
- Identify guest
- Move to new room
- Verify audit trail

### Scenario 4: Housekeeping (3 min)
- View tasks
- Update statuses
- Report maintenance
- Inspect rooms

### Scenario 5: Check-out (2 min)
- View departures
- Review bill
- Complete check-out

### Scenario 6: Cancellation (2 min)
- Select booking
- Calculate refund
- Confirm cancellation

### Scenario 7: Pricing Management (3 min)
- View calendar
- Update tiers
- Modify prices

### Scenario 8: Inventory (2 min)
- View heatmap
- Adjust allotment
- Verify constraints

### Scenario 9: Reports (3 min)
- Occupancy report
- Revenue analysis
- Export data

### Scenario 10: No-Show (2 min)
- Mark no-show
- Handle late arrival

### Scenario 11: Race Condition (2 min)
- Concurrent bookings
- Verify prevention

### Scenario 12: Background Jobs (1 min)
- Night audit
- Hold cleanup

---

## Presentation Formats

### Lightning Talk (5 minutes)
**Slides:** 1, 2, 3, 6 (demo), 18, 22
**Focus:** Problem → Solution → Demo → Stats

### Standard Presentation (15 minutes)
**Slides:** 1-10, 18, 21-22
**Focus:** Complete overview with live demo

### Technical Deep Dive (30 minutes)
**Slides:** All slides + extended Q&A
**Focus:** Architecture, implementation, best practices

### Workshop (2 hours)
**Format:** Presentation + Hands-on + Discussion
**Focus:** Learning and implementation

---

## Tips for Successful Demos

### Before Demo
1. ✅ Run seed data script
2. ✅ Test all credentials
3. ✅ Clear browser cache
4. ✅ Check internet connection
5. ✅ Prepare backup scenarios
6. ✅ Test all features
7. ✅ Have database viewer ready (optional)
8. ✅ Print cheat sheet with credentials

### During Demo
1. 🎯 Explain context before actions
2. 🎯 Highlight key features
3. 🎯 Show real-time updates
4. 🎯 Point out error handling
5. 🎯 Emphasize data integrity
6. 🎯 Engage with audience
7. 🎯 Handle questions gracefully
8. 🎯 Stay calm if issues occur

### After Demo
1. 📝 Share documentation links
2. 📝 Provide access to demo environment
3. 📝 Answer follow-up questions
4. 📝 Collect feedback
5. 📝 Note improvements for next time

---

## Troubleshooting

### Issue: Demo data not loading
**Solution:**
```bash
# Check database connection
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) FROM guests;"

# Re-run seed script
cd database/migrations
./run_seed_demo_data.sh
```

### Issue: Booking hold expires during demo
**Solution:**
- Work quickly through booking flow
- Or increase hold duration in config
- Or use pre-created bookings

### Issue: No available rooms
**Solution:**
```sql
-- Reset inventory
UPDATE room_inventory 
SET booked_count = 0, tentative_count = 0
WHERE date >= CURRENT_DATE;
```

### Issue: Voucher max uses reached
**Solution:**
```sql
-- Reset voucher usage
UPDATE vouchers 
SET current_uses = 0 
WHERE code = 'WELCOME10';
```

### Issue: Room status not updating
**Solution:**
- Refresh browser page
- Check backend logs
- Verify database connection

---

## Recording Demo Videos

### Equipment Needed
- Screen recording software (OBS Studio)
- Good microphone
- Quiet environment
- 1920x1080 display

### Recording Steps
1. Follow `VIDEO_DEMO_SCRIPT.md`
2. Record in segments
3. Do multiple takes
4. Edit and enhance
5. Add captions
6. Export and upload

### Video Checklist
- [ ] Clear audio
- [ ] Smooth transitions
- [ ] All features shown
- [ ] No errors visible
- [ ] Professional appearance
- [ ] Proper pacing
- [ ] Captions added
- [ ] Contact info included

---

## Additional Resources

### Documentation
- **Architecture:** `/docs/architecture/DESIGN.md`
- **Requirements:** `/docs/architecture/REQUIREMENTS.md`
- **API Docs:** `/backend/docs/swagger.yaml`
- **User Guides:** `/docs/user-guides/`

### Testing
- **Unit Tests:** `/backend/internal/*/test.go`
- **Integration Tests:** `/database/tests/`
- **E2E Tests:** `/e2e/tests/`
- **Load Tests:** `/load-tests/`

### Deployment
- **Production Guide:** `/docs/deployment/PRODUCTION_DEPLOYMENT.md`
- **Docker Setup:** `/docker-compose.yml`
- **Environment Config:** `/.env.example`

---

## Support

### Questions?
- Check documentation in `/docs`
- Review code comments
- Check GitHub issues
- Contact: [your-email]

### Found a Bug?
- Check existing issues
- Create detailed bug report
- Include steps to reproduce
- Provide system information

### Want to Contribute?
- Fork repository
- Create feature branch
- Submit pull request
- Follow coding standards

---

## License

This project is licensed under the MIT License. See LICENSE file for details.

---

## Acknowledgments

- Built with Next.js, Go, and PostgreSQL
- Inspired by real hotel management challenges
- Designed for educational and commercial use
- Community contributions welcome

---

**Last Updated:** [Current Date]
**Version:** 1.0.0
**Status:** Production Ready ✅

