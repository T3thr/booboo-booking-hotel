"use client";

import { useState, useEffect } from "react";
import { useRoomStatus } from "@/hooks/use-room-status";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import type { Room } from "@/types";

interface RoomStatusSummary {
  total_rooms: number;
  vacant_inspected: number;
  vacant_clean: number;
  vacant_dirty: number;
  occupied: number;
  out_of_service: number;
  maintenance_required: number;
}

export default function RoomStatusDashboard() {
  const { data: rooms, isLoading, error, refetch } = useRoomStatus();
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Auto-refresh every 30 seconds
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(() => {
      refetch();
    }, 30000); // 30 seconds

    return () => clearInterval(interval);
  }, [autoRefresh, refetch]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-background">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">กำลังโหลดข้อมูล...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-4">
        <Card className="p-6 bg-destructive/10 border-destructive/30">
          <div className="space-y-3">
            <div className="flex items-start gap-3">
              <div className="text-destructive text-2xl">⚠️</div>
              <div className="flex-1">
                <h3 className="font-semibold text-destructive mb-1">
                  ไม่สามารถเชื่อมต่อกับ Backend
                </h3>
                <p className="text-sm text-muted-foreground">
                  {error.message}
                </p>
              </div>
            </div>
            <div className="pl-11 space-y-2 text-sm text-muted-foreground">
              <p>กรุณาตรวจสอบ:</p>
              <ul className="list-disc list-inside space-y-1 pl-2">
                <li>Backend Server กำลังทำงานที่ <code className="bg-muted px-1 py-0.5 rounded">http://localhost:8080</code></li>
                <li>Database เชื่อมต่อสำเร็จ</li>
                <li>มีข้อมูลห้องพักในระบบ</li>
              </ul>
            </div>
            <button
              onClick={() => refetch()}
              className="mt-4 px-4 py-2 bg-destructive text-destructive-foreground rounded-lg hover:bg-destructive/90 transition-colors"
            >
              ลองอีกครั้ง
            </button>
          </div>
        </Card>
      </div>
    );
  }

  // Ensure rooms is an array
  const roomList: Room[] = Array.isArray(rooms) ? rooms : [];

  // Calculate summary
  const summary: RoomStatusSummary = roomList.reduce(
    (acc, room) => {
      acc.total_rooms++;
      if (room.occupancy_status === "Occupied") {
        acc.occupied++;
      } else if (room.housekeeping_status === "Inspected") {
        acc.vacant_inspected++;
      } else if (room.housekeeping_status === "Clean") {
        acc.vacant_clean++;
      } else if (room.housekeeping_status === "Dirty" || room.housekeeping_status === "Cleaning") {
        acc.vacant_dirty++;
      } else if (room.housekeeping_status === "MaintenanceRequired") {
        acc.maintenance_required++;
      } else if (room.housekeeping_status === "OutOfService") {
        acc.out_of_service++;
      }
      return acc;
    },
    {
      total_rooms: 0,
      vacant_inspected: 0,
      vacant_clean: 0,
      vacant_dirty: 0,
      occupied: 0,
      out_of_service: 0,
      maintenance_required: 0,
    }
  );

  // Filter rooms
  const filteredRooms = roomList.filter((room) => {
    const matchesSearch =
      room.room_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (room.room_type?.name &&
        room.room_type.name.toLowerCase().includes(searchTerm.toLowerCase()));

    if (filterStatus === "all") return matchesSearch;
    if (filterStatus === "vacant-inspected")
      return (
        matchesSearch &&
        room.occupancy_status === "Vacant" &&
        room.housekeeping_status === "Inspected"
      );
    if (filterStatus === "vacant-clean")
      return (
        matchesSearch &&
        room.occupancy_status === "Vacant" &&
        room.housekeeping_status === "Clean"
      );
    if (filterStatus === "vacant-dirty")
      return (
        matchesSearch &&
        room.occupancy_status === "Vacant" &&
        (room.housekeeping_status === "Dirty" ||
          room.housekeeping_status === "Cleaning")
      );
    if (filterStatus === "occupied")
      return matchesSearch && room.occupancy_status === "Occupied";
    if (filterStatus === "maintenance")
      return matchesSearch && room.housekeeping_status === "MaintenanceRequired";
    if (filterStatus === "out-of-service")
      return matchesSearch && room.housekeeping_status === "OutOfService";

    return matchesSearch;
  });

  // Get room status color
  const getRoomStatusColor = (room: Room): string => {
    if (room.housekeeping_status === "OutOfService") return "bg-gray-400";
    if (room.housekeeping_status === "MaintenanceRequired") return "bg-orange-500";
    if (room.occupancy_status === "Occupied") return "bg-red-500";
    if (room.housekeeping_status === "Inspected") return "bg-green-500";
    if (room.housekeeping_status === "Clean") return "bg-yellow-400";
    return "bg-gray-300"; // Dirty/Cleaning
  };

  // Get status text in Thai
  const getStatusText = (room: Room): string => {
    if (room.housekeeping_status === "OutOfService") return "ปิดให้บริการ";
    if (room.housekeeping_status === "MaintenanceRequired") return "ต้องซ่อมบำรุง";
    if (room.occupancy_status === "Occupied") return "มีผู้เข้าพัก";
    if (room.housekeeping_status === "Inspected") return "ว่าง - ตรวจสอบแล้ว";
    if (room.housekeeping_status === "Clean") return "ว่าง - สะอาด";
    if (room.housekeeping_status === "Cleaning") return "ว่าง - กำลังทำความสะอาด";
    return "ว่าง - รอทำความสะอาด";
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-foreground">
            แดชบอร์ดสถานะห้องพัก
          </h1>
          <p className="text-muted-foreground mt-1">ดูและจัดการสถานะห้องพักแบบเรียลไทม์</p>
        </div>
        <div className="flex items-center gap-4">
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
              className="rounded border-border text-primary focus:ring-primary"
            />
            <span className="text-sm text-muted-foreground">
              รีเฟรชอัตโนมัติ (30 วินาที)
            </span>
          </label>
          <button
            onClick={() => refetch()}
            className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
          >
            รีเฟรชตอนนี้
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
        <Card className="p-4 hover:shadow-md transition-shadow">
          <div className="text-sm text-muted-foreground">ห้องทั้งหมด</div>
          <div className="text-2xl font-bold text-foreground">
            {summary.total_rooms}
          </div>
        </Card>
        <Card className="p-4 bg-green-500/10 border-green-500/30 hover:shadow-md transition-shadow">
          <div className="text-sm text-green-700 dark:text-green-400">ว่าง - ตรวจสอบแล้ว</div>
          <div className="text-2xl font-bold text-green-900 dark:text-green-300">
            {summary.vacant_inspected}
          </div>
        </Card>
        <Card className="p-4 bg-yellow-500/10 border-yellow-500/30 hover:shadow-md transition-shadow">
          <div className="text-sm text-yellow-700 dark:text-yellow-400">ว่าง - สะอาด</div>
          <div className="text-2xl font-bold text-yellow-900 dark:text-yellow-300">
            {summary.vacant_clean}
          </div>
        </Card>
        <Card className="p-4 bg-muted hover:shadow-md transition-shadow">
          <div className="text-sm text-muted-foreground">ว่าง - รอทำความสะอาด</div>
          <div className="text-2xl font-bold text-foreground">
            {summary.vacant_dirty}
          </div>
        </Card>
        <Card className="p-4 bg-red-500/10 border-red-500/30 hover:shadow-md transition-shadow">
          <div className="text-sm text-red-700 dark:text-red-400">มีผู้เข้าพัก</div>
          <div className="text-2xl font-bold text-red-900 dark:text-red-300">
            {summary.occupied}
          </div>
        </Card>
        <Card className="p-4 bg-orange-500/10 border-orange-500/30 hover:shadow-md transition-shadow">
          <div className="text-sm text-orange-700 dark:text-orange-400">ต้องซ่อมบำรุง</div>
          <div className="text-2xl font-bold text-orange-900 dark:text-orange-300">
            {summary.maintenance_required}
          </div>
        </Card>
        <Card className="p-4 bg-muted/50 hover:shadow-md transition-shadow">
          <div className="text-sm text-muted-foreground">ปิดให้บริการ</div>
          <div className="text-2xl font-bold text-foreground">
            {summary.out_of_service}
          </div>
        </Card>
      </div>

      {/* Filters */}
      <Card className="p-4">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <Input
              type="text"
              placeholder="ค้นหาหมายเลขห้อง หรือประเภทห้อง..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full"
            />
          </div>
          <div className="flex gap-2 flex-wrap">
            <button
              onClick={() => setFilterStatus("all")}
              className={`px-4 py-2 rounded-lg transition-colors ${
                filterStatus === "all"
                  ? "bg-primary text-primary-foreground"
                  : "bg-secondary text-secondary-foreground hover:bg-accent"
              }`}
            >
              ทั้งหมด
            </button>
            <button
              onClick={() => setFilterStatus("vacant-inspected")}
              className={`px-4 py-2 rounded-lg transition-colors ${
                filterStatus === "vacant-inspected"
                  ? "bg-green-600 text-white"
                  : "bg-green-500/10 text-green-700 dark:text-green-400 hover:bg-green-500/20"
              }`}
            >
              ว่าง - ตรวจสอบแล้ว
            </button>
            <button
              onClick={() => setFilterStatus("vacant-clean")}
              className={`px-4 py-2 rounded-lg transition-colors ${
                filterStatus === "vacant-clean"
                  ? "bg-yellow-600 text-white"
                  : "bg-yellow-500/10 text-yellow-700 dark:text-yellow-400 hover:bg-yellow-500/20"
              }`}
            >
              ว่าง - สะอาด
            </button>
            <button
              onClick={() => setFilterStatus("occupied")}
              className={`px-4 py-2 rounded-lg transition-colors ${
                filterStatus === "occupied"
                  ? "bg-red-600 text-white"
                  : "bg-red-500/10 text-red-700 dark:text-red-400 hover:bg-red-500/20"
              }`}
            >
              มีผู้เข้าพัก
            </button>
            <button
              onClick={() => setFilterStatus("maintenance")}
              className={`px-4 py-2 rounded-lg transition-colors ${
                filterStatus === "maintenance"
                  ? "bg-orange-600 text-white"
                  : "bg-orange-500/10 text-orange-700 dark:text-orange-400 hover:bg-orange-500/20"
              }`}
            >
              ต้องซ่อมบำรุง
            </button>
          </div>
        </div>
      </Card>

      {/* Room Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-4">
        {filteredRooms.map((room) => (
          <Card
            key={room.room_id}
            className={`p-4 cursor-pointer hover:shadow-lg transition-shadow ${getRoomStatusColor(
              room
            )} text-white`}
          >
            <div className="text-center">
              <div className="text-xl font-bold mb-1">{room.room_number}</div>
              <div className="text-xs opacity-90 mb-2">
                {room.room_type?.name || "ไม่ระบุ"}
              </div>
              <div className="text-xs font-medium">
                {getStatusText(room)}
              </div>
            </div>
          </Card>
        ))}
      </div>

      {filteredRooms.length === 0 && (
        <Card className="p-8 text-center">
          <p className="text-muted-foreground">ไม่พบห้องที่ตรงกับเงื่อนไขการค้นหา</p>
        </Card>
      )}

      {/* Legend */}
      <Card className="p-4">
        <h3 className="text-sm font-semibold text-foreground mb-3">
          คำอธิบายสี
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 text-sm">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-green-500 rounded"></div>
            <span className="text-muted-foreground">ว่าง - ตรวจสอบแล้ว</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-yellow-400 rounded"></div>
            <span className="text-muted-foreground">ว่าง - สะอาด</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-muted rounded"></div>
            <span className="text-muted-foreground">ว่าง - รอทำความสะอาด</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-red-500 rounded"></div>
            <span className="text-muted-foreground">มีผู้เข้าพัก</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-orange-500 rounded"></div>
            <span className="text-muted-foreground">ต้องซ่อมบำรุง</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-muted/50 rounded"></div>
            <span className="text-muted-foreground">ปิดให้บริการ</span>
          </div>
        </div>
      </Card>
    </div>
  );
}