"use client";

import { useState } from "react";
import { useRateTiers, useCreateRateTier, useUpdateRateTier, useDeleteRateTier } from "@/hooks/use-pricing";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function TiersTab() {
  const { data: tiers, isLoading } = useRateTiers();
  const createTier = useCreateRateTier();
  const updateTier = useUpdateRateTier();
  const deleteTier = useDeleteRateTier();

  const [editingId, setEditingId] = useState<number | null>(null);
  const [editName, setEditName] = useState("");
  const [isCreating, setIsCreating] = useState(false);
  const [newTierName, setNewTierName] = useState("");

  const handleEdit = (tier: any) => {
    setEditingId(tier.rate_tier_id);
    setEditName(tier.name);
  };

  const handleSave = async (tierId: number) => {
    try {
      await updateTier.mutateAsync({ rate_tier_id: tierId, name: editName });
      setEditingId(null);
      setEditName("");
    } catch (error) {
      console.error("Failed to update tier:", error);
      alert("ไม่สามารถอัปเดตระดับราคาได้");
    }
  };

  const handleDelete = async (tierId: number, tierName: string) => {
    if (!confirm(`ยืนยันการลบระดับราคา "${tierName}"?`)) return;

    try {
      await deleteTier.mutateAsync(tierId);
    } catch (error) {
      console.error("Failed to delete tier:", error);
      alert("ไม่สามารถลบระดับราคาได้");
    }
  };

  const handleCreate = async () => {
    if (!newTierName.trim()) {
      alert("กรุณากรอกชื่อระดับราคา");
      return;
    }

    try {
      await createTier.mutateAsync({ name: newTierName });
      setIsCreating(false);
      setNewTierName("");
    } catch (error) {
      console.error("Failed to create tier:", error);
      alert("ไม่สามารถสร้างระดับราคาได้");
    }
  };

  if (isLoading) {
    return (
      <div className="text-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-muted-foreground">กำลังโหลดข้อมูล...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with Add Button */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-foreground">ระดับราคา (Rate Tiers)</h2>
          <p className="text-sm text-muted-foreground mt-1">
            กำหนดระดับราคาต่างๆ เช่น Low Season, High Season, Peak Season
          </p>
        </div>
        <Button onClick={() => setIsCreating(true)} disabled={isCreating}>
          + เพิ่มระดับราคา
        </Button>
      </div>

      {/* Create New Tier Form */}
      {isCreating && (
        <Card className="p-6 bg-muted/30">
          <h3 className="font-semibold mb-4">สร้างระดับราคาใหม่</h3>
          <div className="flex gap-3">
            <Input
              type="text"
              placeholder="ชื่อระดับราคา (เช่น Super Peak Season)"
              value={newTierName}
              onChange={(e) => setNewTierName(e.target.value)}
              className="flex-1"
            />
            <Button onClick={handleCreate} disabled={createTier.isPending}>
              {createTier.isPending ? "กำลังสร้าง..." : "สร้าง"}
            </Button>
            <Button
              variant="outline"
              onClick={() => {
                setIsCreating(false);
                setNewTierName("");
              }}
            >
              ยกเลิก
            </Button>
          </div>
        </Card>
      )}

      {/* Tiers List */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {!tiers || tiers.length === 0 ? (
          <Card className="col-span-full p-8 text-center">
            <p className="text-muted-foreground">ยังไม่มีระดับราคา</p>
            <p className="text-sm text-muted-foreground mt-2">
              คลิกปุ่ม "เพิ่มระดับราคา" เพื่อสร้างระดับราคาใหม่
            </p>
          </Card>
        ) : (
          tiers.map((tier: any, index: number) => (
            <Card key={tier.rate_tier_id} className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div
                    className={`w-12 h-12 rounded-lg flex items-center justify-center text-2xl font-bold text-white ${
                      index === 0
                        ? "bg-green-500"
                        : index === 1
                        ? "bg-yellow-500"
                        : index === 2
                        ? "bg-orange-500"
                        : "bg-red-500"
                    }`}
                  >
                    {index + 1}
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">Tier ID</p>
                    <p className="font-mono text-sm">{tier.rate_tier_id}</p>
                  </div>
                </div>
              </div>

              {editingId === tier.rate_tier_id ? (
                <div className="space-y-3">
                  <Input
                    type="text"
                    value={editName}
                    onChange={(e) => setEditName(e.target.value)}
                    className="w-full"
                  />
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      onClick={() => handleSave(tier.rate_tier_id)}
                      disabled={updateTier.isPending}
                      className="flex-1"
                    >
                      {updateTier.isPending ? "กำลังบันทึก..." : "บันทึก"}
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setEditingId(null);
                        setEditName("");
                      }}
                      className="flex-1"
                    >
                      ยกเลิก
                    </Button>
                  </div>
                </div>
              ) : (
                <>
                  <h3 className="text-xl font-bold text-foreground mb-4">{tier.name}</h3>
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleEdit(tier)}
                      className="flex-1"
                    >
                      แก้ไข
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleDelete(tier.rate_tier_id, tier.name)}
                      disabled={deleteTier.isPending}
                      className="flex-1 border-red-500 text-red-600 hover:bg-red-50"
                    >
                      ลบ
                    </Button>
                  </div>
                </>
              )}
            </Card>
          ))
        )}
      </div>

      {/* Info Card */}
      <Card className="p-6 bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800">
        <h3 className="font-semibold text-blue-900 dark:text-blue-100 mb-2">
          💡 คำแนะนำ
        </h3>
        <ul className="text-sm text-blue-800 dark:text-blue-200 space-y-1">
          <li>• ระดับราคาใช้สำหรับกำหนดราคาห้องในแต่ละช่วงเวลา</li>
          <li>• ตัวอย่าง: Low Season, Standard, High Season, Peak Season</li>
          <li>• หลังจากสร้างระดับราคาแล้ว ไปที่แท็บ "ปฏิทินราคา" เพื่อกำหนดวันที่</li>
          <li>• และไปที่แท็บ "ตารางราคา" เพื่อกำหนดราคาสำหรับแต่ละระดับ</li>
        </ul>
      </Card>
    </div>
  );
}
