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
  Menu,
  X
} from 'lucide-react';
import { useState } from 'react';

export function StaffNavbar() {
  const { data: session } = useSession();
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const isManager = session?.user?.role === 'MANAGER';
  const isReceptionist = session?.user?.role === 'RECEPTIONIST';
  const isHousekeeper = session?.user?.role === 'HOUSEKEEPER';

  const managerLinks = [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/pricing/tiers', label: 'จัดการราคา', icon: DollarSign },
    { href: '/inventory', label: 'สต็อกห้องพัก', icon: Package },
    { href: '/reports', label: 'รายงาน', icon: BarChart3 },
  ];

  const receptionistLinks = [
    { href: '/reception', label: 'ต้อนรับ', icon: Users },
    { href: '/checkin', label: 'เช็คอิน', icon: ClipboardCheck },
    { href: '/checkout', label: 'เช็คเอาท์', icon: ClipboardCheck },
  ];

  const housekeeperLinks = [
    { href: '/housekeeping', label: 'แม่บ้าน', icon: ClipboardCheck },
    { href: '/housekeeping/inspection', label: 'ตรวจสอบห้อง', icon: ClipboardCheck },
  ];

  let links: Array<{ href: string; label: string; icon: any }> = [];
  if (isManager) links = managerLinks;
  else if (isReceptionist) links = receptionistLinks;
  else if (isHousekeeper) links = housekeeperLinks;

  const isActive = (href: string) => pathname === href || pathname.startsWith(href + '/');

  return (
    <nav className="bg-card border-b border-border shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          {/* Logo & Title */}
          <div className="flex items-center">
            <Link href={isManager ? '/dashboard' : isReceptionist ? '/reception' : '/housekeeping'} className="flex items-center">
              <div className="flex-shrink-0 flex items-center">
                <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center mr-3">
                  <LayoutDashboard className="w-5 h-5 text-primary-foreground" />
                </div>
                <div>
                  <h1 className="text-lg font-bold text-foreground">
                    ระบบจัดการโรงแรม
                  </h1>
                  <p className="text-xs text-muted-foreground">
                    {isManager && 'ผู้จัดการ'}
                    {isReceptionist && 'พนักงานต้อนรับ'}
                    {isHousekeeper && 'แม่บ้าน'}
                  </p>
                </div>
              </div>
            </Link>
          </div>

          {/* Desktop Navigation */}
          <div className="hidden md:flex md:items-center md:space-x-1">
            {links.map((link) => {
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`
                    inline-flex items-center px-4 py-2 rounded-md text-sm font-medium transition-colors
                    ${isActive(link.href)
                      ? 'bg-primary text-primary-foreground'
                      : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                    }
                  `}
                >
                  <Icon className="w-4 h-4 mr-2" />
                  {link.label}
                </Link>
              );
            })}
          </div>

          {/* User Menu */}
          <div className="hidden md:flex md:items-center md:space-x-4">
            <div className="text-sm text-muted-foreground">
              <p className="font-medium text-foreground">{session?.user?.name}</p>
              <p className="text-xs">{session?.user?.email}</p>
            </div>
            <button
              onClick={() => signOut({ callbackUrl: '/auth/signin' })}
              className="inline-flex items-center px-4 py-2 rounded-md text-sm font-medium text-muted-foreground hover:bg-accent hover:text-accent-foreground transition-colors"
            >
              <LogOut className="w-4 h-4 mr-2" />
              ออกจากระบบ
            </button>
          </div>

          {/* Mobile menu button */}
          <div className="flex items-center md:hidden">
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="inline-flex items-center justify-center p-2 rounded-md text-muted-foreground hover:bg-accent hover:text-accent-foreground"
            >
              {mobileMenuOpen ? (
                <X className="w-6 h-6" />
              ) : (
                <Menu className="w-6 h-6" />
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-border">
          <div className="px-2 pt-2 pb-3 space-y-1">
            {links.map((link) => {
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`
                    flex items-center px-3 py-2 rounded-md text-base font-medium
                    ${isActive(link.href)
                      ? 'bg-primary text-primary-foreground'
                      : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                    }
                  `}
                >
                  <Icon className="w-5 h-5 mr-3" />
                  {link.label}
                </Link>
              );
            })}
          </div>
          <div className="border-t border-border px-4 py-3">
            <div className="text-sm text-muted-foreground mb-3">
              <p className="font-medium text-foreground">{session?.user?.name}</p>
              <p className="text-xs">{session?.user?.email}</p>
            </div>
            <button
              onClick={() => {
                setMobileMenuOpen(false);
                signOut({ callbackUrl: '/auth/signin' });
              }}
              className="flex items-center w-full px-3 py-2 rounded-md text-base font-medium text-muted-foreground hover:bg-accent hover:text-accent-foreground"
            >
              <LogOut className="w-5 h-5 mr-3" />
              ออกจากระบบ
            </button>
          </div>
        </div>
      )}
    </nav>
  );
}
