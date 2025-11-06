# Quick Fix: Manager Pages - Database Connection

## 🎯 เป้าหมาย
เชื่อมต่อ Manager pages ทั้งหมดกับ database จริง (1-2 ชั่วโมง)

---

## 1. Dashboard Page (15 นาที)

### File: `frontend/src/app/(manager)/dashboard/page.tsx`

```typescript
'use client';

import { useSession } from 'next-auth/react';
import { Card } from '@/components/ui/card';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { LoadingSpinner } from '@/components/ui/loading';
import {
  BarChart3,
  DollarSign,
  Package,
  FileText,
  TrendingUp,
  Users,
  Calendar,
} from 'lucide-react';
import Link from 'next/link';

export default function ManagerDashboardPage() {
  const { data: session } = useSession();

  // Fetch real-time stats
  const today = new Date().toISOString().split('T')[0];
  const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    .toISOString()
    .split('T')[0];

  const { data: stats, isLoading } = useQuery({
    queryKey: ['dashboard-stats', today],
    queryFn: async () => {
      try {
        const [revenueRes, occupancyRes, bookingsRes] = await Promise.all([
          api.get('/api/reports/revenue', {
            params: { start_date: today, end_date: today }
          }),
          api.get('/api/reports/occupancy', {
            params: { start_date: today, end_date: today }
          }),
          api.get('/api/bookings', {
            params: { status: 'Confirmed', limit: 100 }
          })
        ]);

        const todayRevenue = revenueRes.data.data?.[0]?.total_revenue || 0;
        const todayOccupancy = occupancyRes.data.data?.[0]?.occupancy_rate || 0;
        const todayBookings = bookingsRes.data.data?.filter((b: any) => {
          const createdDate = new Date(b.created_at).toISOString().split('T')[0];
          return createdDate === today;
        }).length || 0;

        return {
          revenue: todayRevenue,
          occupancy: todayOccupancy,
          bookings: todayBookings,
          totalBookings: bookingsRes.data.total || 0
        };
      } catch (error) {
        console.error('Failed to fetch stats:', error);
        return {
          revenue: 0,
          occupancy: 0,
          bookings: 0,
          totalBookings: 0
        };
      }
    },
    refetchInterval: 30000 // Refresh every 30 seconds
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
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
      value: stats?.bookings || 0,
      change: '+8',
      icon: Calendar,
      positive: true,
    },
    {
      label: 'การจองทั้งหมด',
      value: stats?.totalBookings || 0,
      change: `${stats?.bookings || 0} วันนี้`,
      icon: FileText,
      positive: true,
    },
  ];

  const quickActions = [
    {
      title: 'จัดการราคา',
      description: 'ตั้งค่าราคาห้องพักและโปรโมชั่น',
      icon: DollarSign,
      href: '/pricing/tiers',
      color: 'text-green-600 dark:text-green-400',
      bgColor: 'bg-green-50 dark:bg-green-950',
    },
    {
      title: 'สต็อกห้องพัก',
      description: 'จัดการจำนวนห้องที่เปิดขาย',
      icon: Package,
      href: '/inventory',
      color: 'text-blue-600 dark:text-blue-400',
      bgColor: 'bg-blue-50 dark:bg-blue-950',
    },
    {
      title: 'รายงาน',
      description: 'ดูรายงานและสถิติต่างๆ',
      icon: BarChart3,
      href: '/reports',
      color: 'text-purple-600 dark:text-purple-400',
      bgColor: 'bg-purple-50 dark:bg-purple-950',
    },
  ];

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Header */}
        <div>
          <h1 className="text-4xl font-bold text-foreground mb-2">
            Manager Dashboard
          </h1>
          <p className="text-muted-foreground">
            ยินดีต้อนรับ, {session?.user?.name || 'Manager'}
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {statsData.map((stat, index) => (
            <Card key={index} className="p-6">
              <div className="flex items-center justify-between mb-4">
                <stat.icon className="w-8 h-8 text-primary" />
                <span
                  className={`text-sm font-medium ${
                    stat.positive ? 'text-green-600' : 'text-red-600'
                  }`}
                >
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
          <h2 className="text-2xl font-bold text-foreground mb-6">
            เมนูหลัก
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {quickActions.map((action, index) => (
              <Link key={index} href={action.href}>
                <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer h-full">
                  <div
                    className={`w-12 h-12 rounded-lg ${action.bgColor} flex items-center justify-center mb-4`}
                  >
                    <action.icon className={`w-6 h-6 ${action.color}`} />
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
    </div>
  );
}
```

