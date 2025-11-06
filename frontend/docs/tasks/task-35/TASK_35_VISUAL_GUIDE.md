# Task 35: Inventory Management - Visual Guide

## Overview
This visual guide provides detailed explanations of the inventory management interface with descriptions of UI elements and workflows.

## Page Layout

### Full Page View
```
┌────────────────────────────────────────────────────────────────┐
│ 🏨 ระบบจัดการโรงแรม - ผู้จัดการ          user@email.com [ออก] │
│ [จัดการระดับราคา] [ปฏิทินราคา] [เมทริกซ์ราคา] [จัดการสต็อก*] │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  จัดการสต็อกห้องพัก                                            │
│  จัดการจำนวนห้องที่เปิดขายสำหรับแต่ละวัน                      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Controls Section                                         │  │
│  │ ┌──────────────┬──────────────┬─────────────────────┐   │  │
│  │ │ ประเภทห้อง   │    เดือน     │  แก้ไขแบบกลุ่ม      │   │  │
│  │ │ [Deluxe ▼]   │ [2025-02 ▼]  │  [แก้ไขแบบกลุ่ม]    │   │  │
│  │ └──────────────┴──────────────┴─────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ สีแสดงระดับการจอง                                        │  │
│  │ 🟢 < 30% (ว่างมาก)  🟢 30-50%  🟡 50-70%               │  │
│  │ 🟠 70-90%  🔴 >= 90% (เกือบเต็ม)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Calendar Table                                           │  │
│  │ ┌────────┬──────┬──────┬────────┬──────┬────────┬──────┐│  │
│  │ │ วันที่  │จำนวน│จองแล้ว│กำลังจอง│ ว่าง │ สถานะ  │จัดการ││  │
│  │ ├────────┼──────┼──────┼────────┼──────┼────────┼──────┤│  │
│  │ │ 1 ก.พ. │  20  │  5   │   2    │  13  │ 🟢 35% │[แก้ไข]││  │
│  │ │ 2 ก.พ. │  20  │  8   │   1    │  11  │ 🟢 45% │[แก้ไข]││  │
│  │ │ 3 ก.พ. │  20  │ 12   │   2    │   6  │ 🟡 70% │[แก้ไข]││  │
│  │ │ 4 ก.พ. │  20  │ 15   │   3    │   2  │ 🔴 90% │[แก้ไข]││  │
│  │ └────────┴──────┴──────┴────────┴──────┴────────┴──────┘│  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## UI Components

### 1. Navigation Bar

```
┌────────────────────────────────────────────────────────────┐
│ 🏨 ระบบจัดการโรงแรม - ผู้จัดการ      user@email.com [ออก] │
│ [จัดการระดับราคา] [ปฏิทินราคา] [เมทริกซ์ราคา] [จัดการสต็อก*]│
└────────────────────────────────────────────────────────────┘
```

**Elements:**
- **Logo/Title**: System branding
- **Navigation Links**: Quick access to other manager pages
- **User Info**: Current user email
- **Logout Button**: Sign out functionality
- **Active Indicator**: Current page highlighted

### 2. Page Header

```
┌────────────────────────────────────────────────────────────┐
│  จัดการสต็อกห้องพัก                                        │
│  จัดการจำนวนห้องที่เปิดขายสำหรับแต่ละวัน                  │
└────────────────────────────────────────────────────────────┘
```

**Elements:**
- **Title**: Page name in Thai
- **Description**: Brief explanation of page purpose

### 3. Controls Section

```
┌──────────────────────────────────────────────────────────┐
│ ┌──────────────┬──────────────┬─────────────────────┐   │
│ │ ประเภทห้อง   │    เดือน     │                     │   │
│ │ ┌──────────┐ │ ┌──────────┐ │  ┌───────────────┐  │   │
│ │ │Deluxe ▼  │ │ │2025-02 ▼ │ │  │แก้ไขแบบกลุ่ม  │  │   │
│ │ └──────────┘ │ └──────────┘ │  └───────────────┘  │   │
│ └──────────────┴──────────────┴─────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

**Room Type Selector:**
- Dropdown with all room types
- "ทุกประเภท" option to view all
- Required for calendar display

**Month Picker:**
- Native HTML month input
- Format: YYYY-MM
- Defaults to current month

**Bulk Edit Button:**
- Enabled only when room type selected
- Opens bulk edit modal
- Blue primary button

### 4. Color Legend

