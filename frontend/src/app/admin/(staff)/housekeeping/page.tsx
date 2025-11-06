"use client";

import { useState } from "react";
import { useHousekeepingTasks, useUpdateRoomStatus, useReportMaintenance } from "@/hooks/use-housekeeping";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

type FilterStatus = "all" | "Dirty" | "Cleaning" | "Clean" | "MaintenanceRequired";

export default function HousekeepingPage() {
  const [filter, setFilter] = useState<FilterStatus>("all");
  const [searchTerm, setSearchTerm] = useState("");
  const [maintenanceModal, setMaintenanceModal] = useState<{
    isOpen: boolean;
    roomId: number | null;
    roomNumber: string;
  }>({
    isOpen: false,
    roomId: null,
    roomNumber: "",
  });
  const [maintenanceDescription, setMaintenanceDescription] = useState("");

  const { data: tasksData, isLoading, error } = useHousekeepingTasks();
  const updateStatus = useUpdateRoomStatus();
  const reportMaintenance = useReportMaintenance();

  const handleStatusUpdate = async (roomId: number, newStatus: string) => {
    try {
      await updateStatus.mutateAsync({ roomId, status: newStatus });
    } catch (error) {
      console.error("Failed to update status:", error);
      alert("ไม่สามารถอัปเดตสถานะได้: " + (error as Error).message);
    }
  };

  const openMaintenanceModal = (roomId: number, roomNumber: string) => {
    setMaintenanceModal({ isOpen: true, roomId, roomNumber });
    setMaintenanceDescription("");
  };

  const closeMaintenanceModal = () => {
    setMaintenanceModal({ isOpen: false, roomId: null, roomNumber: "" });
    setMaintenanceDescription("");
  };

  const handleReportMaintenance = async () => {
    if (!maintenanceModal.roomId || !maintenanceDescription.trim()) {
      alert("กรุณากรอกรายละเอียดปัญหา");
      return;
    }

    try {
      await reportMaintenance.mutateAsync({
        roomId: maintenanceModal.roomId,
        description: maintenanceDescription,
      });
      closeMaintenanceModal();
      alert("รายงานปัญหาเรียบร้อยแล้ว");
    } catch (error) {
      console.error("Failed to report maintenance:", error);
      alert("ไม่สามารถรายงานปัญหาได้: " + (error as Error).message);
    }
  };

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">กำลังโหลดรายการงาน...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center py-12">
          <p className="text-red-600">เกิดข้อผิดพลาด: {(error as Error).message}</p>
        </div>
      </div>
    );
  }

  const tasks = tasksData?.data?.tasks || [];
  const summary = tasksData?.data?.summary || {
    dirty: 0,
    cleaning: 0,
    clean: 0,
    inspected: 0,
    maintenance_required: 0,
  };

  // Filter tasks
  const filteredTasks = tasks.filter((task: any) => {
    const matchesFilter = filter === "all" || task.housekeeping_status === filter;
    const matchesSearch =
      searchTerm === "" ||
      task.room_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      task.room_type_name.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  // Sort by priority
  const sortedTasks = [...filteredTasks].sort((a: any, b: any) => b.priority - a.priority);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "Dirty":
        return "bg-red-100 text-red-800 border-red-300";
      case "Cleaning":
        return "bg-yellow-100 text-yellow-800 border-yellow-300";
      case "Clean":
        return "bg-green-100 text-green-800 border-green-300";
      case "Inspected":
        return "bg-blue-100 text-blue-800 border-blue-300";
      case "MaintenanceRequired":
        return "bg-orange-100 text-orange-800 border-orange-300";
      default:
        return "bg-gray-100 text-gray-800 border-gray-300";
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case "Dirty":
        return "รอทำความสะอาด";
      case "Cleaning":
        return "กำลังทำความสะอาด";
      case "Clean":
        return "สะอาดแล้ว";
      case "Inspected":
        return "ตรวจสอบแล้ว";
      case "MaintenanceRequired":
        return "ต้องซ่อมบำรุง";
      default:
        return status;
    }
  };

  const getNextStatus = (currentStatus: string) => {
    switch (currentStatus) {
      case "Dirty":
        return "Cleaning";
      case "Cleaning":
        return "Clean";
      default:
        return null;
    }
  };

  const getNextStatusText = (currentStatus: string) => {
    const next = getNextStatus(currentStatus);
    return next ? getStatusText(next) : null;
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">รายการงานทำความสะอาด</h1>
        <p className="mt-2 text-gray-600">จัดการและอัปเดตสถานะการทำความสะอาดห้องพัก</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
        <Card className="p-4">
          <div className="text-sm text-gray-600">รอทำความสะอาด</div>
          <div className="text-2xl font-bold text-red-600">{summary.dirty}</div>
        </Card>
        <Card className="p-4">
          <div className="text-sm text-gray-600">กำลังทำความสะอาด</div>
          <div className="text-2xl font-bold text-yellow-600">{summary.cleaning}</div>
        </Card>
        <Card className="p-4">
          <div className="text-sm text-gray-600">สะอาดแล้ว</div>
          <div className="text-2xl font-bold text-green-600">{summary.clean}</div>
        </Card>
        <Card className="p-4">
          <div className="text-sm text-gray-600">ตรวจสอบแล้ว</div>
          <div className="text-2xl font-bold text-blue-600">{summary.inspected}</div>
        </Card>
        <Card className="p-4">
          <div className="text-sm text-gray-600">ต้องซ่อมบำรุง</div>
          <div className="text-2xl font-bold text-orange-600">{summary.maintenance_required}</div>
        </Card>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-col sm:flex-row gap-4">
        <div className="flex-1">
          <Input
            type="text"
            placeholder="ค้นหาห้อง..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full"
          />
        </div>
        <div className="flex gap-2 flex-wrap">
          <Button
            variant={filter === "all" ? "default" : "outline"}
            onClick={() => setFilter("all")}
            size="sm"
          >
            ทั้งหมด
          </Button>
          <Button
            variant={filter === "Dirty" ? "default" : "outline"}
            onClick={() => setFilter("Dirty")}
            size="sm"
          >
            รอทำความสะอาด
          </Button>
          <Button
            variant={filter === "Cleaning" ? "default" : "outline"}
            onClick={() => setFilter("Cleaning")}
            size="sm"
          >
            กำลังทำความสะอาด
          </Button>
          <Button
            variant={filter === "Clean" ? "default" : "outline"}
            onClick={() => setFilter("Clean")}
            size="sm"
          >
            สะอาดแล้ว
          </Button>
        </div>
      </div>

      {/* Task List */}
      <div className="space-y-4">
        {sortedTasks.length === 0 ? (
          <Card className="p-8 text-center">
            <p className="text-gray-500">ไม่มีงานที่ตรงกับเงื่อนไขการค้นหา</p>
          </Card>
        ) : (
          sortedTasks.map((task: any) => (
            <Card key={task.room_id} className="p-6">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="text-xl font-semibold text-gray-900">
                      ห้อง {task.room_number}
                    </h3>
                    <span
                      className={`px-3 py-1 rounded-full text-sm font-medium border ${getStatusColor(
                        task.housekeeping_status
                      )}`}
                    >
                      {getStatusText(task.housekeeping_status)}
                    </span>
                    {task.priority > 5 && (
                      <span className="px-2 py-1 bg-red-500 text-white text-xs rounded-full">
                        ด่วน
                      </span>
                    )}
                  </div>
                  <div className="text-sm text-gray-600 space-y-1">
                    <p>ประเภทห้อง: {task.room_type_name}</p>
                    <p>สถานะการเข้าพัก: {task.occupancy_status === "Vacant" ? "ว่าง" : "มีผู้เข้าพัก"}</p>
                    {task.estimated_time && (
                      <p>เวลาโดยประมาณ: {task.estimated_time} นาที</p>
                    )}
                  </div>
                </div>

                <div className="flex flex-col gap-2 min-w-[200px]">
                  {getNextStatus(task.housekeeping_status) && (
                    <Button
                      onClick={() =>
                        handleStatusUpdate(task.room_id, getNextStatus(task.housekeeping_status)!)
                      }
                      disabled={updateStatus.isPending}
                      className="w-full"
                    >
                      {updateStatus.isPending ? "กำลังอัปเดต..." : `→ ${getNextStatusText(task.housekeeping_status)}`}
                    </Button>
                  )}

                  {task.housekeeping_status !== "MaintenanceRequired" && (
                    <Button
                      variant="outline"
                      onClick={() => openMaintenanceModal(task.room_id, task.room_number)}
                      disabled={reportMaintenance.isPending}
                      className="w-full border-orange-500 text-orange-600 hover:bg-orange-50"
                    >
                      รายงานปัญหา
                    </Button>
                  )}
                </div>
              </div>
            </Card>
          ))
        )}
      </div>

      {/* Maintenance Modal */}
      {maintenanceModal.isOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <Card className="max-w-md w-full p-6">
            <h2 className="text-xl font-bold mb-4">รายงานปัญหาห้อง {maintenanceModal.roomNumber}</h2>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                รายละเอียดปัญหา
              </label>
              <textarea
                value={maintenanceDescription}
                onChange={(e) => setMaintenanceDescription(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={4}
                placeholder="กรุณาระบุรายละเอียดปัญหาที่พบ..."
              />
            </div>
            <div className="flex gap-2">
              <Button
                onClick={handleReportMaintenance}
                disabled={reportMaintenance.isPending || !maintenanceDescription.trim()}
                className="flex-1"
              >
                {reportMaintenance.isPending ? "กำลังบันทึก..." : "บันทึก"}
              </Button>
              <Button
                variant="outline"
                onClick={closeMaintenanceModal}
                disabled={reportMaintenance.isPending}
                className="flex-1"
              >
                ยกเลิก
              </Button>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
}
