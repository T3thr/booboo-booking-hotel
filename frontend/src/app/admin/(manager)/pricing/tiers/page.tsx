"use client";

import { useState } from "react";
import {
  useRateTiers,
  useCreateRateTier,
  useUpdateRateTier,
} from "@/hooks/use-pricing";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

export default function RateTiersPage() {
  const { data: tiers, isLoading, error } = useRateTiers();
  const createTier = useCreateRateTier();
  const updateTier = useUpdateRateTier();

  const [isCreating, setIsCreating] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [newTierName, setNewTierName] = useState("");
  const [editTierName, setEditTierName] = useState("");

  const handleCreate = async () => {
    if (!newTierName.trim()) return;

    try {
      await createTier.mutateAsync({ name: newTierName.trim() });
      setNewTierName("");
      setIsCreating(false);
    } catch (error) {
      console.error("Failed to create tier:", error);
      alert("ไม่สามารถสร้างระดับราคาได้: " + (error as Error).message);
    }
  };

  const handleUpdate = async (id: number) => {
    if (!editTierName.trim()) return;

    try {
      await updateTier.mutateAsync({ id, data: { name: editTierName.trim() } });
      setEditingId(null);
      setEditTierName("");
    } catch (error) {
      console.error("Failed to update tier:", error);
      alert("ไม่สามารถอัปเดตระดับราคาได้: " + (error as Error).message);
    }
  };

  const startEdit = (tier: any) => {
    setEditingId(tier.rate_tier_id);
    setEditTierName(tier.name);
  };

  const cancelEdit = () => {
    setEditingId(null);
    setEditTierName("");
  };

  if (isLoading) {
    return (
      <div className="max-w-4xl mx-auto px-4">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">กำลังโหลดข้อมูล...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-4xl mx-auto px-4">
        <Card className="p-6 bg-red-50 border-red-200">
          <p className="text-red-600">เกิดข้อผิดพลาด: {(error as Error).message}</p>
        </Card>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto px-4">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">จัดการระดับราคา (Rate Tiers)</h1>
        <p className="mt-2 text-gray-600">
          กำหนดระดับราคาสำหรับฤดูกาลต่างๆ เช่น ฤดูต่ำ, ฤดูสูง, วันหยุดพิเศษ
        </p>
      </div>

      {/* Create New Tier */}
      <Card className="p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">สร้างระดับราคาใหม่</h2>
        {!isCreating ? (
          <Button onClick={() => setIsCreating(true)}>
            + เพิ่มระดับราคา
          </Button>
        ) : (
          <div className="flex gap-2">
            <Input
              type="text"
              placeholder="ชื่อระดับราคา (เช่น Low Season, High Season)"
              value={newTierName}
              onChange={(e) => setNewTierName(e.target.value)}
              onKeyPress={(e) => e.key === "Enter" && handleCreate()}
              className="flex-1"
              autoFocus
            />
            <Button
              onClick={handleCreate}
              disabled={!newTierName.trim() || createTier.isPending}
            >
              {createTier.isPending ? "กำลังบันทึก..." : "บันทึก"}
            </Button>
            <Button
              onClick={() => {
                setIsCreating(false);
                setNewTierName("");
              }}
              variant="outline"
            >
              ยกเลิก
            </Button>
          </div>
        )}
      </Card>

      {/* Existing Tiers */}
      <Card className="p-6">
        <h2 className="text-lg font-semibold mb-4">ระดับราคาที่มีอยู่</h2>
        {!tiers || tiers.length === 0 ? (
          <p className="text-gray-500 text-center py-8">
            ยังไม่มีระดับราคา กรุณาสร้างระดับราคาใหม่
          </p>
        ) : (
          <div className="space-y-3">
            {tiers.map((tier: any) => (
              <div
                key={tier.rate_tier_id}
                className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
              >
                {editingId === tier.rate_tier_id ? (
                  <div className="flex gap-2 flex-1">
                    <Input
                      type="text"
                      value={editTierName}
                      onChange={(e) => setEditTierName(e.target.value)}
                      onKeyPress={(e) =>
                        e.key === "Enter" && handleUpdate(tier.rate_tier_id)
                      }
                      className="flex-1"
                      autoFocus
                    />
                    <Button
                      onClick={() => handleUpdate(tier.rate_tier_id)}
                      disabled={!editTierName.trim() || updateTier.isPending}
                      size="sm"
                    >
                      {updateTier.isPending ? "กำลังบันทึก..." : "บันทึก"}
                    </Button>
                    <Button onClick={cancelEdit} variant="outline" size="sm">
                      ยกเลิก
                    </Button>
                  </div>
                ) : (
                  <>
                    <div>
                      <p className="font-medium text-gray-900">{tier.name}</p>
                      <p className="text-sm text-gray-500">
                        ID: {tier.rate_tier_id}
                      </p>
                    </div>
                    <Button
                      onClick={() => startEdit(tier)}
                      variant="outline"
                      size="sm"
                    >
                      แก้ไข
                    </Button>
                  </>
                )}
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* Info Box */}
      <Card className="p-6 mt-6 bg-blue-50 border-blue-200">
        <h3 className="font-semibold text-blue-900 mb-2">💡 คำแนะนำ</h3>
        <ul className="text-sm text-blue-800 space-y-1">
          <li>• ระดับราคาใช้สำหรับกำหนดราคาห้องในช่วงเวลาต่างๆ</li>
          <li>• ตัวอย่าง: Low Season, High Season, Peak Season, Holiday</li>
          <li>• หลังจากสร้างระดับราคาแล้ว ไปที่ "ปฏิทินราคา" เพื่อกำหนดวันที่</li>
          <li>• จากนั้นไปที่ "เมทริกซ์ราคา" เพื่อกำหนดราคาสำหรับแต่ละระดับ</li>
        </ul>
      </Card>
    </div>
  );
}
