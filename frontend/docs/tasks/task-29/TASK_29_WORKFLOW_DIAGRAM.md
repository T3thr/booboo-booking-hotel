# Task 29: Housekeeping Workflow Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Housekeeping System                       │
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │   Task List      │         │   Inspection     │         │
│  │   /housekeeping  │◄───────►│   /inspection    │         │
│  └──────────────────┘         └──────────────────┘         │
│           │                            │                     │
│           │                            │                     │
│           ▼                            ▼                     │
│  ┌─────────────────────────────────────────────┐           │
│  │         Backend API (Task 26)                │           │
│  │  - GET /housekeeping/tasks                   │           │
│  │  - PUT /housekeeping/rooms/:id/status        │           │
│  │  - POST /housekeeping/rooms/:id/inspect      │           │
│  │  - POST /housekeeping/rooms/:id/maintenance  │           │
│  └─────────────────────────────────────────────┘           │
│                       │                                      │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────┐           │
│  │         PostgreSQL Database                  │           │
│  │  - rooms table                               │           │
│  │  - housekeeping_status field                 │           │
│  └─────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## Status Workflow

### Housekeeper Workflow

```
┌─────────┐
│  Dirty  │  Room needs cleaning
└────┬────┘
     │ Click "→ กำลังทำความสะอาด"
     ▼
┌──────────┐
│ Cleaning │  Housekeeper is cleaning
└────┬─────┘
     │ Click "→ สะอาดแล้ว"
     ▼
┌─────────┐
│  Clean  │  Ready for inspection
└────┬────┘
     │
     │ ┌──────────────────────────┐
     │ │ Alternative: Report Issue │
     │ └──────────────────────────┘
     │              │
     │              ▼
     │    ┌──────────────────────┐
     │    │ MaintenanceRequired  │
     │    └──────────────────────┘
     │
     ▼
┌────────────┐
│ Inspection │  Supervisor reviews
└────────────┘
```

### Supervisor Workflow

```
┌─────────┐
│  Clean  │  Room ready for inspection
└────┬────┘
     │
     ├─────────────────┬─────────────────┐
     │                 │                 │
     │ Approve         │ Reject          │
     ▼                 ▼                 │
┌───────────┐    ┌─────────┐           │
│ Inspected │    │  Dirty  │◄──────────┘
└───────────┘    └─────────┘
  (Ready for       (Back to
   check-in)        cleaning)
```

## Page Flow

### Task List Page Flow

```
┌──────────────────────────────────────────────────────────┐
│                    Task List Page                         │
│                   /housekeeping                           │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Summary Dashboard                        │    │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │    │
│  │  │Dirty │ │Clean │ │Clean │ │Insp. │ │Maint.│ │    │
│  │  │  3   │ │ing 2 │ │  4   │ │  5   │ │  1   │ │    │
│  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Filters & Search                         │    │
│  │  [Search: ___________]                          │    │
│  │  [All] [Dirty] [Cleaning] [Clean]              │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Task Cards                               │    │
│  │  ┌──────────────────────────────────────────┐  │    │
│  │  │ Room 101 - Deluxe        [Dirty]         │  │    │
│  │  │ Vacant | Est: 30 min                     │  │    │
│  │  │ [→ กำลังทำความสะอาด] [รายงานปัญหา]      │  │    │
│  │  └──────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────┐  │    │
│  │  │ Room 102 - Standard      [Cleaning]      │  │    │
│  │  │ Vacant | Est: 25 min                     │  │    │
│  │  │ [→ สะอาดแล้ว] [รายงานปัญหา]             │  │    │
│  │  └──────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### Inspection Page Flow

```
┌──────────────────────────────────────────────────────────┐
│                  Inspection Page                          │
│              /housekeeping/inspection                     │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Summary Card                             │    │
│  │  ห้องที่รอตรวจสอบ                    [4]        │    │
│  │  ห้องที่ทำความสะอาดเสร็จแล้วและรอการตรวจสอบ    │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Search                                   │    │
│  │  [Search: ___________]                          │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Room Cards                               │    │
│  │  ┌──────────────────────────────────────────┐  │    │
│  │  │ Room 103 - Deluxe        [Clean]         │  │    │
│  │  │ Vacant | Cleaned: 28 min                 │  │    │
│  │  │ [✓ อนุมัติ] [✗ ปฏิเสธ]                   │  │    │
│  │  └──────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────┐  │    │
│  │  │ Room 104 - Standard      [Clean]         │  │    │
│  │  │ Vacant | Cleaned: 22 min                 │  │    │
│  │  │ [✓ อนุมัติ] [✗ ปฏิเสธ]                   │  │    │
│  │  └──────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

## Modal Interactions

### Maintenance Report Modal

```
┌────────────────────────────────────────┐
│  รายงานปัญหาห้อง 101                   │
├────────────────────────────────────────┤
│                                        │
│  รายละเอียดปัญหา                       │
│  ┌────────────────────────────────┐   │
│  │ Air conditioning not working   │   │
│  │                                │   │
│  │                                │   │
│  └────────────────────────────────┘   │
│                                        │
│  [บันทึก]  [ยกเลิก]                   │
└────────────────────────────────────────┘
```

### Inspection Modal (Approve)

```
┌────────────────────────────────────────┐
│  อนุมัติห้อง 103                       │
├────────────────────────────────────────┤
│                                        │
│  หมายเหตุ (ถ้ามี)                      │
│  ┌────────────────────────────────┐   │
│  │ Room is perfect                │   │
│  │                                │   │
│  │                                │   │
│  └────────────────────────────────┘   │
│                                        │
│  [ยืนยันการอนุมัติ]  [ยกเลิก]         │
└────────────────────────────────────────┘
```

