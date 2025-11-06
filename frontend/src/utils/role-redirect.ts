/**
 * Role-based redirect utilities
 * Provides functions to determine appropriate pages based on user roles
 */

export type UserRole = 'GUEST' | 'RECEPTIONIST' | 'HOUSEKEEPER' | 'MANAGER';

/**
 * Get the home page URL for a specific role
 */
export function getRoleHomePage(role: UserRole | string): string {
  switch (role) {
    case 'GUEST':
      return '/';
    case 'RECEPTIONIST':
      return '/admin/reception';
    case 'HOUSEKEEPER':
      return '/admin/housekeeping';
    case 'MANAGER':
      return '/admin/dashboard';
    default:
      return '/';
  }
}

/**
 * Check if a role can access a specific path
 */
export function canAccessPath(role: UserRole | string, path: string): boolean {
  const roleAccess: Record<string, UserRole[]> = {
    '/bookings': ['GUEST', 'RECEPTIONIST', 'MANAGER'],
    '/profile': ['GUEST', 'RECEPTIONIST', 'HOUSEKEEPER', 'MANAGER'],
    '/staff': ['RECEPTIONIST', 'MANAGER'],
    '/staff/housekeeping': ['HOUSEKEEPER', 'MANAGER'],
    '/admin': ['MANAGER'],
  };

  for (const [prefix, allowedRoles] of Object.entries(roleAccess)) {
    if (path.startsWith(prefix)) {
      return allowedRoles.includes(role as UserRole);
    }
  }

  return true; // Public route
}

/**
 * Get navigation items based on role
 */
export function getRoleNavigation(role: UserRole | string) {
  switch (role) {
    case 'GUEST':
      return [
        { label: 'หน้าแรก', href: '/', icon: 'home' },
        { label: 'ห้องพัก', href: '/rooms', icon: 'bed' },
        { label: 'การจองของฉัน', href: '/bookings', icon: 'calendar' },
        { label: 'โปรไฟล์', href: '/profile', icon: 'user' },
      ];
    
    case 'RECEPTIONIST':
      return [
        { label: 'แดชบอร์ด', href: '/staff', icon: 'dashboard' },
        { label: 'เช็คอิน', href: '/staff/checkin', icon: 'login' },
        { label: 'เช็คเอาท์', href: '/staff/checkout', icon: 'logout' },
        { label: 'การจอง', href: '/staff/bookings', icon: 'calendar' },
        { label: 'ห้องพัก', href: '/staff/rooms', icon: 'bed' },
        { label: 'ย้ายห้อง', href: '/staff/move-room', icon: 'move' },
        { label: 'No-Show', href: '/staff/no-show', icon: 'alert' },
      ];
    
    case 'HOUSEKEEPER':
      return [
        { label: 'แดชบอร์ด', href: '/staff/housekeeping', icon: 'dashboard' },
        { label: 'งานทำความสะอาด', href: '/staff/housekeeping/tasks', icon: 'clean' },
        { label: 'ตรวจสอบห้อง', href: '/staff/housekeeping/inspection', icon: 'check' },
        { label: 'รายงานซ่อมบำรุง', href: '/staff/housekeeping/maintenance', icon: 'tool' },
      ];
    
    case 'MANAGER':
      return [
        { label: 'แดชบอร์ด', href: '/admin', icon: 'dashboard' },
        { label: 'ราคา', href: '/admin/pricing', icon: 'dollar', children: [
          { label: 'Rate Tiers', href: '/admin/pricing/tiers' },
          { label: 'ปฏิทินราคา', href: '/admin/pricing/calendar' },
          { label: 'เมทริกซ์ราคา', href: '/admin/pricing/matrix' },
        ]},
        { label: 'สต็อก', href: '/admin/inventory', icon: 'inventory' },
        { label: 'รายงาน', href: '/admin/reports', icon: 'chart' },
        { label: 'ตั้งค่า', href: '/admin/settings', icon: 'settings', children: [
          { label: 'ห้องพัก', href: '/admin/rooms' },
          { label: 'คูปอง', href: '/admin/vouchers' },
          { label: 'นโยบาย', href: '/admin/policies' },
          { label: 'พนักงาน', href: '/admin/staff' },
        ]},
      ];
    
    default:
      return [
        { label: 'หน้าแรก', href: '/', icon: 'home' },
        { label: 'ห้องพัก', href: '/rooms', icon: 'bed' },
      ];
  }
}

/**
 * Get role display name in Thai
 */
export function getRoleDisplayName(role: UserRole | string): string {
  switch (role) {
    case 'GUEST':
      return 'ผู้เข้าพัก';
    case 'RECEPTIONIST':
      return 'พนักงานต้อนรับ';
    case 'HOUSEKEEPER':
      return 'แม่บ้าน';
    case 'MANAGER':
      return 'ผู้จัดการ';
    default:
      return 'ผู้ใช้';
  }
}

/**
 * Check if role is staff (any staff member)
 */
export function isStaff(role: UserRole | string): boolean {
  return ['RECEPTIONIST', 'HOUSEKEEPER', 'MANAGER'].includes(role);
}

/**
 * Check if role has admin privileges
 */
export function isAdmin(role: UserRole | string): boolean {
  return role === 'MANAGER';
}

/**
 * Get allowed actions for a role
 */
export function getRolePermissions(role: UserRole | string) {
  const permissions = {
    GUEST: {
      canBook: true,
      canViewOwnBookings: true,
      canCancelBooking: true,
      canViewRooms: true,
    },
    RECEPTIONIST: {
      canCheckIn: true,
      canCheckOut: true,
      canMoveRoom: true,
      canViewAllBookings: true,
      canCreateBooking: true,
      canMarkNoShow: true,
      canViewRoomStatus: true,
    },
    HOUSEKEEPER: {
      canUpdateRoomStatus: true,
      canInspectRoom: true,
      canReportMaintenance: true,
      canViewTasks: true,
    },
    MANAGER: {
      canManagePricing: true,
      canManageInventory: true,
      canViewReports: true,
      canManageStaff: true,
      canManageVouchers: true,
      canManagePolicies: true,
      canManageRooms: true,
      // Manager has all permissions
      canCheckIn: true,
      canCheckOut: true,
      canMoveRoom: true,
      canViewAllBookings: true,
      canCreateBooking: true,
      canMarkNoShow: true,
      canViewRoomStatus: true,
      canUpdateRoomStatus: true,
      canInspectRoom: true,
    },
  };

  return permissions[role as UserRole] || {};
}
