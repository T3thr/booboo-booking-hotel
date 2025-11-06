'use client';

import Link from 'next/link';
import { useSession, signOut } from 'next-auth/react';
import { Button } from '@/components/ui/button';
import { Menu, X, User, LogOut, Hotel, Search, Calendar, Shield } from 'lucide-react';
import { useState } from 'react';

export function Navbar() {
  const { data: session, status } = useSession();
  const isLoading = status === 'loading';
  const userRole = session?.user?.role;
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Get role display name
  const getRoleDisplay = () => {
    switch (userRole) {
      case 'RECEPTIONIST':
        return 'พนักงานต้อนรับ';
      case 'HOUSEKEEPER':
        return 'แม่บ้าน';
      case 'MANAGER':
        return 'ผู้จัดการ';
      case 'GUEST':
        return 'ผู้เข้าพัก';
      default:
        return '';
    }
  };

  const isStaff = userRole === 'MANAGER' || userRole === 'RECEPTIONIST' || userRole === 'HOUSEKEEPER';

  return (
    <nav className="sticky top-0 z-50 border-b border-border bg-card/95 backdrop-blur supports-[backdrop-filter]:bg-card/80">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 group flex-shrink-0">
            <div className="w-9 h-9 bg-gradient-to-br from-primary to-primary/80 rounded-lg flex items-center justify-center transition-transform group-hover:scale-105 shadow-md">
              <Hotel className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="text-xl font-bold text-foreground tracking-tight">
              booboo
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-2">
            {isLoading ? (
              <div className="h-9 w-32 bg-muted animate-pulse rounded-md" />
            ) : session ? (
              <>
                {/* Staff Admin Button */}
                {isStaff && (
                  <Link href="/admin">
                    <Button 
                      variant="default" 
                      size="sm"
                      className="gap-2"
                    >
                      <Shield className="w-4 h-4" />
                      <span className="hidden lg:inline">จัดการโรงแรม</span>
                      <span className="lg:hidden">Admin</span>
                    </Button>
                  </Link>
                )}

                {/* Guest Navigation */}
                {userRole === 'GUEST' && (
                  <>
                    <Link href="/rooms/search">
                      <Button variant="ghost" size="sm" className="gap-2">
                        <Search className="w-4 h-4" />
                        <span className="hidden lg:inline">ค้นหาห้องพัก</span>
                      </Button>
                    </Link>
                    <Link href="/bookings">
                      <Button variant="ghost" size="sm" className="gap-2">
                        <Calendar className="w-4 h-4" />
                        <span className="hidden lg:inline">การจองของฉัน</span>
                      </Button>
                    </Link>
                  </>
                )}

                {/* User Menu */}
                <div className="flex items-center gap-2 ml-2 pl-2 border-l border-border">
                  <div className="hidden lg:flex flex-col items-end">
                    <span className="text-sm font-medium text-foreground leading-tight">
                      {session.user?.name || session.user?.email}
                    </span>
                    {userRole && userRole !== 'GUEST' && (
                      <span className="text-xs text-primary font-medium">
                        {getRoleDisplay()}
                      </span>
                    )}
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => signOut({ callbackUrl: '/' })}
                    className="gap-2"
                  >
                    <LogOut className="w-4 h-4" />
                    <span className="hidden xl:inline">ออกจากระบบ</span>
                  </Button>
                </div>
              </>
            ) : (
              <>
                <Link href="/rooms/search">
                  <Button variant="ghost" size="sm" className="gap-2">
                    <Search className="w-4 h-4" />
                    <span className="hidden lg:inline">ค้นหาห้องพัก</span>
                  </Button>
                </Link>
                <Link href="/bookings">
                  <Button variant="ghost" size="sm" className="gap-2">
                    <Calendar className="w-4 h-4" />
                    <span className="hidden lg:inline">ประวัติการจอง</span>
                  </Button>
                </Link>
                <Link href="/auth/signin">
                  <Button variant="ghost" size="sm" className="gap-2">
                    <User className="w-4 h-4" />
                    <span className="hidden lg:inline">เข้าสู่ระบบ</span>
                  </Button>
                </Link>
                <Link href="/auth/register">
                  <Button size="sm">
                    <span className="hidden lg:inline">ลงทะเบียน</span>
                    <span className="lg:hidden">สมัคร</span>
                  </Button>
                </Link>
              </>
            )}
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
            aria-label="Toggle menu"
          >
            {mobileMenuOpen ? (
              <X className="w-6 h-6" />
            ) : (
              <Menu className="w-6 h-6" />
            )}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-border bg-card">
          <div className="px-4 py-3 space-y-2">
            {isLoading ? (
              <div className="h-10 bg-muted animate-pulse rounded-md" />
            ) : session ? (
              <>
                {/* User Info */}
                <div className="px-3 py-2 bg-muted/50 rounded-lg mb-3">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                      <User className="w-4 h-4 text-primary" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-foreground truncate">
                        {session.user?.name || session.user?.email}
                      </p>
                      {userRole && (
                        <p className="text-xs text-muted-foreground">
                          {getRoleDisplay()}
                        </p>
                      )}
                    </div>
                  </div>
                </div>

                {/* Staff Admin Button */}
                {isStaff && (
                  <Link href="/admin" onClick={() => setMobileMenuOpen(false)}>
                    <Button 
                      variant="default" 
                      className="w-full justify-start gap-2"
                    >
                      <Shield className="w-4 h-4" />
                      จัดการโรงแรม
                    </Button>
                  </Link>
                )}

                {/* Guest Navigation */}
                {userRole === 'GUEST' && (
                  <>
                    <Link href="/rooms/search" onClick={() => setMobileMenuOpen(false)}>
                      <Button variant="ghost" className="w-full justify-start gap-2">
                        <Search className="w-4 h-4" />
                        ค้นหาห้องพัก
                      </Button>
                    </Link>
                    <Link href="/bookings" onClick={() => setMobileMenuOpen(false)}>
                      <Button variant="ghost" className="w-full justify-start gap-2">
                        <Calendar className="w-4 h-4" />
                        การจองของฉัน
                      </Button>
                    </Link>
                  </>
                )}

                {/* Logout */}
                <Button
                  variant="outline"
                  onClick={() => {
                    setMobileMenuOpen(false);
                    signOut({ callbackUrl: '/' });
                  }}
                  className="w-full justify-start gap-2 mt-2"
                >
                  <LogOut className="w-4 h-4" />
                  ออกจากระบบ
                </Button>
              </>
            ) : (
              <>
                <Link href="/rooms/search" onClick={() => setMobileMenuOpen(false)}>
                  <Button variant="ghost" className="w-full justify-start gap-2">
                    <Search className="w-4 h-4" />
                    ค้นหาห้องพัก
                  </Button>
                </Link>
                <Link href="/auth/signin" onClick={() => setMobileMenuOpen(false)}>
                  <Button variant="ghost" className="w-full justify-start gap-2">
                    <User className="w-4 h-4" />
                    เข้าสู่ระบบ
                  </Button>
                </Link>
                <Link href="/auth/register" onClick={() => setMobileMenuOpen(false)}>
                  <Button className="w-full justify-start">
                    ลงทะเบียน
                  </Button>
                </Link>
              </>
            )}
          </div>
        </div>
      )}
    </nav>
  );
}
