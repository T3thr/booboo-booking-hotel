# Frontend Documentation

> **Next.js 16 Frontend Documentation Hub**

## 📋 Overview

This directory contains comprehensive documentation for the Next.js 16 frontend application, including setup guides, component references, and feature documentation.

## 📁 Documentation Structure

```
frontend/docs/
├── README.md                      # This file
├── SETUP.md                       # Setup guide
├── QUICK_REFERENCE.md             # Quick reference
│
├── auth/                          # Authentication
│   ├── nextauth-setup.md
│   ├── nextauth-flow.md
│   └── nextauth-reference.md
│
├── features/                      # Feature documentation
│   ├── guest-features.md          # Guest booking flow
│   ├── staff-features.md          # Staff features
│   └── manager-features.md        # Manager features
│
├── tasks/                         # Task-specific docs
│   ├── task-16/                   # Next.js setup
│   ├── task-17/                   # NextAuth setup
│   ├── task-18/                   # API client
│   ├── task-19/                   # Room search
│   ├── task-20/                   # Booking flow
│   ├── task-21/                   # Booking history
│   ├── task-27/                   # Room status dashboard
│   ├── task-28/                   # Check-in/out
│   ├── task-29/                   # Housekeeping
│   ├── task-34/                   # Pricing management
│   ├── task-35/                   # Inventory management
│   └── task-36/                   # Reports & dashboard
│
├── components/                    # Component documentation
│   ├── ui-components.md
│   └── custom-components.md
│
└── guides/                        # How-to guides
    ├── api-integration.md
    ├── state-management.md
    └── styling-guide.md
```

## 🚀 Quick Links

### Getting Started
- [Setup Guide](../SETUP.md)
- [Quick Reference](../QUICK_REFERENCE.md)
- [Theme Reference](../THEME_REFERENCE.md)

### Authentication
- [NextAuth Setup](../NEXTAUTH_SETUP.md)
- [NextAuth Flow Diagram](../NEXTAUTH_FLOW_DIAGRAM.md)
- [NextAuth Quick Reference](../NEXTAUTH_QUICK_REFERENCE.md)

### Features
- [Guest Features](#guest-features)
- [Staff Features](#staff-features)
- [Manager Features](#manager-features)

### API Integration
- [API Client Reference](../API_CLIENT_REFERENCE.md)
- [Custom Hooks](./guides/custom-hooks.md)

## 📖 Feature Documentation

### Guest Features
**Booking Flow:**
- Room search and filtering
- Booking hold system with countdown
- Guest information form
- Booking confirmation
- Booking history and cancellation

**Documentation:**
- [Booking Flow Diagram](../BOOKING_FLOW_DIAGRAM.md)
- [Booking Flow Quick Reference](../BOOKING_FLOW_QUICK_REFERENCE.md)
- [Booking History Flow](../BOOKING_HISTORY_FLOW.md)

### Staff Features
**Receptionist:**
- Room status dashboard (2-axis status display)
- Check-in process
- Check-out process
- Room movement
- No-show marking

**Housekeeper:**
- Task list (rooms to clean)
- Status updates (Dirty → Cleaning → Clean)
- Room inspection (Clean → Inspected)
- Problem reporting

**Documentation:**
- [Room Status Dashboard](./tasks/task-27/)
- [Check-in/out Interface](./tasks/task-28/)
- [Housekeeping](./tasks/task-29/)

### Manager Features
**Pricing Management:**
- Rate tiers management
- Pricing calendar (visual calendar view)
- Rate pricing matrix
- Bulk updates

**Inventory Management:**
- Room inventory calendar
- Allotment management
- Booking heatmap
- Validation and constraints

**Reports & Analytics:**
- Dashboard overview
- Occupancy reports
- Revenue reports
- Voucher usage
- No-show reports

**Documentation:**
- [Pricing Management](./tasks/task-34/)
- [Inventory Management](../INVENTORY_MANAGEMENT_README.md)
- [Reports & Dashboard](./tasks/task-36/)

## 🎨 UI Components

### Shadcn/ui Components
- Button, Input, Card
- Dialog, Sheet, Dropdown
- Calendar, DatePicker
- Table, DataTable
- Toast, Alert

### Custom Components
- RoomCard
- RoomSearchForm
- CountdownTimer
- ProtectedRoute
- ThemeToggle

### Styling
- Tailwind CSS
- CSS Variables for theming
- Dark mode support
- Responsive design

## 🔧 Development

### Run Development Server
```bash
cd frontend
npm run dev
# Open http://localhost:3000
```

### Build for Production
```bash
npm run build
npm start
```

### Run Tests
```bash
npm test
```

## 📝 Code Standards

### Component Structure
```typescript
// 1. Imports
import { useState } from 'react'
import { Button } from '@/components/ui/button'

// 2. Types/Interfaces
interface Props {
  title: string
}

// 3. Component
export function MyComponent({ title }: Props) {
  // 4. Hooks
  const [state, setState] = useState()
  
  // 5. Handlers
  const handleClick = () => {}
  
  // 6. Render
  return <div>{title}</div>
}
```

### File Naming
- Components: `PascalCase.tsx`
- Utilities: `kebab-case.ts`
- Hooks: `use-hook-name.ts`
- Types: `types.ts` or `index.ts`

### Best Practices
- Use TypeScript for type safety
- Implement proper error handling
- Use React Query for data fetching
- Implement loading and error states
- Follow accessibility guidelines
- Write meaningful component names

## 🔗 Related Documentation

- [Backend Documentation](../../backend/docs/)
- [Database Documentation](../../database/docs/)
- [API Reference](../../docs/api/README.md)
- [User Guides](../../docs/user-guides/)

## 📞 Need Help?

1. Check [Setup Guide](../SETUP.md)
2. Review [Quick Reference](../QUICK_REFERENCE.md)
3. See [API Client Reference](../API_CLIENT_REFERENCE.md)
4. Check task-specific documentation

---

**Last Updated:** 2025-02-04  
**Frontend Version:** 1.0.0  
**Next.js Version:** 16.0.0  
**React Version:** 19.0.0
