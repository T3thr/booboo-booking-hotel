"use client";

import { useState, useMemo } from "react";
import {
  useRateTiers,
  usePricingCalendar,
  useUpdatePricingCalendar,
} from "@/hooks/use-pricing";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

export default function CalendarTab() {
  const today = new Date();
  const [selectedYear, setSelectedYear] = useState(today.getFullYear());
  const [selectedMonth, setSelectedMonth] = useState(today.getMonth());
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
        const dateStr = entry.date.split('T')[0]; // แปลง ISO date เป็น YYYY-MM-DD
        map.set(dateStr, entry.rate_tier_id);
      });
    }
    return map;
  }, [calendarData]);

  // Get tier color
  const getTierColor = (tierId: number | undefined) => {
    if (!tierId || !tiers) return "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200";
    
    const tierIndex = tiers.findIndex((t: any) => t.rate_tier_id === tierId);
    const colors = [
      "bg-green-100 text-green-800 border-green-300 dark:bg-green-900 dark:text-green-200",
      "bg-yellow-100 text-yellow-800 border-yellow-300 dark:bg-yellow-900 dark:text-yellow-200",
      "bg-orange-100 text-orange-800 border-orange-300 dark:bg-orange-900 dark:text-orange-200",
      "bg-red-100 text-red-800 border-red-300 dark:bg-red-900 dark:text-red-200",
      "bg-purple-100 text-purple-800 border-purple-300 dark:bg-purple-900 dark:text-purple-200",
      "bg-blue-100 text-blue-800 border-blue-300 dark:bg-blue-900 dark:text-blue-200",
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
      const dateObj = new Date(selectedYear, selectedMonth, day);
      const isToday = dateObj.toDateString() === today.toDateString();
      const isPast = dateObj < today && !isToday;
      
      days.push({ date: dateStr, day, tierId, isToday, isPast, dateObj });
    }
    
    return days;
  }, [selectedYear, selectedMonth, dateToTierMap, today]);

  const handleDateClick = (dateStr: string, isPast: boolean) => {
    if (isPast) return; // ไม่ให้เลือกวันที่ผ่านไปแล้ว
    
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
    if (!selectedTierId || !rangeStart) {
      alert("กรุณาเลือกระดับราคาและวันที่");
      return;
    }

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
      <div className="text-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-muted-foreground">กำลังโหลดข้อมูล...</p>
      </div>
    );
  }

  return (
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
              <h2 className="text-lg font-semibold min-w-[200px] text-center">
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
              onClick={() => {
                setSelectedYear(today.getFullYear());
                setSelectedMonth(today.getMonth());
              }}
              variant="outline"
              size="sm"
            >
              วันนี้
            </Button>
          </div>

          {/* Calendar Grid */}
          <div className="grid grid-cols-7 gap-2">
            {/* Day headers */}
            {dayNames.map((day) => (
              <div
                key={day}
                className="text-center font-semibold text-muted-foreground py-2"
              >
                {day}
              </div>
            ))}

            {/* Calendar days */}
            {calendarDays.map((dayData, index) => {
              if (!dayData) {
                return <div key={`empty-${index}`} className="aspect-square" />;
              }

              const { date, day, tierId, isToday, isPast } = dayData;
              const tierColor = getTierColor(tierId);
              const isSelected = isDateInRange(date);
              const tier = tiers?.find((t: any) => t.rate_tier_id === tierId);

              return (
                <button
                  key={date}
                  onClick={() => handleDateClick(date, isPast)}
                  disabled={isPast}
                  className={`
                    aspect-square p-2 rounded-lg border-2 transition-all text-sm
                    ${tierColor}
                    ${isSelected ? "ring-2 ring-primary ring-offset-2" : ""}
                    ${isToday ? "ring-2 ring-blue-500" : ""}
                    ${isPast ? "opacity-40 cursor-not-allowed" : "hover:shadow-md cursor-pointer"}
                  `}
                >
                  <div className="font-semibold">{day}</div>
                  {tier && (
                    <div className="text-xs mt-1 truncate">{tier.name}</div>
                  )}
                </button>
              );
            })}
          </div>

          {/* Legend */}
          <div className="mt-6 pt-6 border-t border-border">
            <h3 className="text-sm font-semibold mb-3">สีแสดงระดับราคา</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
              {tiers && tiers.map((tier: any, index: number) => (
                <div key={tier.rate_tier_id} className="flex items-center gap-2">
                  <div className={`w-4 h-4 rounded ${getTierColor(tier.rate_tier_id)}`}></div>
                  <span className="text-sm text-foreground">{tier.name}</span>
                </div>
              ))}
            </div>
          </div>
        </Card>
      </div>

      {/* Controls */}
      <div className="space-y-4">
        {/* Selection Mode */}
        <Card className="p-4">
          <h3 className="font-semibold mb-3">โหมดการเลือก</h3>
          <div className="space-y-2">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                checked={selectionMode === "single"}
                onChange={() => {
                  setSelectionMode("single");
                  setRangeStart(null);
                  setRangeEnd(null);
                }}
                className="text-primary"
              />
              <span className="text-sm">เลือกวันเดียว</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                checked={selectionMode === "range"}
                onChange={() => {
                  setSelectionMode("range");
                  setRangeStart(null);
                  setRangeEnd(null);
                }}
                className="text-primary"
              />
              <span className="text-sm">เลือกช่วงวันที่</span>
            </label>
          </div>
        </Card>

        {/* Selected Range */}
        {rangeStart && (
          <Card className="p-4 bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800">
            <h3 className="font-semibold mb-2 text-blue-900 dark:text-blue-100">วันที่เลือก</h3>
            <p className="text-sm text-blue-800 dark:text-blue-200">
              {new Date(rangeStart).toLocaleDateString('th-TH', { 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
              })}
              {rangeEnd && rangeEnd !== rangeStart && (
                <> ถึง {new Date(rangeEnd).toLocaleDateString('th-TH', { 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                })}</>
              )}
            </p>
          </Card>
        )}

        {/* Tier Selection */}
        <Card className="p-4">
          <h3 className="font-semibold mb-3">เลือกระดับราคา</h3>
          {!tiers || tiers.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              ยังไม่มีระดับราคา กรุณาสร้างที่แท็บ "ระดับราคา"
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
                    ${selectedTierId === tier.rate_tier_id ? "ring-2 ring-primary" : ""}
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

        {/* Info */}
        <Card className="p-4 bg-muted/30">
          <h3 className="font-semibold mb-2 text-sm">💡 คำแนะนำ</h3>
          <ul className="text-xs text-muted-foreground space-y-1">
            <li>• คลิกวันที่เพื่อเลือก</li>
            <li>• เลือกระดับราคาที่ต้องการ</li>
            <li>• กดปุ่ม "ใช้ระดับราคา"</li>
            <li>• วันที่ผ่านไปแล้วจะไม่สามารถแก้ไขได้</li>
          </ul>
        </Card>
      </div>
    </div>
  );
}
