"use client";

import { useState, useMemo } from "react";
import { useInventory, useUpdateInventory } from "@/hooks/use-inventory";
import { useQuery } from "@tanstack/react-query";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toast } from "sonner";
import type { RoomInventory } from "@/types";

interface RoomType {
  room_type_id: number;
  name: string;
  description: string;
  base_price: number;
  max_occupancy: number;
  default_allotment: number;
}

export default function InventoryManagementPage() {
  const [selectedRoomType, setSelectedRoomType] = useState<number | null>(null);
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  });
  const [editMode, setEditMode] = useState<"single" | "bulk" | null>(null);
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [bulkStartDate, setBulkStartDate] = useState<string>("");
  const [bulkEndDate, setBulkEndDate] = useState<string>("");
  const [allotmentValue, setAllotmentValue] = useState<string>("");
  const [validationErrors, setValidationErrors] = useState<
    { date: string; message: string }[]
  >([]);

  // Fetch room types from database
  const { data: roomTypesResponse, isLoading: roomTypesLoading, error: roomTypesError } = useQuery({
    queryKey: ["roomTypes"],
    queryFn: async () => {
      console.log('[Inventory] Fetching room types...');
      const response = await fetch("/api/rooms/types");
      console.log('[Inventory] Room types response status:', response.status);
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('[Inventory] Room types error:', errorText);
        throw new Error(`Failed to fetch room types: ${response.status}`);
      }
      
      const data = await response.json();
      console.log('[Inventory] Room types data:', data);
      return data;
    },
  });

  // Ensure roomTypes is always an array
  const roomTypes = useMemo(() => {
    console.log('[Inventory] Processing room types response:', roomTypesResponse);
    
    if (!roomTypesResponse) {
      console.log('[Inventory] No response');
      return [];
    }
    
    // Handle direct array response
    if (Array.isArray(roomTypesResponse)) {
      console.log('[Inventory] Direct array:', roomTypesResponse.length, 'items');
      return roomTypesResponse;
    }
    
    // Handle wrapped response
    if (roomTypesResponse.data && Array.isArray(roomTypesResponse.data)) {
      console.log('[Inventory] Wrapped array:', roomTypesResponse.data.length, 'items');
      return roomTypesResponse.data;
    }
    
    // Handle success wrapper
    if (roomTypesResponse.success && roomTypesResponse.data) {
      if (Array.isArray(roomTypesResponse.data)) {
        console.log('[Inventory] Success wrapped array:', roomTypesResponse.data.length, 'items');
        return roomTypesResponse.data;
      }
    }
    
    console.error('[Inventory] Unknown response format:', roomTypesResponse);
    return [];
  }, [roomTypesResponse]);

  // Calculate date range for the selected month
  const dateRange = useMemo(() => {
    const [year, month] = selectedMonth.split("-").map(Number);
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);
    return {
      start: startDate.toISOString().split("T")[0],
      end: endDate.toISOString().split("T")[0],
    };
  }, [selectedMonth]);

  // Fetch inventory data
  const { data: inventoryResponse, isLoading } = useInventory({
    room_type_id: selectedRoomType || undefined,
    start_date: dateRange.start,
    end_date: dateRange.end,
  });

  // Ensure inventoryData is always an array
  const inventoryData = useMemo(() => {
    if (!inventoryResponse) {
      console.log('[Inventory] No response');
      return [];
    }
    if (Array.isArray(inventoryResponse)) {
      console.log('[Inventory] Response is array:', inventoryResponse.length, 'items');
      return inventoryResponse;
    }
    if (inventoryResponse.data && Array.isArray(inventoryResponse.data)) {
      console.log('[Inventory] Response.data is array:', inventoryResponse.data.length, 'items');
      return inventoryResponse.data;
    }
    console.error('[Inventory] Invalid response format:', inventoryResponse);
    return [];
  }, [inventoryResponse]);

  const updateInventoryMutation = useUpdateInventory();

  // Generate calendar days
  const calendarDays = useMemo(() => {
    const [year, month] = selectedMonth.split("-").map(Number);
    const firstDay = new Date(year, month - 1, 1);
    const lastDay = new Date(year, month, 0);
    const days: Date[] = [];

    for (let d = new Date(firstDay); d <= lastDay; d.setDate(d.getDate() + 1)) {
      days.push(new Date(d));
    }

    return days;
  }, [selectedMonth]);

  // Get inventory for a specific date and room type
  const getInventoryForDate = (date: Date, roomTypeId: number) => {
    const dateStr = date.toISOString().split("T")[0];
    return inventoryData.find(
      (inv: RoomInventory) =>
        inv.room_type_id === roomTypeId &&
        inv.date.split("T")[0] === dateStr
    );
  };

  // Calculate heatmap color based on availability
  const getHeatmapColor = (inventory: RoomInventory | undefined) => {
    if (!inventory) return "bg-gray-100";
    
    const available = inventory.allotment - inventory.booked_count - inventory.tentative_count;
    const occupancyRate = ((inventory.booked_count + inventory.tentative_count) / inventory.allotment) * 100;

    if (occupancyRate >= 90) return "bg-red-500 text-white";
    if (occupancyRate >= 70) return "bg-orange-400 text-white";
    if (occupancyRate >= 50) return "bg-yellow-300";
    if (occupancyRate >= 30) return "bg-green-200";
    return "bg-green-100";
  };

  // Handle single date edit
  const handleSingleEdit = (date: string, roomTypeId: number) => {
    const inventory = inventoryData.find(
      (inv: RoomInventory) =>
        inv.room_type_id === roomTypeId &&
        inv.date.split("T")[0] === date
    );
    
    setEditMode("single");
    setSelectedDate(date);
    setSelectedRoomType(roomTypeId);
    setAllotmentValue(inventory?.allotment.toString() || "");
    setValidationErrors([]);
  };

  // Handle bulk edit
  const handleBulkEdit = () => {
    if (!selectedRoomType) {
      alert("กรุณาเลือกประเภทห้องก่อน");
      return;
    }
    setEditMode("bulk");
    setBulkStartDate(dateRange.start);
    setBulkEndDate(dateRange.end);
    setAllotmentValue("");
    setValidationErrors([]);
  };

  // Validate and submit single update
  const handleSingleSubmit = async () => {
    if (!selectedDate || !selectedRoomType || !allotmentValue) return;

    const allotment = parseInt(allotmentValue);
    if (isNaN(allotment) || allotment < 0) {
      setValidationErrors([
        { date: selectedDate, message: "จำนวนห้องต้องเป็นตัวเลขที่มากกว่าหรือเท่ากับ 0" },
      ]);
      return;
    }

    // Check if allotment is less than current bookings
    const inventory = inventoryData.find(
      (inv: RoomInventory) =>
        inv.room_type_id === selectedRoomType &&
        inv.date.split("T")[0] === selectedDate
    );

    if (inventory) {
      const minRequired = inventory.booked_count + inventory.tentative_count;
      if (allotment < minRequired) {
        setValidationErrors([
          {
            date: selectedDate,
            message: `ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน (${minRequired} ห้อง)`,
          },
        ]);
        return;
      }
    }

    try {
      await updateInventoryMutation.mutateAsync([
        {
          room_type_id: selectedRoomType,
          date: selectedDate,
          allotment,
        },
      ]);
      setEditMode(null);
      setSelectedDate(null);
      setAllotmentValue("");
      setValidationErrors([]);
    } catch (error: any) {
      setValidationErrors([
        { date: selectedDate, message: error.message || "เกิดข้อผิดพลาดในการอัปเดต" },
      ]);
    }
  };

  // Validate and submit bulk update
  const handleBulkSubmit = async () => {
    if (!selectedRoomType || !bulkStartDate || !bulkEndDate || !allotmentValue) {
      alert("กรุณากรอกข้อมูลให้ครบถ้วน");
      return;
    }

    const allotment = parseInt(allotmentValue);
    if (isNaN(allotment) || allotment < 0) {
      alert("จำนวนห้องต้องเป็นตัวเลขที่มากกว่าหรือเท่ากับ 0");
      return;
    }

    if (new Date(bulkEndDate) < new Date(bulkStartDate)) {
      alert("วันที่สิ้นสุดต้องมากกว่าหรือเท่ากับวันที่เริ่มต้น");
      return;
    }

    // Generate all dates in range
    const updates: { room_type_id: number; date: string; allotment: number }[] = [];
    const errors: { date: string; message: string }[] = [];
    
    const start = new Date(bulkStartDate);
    const end = new Date(bulkEndDate);
    
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toISOString().split("T")[0];
      const inventory = inventoryData.find(
        (inv: RoomInventory) =>
          inv.room_type_id === selectedRoomType &&
          inv.date.split("T")[0] === dateStr
      );

      if (inventory) {
        const minRequired = inventory.booked_count + inventory.tentative_count;
        if (allotment < minRequired) {
          errors.push({
            date: dateStr,
            message: `ไม่สามารถลดจำนวนห้องต่ำกว่าการจองปัจจุบัน (${minRequired} ห้อง)`,
          });
          continue;
        }
      }

      updates.push({
        room_type_id: selectedRoomType,
        date: dateStr,
        allotment,
      });
    }

    if (errors.length > 0) {
      setValidationErrors(errors);
      return;
    }

    try {
      await updateInventoryMutation.mutateAsync(updates);
      setEditMode(null);
      setBulkStartDate("");
      setBulkEndDate("");
      setAllotmentValue("");
      setValidationErrors([]);
    } catch (error: any) {
      alert(error.message || "เกิดข้อผิดพลาดในการอัปเดต");
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">จัดการสต็อกห้องพัก</h1>
        <p className="mt-1 text-sm text-gray-600">
          จัดการจำนวนห้องที่เปิดขายสำหรับแต่ละวัน
        </p>
      </div>

      {/* Controls */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Room Type Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              ประเภทห้อง
            </label>
            <select
              value={selectedRoomType || ""}
              onChange={(e) => setSelectedRoomType(Number(e.target.value) || null)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">ทุกประเภท</option>
              {roomTypes.map((type: RoomType) => (
                <option key={type.room_type_id} value={type.room_type_id}>
                  {type.name}
                </option>
              ))}
            </select>
          </div>

          {/* Month Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              เดือน
            </label>
            <input
              type="month"
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Bulk Edit Button */}
          <div className="flex items-end">
            <button
              onClick={handleBulkEdit}
              disabled={!selectedRoomType}
              className="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              แก้ไขแบบกลุ่ม
            </button>
          </div>
        </div>
      </div>

      {/* Legend */}
      <div className="bg-white rounded-lg shadow p-4 mb-6">
        <h3 className="text-sm font-medium text-gray-700 mb-3">สีแสดงระดับการจอง</h3>
        <div className="flex flex-wrap gap-4">
          <div className="flex items-center">
            <div className="w-6 h-6 bg-green-100 border border-gray-300 rounded mr-2"></div>
            <span className="text-sm text-gray-600">&lt; 30% (ว่างมาก)</span>
          </div>
          <div className="flex items-center">
            <div className="w-6 h-6 bg-green-200 border border-gray-300 rounded mr-2"></div>
            <span className="text-sm text-gray-600">30-50%</span>
          </div>
          <div className="flex items-center">
            <div className="w-6 h-6 bg-yellow-300 border border-gray-300 rounded mr-2"></div>
            <span className="text-sm text-gray-600">50-70%</span>
          </div>
          <div className="flex items-center">
            <div className="w-6 h-6 bg-orange-400 border border-gray-300 rounded mr-2"></div>
            <span className="text-sm text-gray-600">70-90%</span>
          </div>
          <div className="flex items-center">
            <div className="w-6 h-6 bg-red-500 border border-gray-300 rounded mr-2"></div>
            <span className="text-sm text-gray-600">&gt;= 90% (เกือบเต็ม)</span>
          </div>
        </div>
      </div>

      {/* Validation Errors */}
      {validationErrors.length > 0 && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <h3 className="text-sm font-medium text-red-800 mb-2">
            ข้อผิดพลาดในการตรวจสอบ
          </h3>
          <ul className="list-disc list-inside space-y-1">
            {validationErrors.map((error, idx) => (
              <li key={idx} className="text-sm text-red-700">
                {error.date}: {error.message}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Error State */}
      {roomTypesError && (
        <Card className="p-6 bg-destructive/10 border-destructive/30">
          <h3 className="font-semibold text-destructive mb-2">เกิดข้อผิดพลาดในการโหลดข้อมูล</h3>
          <p className="text-sm text-muted-foreground">{(roomTypesError as Error).message}</p>
          <p className="text-xs text-muted-foreground mt-2">
            กรุณาตรวจสอบ:
            <br />• Backend กำลังทำงานที่ http://localhost:8080
            <br />• Database มีข้อมูล room_types
            <br />• เปิด Console เพื่อดู error details
          </p>
        </Card>
      )}

      {/* Loading State */}
      {(isLoading || roomTypesLoading) && (
        <div className="text-center py-12 bg-card rounded-lg">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">กำลังโหลดข้อมูล...</p>
        </div>
      )}

      {/* Debug Info */}
      {!isLoading && !roomTypesLoading && (
        <Card className="p-4 bg-muted/30 text-xs font-mono">
          <p>Room Types Count: {roomTypes.length}</p>
          <p>Selected Room Type: {selectedRoomType || 'None'}</p>
          <p>Inventory Data Count: {inventoryData.length}</p>
        </Card>
      )}

      {/* Empty State - No Room Type Selected */}
      {!isLoading && !selectedRoomType && (
        <div className="text-center py-12 bg-card rounded-lg border border-border">
          <div className="text-muted-foreground mb-4">
            <svg className="w-16 h-16 mx-auto mb-4 text-muted-foreground/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <p className="text-lg font-medium text-foreground">เลือกประเภทห้องเพื่อดูข้อมูล Inventory</p>
            <p className="text-sm mt-2">กรุณาเลือกประเภทห้องจาก dropdown ด้านบน</p>
          </div>
        </div>
      )}

      {/* Empty State - No Data */}
      {!isLoading && selectedRoomType && inventoryData.length === 0 && (
        <div className="text-center py-12 bg-card rounded-lg border border-border">
          <div className="text-muted-foreground mb-4">
            <svg className="w-16 h-16 mx-auto mb-4 text-muted-foreground/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <p className="text-lg font-medium text-foreground">ไม่พบข้อมูล Inventory</p>
            <p className="text-sm mt-2">ยังไม่มีข้อมูล inventory สำหรับประเภทห้องและช่วงเวลาที่เลือก</p>
            <p className="text-xs mt-2 text-muted-foreground">
              ระบบจะสร้างข้อมูล inventory อัตโนมัติเมื่อมีการจองห้อง
            </p>
          </div>
        </div>
      )}

      {/* Calendar View */}
      {!isLoading && selectedRoomType && inventoryData.length > 0 && (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    วันที่
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    จำนวนห้อง
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    จองแล้ว
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    กำลังจอง
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    ว่าง
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    สถานะ
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    จัดการ
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {calendarDays.map((day) => {
                  const dateStr = day.toISOString().split("T")[0];
                  const inventory = getInventoryForDate(day, selectedRoomType);
                  const available = inventory
                    ? inventory.allotment - inventory.booked_count - inventory.tentative_count
                    : 0;

                  return (
                    <tr key={dateStr} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {day.toLocaleDateString("th-TH", {
                          weekday: "short",
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                        })}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {inventory?.allotment || 0}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {inventory?.booked_count || 0}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {inventory?.tentative_count || 0}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {available}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span
                          className={`inline-flex px-3 py-1 text-xs font-semibold rounded-full ${getHeatmapColor(
                            inventory
                          )}`}
                        >
                          {inventory
                            ? `${Math.round(
                                ((inventory.booked_count + inventory.tentative_count) /
                                  inventory.allotment) *
                                  100
                              )}%`
                            : "N/A"}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        <button
                          onClick={() => handleSingleEdit(dateStr, selectedRoomType)}
                          className="text-blue-600 hover:text-blue-900"
                        >
                          แก้ไข
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* No Room Type Selected */}
      {!isLoading && !selectedRoomType && (
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <p className="text-gray-500">กรุณาเลือกประเภทห้องเพื่อดูข้อมูลสต็อก</p>
        </div>
      )}

      {/* Single Edit Modal */}
      {editMode === "single" && selectedDate && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              แก้ไขจำนวนห้อง
            </h3>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                วันที่: {new Date(selectedDate).toLocaleDateString("th-TH")}
              </label>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                จำนวนห้อง
              </label>
              <input
                type="number"
                min="0"
                value={allotmentValue}
                onChange={(e) => setAllotmentValue(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setEditMode(null);
                  setSelectedDate(null);
                  setAllotmentValue("");
                  setValidationErrors([]);
                }}
                className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200"
              >
                ยกเลิก
              </button>
              <button
                onClick={handleSingleSubmit}
                disabled={updateInventoryMutation.isPending}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-300"
              >
                {updateInventoryMutation.isPending ? "กำลังบันทึก..." : "บันทึก"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Bulk Edit Modal */}
      {editMode === "bulk" && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              แก้ไขจำนวนห้องแบบกลุ่ม
            </h3>
            <div className="space-y-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  วันที่เริ่มต้น
                </label>
                <input
                  type="date"
                  value={bulkStartDate}
                  onChange={(e) => setBulkStartDate(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  วันที่สิ้นสุด
                </label>
                <input
                  type="date"
                  value={bulkEndDate}
                  onChange={(e) => setBulkEndDate(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  จำนวนห้อง
                </label>
                <input
                  type="number"
                  min="0"
                  value={allotmentValue}
                  onChange={(e) => setAllotmentValue(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setEditMode(null);
                  setBulkStartDate("");
                  setBulkEndDate("");
                  setAllotmentValue("");
                  setValidationErrors([]);
                }}
                className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200"
              >
                ยกเลิก
              </button>
              <button
                onClick={handleBulkSubmit}
                disabled={updateInventoryMutation.isPending}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-300"
              >
                {updateInventoryMutation.isPending ? "กำลังบันทึก..." : "บันทึก"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
