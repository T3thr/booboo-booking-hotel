# Demo Materials Index
## Hotel Reservation System - Complete Guide

---

## 📋 Overview

This index provides a complete guide to all demo and presentation materials for the Hotel Reservation System. Use this as your starting point for demonstrations, presentations, and training.

---

## 🗂️ Document Structure

```
docs/
├── DEMO_README.md                    # Main demo guide (START HERE)
├── DEMO_SCENARIOS.md                 # 12 detailed scenarios
├── DEMO_QUICK_REFERENCE.md           # One-page cheat sheet
├── PRESENTATION_OUTLINE.md           # Complete slide deck
├── VIDEO_DEMO_SCRIPT.md              # Video recording script
├── DEMO_MATERIALS_INDEX.md           # This file
└── TASK_50_COMPLETION_SUMMARY.md     # Implementation summary

database/migrations/
├── 013_seed_demo_data.sql            # Demo data SQL script
├── run_seed_demo_data.bat            # Windows runner
└── run_seed_demo_data.sh             # Linux/Mac runner
```

---

## 🚀 Quick Start Guide

### Step 1: Seed Demo Data (5 minutes)
```bash
# Windows
cd database/migrations
run_seed_demo_data.bat

# Linux/Mac
cd database/migrations
chmod +x run_seed_demo_data.sh
./run_seed_demo_data.sh
```

### Step 2: Start Application (2 minutes)
```bash
# Terminal 1: Backend
cd backend
go run cmd/server/main.go

# Terminal 2: Frontend
cd frontend
npm run dev
```

### Step 3: Access System
- Frontend: http://localhost:3000
- Backend: http://localhost:8080
- API Docs: http://localhost:8080/swagger

### Step 4: Login with Demo Credentials
- **Guest:** somchai@example.com / password123
- **Staff:** staff@hotel.com / staff123
- **Housekeeper:** housekeeper@hotel.com / housekeeper123
- **Manager:** manager@hotel.com / manager123

---

## 📚 Document Guide

### For First-Time Users
**Start with:** `DEMO_README.md`
- Overview of all materials
- Quick start instructions
- Credential reference
- Troubleshooting guide

**Then review:** `DEMO_QUICK_REFERENCE.md`
- One-page cheat sheet
- Essential information
- Quick commands
- Key metrics

### For Live Demonstrations
**Primary:** `DEMO_SCENARIOS.md`
- 12 detailed scenarios
- Step-by-step instructions
- Expected outcomes
- Timing guidance

**Support:** `DEMO_QUICK_REFERENCE.md`
- Keep open during demo
- Quick credential lookup
- Command reference
- Troubleshooting tips

### For Presentations
**Primary:** `PRESENTATION_OUTLINE.md`
- 22 slides with speaker notes
- Multiple formats (5/10/15/30 min)
- Technical deep dives
- Q&A preparation

**Support:** `DEMO_SCENARIOS.md`
- Live demo integration
- Feature demonstrations
- Real-world examples

### For Video Recording
**Primary:** `VIDEO_DEMO_SCRIPT.md`
- Complete 5-minute script
- Scene-by-scene breakdown
- Recording tips
- Post-production guide

**Support:** `DEMO_SCENARIOS.md`
- Detailed feature walkthroughs
- Alternative approaches
- Extended scenarios

### For Training Sessions
**Primary:** `DEMO_README.md`
- Comprehensive overview
- Setup instructions
- Resource links

**Support:** All other documents
- Scenarios for hands-on practice
- Quick reference for students
- Presentation for lectures

---

## 🎯 Use Case Matrix

| Use Case | Primary Document | Support Documents | Duration |
|----------|-----------------|-------------------|----------|
| **Quick Demo** | DEMO_QUICK_REFERENCE.md | DEMO_SCENARIOS.md | 5 min |
| **Client Presentation** | PRESENTATION_OUTLINE.md | DEMO_SCENARIOS.md | 15-30 min |
| **Academic Presentation** | PRESENTATION_OUTLINE.md | All documents | 20-45 min |
| **Video Recording** | VIDEO_DEMO_SCRIPT.md | DEMO_SCENARIOS.md | 5 min |
| **Training Workshop** | DEMO_README.md | All documents | 2 hours |
| **User Testing** | DEMO_SCENARIOS.md | DEMO_QUICK_REFERENCE.md | Variable |
| **Feature Showcase** | DEMO_SCENARIOS.md | PRESENTATION_OUTLINE.md | 10-20 min |
| **Technical Review** | PRESENTATION_OUTLINE.md | Architecture docs | 30-60 min |

---

## 🎬 Demo Scenarios Quick Index

