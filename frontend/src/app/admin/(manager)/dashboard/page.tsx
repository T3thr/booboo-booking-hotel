'use client';

import { useSession } from 'next-auth/react';
import { Card } from '@/components/ui/card';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { reportApi, bookingApi } from '@/lib/api';
import { LoadingSpinner } from '@/components/ui/loading';
import {
  BarChart3,
  DollarSign,
  Package,
  TrendingUp,
  Users,
  Calendar,
} from 'lucide-react';

export default function ManagerDashboardPage() {
  const { data: session } = useSession();

  // Fetch real-time stats
  const today = new Date().toISOString().split('T')[0];
  const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    .toISOString()
    .split('T')[0];

  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['dashboard-stats', today],
    queryFn: async () => {
      try {
        console.log('[Dashboard] Fetching stats...');
        
        // Only fetch revenue and occupancy - skip bookings API to avoid timeout
        const [revenueRes, occupancyRes] = await Promise.all([
          reportApi.getRevenue({ start_date: today, end_date: today }).catch(err => {
            console.error('[Dashboard] Revenue API error:', err);
            return { data: [] };
          }),
          reportApi.getOccupancy({ start_date: today, end_date: today }).catch(err => {
            console.error('[Dashboard] Occupancy API error:', err);
            return { data: [] };
          })
        ]);

        console.log('[Dashboard] Revenue response:', revenueRes);
        console.log('[Dashboard] Occupancy response:', occupancyRes);

        const todayRevenue = revenueRes?.data?.[0]?.total_revenue || 0;
        const todayOccupancy = occupancyRes?.data?.[0]?.occupancy_rate || 0;

        return {
          revenue: todayRevenue,
          occupancy: todayOccupancy,
          bookings: 0, // Placeholder - can be added later when API is optimized
          totalBookings: 0 // Placeholder
        };
      } catch (error) {
        console.error('[Dashboard] Failed to fetch stats:', error);
        return {
          revenue: 0,
          occupancy: 0,
          bookings: 0,
          totalBookings: 0
        };
      }
    },
    retry: false,
    refetchInterval: false, // Disable auto-refresh to prevent repeated errors
    enabled: !!session?.user // Only fetch when user is logged in
  });

  if (error) {
    console.error('[Dashboard] Query error:', error);
  }

  // Show error message if backend is not available
  const showBackendError = error && !stats;

  const quickActions = [
    {
      title: 'จัดการราคา',
      description: 'ตั้งค่าราคาห้องพักและโปรโมชั่น',
      icon: DollarSign,
      href: '/admin/pricing/tiers',
    },
    {
      title: 'สต็อกห้องพัก',
      description: 'จัดการจำนวนห้องที่เปิดขาย',
      icon: Package,
      href: '/admin/inventory',
    },
    {
      title: 'รายงาน',
      description: 'ดูรายงานและสถิติต่างๆ',
      icon: BarChart3,
      href: '/admin/reports',
    },
  ];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-background">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const statsData = [
    {
      label: 'รายได้วันนี้',
      value: `฿${stats?.revenue.toLocaleString() || '0'}`,
      change: '+12.5%',
      icon: TrendingUp,
      positive: true,
    },
    {
      label: 'อัตราการเข้าพัก',
      value: `${Math.round(stats?.occupancy || 0)}%`,
      change: '+5.2%',
      icon: Users,
      positive: true,
    },
    {
      label: 'การจองวันนี้',
      value: '-',
      change: 'เร็วๆ นี้',
      icon: Calendar,
      positive: true,
    },
    {
      label: 'การจองทั้งหมด',
      value: '-',
      change: 'เร็วๆ นี้',
      icon: Package,
      positive: true,
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-foreground mb-2">
          Manager Dashboard
        </h1>
        <p className="text-muted-foreground">
          ยินดีต้อนรับ, {session?.user?.name || 'Manager'}
        </p>
      </div>

      {/* Backend Error Alert */}
      {showBackendError && (
        <Card className="p-4 bg-destructive/10 border-destructive/30">
          <div className="flex items-start gap-3">
            <div className="text-destructive">⚠️</div>
            <div>
              <h3 className="font-semibold text-foreground mb-1">
                ไม่สามารถเชื่อมต่อกับ Backend API
              </h3>
              <p className="text-sm text-muted-foreground">
                กรุณาตรวจสอบว่า Backend Server กำลังทำงานที่ http://localhost:8080
              </p>
              <p className="text-xs text-muted-foreground mt-2">
                ข้อมูลสถิติจะแสดงเป็น 0 จนกว่า Backend จะพร้อมใช้งาน
              </p>
            </div>
          </div>
        </Card>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {statsData.map((stat, index) => (
          <Card key={index} className="p-6 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between mb-4">
              <stat.icon className="w-8 h-8 text-primary" />
              <span className="text-sm font-medium text-muted-foreground">
                {stat.change}
              </span>
            </div>
            <div>
              <p className="text-sm text-muted-foreground mb-1">
                {stat.label}
              </p>
              <p className="text-3xl font-bold text-foreground">
                {stat.value}
              </p>
            </div>
          </Card>
        ))}
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-2xl font-bold text-foreground mb-4">
          เมนูหลัก
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {quickActions.map((action, index) => (
            <Link key={index} href={action.href}>
              <Card className="p-6 hover:shadow-lg transition-all cursor-pointer h-full border-2 hover:border-primary">
                <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4">
                  <action.icon className="w-6 h-6 text-primary" />
                </div>
                <h3 className="text-lg font-semibold text-foreground mb-2">
                  {action.title}
                </h3>
                <p className="text-sm text-muted-foreground">
                  {action.description}
                </p>
              </Card>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
