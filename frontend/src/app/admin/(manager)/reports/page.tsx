"use client";

import { useState, useMemo } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useOccupancyReport, useRevenueReport, useVoucherReport } from "@/hooks/use-reports";
import { formatCurrency, formatDate } from "@/utils/date";

type ReportType = "occupancy" | "revenue" | "vouchers";
type ViewMode = "daily" | "weekly" | "monthly";

export default function ReportsPage() {
  const [reportType, setReportType] = useState<ReportType>("occupancy");
  const [viewMode, setViewMode] = useState<ViewMode>("daily");
  const [startDate, setStartDate] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() - 30);
    return date.toISOString().split("T")[0];
  });
  const [endDate, setEndDate] = useState(() => {
    return new Date().toISOString().split("T")[0];
  });
  const [compareWithLastYear, setCompareWithLastYear] = useState(false);

  // Calculate previous year dates for comparison
  const prevYearStartDate = useMemo(() => {
    const date = new Date(startDate);
    date.setFullYear(date.getFullYear() - 1);
    return date.toISOString().split("T")[0];
  }, [startDate]);

  const prevYearEndDate = useMemo(() => {
    const date = new Date(endDate);
    date.setFullYear(date.getFullYear() - 1);
    return date.toISOString().split("T")[0];
  }, [endDate]);

  // Fetch current period data
  const { data: occupancyResponse, isLoading: occupancyLoading } = useOccupancyReport({
    start_date: startDate,
    end_date: endDate,
  });

  const { data: revenueResponse, isLoading: revenueLoading } = useRevenueReport({
    start_date: startDate,
    end_date: endDate,
  });

  const { data: voucherResponse, isLoading: voucherLoading } = useVoucherReport({
    start_date: startDate,
    end_date: endDate,
  });

  // Fetch previous year data for comparison
  const { data: prevOccupancyResponse } = useOccupancyReport({
    start_date: prevYearStartDate,
    end_date: prevYearEndDate,
  });

  const { data: prevRevenueResponse } = useRevenueReport({
    start_date: prevYearStartDate,
    end_date: prevYearEndDate,
  });

  // Ensure data is always an array
  const occupancyData = useMemo(() => {
    if (!occupancyResponse) return [];
    if (Array.isArray(occupancyResponse)) return occupancyResponse;
    if (occupancyResponse.data && Array.isArray(occupancyResponse.data)) return occupancyResponse.data;
    return [];
  }, [occupancyResponse]);

  const revenueData = useMemo(() => {
    if (!revenueResponse) return [];
    if (Array.isArray(revenueResponse)) return revenueResponse;
    if (revenueResponse.data && Array.isArray(revenueResponse.data)) return revenueResponse.data;
    return [];
  }, [revenueResponse]);

  const voucherData = useMemo(() => {
    if (!voucherResponse) return [];
    if (Array.isArray(voucherResponse)) return voucherResponse;
    if (voucherResponse.data && Array.isArray(voucherResponse.data)) return voucherResponse.data;
    return [];
  }, [voucherResponse]);

  const prevOccupancyData = useMemo(() => {
    if (!prevOccupancyResponse) return [];
    if (Array.isArray(prevOccupancyResponse)) return prevOccupancyResponse;
    if (prevOccupancyResponse.data && Array.isArray(prevOccupancyResponse.data)) return prevOccupancyResponse.data;
    return [];
  }, [prevOccupancyResponse]);

  const prevRevenueData = useMemo(() => {
    if (!prevRevenueResponse) return [];
    if (Array.isArray(prevRevenueResponse)) return prevRevenueResponse;
    if (prevRevenueResponse.data && Array.isArray(prevRevenueResponse.data)) return prevRevenueResponse.data;
    return [];
  }, [prevRevenueResponse]);

  const isLoading = occupancyLoading || revenueLoading || voucherLoading;

  // Calculate summary statistics
  const summary = useMemo(() => {
    if (!Array.isArray(occupancyData) || !Array.isArray(revenueData)) {
      console.warn('[Reports] Data is not array:', { occupancyData, revenueData });
      return null;
    }

    if (occupancyData.length === 0 && revenueData.length === 0) {
      return null;
    }

    const totalRevenue = revenueData.reduce((sum: number, item: any) => sum + (item.total_revenue || 0), 0);
    const totalBookings = revenueData.reduce((sum: number, item: any) => sum + (item.booking_count || 0), 0);
    const totalRoomNights = revenueData.reduce((sum: number, item: any) => sum + (item.room_nights || 0), 0);
    const avgOccupancy = occupancyData.length > 0 
      ? occupancyData.reduce((sum: number, item: any) => sum + (item.occupancy_rate || 0), 0) / occupancyData.length 
      : 0;
    const adr = totalRoomNights > 0 ? totalRevenue / totalRoomNights : 0;

    return {
      totalRevenue,
      totalBookings,
      totalRoomNights,
      avgOccupancy,
      adr,
    };
  }, [occupancyData, revenueData]);

  // Calculate previous year summary for comparison
  const prevSummary = useMemo(() => {
    if (!compareWithLastYear || !prevOccupancyData || !prevRevenueData) return null;

    const totalRevenue = prevRevenueData.reduce((sum: number, item: any) => sum + item.total_revenue, 0);
    const totalRoomNights = prevRevenueData.reduce((sum: number, item: any) => sum + item.room_nights, 0);
    const avgOccupancy = prevOccupancyData.reduce((sum: number, item: any) => sum + item.occupancy_rate, 0) / (prevOccupancyData.length || 1);
    const adr = totalRoomNights > 0 ? totalRevenue / totalRoomNights : 0;

    return {
      totalRevenue,
      avgOccupancy,
      adr,
    };
  }, [compareWithLastYear, prevOccupancyData, prevRevenueData]);

  // Calculate percentage changes
  const changes = useMemo(() => {
    if (!summary || !prevSummary) return null;

    return {
      revenue: prevSummary.totalRevenue > 0 
        ? ((summary.totalRevenue - prevSummary.totalRevenue) / prevSummary.totalRevenue) * 100 
        : 0,
      occupancy: prevSummary.avgOccupancy > 0 
        ? ((summary.avgOccupancy - prevSummary.avgOccupancy) / prevSummary.avgOccupancy) * 100 
        : 0,
      adr: prevSummary.adr > 0 
        ? ((summary.adr - prevSummary.adr) / prevSummary.adr) * 100 
        : 0,
    };
  }, [summary, prevSummary]);

  const handleExport = async () => {
    try {
      const params = {
        start_date: startDate,
        end_date: endDate,
        type: reportType,
      };
      
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'}/api/reports/export?${new URLSearchParams(params)}`,
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        }
      );

      if (!response.ok) throw new Error("Export failed");

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${reportType}_report_${startDate}_${endDate}.csv`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (error) {
      console.error("Export error:", error);
      alert("ไม่สามารถส่งออกรายงานได้");
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">รายงานและการวิเคราะห์</h1>
        <p className="mt-2 text-gray-600">
          ติดตามผลการดำเนินงานและวิเคราะห์ข้อมูลธุรกิจ
        </p>
      </div>

      {/* Filters */}
      <Card className="p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              วันที่เริ่มต้น
            </label>
            <Input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              วันที่สิ้นสุด
            </label>
            <Input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              ประเภทรายงาน
            </label>
            <select
              value={reportType}
              onChange={(e) => setReportType(e.target.value as ReportType)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="occupancy">การเข้าพัก (Occupancy)</option>
              <option value="revenue">รายได้ (Revenue)</option>
              <option value="vouchers">คูปอง (Vouchers)</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              มุมมอง
            </label>
            <select
              value={viewMode}
              onChange={(e) => setViewMode(e.target.value as ViewMode)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="daily">รายวัน</option>
              <option value="weekly">รายสัปดาห์</option>
              <option value="monthly">รายเดือน</option>
            </select>
          </div>
        </div>

        <div className="mt-4 flex items-center justify-between">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={compareWithLastYear}
              onChange={(e) => setCompareWithLastYear(e.target.checked)}
              className="mr-2"
            />
            <span className="text-sm text-gray-700">เปรียบเทียบกับปีก่อน</span>
          </label>
          <Button onClick={handleExport} variant="outline">
            📥 ส่งออก CSV
          </Button>
        </div>
      </Card>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <Card className="p-6">
            <div className="text-sm text-gray-600 mb-1">รายได้รวม</div>
            <div className="text-2xl font-bold text-gray-900">
              {formatCurrency(summary.totalRevenue)}
            </div>
            {changes && (
              <div className={`text-sm mt-2 ${changes.revenue >= 0 ? "text-green-600" : "text-red-600"}`}>
                {changes.revenue >= 0 ? "↑" : "↓"} {Math.abs(changes.revenue).toFixed(1)}% จากปีก่อน
              </div>
            )}
          </Card>

          <Card className="p-6">
            <div className="text-sm text-gray-600 mb-1">การจองทั้งหมด</div>
            <div className="text-2xl font-bold text-gray-900">
              {summary.totalBookings}
            </div>
            <div className="text-sm text-gray-500 mt-2">
              {summary.totalRoomNights} คืน
            </div>
          </Card>

          <Card className="p-6">
            <div className="text-sm text-gray-600 mb-1">อัตราการเข้าพักเฉลี่ย</div>
            <div className="text-2xl font-bold text-gray-900">
              {summary.avgOccupancy.toFixed(1)}%
            </div>
            {changes && (
              <div className={`text-sm mt-2 ${changes.occupancy >= 0 ? "text-green-600" : "text-red-600"}`}>
                {changes.occupancy >= 0 ? "↑" : "↓"} {Math.abs(changes.occupancy).toFixed(1)}% จากปีก่อน
              </div>
            )}
          </Card>

          <Card className="p-6">
            <div className="text-sm text-gray-600 mb-1">ADR (ราคาเฉลี่ยต่อคืน)</div>
            <div className="text-2xl font-bold text-gray-900">
              {formatCurrency(summary.adr)}
            </div>
            {changes && (
              <div className={`text-sm mt-2 ${changes.adr >= 0 ? "text-green-600" : "text-red-600"}`}>
                {changes.adr >= 0 ? "↑" : "↓"} {Math.abs(changes.adr).toFixed(1)}% จากปีก่อน
              </div>
            )}
          </Card>
        </div>
      )}

      {/* Report Content */}
      {isLoading ? (
        <Card className="p-12 text-center">
          <div className="text-gray-500">กำลังโหลดข้อมูล...</div>
        </Card>
      ) : (
        <>
          {reportType === "occupancy" && occupancyData && (
            <OccupancyReport data={occupancyData} viewMode={viewMode} />
          )}
          {reportType === "revenue" && revenueData && (
            <RevenueReport data={revenueData} viewMode={viewMode} />
          )}
          {reportType === "vouchers" && voucherData && (
            <VoucherReport data={voucherData} />
          )}
        </>
      )}
    </div>
  );
}

// Occupancy Report Component
function OccupancyReport({ data, viewMode }: { data: any[]; viewMode: ViewMode }) {
  const aggregatedData = useMemo(() => {
    if (viewMode === "daily") return data;

    // Group by week or month
    const grouped = data.reduce((acc: any, item: any) => {
      const date = new Date(item.date);
      let key: string;

      if (viewMode === "weekly") {
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay());
        key = weekStart.toISOString().split("T")[0];
      } else {
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
      }

      if (!acc[key]) {
        acc[key] = {
          date: key,
          total_rooms: 0,
          booked_rooms: 0,
          count: 0,
        };
      }

      acc[key].total_rooms += item.total_rooms;
      acc[key].booked_rooms += item.booked_rooms;
      acc[key].count += 1;

      return acc;
    }, {});

    return Object.values(grouped).map((item: any) => ({
      ...item,
      occupancy_rate: (item.booked_rooms / item.total_rooms) * 100,
      available_rooms: item.total_rooms - item.booked_rooms,
    }));
  }, [data, viewMode]);

  return (
    <Card className="p-6">
      <h2 className="text-xl font-bold mb-4">รายงานการเข้าพัก</h2>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b">
              <th className="text-left py-3 px-4">วันที่</th>
              <th className="text-right py-3 px-4">ห้องทั้งหมด</th>
              <th className="text-right py-3 px-4">ห้องที่จอง</th>
              <th className="text-right py-3 px-4">ห้องว่าง</th>
              <th className="text-right py-3 px-4">อัตราการเข้าพัก</th>
            </tr>
          </thead>
          <tbody>
            {aggregatedData.map((item: any, index: number) => (
              <tr key={index} className="border-b hover:bg-gray-50">
                <td className="py-3 px-4">{formatDate(item.date)}</td>
                <td className="text-right py-3 px-4">{item.total_rooms}</td>
                <td className="text-right py-3 px-4">{item.booked_rooms}</td>
                <td className="text-right py-3 px-4">{item.available_rooms}</td>
                <td className="text-right py-3 px-4">
                  <span
                    className={`px-2 py-1 rounded ${
                      item.occupancy_rate >= 80
                        ? "bg-green-100 text-green-800"
                        : item.occupancy_rate >= 50
                        ? "bg-yellow-100 text-yellow-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {item.occupancy_rate.toFixed(1)}%
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}