| # | Scenario | Duration | Document Section | Page |
|---|----------|----------|------------------|------|
| 1 | Guest Booking Flow | 5 min | DEMO_SCENARIOS.md | Scenario 1 |
| 2 | Check-in Process | 3 min | DEMO_SCENARIOS.md | Scenario 2 |
| 3 | Room Move | 2 min | DEMO_SCENARIOS.md | Scenario 3 |
| 4 | Housekeeping Workflow | 3 min | DEMO_SCENARIOS.md | Scenario 4 |
| 5 | Check-out Process | 2 min | DEMO_SCENARIOS.md | Scenario 5 |
| 6 | Cancellation with Refund | 2 min | DEMO_SCENARIOS.md | Scenario 6 |
| 7 | Pricing Management | 3 min | DEMO_SCENARIOS.md | Scenario 7 |
| 8 | Inventory Management | 2 min | DEMO_SCENARIOS.md | Scenario 8 |
| 9 | Reports & Analytics | 3 min | DEMO_SCENARIOS.md | Scenario 9 |
| 10 | No-Show Handling | 2 min | DEMO_SCENARIOS.md | Scenario 10 |
| 11 | Race Condition Prevention | 2 min | DEMO_SCENARIOS.md | Scenario 11 |
| 12 | Background Jobs | 1 min | DEMO_SCENARIOS.md | Scenario 12 |

---

## 📊 Presentation Formats

### Lightning Talk (5 minutes)
**Document:** PRESENTATION_OUTLINE.md (Slides 1, 2, 3, 6, 18, 22)
**Focus:** Problem → Solution → Quick Demo → Stats
**Best for:** Conferences, networking events, quick pitches

### Standard Presentation (15 minutes)
**Document:** PRESENTATION_OUTLINE.md (Slides 1-10, 18, 21-22)
**Focus:** Complete overview with live demo
**Best for:** Client meetings, academic presentations, team demos

### Technical Deep Dive (30 minutes)
**Document:** PRESENTATION_OUTLINE.md (All slides)
**Focus:** Architecture, implementation, best practices
**Best for:** Technical reviews, developer conferences, workshops

### Workshop Format (2 hours)
**Documents:** All documents
**Focus:** Presentation + Hands-on + Discussion
**Best for:** Training sessions, bootcamps, team onboarding

---

## 🎥 Video Recording Guide

### Pre-Production
1. Review `VIDEO_DEMO_SCRIPT.md`
2. Run seed data script
3. Test all features
4. Prepare recording environment
5. Check equipment

### Production
1. Follow script exactly
2. Record in segments
3. Do multiple takes
4. Maintain consistent pace
5. Show enthusiasm

### Post-Production
1. Edit segments together
2. Add transitions
3. Include captions
4. Add contact information
5. Export and upload

**Detailed Guide:** `VIDEO_DEMO_SCRIPT.md`

---

## 🔑 Essential Information

### Demo Credentials
```
Guest:       somchai@example.com / password123
Staff:       staff@hotel.com / staff123
Housekeeper: housekeeper@hotel.com / housekeeper123
Manager:     manager@hotel.com / manager123
```

### Active Vouchers
```
WELCOME10  - 10% off
SUMMER20   - 20% off
SAVE500    - ฿500 off
WEEKEND15  - 15% off
EARLYBIRD  - 25% off
```

### System URLs
```
Frontend:  http://localhost:3000
Backend:   http://localhost:8080
API Docs:  http://localhost:8080/swagger
Database:  localhost:5432/hotel_booking
```

### Key Statistics
```
Total Records:    200+
Rooms:            50 (20 Standard, 20 Deluxe, 10 Suite)
Bookings:         30 (various statuses)
Occupancy Rate:   65%
Average Rate:     ฿1,500/night
```

---

## 🛠️ Troubleshooting Quick Reference

### Issue: Demo data not loading
```bash
# Check database
psql -U postgres -d hotel_booking -c "SELECT COUNT(*) FROM guests;"

# Re-run seed
cd database/migrations
./run_seed_demo_data.sh
```

### Issue: Hold expires during demo
**Solution:** Work quickly or increase hold duration in config

### Issue: No available rooms
```sql
UPDATE room_inventory 
SET booked_count = 0, tentative_count = 0
WHERE date >= CURRENT_DATE;
```

### Issue: Voucher maxed out
```sql
UPDATE vouchers 
SET current_uses = 0 
WHERE code = 'WELCOME10';
```

**Full Guide:** `DEMO_README.md` → Troubleshooting section

---

## 📖 Related Documentation

### Architecture & Design
- `/docs/architecture/DESIGN.md` - System design
- `/docs/architecture/REQUIREMENTS.md` - Requirements
- `/backend/ARCHITECTURE.md` - Backend architecture