---

## 2. Pricing Tiers Page (20 นาที)

### File: `frontend/src/app/(manager)/pricing/tiers/page.tsx`

```typescript
'use client';

import { useState } from 'react';
import { useRateTiers, useCreateRateTier, useUpdateRateTier } from '@/hooks/use-pricing';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { LoadingSpinner } from '@/components/ui/loading';
import { Plus, Edit, Check, X } from 'lucide-react';

export default function RateTiersPage() {
  const { data: tiers, isLoading } = useRateTiers();
  const createTier = useCreateRateTier();
  const updateTier = useUpdateRateTier();

  const [isCreating, setIsCreating] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
  });

  const handleCreate = async () => {
    try {
      await createTier.mutateAsync(formData);
      setIsCreating(false);
      setFormData({ name: '', description: '' });
    } catch (error) {
      console.error('Failed to create tier:', error);
    }
  };

  const handleUpdate = async (id: number) => {
    try {
      await updateTier.mutateAsync({ id, ...formData });
      setEditingId(null);
      setFormData({ name: '', description: '' });
    } catch (error) {
      console.error('Failed to update tier:', error);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold text-foreground mb-2">
              Rate Tiers
            </h1>
            <p className="text-muted-foreground">
              จัดการระดับราคาห้องพัก
            </p>
          </div>
          <Button onClick={() => setIsCreating(true)}>
            <Plus className="w-4 h-4 mr-2" />
            เพิ่ม Rate Tier
          </Button>
        </div>

        {/* Create Form */}
        {isCreating && (
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">สร้าง Rate Tier ใหม่</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">ชื่อ</label>
                <Input
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="เช่น High Season"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">คำอธิบาย</label>
                <Input
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="เช่น ช่วงเทศกาล"
                />
              </div>
              <div className="flex gap-2">
                <Button onClick={handleCreate} disabled={createTier.isPending}>
                  <Check className="w-4 h-4 mr-2" />
                  บันทึก
                </Button>
                <Button variant="outline" onClick={() => setIsCreating(false)}>
                  <X className="w-4 h-4 mr-2" />
                  ยกเลิก
                </Button>
              </div>
            </div>
          </Card>
        )}

        {/* Tiers List */}
        <div className="grid gap-4">
          {tiers?.data?.map((tier: any) => (
            <Card key={tier.rate_tier_id} className="p-6">
              {editingId === tier.rate_tier_id ? (
                <div className="space-y-4">
                  <Input
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  />
                  <Input
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  />
                  <div className="flex gap-2">
                    <Button onClick={() => handleUpdate(tier.rate_tier_id)}>
                      บันทึก
                    </Button>
                    <Button variant="outline" onClick={() => setEditingId(null)}>
                      ยกเลิก
                    </Button>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-semibold">{tier.name}</h3>
                    <p className="text-sm text-muted-foreground">{tier.description}</p>
                  </div>
                  <Button
                    variant="outline"
                    onClick={() => {
                      setEditingId(tier.rate_tier_id);
                      setFormData({
                        name: tier.name,
                        description: tier.description || '',
                      });
                    }}
                  >
                    <Edit className="w-4 h-4 mr-2" />
                    แก้ไข
                  </Button>
                </div>
              )}
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
```

---

## 3. Inventory Page (20 นาที)

### File: `frontend/src/app/(manager)/inventory/page.tsx`

