'use client';

import { useSession } from 'next-auth/react';
import { Card } from '@/components/ui/card';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import {
  BarChart3,
  DollarSign,
  Package,
  TrendingUp,
  Users,
  Calendar,
  Clock,
  CheckCircle,
} from 'lucide-react';

export default function ManagerDashboardPage() {
  const { data: session } = useSession();

  const today = new Date().toISOString().split('T')[0];
  const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    .toISOString()
    .split('T')[0];
  const endOfMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0)
    .toISOString()
    .split('T')[0];

  // Fetch today's revenue from approved bookings
  const { data: todayRevenue, isLoading: revenueLoading } = useQuery({
    queryKey: ['todayRevenue', today],
    queryFn: async () => {
      const res = await fetch(`/api/admin/reports/revenue?date=${today}`);
      if (!res.ok) return { revenue: 0 };
      const data = await res.json();
      return data;
    },
    refetchInterval: 30000, // Refresh every 30 seconds for real-time updates
  });

  // Fetch this month's revenue
  const { data: monthRevenue } = useQuery({
    queryKey: ['monthRevenue', startOfMonth, endOfMonth],
    queryFn: async () => {
      const res = await fetch(
        `/api/admin/reports/revenue?start_date=${startOfMonth}&end_date=${endOfMonth}`
      );
      if (!res.ok) return { revenue: 0 };
      const data = await res.json();
      return data;
    },
  });

  // Fetch occupancy rate
  const { data: occupancyData } = useQuery({
    queryKey: ['occupancy', today],
    queryFn: async () => {
      const res = await fetch(`/api/admin/reports/occupancy?date=${today}`);
      if (!res.ok) return { occupancy_rate: 0, occupied_rooms: 0, total_rooms: 0 };
      const data = await res.json();
      return data;
    },
    refetchInterval: 60000, // Refresh every minute
  });

  // Fetch pending bookings
  const { data: pendingBookings } = useQuery({
    queryKey: ['pendingBookings'],
    queryFn: async () => {
      const res = await fetch('/api/admin/bookings?status=pending');
      if (!res.ok) return { count: 0, bookings: [] };
      const data = await res.json();
      return data;
    },
    refetchInterval: 30000,
  });

  // Fetch pending payment proofs
  const { data: pendingPayments } = useQuery({
    queryKey: ['pendingPayments'],
    queryFn: async () => {
      const res = await fetch('/api/admin/payment-proofs?status=pending');
      if (!res.ok) return { count: 0, proofs: [] };
      const data = await res.json();
      return data;
    },
    refetchInterval: 30000,
  });

  // Fetch recent bookings
  const { data: recentBookings } = useQuery({
    queryKey: ['recentBookings'],
    queryFn: async () => {
      const res = await fetch('/api/admin/bookings?limit=10&sort=created_at&order=desc');
      if (!res.ok) return { bookings: [] };
      const data = await res.json();
      return data;
    },
  });

  const stats = [
    {
      title: 'รายได้วันนี้',
      value: revenueLoading
        ? '...'
        : `฿${(todayRevenue?.revenue || 0).toLocaleString()}`,
      icon: DollarSign,
      color: 'text-green-600 dark:text-green-400',
      bgColor: 'bg-green-100 dark:bg-green-900',
      description: 'จากการจองที่อนุมัติแล้ว',
    },
    {
      title: 'รายได้เดือนนี้',
      value: `฿${(monthRevenue?.revenue || 0).toLocaleString()}`,
      icon: TrendingUp,
      color: 'text-blue-600 dark:text-blue-400',
      bgColor: 'bg-blue-100 dark:bg-blue-900',
      description: `${startOfMonth} - ${endOfMonth}`,
    },
    {
      title: 'อัตราการเข้าพัก',
      value: `${(occupancyData?.occupancy_rate || 0).toFixed(1)}%`,
      icon: Package,
      color: 'text-purple-600 dark:text-purple-400',
      bgColor: 'bg-purple-100 dark:bg-purple-900',
      description: `${occupancyData?.occupied_rooms || 0}/${occupancyData?.total_rooms || 0} ห้อง`,
    },
    {
      title: 'รอตรวจสอบ',
      value: pendingPayments?.count || 0,
      icon: Clock,
      color: 'text-orange-600 dark:text-orange-400',
      bgColor: 'bg-orange-100 dark:bg-orange-900',
      description: 'หลักฐานการชำระเงิน',
    },
  ];

  const quickActions = [
    {
      title: 'จัดการการจอง',
      description: 'อนุมัติและจัดการการจอง',
      icon: CheckCircle,
      href: '/admin/bookings',
      badge: pendingBookings?.count || 0,
    },
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

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground">
          สวัสดี, {session?.user?.name || 'Manager'}
        </h1>
        <p className="mt-2 text-muted-foreground">
          ภาพรวมของโรงแรมวันนี้ - {new Date().toLocaleDateString('th-TH', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          })}
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {stats.map((stat, index) => (
          <Card key={index} className="p-6 bg-card border-border">
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <p className="text-sm font-medium text-muted-foreground">{stat.title}</p>
                <p className="mt-2 text-3xl font-bold text-foreground">{stat.value}</p>
                <p className="mt-1 text-xs text-muted-foreground">{stat.description}</p>
              </div>
              <div className={`p-3 rounded-full ${stat.bgColor}`}>
                <stat.icon className={`w-6 h-6 ${stat.color}`} />
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Alerts Section */}
      {(pendingPayments?.count > 0 || pendingBookings?.count > 0) && (
        <Card className="p-6 mb-8 bg-yellow-50 dark:bg-yellow-950 border-yellow-200 dark:border-yellow-800">
          <h2 className="text-lg font-semibold mb-4 text-yellow-800 dark:text-yellow-200 flex items-center gap-2">
            <Clock className="w-5 h-5" />
            การแจ้งเตือน
          </h2>
          <div className="space-y-2">
            {pendingPayments?.count > 0 && (
              <div className="flex items-center justify-between p-3 bg-white dark:bg-gray-800 rounded">
                <div>
                  <p className="font-medium text-foreground">
                    มีหลักฐานการชำระเงินรอตรวจสอบ {pendingPayments.count} รายการ
                  </p>
                  <p className="text-sm text-muted-foreground">
                    กรุณาตรวจสอบและอนุมัติการชำระเงิน
                  </p>
                </div>
                <Link
                  href="/admin/bookings"
                  className="px-4 py-2 bg-primary text-primary-foreground rounded hover:bg-primary/90"
                >
                  ดูรายการ
                </Link>
              </div>
            )}
            {pendingBookings?.count > 0 && (
              <div className="flex items-center justify-between p-3 bg-white dark:bg-gray-800 rounded">
                <div>
                  <p className="font-medium text-foreground">
                    มีการจองรอดำเนินการ {pendingBookings.count} รายการ
                  </p>
                  <p className="text-sm text-muted-foreground">
                    กรุณาตรวจสอบและจัดการการจอง
                  </p>
                </div>
                <Link
                  href="/admin/bookings"
                  className="px-4 py-2 bg-primary text-primary-foreground rounded hover:bg-primary/90"
                >
                  ดูรายการ
                </Link>
              </div>
            )}
          </div>
        </Card>
      )}

      {/* Quick Actions */}
      <div className="mb-8">
        <h2 className="text-xl font-semibold mb-4 text-foreground">เมนูด่วน</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {quickActions.map((action, index) => (
            <Link key={index} href={action.href}>
              <Card className="p-6 bg-card border-border hover:bg-accent transition-colors cursor-pointer h-full">
                <div className="flex items-start justify-between mb-3">
                  <div className={`p-2 rounded-lg bg-primary/10`}>
                    <action.icon className="w-6 h-6 text-primary" />
                  </div>
                  {action.badge !== undefined && action.badge > 0 && (
                    <span className="px-2 py-1 text-xs font-bold bg-red-500 text-white rounded-full">
                      {action.badge}
                    </span>
                  )}
                </div>
                <h3 className="font-semibold text-foreground mb-1">{action.title}</h3>
                <p className="text-sm text-muted-foreground">{action.description}</p>
              </Card>
            </Link>
          ))}
        </div>
      </div>

      {/* Recent Bookings */}
      <Card className="p-6 bg-card border-border">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-foreground">การจองล่าสุด</h2>
          <Link
            href="/admin/bookings"
            className="text-sm text-primary hover:underline"
          >
            ดูทั้งหมด →
          </Link>
        </div>
        {!recentBookings || recentBookings.bookings?.length === 0 ? (
          <p className="text-center text-muted-foreground py-8">ยังไม่มีการจอง</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-border">
              <thead>
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">
                    รหัสการจอง
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">
                    ชื่อแขก
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">
                    วันที่เช็คอิน
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">
                    สถานะ
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">
                    ยอดเงิน
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {recentBookings.bookings.slice(0, 10).map((booking: any) => (
                  <tr key={booking.booking_id} className="hover:bg-muted">
                    <td className="px-4 py-3 text-sm font-medium text-foreground">
                      #{booking.booking_id}
                    </td>
                    <td className="px-4 py-3 text-sm text-foreground">
                      {booking.guest_name}
                    </td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">
                      {new Date(booking.check_in_date).toLocaleDateString('th-TH')}
                    </td>
                    <td className="px-4 py-3 text-sm">
                      <span
                        className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                          booking.status === 'Confirmed'
                            ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                            : booking.status === 'Pending'
                            ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
                            : booking.status === 'CheckedIn'
                            ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
                            : 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
                        }`}
                      >
                        {booking.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm font-medium text-foreground">
                      ฿{booking.total_amount?.toLocaleString() || 0}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
