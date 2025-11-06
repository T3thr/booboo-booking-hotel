# Task 35: Inventory Management Page - Index

## Overview
This document provides an index of all documentation related to Task 35: สร้างหน้า Manager - Inventory Management.

## Task Description
Create a comprehensive inventory management page for hotel managers to control room allotments with calendar view, heatmap visualization, and both single and bulk editing capabilities.

## Documentation Files

1. **TASK_35_INDEX.md** (this file)
   - Overview and navigation for all Task 35 documentation

2. **TASK_35_QUICKSTART.md**
   - Quick start guide for using the inventory management page
   - Step-by-step instructions for common operations

3. **TASK_35_VERIFICATION.md**
   - Testing checklist and verification steps
   - Manual testing procedures

4. **TASK_35_SUMMARY.md**
   - Implementation summary
   - Technical details and architecture

5. **TASK_35_VISUAL_GUIDE.md**
   - Visual guide with screenshots and UI explanations
   - Heatmap color coding reference

## Key Features Implemented

### 1. Calendar View
- Monthly calendar display of inventory
- Shows allotment, booked, tentative, and available counts
- Easy navigation between months

### 2. Heatmap Visualization
- Color-coded occupancy rates
- 5-level color scheme (green to red)
- Visual indication of booking pressure

### 3. Single Date Editing
- Click-to-edit functionality
- Real-time validation
- Prevents reducing below current bookings

### 4. Bulk Editing
- Date range selection
- Apply same allotment to multiple dates
- Batch validation and error reporting

### 5. Validation
- Prevents allotment below booked + tentative counts
- Clear error messages
- Date-specific error reporting

## Requirements Covered

This implementation addresses requirements 13.1-13.7:

- **13.1**: Manager can access inventory management
- **13.2**: Display RoomInventory for 365 days ahead
- **13.3**: Validate Allotment >= (BookedCount + TentativeCount)
- **13.4**: Reject updates with clear error messages
- **13.5**: INSERT or UPDATE RoomInventory
- **13.6**: Display Allotment, BookedCount, TentativeCount, Available
- **13.7**: Heatmap calendar view with color coding

## File Structure

```
frontend/src/app/(manager)/inventory/
└── page.tsx                    # Main inventory management page

frontend/
├── TASK_35_INDEX.md           # This file
├── TASK_35_QUICKSTART.md      # Quick start guide
├── TASK_35_VERIFICATION.md    # Testing checklist
├── TASK_35_SUMMARY.md         # Implementation summary
└── TASK_35_VISUAL_GUIDE.md    # Visual guide
```

## API Endpoints Used

### GET /api/inventory
- Fetch inventory data for date range
- Query params: room_type_id, start_date, end_date

### PUT /api/inventory
- Update inventory allotments
- Body: Array of { room_type_id, date, allotment }

### GET /api/rooms/types
- Fetch all room types for selector

## Related Tasks

- **Task 31**: Backend Inventory Management Module
- **Task 30**: Backend Pricing Management Module
- **Task 34**: Frontend Pricing Management Pages

## Next Steps

After completing this task:
1. Test all inventory management features
2. Verify validation rules work correctly
3. Test bulk updates with various date ranges
4. Proceed to Task 36: Manager Dashboard & Reports

## Quick Links

- [Backend Inventory Module Reference](../backend/INVENTORY_MODULE_REFERENCE.md)
- [Manager Layout](./src/app/(manager)/layout.tsx)
- [Inventory Hook](./src/hooks/use-inventory.ts)
- [API Client](./src/lib/api.ts)