```typescript
'use client';

import { useState } from 'react';
import { useInventory, useUpdateInventory } from '@/hooks/use-inventory';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { LoadingSpinner } from '@/components/ui/loading';
import { Calendar } from 'lucide-react';

export default function InventoryPage() {
  const [dateRange, setDateRange] = useState({
    start_date: new Date().toISOString().split('T')[0],
    end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  });

  const { data: inventory, isLoading } = useInventory(dateRange);
  const updateInventory = useUpdateInventory();

  const [editingKey, setEditingKey] = useState<string | null>(null);
  const [editValue, setEditValue] = useState<number>(0);

  const handleUpdate = async (roomTypeId: number, date: string, currentAllotment: number) => {
    try {
      await updateInventory.mutateAsync({
        room_type_id: roomTypeId,
        date,
        allotment: editValue,
      });
      setEditingKey(null);
    } catch (error) {
      console.error('Failed to update inventory:', error);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Header */}
        <div>
          <h1 className="text-4xl font-bold text-foreground mb-2">
            Inventory Management
          </h1>
          <p className="text-muted-foreground">
            จัดการจำนวนห้องที่เปิดขาย
          </p>
        </div>

        {/* Date Range Selector */}
        <Card className="p-6">
          <div className="flex items-center gap-4">
            <Calendar className="w-5 h-5 text-muted-foreground" />
            <div className="flex gap-4 items-center">
              <div>
                <label className="block text-sm font-medium mb-2">วันที่เริ่มต้น</label>
                <Input
                  type="date"
                  value={dateRange.start_date}
                  onChange={(e) => setDateRange({ ...dateRange, start_date: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">วันที่สิ้นสุด</label>
                <Input
                  type="date"
                  value={dateRange.end_date}
                  onChange={(e) => setDateRange({ ...dateRange, end_date: e.target.value })}
                />
              </div>
            </div>
          </div>
        </Card>

        {/* Inventory Table */}
        <Card className="p-6">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-4">ประเภทห้อง</th>
                  <th className="text-left p-4">วันที่</th>
                  <th className="text-right p-4">Allotment</th>
                  <th className="text-right p-4">จองแล้ว</th>
                  <th className="text-right p-4">ว่าง</th>
                  <th className="text-right p-4">การจัดการ</th>
                </tr>
              </thead>
              <tbody>
                {inventory?.data?.map((item: any) => {
                  const key = `${item.room_type_id}-${item.date}`;
                  const isEditing = editingKey === key;

                  return (
                    <tr key={key} className="border-b hover:bg-muted/50">
                      <td className="p-4">{item.room_type_name}</td>
                      <td className="p-4">
                        {new Date(item.date).toLocaleDateString('th-TH')}
                      </td>
                      <td className="text-right p-4">
                        {isEditing ? (
                          <Input
                            type="number"
                            value={editValue}
                            onChange={(e) => setEditValue(parseInt(e.target.value))}
                            className="w-20"
                          />
                        ) : (
                          item.allotment
                        )}
                      </td>
                      <td className="text-right p-4">{item.booked_count}</td>
                      <td className="text-right p-4 font-semibold">
                        {item.allotment - item.booked_count - item.tentative_count}
                      </td>
                      <td className="text-right p-4">
                        {isEditing ? (
                          <div className="flex gap-2 justify-end">
                            <Button
                              size="sm"
                              onClick={() => handleUpdate(item.room_type_id, item.date, item.allotment)}
                            >
                              บันทึก
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => setEditingKey(null)}
                            >
                              ยกเลิก
                            </Button>
                          </div>
                        ) : (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => {
                              setEditingKey(key);
                              setEditValue(item.allotment);
                            }}
                          >
                            แก้ไข
                          </Button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </div>
  );
}
```

---

## 4. Reports Page (15 นาที)

### File: `frontend/src/app/(manager)/reports/page.tsx`

