# Video Demo Script - Hotel Reservation System
## 5-Minute Demonstration

---

## Pre-Recording Checklist

- [ ] Run seed data script
- [ ] Clear browser cache and cookies
- [ ] Test all credentials
- [ ] Close unnecessary applications
- [ ] Set screen resolution to 1920x1080
- [ ] Enable "Do Not Disturb" mode
- [ ] Test microphone and audio
- [ ] Prepare backup recording
- [ ] Have water nearby

---

## Video Structure

**Total Duration:** 5 minutes
- Introduction: 30 seconds
- Guest Booking: 1 minute 30 seconds
- Staff Operations: 1 minute 30 seconds
- Manager Features: 1 minute
- Conclusion: 30 seconds

---

## Scene 1: Introduction (0:00 - 0:30)

### Visual
- Show title screen with system logo
- Fade to homepage

### Script
```
"Hello! Welcome to the Hotel Reservation System demonstration.

This is a full-stack web application built with Next.js, Go, and PostgreSQL,
designed to solve real-world problems in hotel management.

In the next 5 minutes, I'll show you how this system handles:
- Guest bookings with race condition prevention
- Staff operations with real-time updates
- And manager tools for pricing and analytics

Let's get started!"
```

### Actions
- Speak clearly and enthusiastically
- Show confidence
- Smile (if on camera)

---

## Scene 2: Guest Booking Flow (0:30 - 2:00)

### Part A: Room Search (0:30 - 0:50)

### Visual
- Homepage with search form

### Script
```
"First, let's see the guest experience. I'm searching for a room
for 2 guests, checking in 7 days from now, for a 3-night stay."
```

### Actions
1. Fill in search form:
   - Check-in: [7 days from today]
   - Check-out: [10 days from today]
   - Guests: 2
2. Click "Search"
3. Wait for results

### Script (continued)
```
"The system instantly shows available room types with real-time pricing.
Notice how each room displays amenities, capacity, and the total cost
calculated across all nights."
```

### Part B: Booking Creation (0:50 - 1:20)

### Visual
- Room search results → Guest info form

### Script
```
"I'll select the Deluxe Room. When I click 'Book Now', the system
creates a 15-minute hold on this room, preventing others from booking it
while I complete my reservation."
```

### Actions
1. Click "Book Now" on Deluxe Room
2. Fill in guest information:
   - Primary: John Doe
   - Secondary: Jane Doe
3. Click "Continue"

### Script (continued)
```
"Notice the countdown timer at the top - I have 15 minutes to complete
this booking. Now let me apply a discount voucher."
```

### Actions
1. Enter voucher code: WELCOME10
2. Click "Apply"
3. Show discount applied

### Part C: Confirmation (1:20 - 2:00)

### Visual
- Booking summary → Confirmation page

### Script
```
"The voucher gives me 10% off. I can see the complete breakdown:
room charges per night, discount, and total amount.

The cancellation policy is clearly displayed - this is a snapshot
that won't change even if the hotel updates their policy later.

Let me confirm this booking."
```

### Actions
1. Review summary
2. Click "Confirm & Pay"
3. Show confirmation message
4. Show booking ID

### Script (continued)
```
"Perfect! The booking is confirmed. I receive a confirmation email
with all details, and the room inventory is automatically updated."
```

---

## Scene 3: Staff Operations (2:00 - 3:30)

### Part A: Check-in (2:00 - 2:40)

### Visual
- Login as receptionist → Staff dashboard

### Script
```
"Now let's switch to the staff perspective. I'm logging in as a
receptionist to handle today's arrivals."
```

### Actions
1. Logout from guest account
2. Login with staff credentials
3. Navigate to "Today's Arrivals"

### Script (continued)
```
"Here's our arrivals list. I can see all guests checking in today,
their room types, and booking details.

Let me check in this guest. The system shows me only rooms that are
both vacant AND clean or inspected - ensuring we never assign a
dirty room."
```

### Actions
1. Select a guest
2. Click "Check In"
3. Show available rooms (filtered)
4. Select room 302
5. Click "Confirm Check-in"

### Script (continued)
```
"Done! The room status instantly updates to 'Occupied', and the
booking status changes to 'CheckedIn'. This update is visible
to all departments in real-time."
```

### Part B: Housekeeping (2:40 - 3:30)

### Visual
- Switch to housekeeper view

### Script
```
"Let me show you the housekeeping workflow. Housekeepers see a
prioritized task list of rooms needing attention."
```

### Actions
1. Navigate to Housekeeping Dashboard
2. Show task list

### Script (continued)
```
"When a housekeeper starts cleaning, they update the status.
Watch how this works."
```

### Actions
1. Select room 107 (Dirty)
2. Click "Start Cleaning"
3. Show status change to "Cleaning"
4. Click "Mark as Clean"
5. Show status change to "Clean"

### Script (continued)
```
"Now a supervisor can inspect this room. Once inspected, it's
marked as ready for the next guest. This two-step process
ensures quality control."
```

### Actions
1. Click "Inspect" on room 107
2. Show status change to "Inspected"
3. Show room now appears in available rooms for check-in

---

## Scene 4: Manager Features (3:30 - 4:30)

### Part A: Pricing Management (3:30 - 4:00)

### Visual
- Login as manager → Pricing dashboard

### Script
```
"Finally, let's look at manager tools. The pricing calendar shows
90 days with color-coded rate tiers."
```

### Actions
1. Navigate to Pricing Calendar
2. Show calendar view

