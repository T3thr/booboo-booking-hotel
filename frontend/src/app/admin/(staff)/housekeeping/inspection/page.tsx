"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useInspectRoom } from "@/hooks/use-housekeeping";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { housekeepingApi } from "@/lib/api";

export default function InspectionPage() {
  const [searchTerm, setSearchTerm] = useState("");
  const [inspectionModal, setInspectionModal] = useState<{
    isOpen: boolean;
    roomId: number | null;
    roomNumber: string;
    approved: boolean | null;
  }>({
    isOpen: false,
    roomId: null,
    roomNumber: "",
    approved: null,
  });
  const [notes, setNotes] = useState("");

  const { data: roomsData, isLoading, error } = useQuery({
    queryKey: ["housekeeping", "inspection"],
    queryFn: async () => {
      const response = await housekeepingApi.getTasks();
      // Filter only Clean rooms
      const tasks = response?.data?.tasks || [];
      return tasks.filter((task: any) => task.housekeeping_status === "Clean");
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  });

  const inspectRoom = useInspectRoom();

  const openInspectionModal = (roomId: number, roomNumber: string, approved: boolean) => {
    setInspectionModal({ isOpen: true, roomId, roomNumber, approved });
    setNotes("");
  };

  const closeInspectionModal = () => {
    setInspectionModal({ isOpen: false, roomId: null, roomNumber: "", approved: null });
    setNotes("");
  };

  const handleInspection = async () => {
    if (!inspectionModal.roomId || inspectionModal.approved === null) {
      return;
    }

    try {
      await inspectRoom.mutateAsync({
        roomId: inspectionModal.roomId,
        approved: inspectionModal.approved,
        reason: notes.trim() || undefined,
      });
      closeInspectionModal();
      alert(
        inspectionModal.approved
          ? "อนุมัติห้องเรียบร้อยแล้ว"
          : "ปฏิเสธห้องเรียบร้อยแล้ว ห้องจะถูกส่งกลับไปทำความสะอาดใหม่"
      );
    } catch (error) {
      console.error("Failed to inspect room:", error);
      alert("ไม่สามารถตรวจสอบห้องได้: " + (error as Error).message);
    }
  };

  if (isLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">กำลังโหลดรายการห้องที่รอตรวจสอบ...</p>
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

  const rooms = roomsData || [];

  // Filter rooms by search term
  const filteredRooms = rooms.filter((room: any) => {
    const matchesSearch =
      searchTerm === "" ||
      room.room_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      room.room_type_name.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">ตรวจสอบห้องพัก</h1>
        <p className="mt-2 text-gray-600">
          ตรวจสอบและอนุมัติห้องที่ทำความสะอาดเสร็จแล้ว
        </p>
      </div>

      {/* Summary */}
      <Card className="p-6 mb-6 bg-green-50 border-green-200">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-green-900">
              ห้องที่รอตรวจสอบ
            </h2>
            <p className="text-sm text-green-700">
              ห้องที่ทำความสะอาดเสร็จแล้วและรอการตรวจสอบจากหัวหน้าแม่บ้าน
            </p>
          </div>
          <div className="text-4xl font-bold text-green-600">{rooms.length}</div>
        </div>
      </Card>

      {/* Search */}
      <div className="mb-6">
        <Input
          type="text"
          placeholder="ค้นหาห้อง..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="max-w-md"
        />
      </div>

      {/* Room List */}
      <div className="space-y-4">
        {filteredRooms.length === 0 ? (
          <Card className="p-8 text-center">
            <div className="text-gray-400 mb-2">
              <svg
                className="mx-auto h-12 w-12"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <p className="text-gray-500">
              {searchTerm
                ? "ไม่มีห้องที่ตรงกับเงื่อนไขการค้นหา"
                : "ไม่มีห้องที่รอตรวจสอบในขณะนี้"}
            </p>
          </Card>
        ) : (
          filteredRooms.map((room: any) => (
            <Card key={room.room_id} className="p-6">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="text-xl font-semibold text-gray-900">
                      ห้อง {room.room_number}
                    </h3>
                    <span className="px-3 py-1 rounded-full text-sm font-medium border bg-green-100 text-green-800 border-green-300">
                      สะอาดแล้ว
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 space-y-1">
                    <p>ประเภทห้อง: {room.room_type_name}</p>
                    <p>
                      สถานะการเข้าพัก:{" "}
                      {room.occupancy_status === "Vacant" ? "ว่าง" : "มีผู้เข้าพัก"}
                    </p>
                    {room.estimated_time && (
                      <p>เวลาที่ใช้ทำความสะอาด: {room.estimated_time} นาที</p>
                    )}
                  </div>
                </div>

                <div className="flex flex-col sm:flex-row gap-2 min-w-[280px]">
                  <Button
                    onClick={() => openInspectionModal(room.room_id, room.room_number, true)}
                    disabled={inspectRoom.isPending}
                    className="flex-1 bg-green-600 hover:bg-green-700"
                  >
                    ✓ อนุมัติ
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => openInspectionModal(room.room_id, room.room_number, false)}
                    disabled={inspectRoom.isPending}
                    className="flex-1 border-red-500 text-red-600 hover:bg-red-50"
                  >
                    ✗ ปฏิเสธ
                  </Button>
                </div>
              </div>
            </Card>
          ))
        )}
      </div>

      {/* Inspection Modal */}
      {inspectionModal.isOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <Card className="max-w-md w-full p-6">
            <h2 className="text-xl font-bold mb-4">
              {inspectionModal.approved ? "อนุมัติ" : "ปฏิเสธ"}ห้อง {inspectionModal.roomNumber}
            </h2>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {inspectionModal.approved ? "หมายเหตุ (ถ้ามี)" : "เหตุผลในการปฏิเสธ"}
              </label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={4}
                placeholder={
                  inspectionModal.approved
                    ? "หมายเหตุเพิ่มเติม..."
                    : "กรุณาระบุเหตุผลในการปฏิเสธ..."
                }
              />
            </div>
            <div className="flex gap-2">
              <Button
                onClick={handleInspection}
                disabled={inspectRoom.isPending}
                className={`flex-1 ${
                  inspectionModal.approved
                    ? "bg-green-600 hover:bg-green-700"
                    : "bg-red-600 hover:bg-red-700"
                }`}
              >
                {inspectRoom.isPending
                  ? "กำลังบันทึก..."
                  : inspectionModal.approved
                  ? "ยืนยันการอนุมัติ"
                  : "ยืนยันการปฏิเสธ"}
              </Button>
              <Button
                variant="outline"
                onClick={closeInspectionModal}
                disabled={inspectRoom.isPending}
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