```
┌──────────────────────────────────────────────────────────┐
│ สีแสดงระดับการจอง                                        │
│ ┌────┐ < 30% (ว่างมาก)                                  │
│ │🟢  │                                                    │
│ └────┘                                                    │
│ ┌────┐ 30-50%                                            │
│ │🟢  │                                                    │
│ └────┘                                                    │
│ ┌────┐ 50-70%                                            │
│ │🟡  │                                                    │
│ └────┘                                                    │
│ ┌────┐ 70-90%                                            │
│ │🟠  │                                                    │
│ └────┘                                                    │
│ ┌────┐ >= 90% (เกือบเต็ม)                                │
│ │🔴  │                                                    │
│ └────┘                                                    │
└──────────────────────────────────────────────────────────┘
```

**Color Meanings:**
- **Light Green (bg-green-100)**: Very low occupancy, lots of availability
- **Green (bg-green-200)**: Low to moderate occupancy
- **Yellow (bg-yellow-300)**: Moderate occupancy, watch closely
- **Orange (bg-orange-400)**: High occupancy, limited availability
- **Red (bg-red-500)**: Very high occupancy, nearly full

### 5. Validation Error Box

```
┌──────────────────────────────────────────────────────────┐
│ ⚠️ ข้อผิดพลาดในการตรวจสอบ                               │
│                                                           │
│ • 2025-02-05: ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน │
│   (8 ห้อง)                                                │
│ • 2025-02-06: ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน │
│   (10 ห้อง)                                               │
└──────────────────────────────────────────────────────────┘
```

**Appearance:**
- Red background (bg-red-50)
- Red border (border-red-200)
- Warning icon
- List of errors with dates
- Clear, actionable messages

### 6. Calendar Table

```
┌────────────────────────────────────────────────────────────┐
│ ┌────────┬──────┬──────┬────────┬──────┬────────┬──────┐  │
│ │ วันที่  │จำนวน│จองแล้ว│กำลังจอง│ ว่าง │ สถานะ  │จัดการ│  │
│ ├────────┼──────┼──────┼────────┼──────┼────────┼──────┤  │
│ │พ. 1 ก.พ.│  20  │  5   │   2    │  13  │ 🟢 35% │[แก้ไข]│  │
│ │พฤ. 2 ก.พ│  20  │  8   │   1    │  11  │ 🟢 45% │[แก้ไข]│  │
│ │ศ. 3 ก.พ.│  20  │ 12   │   2    │   6  │ 🟡 70% │[แก้ไข]│  │
│ │ส. 4 ก.พ.│  20  │ 15   │   3    │   2  │ 🔴 90% │[แก้ไข]│  │
│ │อา. 5 ก.พ│  20  │ 18   │   1    │   1  │ 🔴 95% │[แก้ไข]│  │
│ └────────┴──────┴──────┴────────┴──────┴────────┴──────┘  │
└────────────────────────────────────────────────────────────┘
```

**Columns:**

1. **วันที่ (Date)**
   - Day of week abbreviation
   - Date in Thai format
   - Example: "พ. 1 ก.พ. 2568"

2. **จำนวนห้อง (Allotment)**
   - Total rooms available for sale
   - Editable value
   - Example: 20

3. **จองแล้ว (Booked)**
   - Confirmed bookings
   - Read-only
   - Example: 5

4. **กำลังจอง (Tentative)**
   - Pending holds
   - Read-only
   - Example: 2

5. **ว่าง (Available)**
   - Calculated: Allotment - Booked - Tentative
   - Read-only
   - Example: 13

6. **สถานะ (Status)**
   - Colored badge
   - Occupancy percentage
   - Visual indicator
   - Example: 🟢 35%

7. **จัดการ (Manage)**
   - Edit button
   - Opens single edit modal
   - Blue text link

**Row Styling:**
- Hover effect (bg-gray-50)
- Alternating row colors (optional)
- Responsive scrolling on mobile

### 7. Single Edit Modal

```
┌─────────────────────────────────────────┐
│  แก้ไขจำนวนห้อง                    [×] │
├─────────────────────────────────────────┤
│                                         │
│  วันที่: พุธ 1 กุมภาพันธ์ 2568          │
│                                         │
│  จำนวนห้อง                              │
│  ┌───────────────────────────────────┐  │
│  │ 20                                │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ปัจจุบัน: จองแล้ว 5, กำลังจอง 2       │
│  ต้องการอย่างน้อย: 7 ห้อง              │
│                                         │
│              ┌────────┐  ┌──────────┐   │
│              │ ยกเลิก │  │  บันทึก  │   │
│              └────────┘  └──────────┘   │
└─────────────────────────────────────────┘
```

