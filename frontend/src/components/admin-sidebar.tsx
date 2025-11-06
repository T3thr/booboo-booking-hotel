'use client';

import { useSession, signOut } from 'next-auth/react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  DollarSign, 
  Package, 
  BarChart3,
  Users,
  ClipboardCheck,
  LogOut,
  Home,
  Sparkles,
  LogIn as LogInIcon,
  ArrowLeftRight,
  XCircle,
  Settings,
  ChevronLeft,
  Menu,
  X,
  Hotel
} from 'lucide-react';
import { useState } from 'react';

export function AdminSidebar() {
  const { data: session } = useSession();
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  const userRole = session?.user?.role;

  // Define navigation items based on role
  const getNavigationItems = () => {
    const items = [];

    // Manager items - Full access
    if (userRole === 'MANAGER') {
      items.push(
        { href: '/admin/dashboard', label: 'Dashboard', icon: LayoutDashboard, section: 'manager' },
        { href: '/admin/pricing', label: 'จัดการราคา', icon: DollarSign, section: 'manager' },
        { href: '/admin/inventory', label: 'สต็อกห้องพัก', icon: Package, section: 'manager' },
        { href: '/admin/reports', label: 'รายงาน', icon: BarChart3, section: 'manager' },
        { href: '/admin/settings', label: 'ตั้งค่า', icon: Settings, section: 'manager' },
      );
    }

    // Receptionist items
    if (userRole === 'RECEPTIONIST' || userRole === 'MANAGER') {
      items.push(
        { href: '/admin/reception', label: 'ต้อนรับ', icon: Users, section: 'reception' },
        { href: '/admin/checkin', label: 'เช็คอิน', icon: LogInIcon, section: 'reception' },
        { href: '/admin/checkout', label: 'เช็คเอาท์', icon: LogOut, section: 'reception' },
        { href: '/admin/move-room', label: 'ย้ายห้อง', icon: ArrowLeftRight, section: 'reception' },
        { href: '/admin/no-show', label: 'No-Show', icon: XCircle, section: 'reception' },
      );
    }

    // Housekeeper items
    if (userRole === 'HOUSEKEEPER' || userRole === 'MANAGER') {
      items.push(
        { href: '/admin/housekeeping', label: 'ทำความสะอาด', icon: Sparkles, section: 'housekeeping' },
        { href: '/admin/housekeeping/inspection', label: 'ตรวจสอบห้อง', icon: ClipboardCheck, section: 'housekeeping' },
      );
    }

    return items;
  };

  const navigationItems = getNavigationItems();

  const isActive = (href: string) => {
    if (href === '/admin/dashboard') {
      return pathname === href;
    }
    return pathname.startsWith(href);
  };

  const getRoleDisplay = () => {
    switch (userRole) {
      case 'MANAGER':
        return 'ผู้จัดการ';
      case 'RECEPTIONIST':
        return 'พนักงานต้อนรับ';
      case 'HOUSEKEEPER':
        return 'แม่บ้าน';
      default:
        return '';
    }
  };

  // Desktop Sidebar
  const SidebarContent = () => (
    <div className="flex flex-col h-full bg-card border-r border-border shadow-lg">
      {/* Header */}
      <div className="p-4 border-b border-border bg-primary/5">
        <div className="flex items-center justify-between">
          {!collapsed ? (
            <div className="flex items-center gap-3 flex-1">
              <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center shadow-md">
                <Hotel className="w-6 h-6 text-primary-foreground" />
              </div>
              <div className="flex-1">
                <h2 className="text-lg font-bold text-foreground">booboo</h2>
                <p className="text-xs text-primary font-medium">{getRoleDisplay()}</p>
              </div>
            </div>
          ) : (
            <div className="w-10 h-10 bg-primary rounded-lg flex items-center justify-center shadow-md mx-auto">
              <Hotel className="w-6 h-6 text-primary-foreground" />
            </div>
          )}
          <button
            onClick={() => setCollapsed(!collapsed)}
            className="p-2 rounded-md hover:bg-accent transition-colors hidden lg:block ml-2"
          >
            <ChevronLeft className={`w-4 h-4 transition-transform ${collapsed ? 'rotate-180' : ''}`} />
          </button>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
        {navigationItems.map((item) => {
          const Icon = item.icon;
          const active = isActive(item.href);
          
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setMobileOpen(false)}
              className={`
                flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all
                ${active
                  ? 'bg-primary text-primary-foreground shadow-md'
                  : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                }
                ${collapsed ? 'justify-center' : ''}
              `}
              title={collapsed ? item.label : undefined}
            >
              <Icon className="w-5 h-5 flex-shrink-0" />
              {!collapsed && <span className="truncate">{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-3 border-t border-border space-y-2 bg-muted/30">
        {/* User Info */}
        {!collapsed && (
          <div className="px-3 py-2 bg-card rounded-lg border border-border">
            <p className="text-sm font-medium text-foreground truncate">
              {session?.user?.name}
            </p>
            <p className="text-xs text-muted-foreground truncate">
              {session?.user?.email}
            </p>
          </div>
        )}

        {/* Back to Home */}
        <Link
          href="/"
          className={`
            flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors
            text-muted-foreground hover:bg-accent hover:text-accent-foreground
            ${collapsed ? 'justify-center' : ''}
          `}
          title={collapsed ? 'กลับหน้าหลัก' : undefined}
        >
          <Home className="w-5 h-5 flex-shrink-0" />
          {!collapsed && <span>กลับหน้าหลัก</span>}
        </Link>
        
        {/* Logout */}
        <button
          onClick={() => signOut({ callbackUrl: '/' })}
          className={`
            w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors
            text-destructive hover:bg-destructive/10
            ${collapsed ? 'justify-center' : ''}
          `}
          title={collapsed ? 'ออกจากระบบ' : undefined}
        >
          <LogOut className="w-5 h-5 flex-shrink-0" />
          {!collapsed && <span>ออกจากระบบ</span>}
        </button>
      </div>
    </div>
  );

  return (
    <>
      {/* Mobile Menu Button */}
      <button
        onClick={() => setMobileOpen(!mobileOpen)}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-md bg-card border border-border shadow-lg"
      >
        {mobileOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
      </button>

      {/* Mobile Sidebar */}
      {mobileOpen && (
        <>
          <div
            className="lg:hidden fixed inset-0 bg-background/80 backdrop-blur-sm z-40"
            onClick={() => setMobileOpen(false)}
          />
          <aside className="lg:hidden fixed left-0 top-0 bottom-0 w-64 z-50">
            <SidebarContent />
          </aside>
        </>
      )}

      {/* Desktop Sidebar */}
      <aside className={`hidden lg:block fixed left-0 top-0 bottom-0 transition-all duration-300 ${collapsed ? 'w-20' : 'w-64'} z-30`}>
        <SidebarContent />
      </aside>
    </>
  );
}
