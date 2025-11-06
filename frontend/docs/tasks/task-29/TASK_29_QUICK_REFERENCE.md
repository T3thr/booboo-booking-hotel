# Task 29: Housekeeper Task List - Quick Reference

## Pages

### 1. Housekeeping Task List
**URL:** `/housekeeping`
**Role:** Housekeeper
**Purpose:** Manage cleaning tasks and update room status

### 2. Room Inspection
**URL:** `/housekeeping/inspection`
**Role:** Housekeeper (Supervisor)
**Purpose:** Inspect and approve cleaned rooms

## Key Features

### Task List Page
- View all housekeeping tasks
- Filter by status (All, Dirty, Cleaning, Clean)
- Search by room number or type
- Update room status with one click
- Report maintenance issues
- Auto-refresh every 30 seconds

### Inspection Page
- View rooms ready for inspection (Clean status)
- Approve rooms (Clean → Inspected)
- Reject rooms (Clean → Dirty)
- Add notes/reasons for decisions

## Status Workflow

### Housekeeper Actions
```
Dirty → [Start Cleaning] → Cleaning
Cleaning → [Finish Cleaning] → Clean
Any Status → [Report Issue] → MaintenanceRequired
```

### Supervisor Actions
```
Clean → [Approve] → Inspected
Clean → [Reject] → Dirty (with reason)
```

## API Endpoints

### Get Tasks
```
GET /api/housekeeping/tasks
Response: { tasks: [], total_tasks: 0, summary: {} }
```

### Update Status
```
PUT /api/housekeeping/rooms/:id/status
Body: { status: "Cleaning" | "Clean" }
```

### Inspect Room
```
POST /api/housekeeping/rooms/:id/inspect
Body: { approved: true/false, notes: "..." }
```

### Report Maintenance
```
POST /api/housekeeping/rooms/:id/maintenance
Body: { description: "..." }
```

## UI Components

### Status Badge Colors
- 🔴 Dirty (Red)
- 🟡 Cleaning (Yellow)
- 🟢 Clean (Green)
- 🔵 Inspected (Blue)
- 🟠 MaintenanceRequired (Orange)

### Priority Indicators
- High priority (>5): Red "ด่วน" badge
- Normal priority: No badge

## Common Actions

### Update Room Status
1. Find room in task list
2. Click status button (e.g., "→ กำลังทำความสะอาด")
3. Status updates automatically
4. Task list refreshes

### Report Maintenance
1. Find room in task list
2. Click "รายงานปัญหา" button
3. Enter issue description
4. Click "บันทึก"
5. Room status changes to MaintenanceRequired

### Inspect Room
1. Go to Inspection page
2. Find room with Clean status
3. Click "✓ อนุมัติ" or "✗ ปฏิเสธ"
4. Add notes (optional for approve, recommended for reject)
5. Confirm action

## Filters & Search

### Status Filters
- **ทั้งหมด** - Show all tasks
- **รอทำความสะอาด** - Show Dirty rooms
- **กำลังทำความสะอาด** - Show Cleaning rooms
- **สะอาดแล้ว** - Show Clean rooms

### Search
- Search by room number (e.g., "101")
- Search by room type (e.g., "Deluxe")
- Case-insensitive
- Real-time filtering

## Summary Dashboard

### Task Counts
- **รอทำความสะอาด** - Dirty count
- **กำลังทำความสะอาด** - Cleaning count
- **สะอาดแล้ว** - Clean count
- **ตรวจสอบแล้ว** - Inspected count
- **ต้องซ่อมบำรุง** - MaintenanceRequired count

## Troubleshooting

### Tasks Not Loading
- Check network connection
- Verify authentication token
- Check backend API status
- Look for error messages

### Status Update Failed
- Verify room is in correct current status
- Check for invalid status transitions
- Ensure room exists
- Check user permissions

### Auto-refresh Not Working
- Check React Query configuration
- Verify refetchInterval is set (30000ms)
- Check browser console for errors

## Best Practices

### For Housekeepers
1. Start cleaning by updating status to "Cleaning"
2. Mark as "Clean" only when fully finished
3. Report maintenance issues immediately
4. Check priority tasks first (marked "ด่วน")

### For Supervisors
1. Inspect rooms promptly after cleaning
2. Provide clear rejection reasons
3. Approve only if room meets standards
4. Check all areas before approving

## Keyboard Shortcuts

### Navigation
- Tab - Move between elements
- Enter - Activate buttons
- Esc - Close modals

## Mobile Usage

### Responsive Features
- Stacked layout on small screens
- Full-width buttons
- Touch-friendly tap targets
- Optimized spacing

## Performance Tips

### Optimize Loading
- Use filters to reduce visible tasks
- Search for specific rooms
- Auto-refresh handles updates

### Network Efficiency
- Tasks cached by React Query
- Only changed data refetched
- Optimistic updates for better UX

## Related Documentation

- [Backend Housekeeping Module](../../backend/HOUSEKEEPING_MODULE_REFERENCE.md)
- [Task 26 Summary](../../backend/TASK_26_SUMMARY.md)
- [API Client Reference](./API_CLIENT_REFERENCE.md)
- [Requirements](../../docs/architecture/REQUIREMENTS.md)

## Quick Links

### Development
```bash
# Run frontend
cd frontend
npm run dev

# Run backend
cd backend
make run

# Run tests
cd frontend
npm test
```

### Testing URLs
- Task List: http://localhost:3000/housekeeping
- Inspection: http://localhost:3000/housekeeping/inspection

## Support

### Common Issues
1. **401 Unauthorized** - Login again
2. **403 Forbidden** - Check user role
3. **404 Not Found** - Verify backend is running
4. **500 Server Error** - Check backend logs

### Debug Mode
- Open browser console (F12)
- Check Network tab for API calls
- Look for error messages
- Verify request/response data