### Script (continued)
```
"Managers can easily update pricing for date ranges. For example,
I'll change next weekend to 'High Season' pricing."
```

### Actions
1. Select next weekend dates
2. Change tier to "High Season"
3. Click "Apply"
4. Show calendar update

### Part B: Reports (4:00 - 4:30)

### Visual
- Navigate to Reports

### Script
```
"The reporting dashboard provides key business insights.
Here's the occupancy report showing our performance over
the last 30 days."
```

### Actions
1. Click "Occupancy Report"
2. Show graph
3. Highlight key metrics

### Script (continued)
```
"We can see average occupancy of 65%, peak days, and trends.
The revenue report breaks down income by room type and shows
important metrics like ADR and RevPAR.

All reports can be exported to CSV for further analysis."
```

### Actions
1. Navigate to Revenue Report
2. Show charts
3. Click "Export to CSV"

---

## Scene 5: Conclusion (4:30 - 5:00)

### Visual
- Return to homepage or show architecture diagram

### Script
```
"So that's the Hotel Reservation System in action!

We've seen how it handles:
- Guest bookings with automatic hold mechanisms
- Real-time staff operations across departments
- And powerful manager tools for pricing and analytics

The system is built on solid foundations with PostgreSQL stored
procedures ensuring data integrity, preventing race conditions,
and maintaining complete audit trails.

All the code, documentation, and deployment guides are available
in the repository. Thank you for watching!"
```

### Visual
- Show final slide with:
  - GitHub link
  - Documentation link
  - Contact information

---

## Recording Tips

### Technical Setup
1. **Screen Recording:**
   - Use OBS Studio or similar
   - Record at 1920x1080, 30fps
   - Enable system audio
   - Use high-quality microphone

2. **Browser Setup:**
   - Use Chrome or Firefox
   - Zoom to 100%
   - Hide bookmarks bar
   - Close unnecessary tabs
   - Disable notifications

3. **Audio:**
   - Use external microphone if possible
   - Record in quiet environment
   - Test audio levels
   - Speak clearly and at moderate pace

### Recording Process
1. **Do a Dry Run:**
   - Practice entire script
   - Time each section
   - Identify potential issues
   - Adjust pace as needed

2. **Record in Segments:**
   - Record each scene separately
   - Easier to fix mistakes
   - Better quality control
   - Less pressure

3. **Multiple Takes:**
   - Record each segment 2-3 times
   - Choose best take
   - Don't worry about perfection
   - Natural is better than perfect

### Post-Production
1. **Editing:**
   - Cut out mistakes and pauses
   - Add transitions between scenes
   - Include background music (optional)
   - Add text overlays for key points

2. **Enhancements:**
   - Zoom in on important details
   - Highlight cursor for clarity
   - Add annotations
   - Include captions (accessibility)

3. **Export:**
   - Format: MP4 (H.264)
   - Resolution: 1920x1080
   - Bitrate: 5-10 Mbps
   - Audio: AAC, 192 kbps

---

## Alternative Scripts

### 3-Minute Version
- Skip housekeeping section
- Combine check-in and reports
- Faster pace

### 10-Minute Version
- Add technical deep dive
- Show database operations
- Demonstrate error handling
- Include more features

### Silent Version (with captions)
- Focus on visual demonstration
- Add text overlays
- Use arrows and highlights
- Background music only

---

## Troubleshooting

### Common Issues

**Issue:** Demo data not showing
- **Solution:** Run seed script before recording

**Issue:** Slow performance during recording
- **Solution:** Close other applications, reduce recording quality

**Issue:** Audio quality poor
- **Solution:** Use external mic, reduce background noise

**Issue:** Forgot to show something
- **Solution:** Record additional segment, splice in editing

**Issue:** Made a mistake
- **Solution:** Pause, restart from last good point, edit later

---

## Checklist for Final Video

- [ ] Clear audio throughout
- [ ] No background noise
- [ ] Smooth transitions
- [ ] All features demonstrated
- [ ] No errors or bugs shown
- [ ] Proper pacing (not too fast/slow)
- [ ] Professional appearance
- [ ] Captions added (optional)
- [ ] Intro and outro included
- [ ] Contact information displayed
- [ ] File size reasonable (<100MB)
- [ ] Uploaded to platform
- [ ] Link tested and working

---

## Distribution

### Where to Share
1. **GitHub Repository:**
   - Add to README
   - Include in releases
   - Link in documentation

2. **Video Platforms:**
   - YouTube (public/unlisted)
   - Vimeo
   - Google Drive (for sharing)

3. **Presentation:**
   - Embed in slides
   - Show during presentation
   - Backup if live demo fails

### Video Description Template
```
Hotel Reservation System - Full Demo

A comprehensive demonstration of a full-stack hotel management system
built with Next.js 16, Go, and PostgreSQL.

Features demonstrated:
✅ Guest booking with race condition prevention
✅ Staff check-in and housekeeping workflows
✅ Manager pricing and reporting tools
✅ Real-time updates across all modules

Technology Stack:
- Frontend: Next.js 16, TypeScript, Tailwind CSS
- Backend: Go, Gin Framework
- Database: PostgreSQL 15+

Links:
📚 Documentation: [link]
💻 Source Code: [link]
🌐 Live Demo: [link]

Timestamps:
0:00 - Introduction
0:30 - Guest Booking Flow
2:00 - Staff Operations
3:30 - Manager Features
4:30 - Conclusion
```

