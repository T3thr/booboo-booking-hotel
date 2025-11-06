"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { toast } from "sonner";

type Tab = "tiers" | "calendar" | "matrix";

interface RateTier {
  rate_tier_id: number;
  name: string;
}

interface RoomType {
  room_type_id: number;
  name: string;
  base_price: number;
}

interface RatePlan {
  rate_plan_id: number;
  name: string;
}

export default function PricingTiersAllInOnePage() {
  const [activeTab, setActiveTab] = useState<Tab>("tiers");
  const queryClient = useQueryClient();

  // Tab 1: Manage Tiers
  const [isCreatingTier, setIsCreatingTier] = useState(false);
  const [newTierName, setNewTierName] = useState("");
  const [editingTierId, setEditingTierId] = useState<number | null>(null);
  const [editTierName, setEditTierName] = useState("");

  // Tab 2: Calendar
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedDates, setSelectedDates] = useState<string[]>([]);
  const [selectedTierForCalendar, setSelectedTierForCalendar] = useState<number | null>(null);

  // Tab 3: Matrix
  const [editingCell, setEditingCell] = useState<{
    room_type_id: number;
    rate_plan_id: number;
    rate_tier_id: number;
  } | null>(null);
  const [editPrice, setEditPrice] = useState("");

  // Fetch data
  const { data: tiers } = useQuery({
    queryKey: ["rateTiers"],
    queryFn: async () => {
      const res = await fetch("/api/pricing/tiers");
      if (!res.ok) throw new Error("Failed to fetch tiers");
      return res.json();
    },
  });

  const { data: roomTypes } = useQuery({
    queryKey: ["roomTypes"],
    queryFn: async () => {
      const res = await fetch("/api/rooms/types");
      if (!res.ok) throw new Error("Failed to fetch room types");
      return res.json();
    },
  });

  const { data: ratePlans } = useQuery({
    queryKey: ["ratePlans"],
    queryFn: async () => {
      const res = await fetch("/api/pricing/plans");
      if (!res.ok) throw new Error("Failed to fetch rate plans");
      return res.json();
    },
  });

  const { data: pricingCalendar } = useQuery({
    queryKey: ["pricingCalendar", selectedYear],
    queryFn: async () => {
      const res = await fetch(`/api/pricing/calendar?year=${selectedYear}`);
      if (!res.ok) throw new Error("Failed to fetch calendar");
      return res.json();
    },
    enabled: activeTab === "calendar",
  });

  const { data: pricingMatrix } = useQuery({
    queryKey: ["pricingMatrix"],
    queryFn: async () => {
      const res = await fetch("/api/pricing/rates");
      if (!res.ok) throw new Error("Failed to fetch pricing matrix");
      return res.json();
    },
    enabled: activeTab === "matrix",
  });

  // Mutations
  const createTierMutation = useMutation({
    mutationFn: async (name: string) => {
      const res = await fetch("/api/pricing/tiers", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name }),
      });
      if (!res.ok) throw new Error("Failed to create tier");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["rateTiers"] });
      toast.success("สร้างระดับราคาสำเร็จ");
      setNewTierName("");
      setIsCreatingTier(false);
    },
    onError: () => toast.error("ไม่สามารถสร้างระดับราคาได้"),
  });

  const updateTierMutation = useMutation({
    mutationFn: async ({ id, name }: { id: number; name: string }) => {
      const res = await fetch(`/api/pricing/tiers/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name }),
      });
      if (!res.ok) throw new Error("Failed to update tier");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["rateTiers"] });
      toast.success("อัปเดตระดับราคาสำเร็จ");
      setEditingTierId(null);
      setEditTierName("");
    },
    onError: () => toast.error("ไม่สามารถอัปเดตระดับราคาได้"),
  });

  const deleteTierMutation = useMutation({
    mutationFn: async (id: number) => {
      const res = await fetch(`/api/pricing/tiers/${id}`, {
        method: "DELETE",
      });
      if (!res.ok) throw new Error("Failed to delete tier");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["rateTiers"] });
      toast.success("ลบระดับราคาสำเร็จ");
    },
    onError: () => toast.error("ไม่สามารถลบระดับราคาได้"),
  });

  const updateCalendarMutation = useMutation({
    mutationFn: async (updates: { date: string; rate_tier_id: number }[]) => {
      const res = await fetch("/api/pricing/calendar", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ updates }),
      });
      if (!res.ok) throw new Error("Failed to update calendar");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["pricingCalendar"] });
      toast.success("อัปเดตปฏิทินราคาสำเร็จ");
      setSelectedDates([]);
      setSelectedTierForCalendar(null);
    },
    onError: () => toast.error("ไม่สามารถอัปเดตปฏิทินราคาได้"),
  });

  const updatePriceMutation = useMutation({
    mutationFn: async (data: {
      room_type_id: number;
      rate_plan_id: number;
      rate_tier_id: number;
      price: number;
    }) => {
      const res = await fetch("/api/pricing/rates", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error("Failed to update price");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["pricingMatrix"] });
      toast.success("อัปเดตราคาสำเร็จ");
      setEditingCell(null);
      setEditPrice("");
    },
    onError: () => toast.error("ไม่สามารถอัปเดตราคาได้"),
  });

  // Handlers
  const handleCreateTier = () => {
    if (!newTierName.trim()) {
      toast.error("กรุณากรอกชื่อระดับราคา");
      return;
    }
    createTierMutation.mutate(newTierName.trim());
  };

  const handleUpdateTier = (id: number) => {
    if (!editTierName.trim()) {
      toast.error("กรุณากรอกชื่อระดับราคา");
      return;
    }
    updateTierMutation.mutate({ id, name: editTierName.trim() });
  };

  const handleDeleteTier = (id: number) => {
    if (confirm("คุณแน่ใจหรือไม่ที่จะลบระดับราคานี้?")) {
      deleteTierMutation.mutate(id);
    }
  };

  const handleApplyCalendar = () => {
    if (selectedDates.length === 0) {
      toast.error("กรุณาเลือกวันที่");
      return;
    }
    if (!selectedTierForCalendar) {
      toast.error("กรุณาเลือกระดับราคา");
      return;
    }
    const updates = selectedDates.map((date) => ({
      date,
      rate_tier_id: selectedTierForCalendar,
    }));
    updateCalendarMutation.mutate(updates);
  };

  const handleUpdatePrice = () => {
    if (!editingCell || !editPrice) return;
    const price = parseFloat(editPrice);
    if (isNaN(price) || price < 0) {
      toast.error("กรุณากรอกราคาที่ถูกต้อง");
      return;
    }
    updatePriceMutation.mutate({ ...editingCell, price });
  };

  // Generate calendar days
  const generateCalendarDays = () => {
    const firstDay = new Date(selectedYear, selectedMonth, 1);
    const lastDay = new Date(selectedYear, selectedMonth + 1, 0);
    const days: Date[] = [];
    for (let d = new Date(firstDay); d <= lastDay; d.setDate(d.getDate() + 1)) {
      days.push(new Date(d));
    }
    return days;
  };

  const calendarDays = generateCalendarDays();

  const getTierForDate = (date: Date) => {
    const dateStr = date.toISOString().split("T")[0];
    const entry = pricingCalendar?.find((c: any) => c.date.split("T")[0] === dateStr);
    return entry?.rate_tier_id || null;
  };

  const toggleDateSelection = (date: string) => {
    setSelectedDates((prev) =>
      prev.includes(date) ? prev.filter((d) => d !== date) : [...prev, date]
    );
  };

  const getPrice = (roomTypeId: number, ratePlanId: number, rateTierId: number) => {
    const entry = pricingMatrix?.find(
      (p: any) =>
        p.room_type_id === roomTypeId &&
        p.rate_plan_id === ratePlanId &&
        p.rate_tier_id === rateTierId
    );
    return entry?.price || 0;
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-foreground">จัดการระดับราคา (All-in-One)</h1>
        <p className="mt-2 text-muted-foreground">
          จัดการระดับราคา, ปฏิทินราคา, และเมทริกซ์ราคาในหน้าเดียว
        </p>
      </div>

      {/* Tabs */}
      <div className="border-b border-border mb-6">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab("tiers")}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === "tiers"
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground hover:border-border"
            }`}
          >
            1. จัดการระดับราคา
          </button>
          <button
            onClick={() => setActiveTab("calendar")}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === "calendar"
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground hover:border-border"
            }`}
          >
            2. ปฏิทินราคา
          </button>
          <button
            onClick={() => setActiveTab("matrix")}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === "matrix"
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground hover:border-border"
            }`}
          >
            3. เมทริกซ์ราคา
          </button>
        </nav>
      </div>

      {/* Tab 1: Manage Tiers */}
      {activeTab === "tiers" && (
        <div className="space-y-6">
          <Card className="p-6 bg-card border-border">
            <h2 className="text-xl font-semibold mb-4 text-foreground">สร้างระดับราคาใหม่</h2>
            {!isCreatingTier ? (
              <Button onClick={() => setIsCreatingTier(true)} className="bg-primary text-primary-foreground">
                + เพิ่มระดับราคา
              </Button>
            ) : (
              <div className="flex gap-2">
                <Input
                  type="text"
                  placeholder="ชื่อระดับราคา (เช่น Low Season, High Season)"
                  value={newTierName}
                  onChange={(e) => setNewTierName(e.target.value)}
                  className="flex-1 bg-background text-foreground border-input"
                />
                <Button onClick={handleCreateTier} disabled={createTierMutation.isPending} className="bg-primary text-primary-foreground">
                  {createTierMutation.isPending ? "กำลังสร้าง..." : "สร้าง"}
                </Button>
                <Button
                  onClick={() => {
                    setIsCreatingTier(false);
                    setNewTierName("");
                  }}
                  className="bg-secondary text-secondary-foreground"
                >
                  ยกเลิก
                </Button>
              </div>
            )}
          </Card>

          <Card className="p-6 bg-card border-border">
            <h2 className="text-xl font-semibold mb-4 text-foreground">ระดับราคาทั้งหมด</h2>
            {!tiers || tiers.length === 0 ? (
              <p className="text-muted-foreground">ยังไม่มีระดับราคา</p>
            ) : (
              <div className="space-y-3">
                {tiers.map((tier: RateTier) => (
                  <div
                    key={tier.rate_tier_id}
                    className="flex items-center justify-between p-4 bg-muted rounded-lg border border-border"
                  >
                    {editingTierId === tier.rate_tier_id ? (
                      <div className="flex gap-2 flex-1">
                        <Input
                          type="text"
                          value={editTierName}
                          onChange={(e) => setEditTierName(e.target.value)}
                          className="flex-1 bg-background text-foreground border-input"
                        />
                        <Button
                          onClick={() => handleUpdateTier(tier.rate_tier_id)}
                          disabled={updateTierMutation.isPending}
                          className="bg-primary text-primary-foreground"
                        >
                          {updateTierMutation.isPending ? "กำลังบันทึก..." : "บันทึก"}
                        </Button>
                        <Button
                          onClick={() => {
                            setEditingTierId(null);
                            setEditTierName("");
                          }}
                          className="bg-secondary text-secondary-foreground"
                        >
                          ยกเลิก
                        </Button>
                      </div>
                    ) : (
                      <>
                        <div>
                          <h3 className="font-medium text-foreground">{tier.name}</h3>
                          <p className="text-sm text-muted-foreground">ID: {tier.rate_tier_id}</p>
                        </div>
                        <div className="flex gap-2">
                          <Button
                            onClick={() => {
                              setEditingTierId(tier.rate_tier_id);
                              setEditTierName(tier.name);
                            }}
                            className="bg-accent text-accent-foreground"
                          >
                            แก้ไข
                          </Button>
                          <Button
                            onClick={() => handleDeleteTier(tier.rate_tier_id)}
                            disabled={deleteTierMutation.isPending}
                            className="bg-destructive text-destructive-foreground"
                          >
                            ลบ
                          </Button>
                        </div>
                      </>
                    )}
                  </div>
                ))}
              </div>
            )}
          </Card>

          <Card className="p-6 bg-accent border-border">
            <h3 className="font-medium mb-2 text-accent-foreground">💡 คำแนะนำ</h3>
            <ul className="list-disc list-inside space-y-1 text-sm text-accent-foreground">
              <li>ระดับราคาใช้สำหรับกำหนดราคาห้องในช่วงเวลาต่างๆ</li>
              <li>ตัวอย่าง: Low Season, High Season, Peak Season, Holiday</li>
              <li>หลังจากสร้างระดับราคาแล้ว ไปที่ "ปฏิทินราคา" เพื่อกำหนดวันที่</li>
              <li>จากนั้นไปที่ "เมทริกซ์ราคา" เพื่อกำหนดราคาสำหรับแต่ละระดับ</li>
            </ul>
          </Card>
        </div>
      )}

      {/* Tab 2: Pricing Calendar */}
      {activeTab === "calendar" && (
        <div className="space-y-6">
          <Card className="p-6 bg-card border-border">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-semibold text-foreground">ปฏิทินราคา</h2>
              <div className="flex gap-4">
                <select
                  value={selectedMonth}
                  onChange={(e) => setSelectedMonth(Number(e.target.value))}
                  className="px-3 py-2 border border-input rounded-md bg-background text-foreground"
                >
                  {Array.from({ length: 12 }, (_, i) => (
                    <option key={i} value={i}>
                      {new Date(2000, i).toLocaleDateString("th-TH", { month: "long" })}
                    </option>
                  ))}
                </select>
                <select
                  value={selectedYear}
                  onChange={(e) => setSelectedYear(Number(e.target.value))}
                  className="px-3 py-2 border border-input rounded-md bg-background text-foreground"
                >
                  {Array.from({ length: 5 }, (_, i) => {
                    const year = new Date().getFullYear() + i;
                    return (
                      <option key={year} value={year}>
                        {year + 543}
                      </option>
                    );
                  })}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-7 gap-2 mb-4">
              {["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"].map((day) => (
                <div key={day} className="text-center font-medium text-muted-foreground">
                  {day}
                </div>
              ))}
              {calendarDays.map((day) => {
                const dateStr = day.toISOString().split("T")[0];
                const tierId = getTierForDate(day);
                const tier = tiers?.find((t: RateTier) => t.rate_tier_id === tierId);
                const isSelected = selectedDates.includes(dateStr);

                return (
                  <button
                    key={dateStr}
                    onClick={() => toggleDateSelection(dateStr)}
                    className={`p-2 text-sm rounded border ${
                      isSelected
                        ? "bg-primary text-primary-foreground border-primary"
                        : tier
                        ? "bg-accent text-accent-foreground border-accent"
                        : "bg-muted text-muted-foreground border-border hover:bg-accent"
                    }`}
                  >
                    <div className="font-medium">{day.getDate()}</div>
                    {tier && <div className="text-xs truncate">{tier.name}</div>}
                  </button>
                );
              })}
            </div>

            <div className="flex gap-4 items-end">
              <div className="flex-1">
                <label className="block text-sm font-medium mb-2 text-foreground">
                  เลือกระดับราคา
                </label>
                <select
                  value={selectedTierForCalendar || ""}
                  onChange={(e) => setSelectedTierForCalendar(Number(e.target.value) || null)}
                  className="w-full px-3 py-2 border border-input rounded-md bg-background text-foreground"
                >
                  <option value="">-- เลือกระดับราคา --</option>
                  {tiers?.map((tier: RateTier) => (
                    <option key={tier.rate_tier_id} value={tier.rate_tier_id}>
                      {tier.name}
                    </option>
                  ))}
                </select>
              </div>
              <Button
                onClick={handleApplyCalendar}
                disabled={updateCalendarMutation.isPending || selectedDates.length === 0}
                className="bg-primary text-primary-foreground"
              >
                {updateCalendarMutation.isPending ? "กำลังบันทึก..." : `ใช้กับ ${selectedDates.length} วัน`}
              </Button>
            </div>
          </Card>

          <Card className="p-6 bg-accent border-border">
            <h3 className="font-medium mb-2 text-accent-foreground">💡 วิธีใช้งาน</h3>
            <ul className="list-disc list-inside space-y-1 text-sm text-accent-foreground">
              <li>คลิกเลือกวันที่ที่ต้องการกำหนดราคา (สามารถเลือกหลายวันได้)</li>
              <li>เลือกระดับราคาจาก dropdown</li>
              <li>กดปุ่ม "ใช้กับ X วัน" เพื่อบันทึก</li>
              <li>วันที่มีสีแสดงว่ามีการกำหนดระดับราคาแล้ว</li>
            </ul>
          </Card>
        </div>
      )}

      {/* Tab 3: Pricing Matrix */}
      {activeTab === "matrix" && (
        <div className="space-y-6">
          <Card className="p-6 bg-card border-border">
            <h2 className="text-xl font-semibold mb-4 text-foreground">เมทริกซ์ราคา</h2>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-border">
                <thead className="bg-muted">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">
                      ประเภทห้อง
                    </th>
                    {tiers?.map((tier: RateTier) => (
                      <th
                        key={tier.rate_tier_id}
                        className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase"
                      >
                        {tier.name}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="bg-card divide-y divide-border">
                  {roomTypes?.map((roomType: RoomType) => (
                    <tr key={roomType.room_type_id}>
                      <td className="px-4 py-4 whitespace-nowrap text-sm font-medium text-foreground">
                        {roomType.name}
                      </td>
                      {tiers?.map((tier: RateTier) => {
                        const price = getPrice(roomType.room_type_id, 1, tier.rate_tier_id);
                        const isEditing =
                          editingCell?.room_type_id === roomType.room_type_id &&
                          editingCell?.rate_tier_id === tier.rate_tier_id;

                        return (
                          <td key={tier.rate_tier_id} className="px-4 py-4 whitespace-nowrap text-sm">
                            {isEditing ? (
                              <div className="flex gap-2">
                                <Input
                                  type="number"
                                  value={editPrice}
                                  onChange={(e) => setEditPrice(e.target.value)}
                                  className="w-24 bg-background text-foreground border-input"
                                />
                                <Button
                                  onClick={handleUpdatePrice}
                                  disabled={updatePriceMutation.isPending}
                                  className="bg-primary text-primary-foreground text-xs px-2 py-1"
                                >
                                  บันทึก
                                </Button>
                                <Button
                                  onClick={() => {
                                    setEditingCell(null);
                                    setEditPrice("");
                                  }}
                                  className="bg-secondary text-secondary-foreground text-xs px-2 py-1"
                                >
                                  ยกเลิก
                                </Button>
                              </div>
                            ) : (
                              <button
                                onClick={() => {
                                  setEditingCell({
                                    room_type_id: roomType.room_type_id,
                                    rate_plan_id: 1,
                                    rate_tier_id: tier.rate_tier_id,
                                  });
                                  setEditPrice(price.toString());
                                }}
                                className="text-primary hover:underline"
                              >
                                ฿{price.toLocaleString()}
                              </button>
                            )}
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          <Card className="p-6 bg-accent border-border">
            <h3 className="font-medium mb-2 text-accent-foreground">💡 คำแนะนำ</h3>
            <ul className="list-disc list-inside space-y-1 text-sm text-accent-foreground">
              <li>คลิกที่ราคาเพื่อแก้ไข</li>
              <li>ราคาจะถูกใช้เมื่อแขกจองห้องในวันที่กำหนดระดับราคานั้นๆ</li>
              <li>ตัวอย่าง: Standard Room ในวัน Low Season จะใช้ราคาที่กำหนดในเซลล์นั้น</li>
            </ul>
          </Card>
        </div>
      )}
    </div>
  );
}