**Elements:**
- **Title**: "แก้ไขจำนวนห้อง"
- **Close Button**: X in top right
- **Date Display**: Selected date in Thai
- **Input Field**: Number input for allotment
- **Context Info**: Current bookings and minimum required
- **Cancel Button**: Gray, closes modal
- **Save Button**: Blue, submits update

**Behavior:**
- Opens on "แก้ไข" click
- Pre-fills current allotment
- Validates on submit
- Shows loading state
- Closes on success
- Shows error if validation fails

### 8. Bulk Edit Modal

```
┌─────────────────────────────────────────┐
│  แก้ไขจำนวนห้องแบบกลุ่ม            [×] │
├─────────────────────────────────────────┤
│                                         │
│  วันที่เริ่มต้น                         │
│  ┌───────────────────────────────────┐  │
│  │ 2025-02-01                        │  │
│  └───────────────────────────────────┘  │
│                                         │
│  วันที่สิ้นสุด                          │
│  ┌───────────────────────────────────┐  │
│  │ 2025-02-28                        │  │
│  └───────────────────────────────────┘  │
│                                         │
│  จำนวนห้อง                              │
│  ┌───────────────────────────────────┐  │
│  │ 25                                │  │
│  └───────────────────────────────────┘  │
│                                         │
│  จะอัปเดต 28 วัน                        │
│                                         │
│              ┌────────┐  ┌──────────┐   │
│              │ ยกเลิก │  │  บันทึก  │   │
│              └────────┘  └──────────┘   │
└─────────────────────────────────────────┘
```

**Elements:**
- **Title**: "แก้ไขจำนวนห้องแบบกลุ่ม"
- **Start Date**: Date picker
- **End Date**: Date picker
- **Allotment**: Number input
- **Summary**: Shows number of days to update
- **Cancel Button**: Gray, closes modal
- **Save Button**: Blue, submits bulk update

**Behavior:**
- Opens on "แก้ไขแบบกลุ่ม" click
- Pre-fills with month range
- Validates date range
- Validates each date individually
- Shows all errors if any fail
- Updates only valid dates
- Shows loading state

## Heatmap Color Examples

### Visual Representation

```
┌─────────────────────────────────────────────────────────┐
│ Occupancy Rate Examples                                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  10% Occupancy  →  🟢 bg-green-100                      │
│  ┌──────────────────────────────────────┐              │
│  │ Allotment: 20  Booked: 2  Tentative: 0 │            │
│  │ Available: 18  Status: 🟢 10%          │            │
│  └──────────────────────────────────────┘              │
│                                                         │
│  40% Occupancy  →  🟢 bg-green-200                      │
│  ┌──────────────────────────────────────┐              │
│  │ Allotment: 20  Booked: 6  Tentative: 2 │            │
│  │ Available: 12  Status: 🟢 40%          │            │
│  └──────────────────────────────────────┘              │
│                                                         │
│  60% Occupancy  →  🟡 bg-yellow-300                     │
│  ┌──────────────────────────────────────┐              │
│  │ Allotment: 20  Booked: 10 Tentative: 2 │            │
│  │ Available: 8   Status: 🟡 60%          │            │
│  └──────────────────────────────────────┘              │
│                                                         │
│  80% Occupancy  →  🟠 bg-orange-400 text-white          │
│  ┌──────────────────────────────────────┐              │
│  │ Allotment: 20  Booked: 14 Tentative: 2 │            │
│  │ Available: 4   Status: 🟠 80%          │            │
│  └──────────────────────────────────────┘              │
│                                                         │
│  95% Occupancy  →  🔴 bg-red-500 text-white             │
│  ┌──────────────────────────────────────┐              │
│  │ Allotment: 20  Booked: 18 Tentative: 1 │            │
│  │ Available: 1   Status: 🔴 95%          │            │
│  └──────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

## User Workflows

### Workflow 1: View Inventory

```
┌─────────────┐
│ 1. Select   │
│ Room Type   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 2. Calendar │
│ Loads       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 3. Review   │
│ Heatmap     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 4. Identify │
│ Issues      │
└─────────────┘
```

### Workflow 2: Single Date Edit

```
┌─────────────┐
│ 1. Find     │
│ Date        │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 2. Click    │
│ แก้ไข       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 3. Modal    │
│ Opens       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 4. Enter    │
│ New Value   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 5. Click    │
│ บันทึก      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 6. Validate │
└──────┬──────┘
       │
       ├─── ❌ Error ───┐
       │                │
       │                ▼
       │         ┌─────────────┐
       │         │ Show Error  │
       │         │ Stay Open   │
       │         └─────────────┘
       │
       └─── ✅ Success ─┐
                        │
                        ▼
                 ┌─────────────┐
                 │ Save & Close│
                 │ Update UI   │
                 └─────────────┘