// Revenue Report Component
function RevenueReport({ data, viewMode }: { data: any[]; viewMode: ViewMode }) {
  const aggregatedData = useMemo(() => {
    if (viewMode === "daily") return data;

    const grouped = data.reduce((acc: any, item: any) => {
      const date = new Date(item.date);
      let key: string;

      if (viewMode === "weekly") {
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay());
        key = weekStart.toISOString().split("T")[0];
      } else {
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
      }

      if (!acc[key]) {
        acc[key] = {
          date: key,
          total_revenue: 0,
          booking_count: 0,
          room_nights: 0,
        };
      }

      acc[key].total_revenue += item.total_revenue;
      acc[key].booking_count += item.booking_count;
      acc[key].room_nights += item.room_nights;

      return acc;
    }, {});

    return Object.values(grouped).map((item: any) => ({
      ...item,
      adr: item.room_nights > 0 ? item.total_revenue / item.room_nights : 0,
    }));
  }, [data, viewMode]);

  return (
    <Card className="p-6">
      <h2 className="text-xl font-bold mb-4">รายงานรายได้</h2>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b">
              <th className="text-left py-3 px-4">วันที่</th>
              <th className="text-right py-3 px-4">รายได้</th>
              <th className="text-right py-3 px-4">จำนวนการจอง</th>
              <th className="text-right py-3 px-4">จำนวนคืน</th>
              <th className="text-right py-3 px-4">ADR</th>
            </tr>
          </thead>
          <tbody>
            {aggregatedData.map((item: any, index: number) => (
              <tr key={index} className="border-b hover:bg-gray-50">
                <td className="py-3 px-4">{formatDate(item.date)}</td>
                <td className="text-right py-3 px-4 font-semibold">
                  {formatCurrency(item.total_revenue)}
                </td>
                <td className="text-right py-3 px-4">{item.booking_count}</td>
                <td className="text-right py-3 px-4">{item.room_nights}</td>
                <td className="text-right py-3 px-4">{formatCurrency(item.adr)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}

// Voucher Report Component
function VoucherReport({ data }: { data: any[] }) {
  return (
    <Card className="p-6">
      <h2 className="text-xl font-bold mb-4">รายงานคูปอง</h2>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b">
              <th className="text-left py-3 px-4">รหัสคูปอง</th>
              <th className="text-left py-3 px-4">ประเภท</th>
              <th className="text-right py-3 px-4">มูลค่าส่วนลด</th>
              <th className="text-right py-3 px-4">จำนวนการใช้</th>
              <th className="text-right py-3 px-4">ส่วนลดรวม</th>
              <th className="text-right py-3 px-4">รายได้รวม</th>
              <th className="text-right py-3 px-4">อัตราการแปลง</th>
            </tr>
          </thead>
          <tbody>
            {data.map((item: any, index: number) => (
              <tr key={index} className="border-b hover:bg-gray-50">
                <td className="py-3 px-4 font-mono">{item.code}</td>
                <td className="py-3 px-4">
                  {item.discount_type === "Percentage" ? "เปอร์เซ็นต์" : "จำนวนเงิน"}
                </td>
                <td className="text-right py-3 px-4">
                  {item.discount_type === "Percentage"
                    ? `${item.discount_value}%`
                    : formatCurrency(item.discount_value)}
                </td>
                <td className="text-right py-3 px-4">{item.total_uses}</td>
                <td className="text-right py-3 px-4 text-red-600">
                  -{formatCurrency(item.total_discount)}
                </td>
                <td className="text-right py-3 px-4 font-semibold">
                  {formatCurrency(item.total_revenue)}
                </td>
                <td className="text-right py-3 px-4">
                  <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded">
                    {item.conversion_rate.toFixed(1)}%
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}