```typescript
'use client';

import { useState } from 'react';
import { useOccupancyReport, useRevenueReport } from '@/hooks/use-reports';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { LoadingSpinner } from '@/components/ui/loading';
import { Download, TrendingUp, DollarSign } from 'lucide-react';

export default function ReportsPage() {
  const [dateRange, setDateRange] = useState({
    start_date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    end_date: new Date().toISOString().split('T')[0],
  });

  const { data: occupancy, isLoading: occupancyLoading } = useOccupancyReport(dateRange);
  const { data: revenue, isLoading: revenueLoading } = useRevenueReport(dateRange);

  const isLoading = occupancyLoading || revenueLoading;

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const totalRevenue = revenue?.data?.reduce((sum: number, item: any) => sum + item.total_revenue, 0) || 0;
  const avgOccupancy = occupancy?.data?.reduce((sum: number, item: any) => sum + item.occupancy_rate, 0) / (occupancy?.data?.length || 1) || 0;

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold text-foreground mb-2">
              Reports & Analytics
            </h1>
            <p className="text-muted-foreground">
              รายงานและสถิติการดำเนินงาน
            </p>
          </div>
          <Button>
            <Download className="w-4 h-4 mr-2" />
            Export CSV
          </Button>
        </div>

        {/* Date Range */}
        <Card className="p-6">
          <div className="flex gap-4 items-center">
            <div>
              <label className="block text-sm font-medium mb-2">วันที่เริ่มต้น</label>
              <Input
                type="date"
                value={dateRange.start_date}
                onChange={(e) => setDateRange({ ...dateRange, start_date: e.target.value })}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">วันที่สิ้นสุด</label>
              <Input
                type="date"
                value={dateRange.end_date}
                onChange={(e) => setDateRange({ ...dateRange, end_date: e.target.value })}
              />
            </div>
          </div>
        </Card>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card className="p-6">
            <div className="flex items-center gap-4 mb-4">
              <div className="w-12 h-12 rounded-lg bg-green-50 dark:bg-green-950 flex items-center justify-center">
                <DollarSign className="w-6 h-6 text-green-600 dark:text-green-400" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">รายได้รวม</p>
                <p className="text-3xl font-bold">฿{totalRevenue.toLocaleString()}</p>
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center gap-4 mb-4">
              <div className="w-12 h-12 rounded-lg bg-blue-50 dark:bg-blue-950 flex items-center justify-center">
                <TrendingUp className="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">อัตราการเข้าพักเฉลี่ย</p>
                <p className="text-3xl font-bold">{Math.round(avgOccupancy)}%</p>
              </div>
            </div>
          </Card>
        </div>

        {/* Revenue Report */}
        <Card className="p-6">
          <h3 className="text-xl font-semibold mb-4">รายงานรายได้</h3>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-4">วันที่</th>
                  <th className="text-right p-4">รายได้</th>
                  <th className="text-right p-4">จำนวนการจอง</th>
                </tr>
              </thead>
              <tbody>
                {revenue?.data?.map((item: any, index: number) => (
                  <tr key={index} className="border-b hover:bg-muted/50">
                    <td className="p-4">
                      {new Date(item.date).toLocaleDateString('th-TH')}
                    </td>
                    <td className="text-right p-4 font-semibold">
                      ฿{item.total_revenue.toLocaleString()}
                    </td>
                    <td className="text-right p-4">{item.booking_count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Occupancy Report */}
        <Card className="p-6">
          <h3 className="text-xl font-semibold mb-4">รายงานการเข้าพัก</h3>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-4">วันที่</th>
                  <th className="text-right p-4">ห้องทั้งหมด</th>
                  <th className="text-right p-4">ห้องที่จอง</th>
                  <th className="text-right p-4">อัตราการเข้าพัก</th>
                </tr>
              </thead>
              <tbody>
                {occupancy?.data?.map((item: any, index: number) => (
                  <tr key={index} className="border-b hover:bg-muted/50">
                    <td className="p-4">
                      {new Date(item.date).toLocaleDateString('th-TH')}
                    </td>
                    <td className="text-right p-4">{item.total_rooms}</td>
                    <td className="text-right p-4">{item.occupied_rooms}</td>
                    <td className="text-right p-4 font-semibold">
                      {Math.round(item.occupancy_rate)}%
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </div>
  );
}
```

---

## ✅ Checklist

### Dashboard
- [ ] แสดงรายได้วันนี้จาก API
- [ ] แสดงอัตราการเข้าพักจาก API
- [ ] แสดงจำนวนการจองจาก API
- [ ] Auto-refresh ทุก 30 วินาที

### Pricing Tiers
- [ ] แสดงรายการ rate tiers
- [ ] สร้าง rate tier ใหม่
- [ ] แก้ไข rate tier
- [ ] Loading states

### Inventory
- [ ] แสดง inventory ตามช่วงวันที่
- [ ] แก้ไข allotment
- [ ] แสดงห้องว่าง
- [ ] Date range selector

### Reports
- [ ] แสดงรายงานรายได้
- [ ] แสดงรายงานการเข้าพัก
- [ ] Summary cards
- [ ] Date range filter

---

## 🚀 Testing

```bash
# 1. Login as manager
# Email: manager@hotel.com
# Password: staff123

# 2. Test each page:
# - /dashboard
# - /pricing/tiers
# - /inventory
# - /reports

# 3. Verify:
# - Data loads from API
# - CRUD operations work
# - Loading states show
# - Error handling works
```

---

**เวลาที่ใช้: 1-2 ชั่วโมง**
**ผลลัพธ์: Manager pages ทำงานได้จริงทั้งหมด**
