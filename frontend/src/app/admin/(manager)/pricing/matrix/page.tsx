"use client";

import { useState, useMemo, useEffect } from "react";
import {
  useRateTiers,
  useRatePricing,
  useUpdateRatePricing,
} from "@/hooks/use-pricing";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";

export default function PricingMatrixPage() {
  const { data: tiers, isLoading: tiersLoading } = useRateTiers();
  const { data: roomTypes, isLoading: roomTypesLoading } = useQuery({
    queryKey: ["roomTypes"],
    queryFn: () => api.get("/rooms/types"),
  });
  const { data: ratePlansResponse, isLoading: ratePlansLoading } = useQuery({
    queryKey: ["ratePlans"],
    queryFn: () => api.get("/pricing/plans"),
  });
  
  const ratePlans = ratePlansResponse?.data || ratePlansResponse;
  
  const [selectedRatePlanId, setSelectedRatePlanId] = useState<number | null>(null);
  const { data: pricingData, isLoading: pricingLoading } = useRatePricing(
    selectedRatePlanId ? { rate_plan_id: selectedRatePlanId } : undefined
  );
  
  const updatePricing = useUpdateRatePricing();

  const [editMode, setEditMode] = useState(false);
  const [prices, setPrices] = useState<Map<string, number>>(new Map());
  const [bulkUpdateMode, setBulkUpdateMode] = useState(false);
  const [bulkPercentage, setBulkPercentage] = useState<string>("");
  const [bulkOperation, setBulkOperation] = useState<"increase" | "decrease">("increase");

  // Initialize prices from API data
  useEffect(() => {
    if (pricingData) {
      const priceMap = new Map<string, number>();
      pricingData.forEach((item: any) => {
        const key = `${item.room_type_id}-${item.rate_tier_id}`;
        priceMap.set(key, item.price);
      });
      setPrices(priceMap);
    }
  }, [pricingData]);

  // Auto-select first rate plan
  useEffect(() => {
    if (ratePlans && ratePlans.length > 0 && !selectedRatePlanId) {
      setSelectedRatePlanId(ratePlans[0].rate_plan_id);
    }
  }, [ratePlans, selectedRatePlanId]);

  const getPrice = (roomTypeId: number, tierId: number): number => {
    const key = `${roomTypeId}-${tierId}`;
    return prices.get(key) || 0;
  };

  const setPrice = (roomTypeId: number, tierId: number, price: number) => {
    const key = `${roomTypeId}-${tierId}`;
    setPrices(new Map(prices.set(key, price)));
  };

  const handleSave = async () => {
    if (!selectedRatePlanId) return;

    const updates: any[] = [];
    prices.forEach((price, key) => {
      const [roomTypeId, tierId] = key.split("-").map(Number);
      updates.push({
        rate_plan_id: selectedRatePlanId,
        room_type_id: roomTypeId,
        rate_tier_id: tierId,
        price,
      });
    });

    try {
      await updatePricing.mutateAsync(updates);
      setEditMode(false);
      alert("บันทึกราคาสำเร็จ");
    } catch (error) {
      console.error("Failed to update pricing:", error);
      alert("ไม่สามารถบันทึกราคาได้: " + (error as Error).message);
    }
  };

  const handleBulkUpdate = () => {
    const percentage = parseFloat(bulkPercentage);
    if (isNaN(percentage) || percentage <= 0) {
      alert("กรุณากรอกเปอร์เซ็นต์ที่ถูกต้อง");
      return;
    }

    const newPrices = new Map(prices);
    newPrices.forEach((price, key) => {
      if (price > 0) {
        const multiplier = bulkOperation === "increase" 
          ? (1 + percentage / 100) 
          : (1 - percentage / 100);
        newPrices.set(key, Math.round(price * multiplier));
      }
    });

    setPrices(newPrices);
    setBulkUpdateMode(false);
    setBulkPercentage("");
  };

  const hasEmptyPrices = useMemo(() => {
    if (!roomTypes || !tiers) return false;
    
    for (const roomType of roomTypes) {
      for (const tier of tiers) {
        if (getPrice(roomType.room_type_id, tier.rate_tier_id) === 0) {
          return true;
        }
      }
    }
    return false;
  }, [roomTypes, tiers, prices]);

  if (tiersLoading || roomTypesLoading || ratePlansLoading || pricingLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">กำลังโหลดข้อมูล...</p>
        </div>
      </div>
    );
  }

  if (!tiers || tiers.length === 0) {
    return (
      <div className="max-w-7xl mx-auto px-4">
        <Card className="p-6 bg-yellow-50 border-yellow-200">
          <p className="text-yellow-800">
            กรุณาสร้างระดับราคาที่หน้า "จัดการระดับราคา" ก่อน
          </p>
        </Card>
      </div>
    );
  }

  if (!roomTypes || roomTypes.length === 0) {
    return (
      <div className="max-w-7xl mx-auto px-4">
        <Card className="p-6 bg-yellow-50 border-yellow-200">
          <p className="text-yellow-800">
            ยังไม่มีประเภทห้องในระบบ
          </p>
        </Card>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">เมทริกซ์ราคา (Rate Pricing Matrix)</h1>
        <p className="mt-2 text-gray-600">
          กำหนดราคาสำหรับแต่ละประเภทห้องและระดับราคา
        </p>
      </div>

      {/* Rate Plan Selector */}
      <Card className="p-4 mb-6">
        <div className="flex items-center gap-4">
          <label className="font-semibold">แผนราคา:</label>
          <select
            value={selectedRatePlanId || ""}
            onChange={(e) => {
              setSelectedRatePlanId(Number(e.target.value));
              setEditMode(false);
            }}
            className="px-4 py-2 border rounded-lg"
          >
            {ratePlans?.map((plan: any) => (
              <option key={plan.rate_plan_id} value={plan.rate_plan_id}>
                {plan.name}
              </option>
            ))}
          </select>
        </div>
      </Card>

      {/* Controls */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex gap-2">
          {!editMode ? (
            <Button onClick={() => setEditMode(true)}>
              แก้ไขราคา
            </Button>
          ) : (
            <>
              <Button onClick={handleSave} disabled={updatePricing.isPending}>
                {updatePricing.isPending ? "กำลังบันทึก..." : "บันทึก"}
              </Button>
              <Button
                onClick={() => {
                  setEditMode(false);
                  // Reset prices from API data
                  if (pricingData) {
                    const priceMap = new Map<string, number>();
                    pricingData.forEach((item: any) => {
                      const key = `${item.room_type_id}-${item.rate_tier_id}`;
                      priceMap.set(key, item.price);
                    });
                    setPrices(priceMap);
                  }
                }}
                variant="outline"
              >
                ยกเลิก
              </Button>
            </>
          )}
        </div>

        {editMode && (
          <Button
            onClick={() => setBulkUpdateMode(!bulkUpdateMode)}
            variant="outline"
          >
            {bulkUpdateMode ? "ปิด Bulk Update" : "Bulk Update"}
          </Button>
        )}
      </div>

      {/* Bulk Update Panel */}
      {editMode && bulkUpdateMode && (
        <Card className="p-4 mb-6 bg-blue-50 border-blue-200">
          <h3 className="font-semibold mb-3">อัปเดตราคาแบบกลุ่ม</h3>
          <div className="flex items-center gap-4">
            <select
              value={bulkOperation}
              onChange={(e) => setBulkOperation(e.target.value as "increase" | "decrease")}
              className="px-4 py-2 border rounded-lg"
            >
              <option value="increase">เพิ่ม</option>
              <option value="decrease">ลด</option>
            </select>
            <Input
              type="number"
              placeholder="เปอร์เซ็นต์"
              value={bulkPercentage}
              onChange={(e) => setBulkPercentage(e.target.value)}
              className="w-32"
            />
            <span>%</span>
            <Button onClick={handleBulkUpdate}>
              ใช้กับทุกราคา
            </Button>
          </div>
        </Card>
      )}

      {/* Warning for empty prices */}
      {hasEmptyPrices && (
        <Card className="p-4 mb-6 bg-red-50 border-red-200">
          <p className="text-red-800">
            ⚠️ มีบางช่องที่ยังไม่ได้กำหนดราคา (แสดงเป็นสีแดง) กรุณากำหนดราคาให้ครบถ้วน
          </p>
        </Card>
      )}

      {/* Pricing Matrix Table */}
      <Card className="p-6 overflow-x-auto">
        <table className="w-full border-collapse">
          <thead>
            <tr>
              <th className="border p-3 bg-gray-100 text-left font-semibold">
                ประเภทห้อง
              </th>
              {tiers.map((tier: any) => (
                <th
                  key={tier.rate_tier_id}
                  className="border p-3 bg-gray-100 text-center font-semibold"
                >
                  {tier.name}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {roomTypes.map((roomType: any) => (
              <tr key={roomType.room_type_id}>
                <td className="border p-3 font-medium bg-gray-50">
                  {roomType.name}
                </td>
                {tiers.map((tier: any) => {
                  const price = getPrice(roomType.room_type_id, tier.rate_tier_id);
                  const isEmpty = price === 0;

                  return (
                    <td
                      key={tier.rate_tier_id}
                      className={`border p-2 text-center ${
                        isEmpty ? "bg-red-50" : ""
                      }`}
                    >
                      {editMode ? (
                        <Input
                          type="number"
                          value={price || ""}
                          onChange={(e) =>
                            setPrice(
                              roomType.room_type_id,
                              tier.rate_tier_id,
                              parseFloat(e.target.value) || 0
                            )
                          }
                          className="text-center"
                          min="0"
                          step="100"
                        />
                      ) : (
                        <span className={isEmpty ? "text-red-600 font-semibold" : ""}>
                          {price > 0 ? `฿${price.toLocaleString()}` : "-"}
                        </span>
                      )}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </Card>

      {/* Info Box */}
      <Card className="p-6 mt-6 bg-blue-50 border-blue-200">
        <h3 className="font-semibold text-blue-900 mb-2">💡 คำแนะนำ</h3>
        <ul className="text-sm text-blue-800 space-y-1">
          <li>• ตารางนี้แสดงราคาสำหรับแต่ละประเภทห้องในแต่ละระดับราคา</li>
          <li>• ช่องสีแดงคือราคาที่ยังไม่ได้กำหนด ต้องกำหนดให้ครบก่อนเปิดให้จอง</li>
          <li>• ใช้ Bulk Update เพื่อเพิ่ม/ลดราคาทั้งหมดตามเปอร์เซ็นต์</li>
          <li>• ราคาที่กำหนดจะถูกใช้คำนวณเมื่อผู้เข้าพักค้นหาห้อง</li>
        </ul>
      </Card>
    </div>
  );
}
