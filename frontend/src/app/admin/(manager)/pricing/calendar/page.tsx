"use client";

import { useState, useMemo } from "react";
import {
  useRateTiers,
  usePricingCalendar,
  useUpdatePricingCalendar,
} from "@/hooks/use-pricing";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

export default function PricingCalendarPage() {
  const currentYear = new Date().getFullYear();
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedTierId, setSelectedTierId] = useState<number | null>(null);
  const [selectionMode, setSelectionMode] = useState<"single" | "range">("single");
  const [rangeStart, setRangeStart] = useState<string | null>(null);
  const [rangeEnd, setRangeEnd] = useState<string | null>(null);

  const { data: tiers, isLoading: tiersLoading } = useRateTiers();
  
  const startDate = `${selectedYear}-${String(selectedMonth + 1).padStart(2, "0")}-01`;
  const endDate = new Date(selectedYear, selectedMonth + 1, 0);
  const endDateStr = `${selectedYear}-${String(selectedMonth + 1).padStart(2, "0")}-${String(endDate.getDate()).padStart(2, "0")}`;
  
  const { data: calendarData, isLoading: calendarLoading } = usePricingCalendar({
    start_date: startDate,
    end_date: endDateStr,
  });
  
  const updateCalendar = useUpdatePricingCalendar();

  // Create a map of date -> tier_id
  const dateToTierMap = useMemo(() => {
    const map = new Map<string, number>();
    if (calendarData) {
      calendarData.forEach((entry: any) => {
        map.set(entry.date, entry.rate_tier_id);
      });
    }
    return map;
  }, [calendarData]);

  // Get tier color
  const getTierColor = (tierId: number | undefined) => {
    if (!tierId || !tiers) return "bg-gray-100 text-gray-800";
    
    const tierIndex = tiers.findIndex((t: any) => t.rate_tier_id === tierId);
    const colors = [
      "bg-green-100 text-green-800 border-green-300",
      "bg-yellow-100 text-yellow-800 border-yellow-300",
      "bg-orange-100 text-orange-800 border-orange-300",
      "bg-red-100 text-red-800 border-red-300",
      "bg-purple-100 text-purple-800 border-purple-300",
      "bg-blue-100 text-blue-800 border-blue-300",
    ];
    return colors[tierIndex % colors.length];
  };

  // Generate calendar days
  const calendarDays = useMemo(() => {
    const firstDay = new Date(selectedYear, selectedMonth, 1);
    const lastDay = new Date(selectedYear, selectedMonth + 1, 0);
    const startDayOfWeek = firstDay.getDay();
    
    const days = [];
    
    // Add empty cells for days before month starts
    for (let i = 0; i < startDayOfWeek; i++) {
      days.push(null);
    }
    
    // Add all days of the month
    for (let day = 1; day <= lastDay.getDate(); day++) {
      const dateStr = `${selectedYear}-${String(selectedMonth + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
      const tierId = dateToTierMap.get(dateStr);
      days.push({ date: dateStr, day, tierId });
    }
    
    return days;
  }, [selectedYear, selectedMonth, dateToTierMap]);

  const handleDateClick = (dateStr: string) => {
    if (selectionMode === "single") {
      setRangeStart(dateStr);
      setRangeEnd(dateStr);
    } else {
      if (!rangeStart) {
        setRangeStart(dateStr);
        setRangeEnd(null);
      } else if (!rangeEnd) {
        if (dateStr >= rangeStart) {
          setRangeEnd(dateStr);
        } else {
          setRangeStart(dateStr);
          setRangeEnd(null);
        }
      } else {
        setRangeStart(dateStr);
        setRangeEnd(null);
      }
    }
  };

  const handleApplyTier = async () => {
    if (!selectedTierId || !rangeStart) return;

    const endDate = rangeEnd || rangeStart;

    try {
      await updateCalendar.mutateAsync({
        start_date: rangeStart,
        end_date: endDate,
        rate_tier_id: selectedTierId,
      });
      
      setRangeStart(null);
      setRangeEnd(null);
      alert("อัปเดตปฏิทินราคาสำเร็จ");
    } catch (error) {
      console.error("Failed to update calendar:", error);
      alert("ไม่สามารถอัปเดตปฏิทินราคาได้: " + (error as Error).message);
    }
  };

  const handleCopyFromPreviousYear = async () => {
    if (!confirm(`คัดลอกการตั้งค่าจากปี ${selectedYear - 1} ไปยังปี ${selectedYear} หรือไม่?`)) {
      return;
    }

    try {
      // This would need a backend endpoint to copy previous year's data
      alert("ฟีเจอร์นี้ต้องการ API endpoint เพิ่มเติมจาก backend");
    } catch (error) {
      console.error("Failed to copy from previous year:", error);
      alert("ไม่สามารถคัดลอกข้อมูลได้: " + (error as Error).message);
    }
  };

  const isDateInRange = (dateStr: string) => {
    if (!rangeStart) return false;
    if (!rangeEnd) return dateStr === rangeStart;
    return dateStr >= rangeStart && dateStr <= rangeEnd;
  };

  const monthNames = [
    "มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน",
    "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"
  ];

  const dayNames = ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"];

  if (tiersLoading || calendarLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">กำลังโหลดข้อมูล...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">ปฏิทินราคา (Pricing Calendar)</h1>
        <p className="mt-2 text-gray-600">
          กำหนดระดับราคาสำหรับแต่ละวันในปี
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Calendar */}
        <div className="lg:col-span-2">
          <Card className="p-6">
            {/* Month/Year Selector */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-2">
                <Button
                  onClick={() => {
                    if (selectedMonth === 0) {
                      setSelectedMonth(11);
                      setSelectedYear(selectedYear - 1);
                    } else {
                      setSelectedMonth(selectedMonth - 1);
                    }
                  }}
                  variant="outline"
                  size="sm"
                >
                  ←
                </Button>
                <h2 className="text-lg font-semibold">
                  {monthNames[selectedMonth]} {selectedYear + 543}
                </h2>
                <Button
                  onClick={() => {
                    if (selectedMonth === 11) {
                      setSelectedMonth(0);
                      setSelectedYear(selectedYear + 1);
                    } else {
                      setSelectedMonth(selectedMonth + 1);
                    }
                  }}
                  variant="outline"
                  size="sm"
                >
                  →
                </Button>
              </div>
              <Button
                onClick={handleCopyFromPreviousYear}
                variant="outline"
                size="sm"
              >
                คัดลอกจากปีก่อน
              </Button>
            </div>

            {/* Calendar Grid */}
            <div className="grid grid-cols-7 gap-2">
              {/* Day headers */}
              {dayNames.map((day) => (
                <div
                  key={day}
                  className="text-center font-semibold text-gray-600 py-2"
                >
                  {day}
                </div>
              ))}

              {/* Calendar days */}
              {calendarDays.map((dayData, index) => {
                if (!dayData) {
                  return <div key={`empty-${index}`} className="aspect-square" />;
                }

                const { date, day, tierId } = dayData;
                const tierColor = getTierColor(tierId);
                const isSelected = isDateInRange(date);
                const tier = tiers?.find((t: any) => t.rate_tier_id === tierId);

                return (
                  <button
                    key={date}
                    onClick={() => handleDateClick(date)}
                    className={`
                      aspect-square p-2 rounded-lg border-2 transition-all
                      ${tierColor}
                      ${isSelected ? "ring-2 ring-blue-500 ring-offset-2" : ""}
                      hover:shadow-md
                    `}
                  >
                    <div className="text-sm font-semibold">{day}</div>
                    {tier && (
                      <div className="text-xs mt-1 truncate">{tier.name}</div>
                    )}
                  </button>
                );
              })}
            </div>
          </Card>
        </div>

        {/* Controls */}
        <div className="space-y-4">
          {/* Selection Mode */}
          <Card className="p-4">
            <h3 className="font-semibold mb-3">โหมดการเลือก</h3>
            <div className="space-y-2">
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  checked={selectionMode === "single"}
                  onChange={() => {
                    setSelectionMode("single");
                    setRangeStart(null);
                    setRangeEnd(null);
                  }}
                />
                <span>เลือกวันเดียว</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="radio"
                  checked={selectionMode === "range"}
                  onChange={() => {
                    setSelectionMode("range");
                    setRangeStart(null);
                    setRangeEnd(null);
                  }}
                />
                <span>เลือกช่วงวันที่</span>
              </label>
            </div>
          </Card>

          {/* Selected Range */}
          {rangeStart && (
            <Card className="p-4 bg-blue-50 border-blue-200">
              <h3 className="font-semibold mb-2">วันที่เลือก</h3>
              <p className="text-sm">
                {rangeStart}
                {rangeEnd && rangeEnd !== rangeStart && ` ถึง ${rangeEnd}`}
              </p>
            </Card>
          )}

          {/* Tier Selection */}
          <Card className="p-4">
            <h3 className="font-semibold mb-3">เลือกระดับราคา</h3>
            {!tiers || tiers.length === 0 ? (
              <p className="text-sm text-gray-500">
                ยังไม่มีระดับราคา กรุณาสร้างที่หน้า "จัดการระดับราคา"
              </p>
            ) : (
              <div className="space-y-2">
                {tiers.map((tier: any) => (
                  <button
                    key={tier.rate_tier_id}
                    onClick={() => setSelectedTierId(tier.rate_tier_id)}
                    className={`
                      w-full p-3 rounded-lg border-2 text-left transition-all
                      ${getTierColor(tier.rate_tier_id)}
                      ${selectedTierId === tier.rate_tier_id ? "ring-2 ring-blue-500" : ""}
                    `}
                  >
                    {tier.name}
                  </button>
                ))}
              </div>
            )}
          </Card>

          {/* Apply Button */}
          <Button
            onClick={handleApplyTier}
            disabled={!selectedTierId || !rangeStart || updateCalendar.isPending}
            className="w-full"
          >
            {updateCalendar.isPending ? "กำลังบันทึก..." : "ใช้ระดับราคา"}
          </Button>

          {/* Legend */}
          <Card className="p-4">
            <h3 className="font-semibold mb-3">คำอธิบาย</h3>
            <div className="space-y-2 text-sm">
              <p>• คลิกวันที่เพื่อเลือก</p>
              <p>• เลือกระดับราคาที่ต้องการ</p>
              <p>• กดปุ่ม "ใช้ระดับราคา"</p>
              <p>• สีต่างๆ แสดงระดับราคาที่แตกต่างกัน</p>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