```

### Workflow 3: Bulk Edit

```
┌─────────────┐
│ 1. Select   │
│ Room Type   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 2. Click    │
│ Bulk Edit   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 3. Modal    │
│ Opens       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 4. Set Date │
│ Range       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 5. Enter    │
│ Allotment   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 6. Click    │
│ บันทึก      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 7. Validate │
│ All Dates   │
└──────┬──────┘
       │
       ├─── ❌ Errors ──┐
       │                │
       │                ▼
       │         ┌─────────────┐
       │         │ Show All    │
       │         │ Errors      │
       │         │ Stay Open   │
       │         └─────────────┘
       │
       └─── ✅ Success ─┐
                        │
                        ▼
                 ┌─────────────┐
                 │ Save All &  │
                 │ Close       │
                 │ Update UI   │
                 └─────────────┘
```

## Responsive Design

### Desktop View (> 1024px)
```
┌────────────────────────────────────────────────────────┐
│ Full width layout                                      │
│ All columns visible                                    │
│ Controls in single row                                 │
│ Table fits without scrolling                           │
└────────────────────────────────────────────────────────┘
```

### Tablet View (768px - 1024px)
```
┌──────────────────────────────────────┐
│ Slightly narrower                    │
│ All columns still visible            │
│ Controls may wrap                    │
│ Table may scroll horizontally        │
└──────────────────────────────────────┘
```

### Mobile View (< 768px)
```
┌────────────────────┐
│ Narrow layout      │
│ Controls stack     │
│ vertically         │
│ Table scrolls      │
│ horizontally       │
│ Touch-friendly     │
│ buttons            │
└────────────────────┘
```

## Accessibility Features

### Keyboard Navigation
```
Tab Order:
1. Room Type Dropdown
2. Month Picker
3. Bulk Edit Button
4. Each Edit Button (in order)
5. Modal Fields (when open)
6. Modal Buttons
```

### Screen Reader Announcements
```
"Room type selector, Deluxe Room selected"
"Month picker, February 2025"
"Edit button for February 1st"
"Allotment input, current value 20"
"Validation error: Cannot reduce below 7 rooms"
"Update successful"
```

### Focus Indicators
```
All interactive elements have visible focus:
- Blue outline on focus
- 2px solid border
- Sufficient contrast
```

## Color Contrast Ratios

### Text on Backgrounds
- Black on white: 21:1 (AAA)
- Gray-700 on white: 7:1 (AAA)
- White on blue-600: 4.5:1 (AA)
- White on red-500: 4.5:1 (AA)
- White on orange-400: 4.5:1 (AA)

### Heatmap Colors
- All meet WCAG AA standards
- Additional percentage text for clarity
- Not relying on color alone

## Loading States

### Initial Load
```
┌────────────────────────────────────┐
│                                    │
│         ⏳ Loading...              │
│     [Spinning animation]           │
│   กำลังโหลดข้อมูล...               │
│                                    │
└────────────────────────────────────┘
```

### Saving State
```
Modal Button:
┌──────────────────┐
│ กำลังบันทึก...   │  ← Disabled, shows spinner
└──────────────────┘
```

## Success States

### After Save
```
✅ Calendar updates immediately
✅ Modal closes
✅ New values visible
✅ Heatmap colors update
✅ No page reload needed
```

## Error States

### Validation Error
```
┌─────────────────────────────────────────┐
│ ⚠️ ข้อผิดพลาดในการตรวจสอบ              │
│                                         │
│ • 2025-02-05: ไม่สามารถลดจำนวนห้อง     │
│   ต่ำกว่าการจองปัจจุบัน (8 ห้อง)       │
└─────────────────────────────────────────┘
```

### Network Error
```
┌─────────────────────────────────────────┐
│ ❌ เกิดข้อผิดพลาด                       │
│                                         │
│ ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์        │
│ กรุณาลองใหม่อีกครั้ง                    │
└─────────────────────────────────────────┘
```

## Tips for Users

### Visual Cues
- 🟢 Green = Safe, plenty of availability
- 🟡 Yellow = Monitor, moderate demand
- 🔴 Red = Action needed, high demand

### Best Practices
- Review red dates first
- Increase capacity for high-demand periods
- Use bulk edit for efficiency
- Check validation errors carefully
- Monitor trends over time

## Related Documentation

- [Task 35 Index](./TASK_35_INDEX.md)
- [Task 35 Quick Start](./TASK_35_QUICKSTART.md)
- [Task 35 Verification](./TASK_35_VERIFICATION.md)
- [Task 35 Summary](./TASK_35_SUMMARY.md)