### Inspection Modal (Reject)

```
┌────────────────────────────────────────┐
│  ปฏิเสธห้อง 104                        │
├────────────────────────────────────────┤
│                                        │
│  เหตุผลในการปฏิเสธ                     │
│  ┌────────────────────────────────┐   │
│  │ Bathroom needs more cleaning   │   │
│  │                                │   │
│  │                                │   │
│  └────────────────────────────────┘   │
│                                        │
│  [ยืนยันการปฏิเสธ]  [ยกเลิก]          │
└────────────────────────────────────────┘
```

## User Journey

### Housekeeper Journey

```
1. Login
   │
   ▼
2. View Task List
   │
   ├─► Filter by status
   ├─► Search for room
   └─► See priority tasks
   │
   ▼
3. Start Cleaning
   │
   └─► Click "→ กำลังทำความสะอาด"
   │
   ▼
4. Clean Room
   │
   ├─► If issue found
   │   └─► Report maintenance
   │       └─► Enter description
   │           └─► Submit
   │
   └─► If cleaning complete
       └─► Click "→ สะอาดแล้ว"
       │
       ▼
5. Move to Next Task
   │
   └─► Repeat from step 2
```

### Supervisor Journey

```
1. Login
   │
   ▼
2. View Inspection Queue
   │
   ├─► See all clean rooms
   └─► Search for specific room
   │
   ▼
3. Inspect Room
   │
   ├─► If room meets standards
   │   └─► Click "✓ อนุมัติ"
   │       └─► Add optional notes
   │           └─► Confirm
   │               └─► Room → Inspected
   │
   └─► If room needs more work
       └─► Click "✗ ปฏิเสธ"
           └─► Enter reason
               └─► Confirm
                   └─► Room → Dirty
   │
   ▼
4. Move to Next Room
   │
   └─► Repeat from step 2
```

## Data Flow

### Status Update Flow

```
User Action
    │
    ▼
Frontend (React)
    │
    ├─► Update UI optimistically
    │
    ▼
API Call (PUT /rooms/:id/status)
    │
    ▼
Backend (Go)
    │
    ├─► Validate status transition
    ├─► Check permissions
    │
    ▼
Database (PostgreSQL)
    │
    ├─► Update rooms.housekeeping_status
    ├─► Record timestamp
    │
    ▼
Response
    │
    ▼
Frontend
    │
    ├─► Update cache
    ├─► Refresh task list
    └─► Show success message
```

### Real-time Update Flow

```
Timer (30 seconds)
    │
    ▼
React Query
    │
    ├─► Fetch latest data
    │
    ▼
API Call (GET /housekeeping/tasks)
    │
    ▼
Backend
    │
    ├─► Query database
    ├─► Calculate summary
    │
    ▼
Response
    │
    ▼
Frontend
    │
    ├─► Update cache
    ├─► Re-render components
    └─► Maintain user state (filter, search)
```

## Component Hierarchy

```
HousekeepingPage
├── Summary Dashboard
│   ├── Status Card (Dirty)
│   ├── Status Card (Cleaning)
│   ├── Status Card (Clean)
│   ├── Status Card (Inspected)
│   └── Status Card (Maintenance)
├── Filters & Search
│   ├── Search Input
│   └── Filter Buttons
├── Task List
│   └── Task Card (multiple)
│       ├── Room Info
│       ├── Status Badge
│       ├── Priority Badge
│       ├── Status Update Button
│       └── Report Maintenance Button
└── Maintenance Modal
    ├── Description Input
    ├── Submit Button
    └── Cancel Button

InspectionPage
├── Summary Card
├── Search Input
├── Room List
│   └── Room Card (multiple)
│       ├── Room Info
│       ├── Status Badge
│       ├── Approve Button
│       └── Reject Button
└── Inspection Modal
    ├── Notes Input
    ├── Confirm Button
    └── Cancel Button
```

## State Management

```
React Query Cache
├── ['housekeeping', 'tasks']
│   └── { tasks: [], summary: {} }
├── ['housekeeping', 'inspection']
│   └── [clean rooms]
└── Mutations
    ├── updateRoomStatus
    ├── inspectRoom
    └── reportMaintenance

Local State (useState)
├── filter: FilterStatus
├── searchTerm: string
├── maintenanceModal: { isOpen, roomId, roomNumber }
├── maintenanceDescription: string
├── inspectionModal: { isOpen, roomId, roomNumber, approved }
└── notes: string
```

## Error Handling Flow

```
User Action
    │
    ▼
API Call
    │
    ├─► Success
    │   └─► Update UI
    │       └─► Show success message
    │
    └─► Error
        │
        ├─► Network Error
        │   └─► Show "Network error" message
        │
        ├─► 401 Unauthorized
        │   └─► Redirect to login
        │
        ├─► 400 Bad Request
        │   └─► Show validation error
        │
        └─► 500 Server Error
            └─► Show "Server error" message
```

## Responsive Breakpoints

```
Mobile (< 640px)
├── 2-column summary grid
├── Stacked task cards
├── Full-width buttons
└── Vertical layout

Tablet (640px - 1024px)
├── 3-column summary grid
├── Optimized task cards
├── Side-by-side buttons
└── Balanced layout

Desktop (> 1024px)
├── 5-column summary grid
├── Horizontal task cards
├── Inline buttons
└── Maximum width container
```

---

This diagram provides a visual overview of the housekeeping system workflow, user journeys, and technical architecture implemented in Task 29.