### API Documentation
- `/backend/docs/swagger.yaml` - OpenAPI specification
- `/backend/docs/README.md` - API guide
- `/backend/docs/examples/` - API examples

### User Guides
- `/docs/user-guides/GUEST_GUIDE.md` - Guest features
- `/docs/user-guides/RECEPTIONIST_GUIDE.md` - Staff features
- `/docs/user-guides/HOUSEKEEPER_GUIDE.md` - Housekeeping
- `/docs/user-guides/MANAGER_GUIDE.md` - Manager tools

### Testing
- `/database/tests/` - Integration tests
- `/e2e/` - End-to-end tests
- `/load-tests/` - Load testing
- `/backend/internal/*/test.go` - Unit tests

### Deployment
- `/docs/deployment/PRODUCTION_DEPLOYMENT.md` - Production guide
- `/docker-compose.yml` - Docker setup
- `/scripts/` - Deployment scripts

---

## ✅ Pre-Demo Checklist

### Technical Setup
- [ ] Demo data seeded successfully
- [ ] Backend running (port 8080)
- [ ] Frontend running (port 3000)
- [ ] Database accessible
- [ ] All credentials tested

### Preparation
- [ ] Demo scenarios reviewed
- [ ] Quick reference printed/accessible
- [ ] Backup plan prepared
- [ ] Questions anticipated
- [ ] Time allocated

### Environment
- [ ] Browser cache cleared
- [ ] Notifications disabled
- [ ] Unnecessary tabs closed
- [ ] Screen resolution set (1920x1080)
- [ ] Audio tested (if recording)

### Materials
- [ ] Presentation slides ready
- [ ] Demo script reviewed
- [ ] Quick reference handy
- [ ] Contact information prepared
- [ ] Backup screenshots available

---

## 🎓 Learning Path

### For Beginners
1. Start with `DEMO_README.md`
2. Run seed data script
3. Follow Scenario 1 (Guest Booking)
4. Explore other scenarios
5. Review architecture documentation

### For Presenters
1. Review `PRESENTATION_OUTLINE.md`
2. Practice with `DEMO_SCENARIOS.md`
3. Memorize `DEMO_QUICK_REFERENCE.md`
4. Do dry runs
5. Prepare for Q&A

### For Video Creators
1. Study `VIDEO_DEMO_SCRIPT.md`
2. Practice each scene
3. Set up recording environment
4. Record in segments
5. Edit and publish

### For Trainers
1. Master all scenarios
2. Understand architecture
3. Prepare hands-on exercises
4. Create assessment materials
5. Gather feedback

---

## 📞 Support & Resources

### Documentation
- **Main Docs:** `/docs/README.md`
- **Quick Start:** `/START_HERE.md`
- **API Docs:** `/backend/docs/`
- **User Guides:** `/docs/user-guides/`

### Code
- **Backend:** `/backend/`
- **Frontend:** `/frontend/`
- **Database:** `/database/`
- **Tests:** `/e2e/`, `/load-tests/`

### Help
- **GitHub Issues:** [repository-url]/issues
- **Email:** [your-email]
- **Documentation:** [docs-url]

---

## 🎉 Success Metrics

### Demo Success Indicators
- ✅ All features demonstrated
- ✅ No technical issues
- ✅ Audience engaged
- ✅ Questions answered
- ✅ Positive feedback

### Presentation Success Indicators
- ✅ Clear message delivered
- ✅ Time management good
- ✅ Technical points understood
- ✅ Business value communicated
- ✅ Follow-up interest generated

### Training Success Indicators
- ✅ Participants can use system
- ✅ Concepts understood
- ✅ Questions answered
- ✅ Hands-on practice completed
- ✅ Positive evaluations

---

## 📝 Feedback & Improvement

### After Each Demo
1. Note what worked well
2. Identify areas for improvement
3. Update materials as needed
4. Collect audience feedback
5. Share learnings with team

### Continuous Improvement
1. Keep materials updated
2. Add new scenarios
3. Improve documentation
4. Enhance presentations
5. Refine processes

---

## 🌟 Best Practices

### Before Demo
- Practice multiple times
- Test all features
- Prepare backup plans
- Arrive early
- Stay calm

### During Demo
- Speak clearly
- Maintain eye contact
- Show enthusiasm
- Handle errors gracefully
- Engage audience

### After Demo
- Answer questions
- Provide resources
- Follow up
- Gather feedback
- Thank participants

---

**Last Updated:** [Current Date]
**Version:** 1.0.0
**Status:** Production Ready ✅

**Need Help?** Start with `DEMO_README.md` or contact [your-email]

