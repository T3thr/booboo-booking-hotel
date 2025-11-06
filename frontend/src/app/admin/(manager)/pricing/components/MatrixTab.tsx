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

export default function MatrixTab() {
  const { data: tiers, isLoading: tiersLoading } = useRateTiers();
  const { data: roomTypesResponse, isLoading: roomTypesLoading } = useQuery({
    queryKey: ["roomTypes"],
    queryFn: () => api.get("/rooms/types"),
  });
  const { data: ratePlansResponse, isLoading: ratePlansLoading } = useQuery({
    queryKey: ["ratePlans"],
    queryFn: () => api.get("/pricing/plans"),
  });
  
  // Ensure roomTypes is always an array
  const roomTypes = useMemo(() => {
    if (!roomTypesResponse) return [];
    if (Array.isArray(roomTypesResponse)) return roomTypesResponse;
    if (roomTypesResponse.data && Array.isArray(roomTypesResponse.data)) {
      return roomTypesResponse.data;
    }
    return [];
  }, [roomTypesResponse]);
  
  const ratePlans = ratePlansResponse?.data || ratePlansResponse;
  
  const [selectedRatePlanId, setSelectedRatePlanId] = useState<number | null>(null);
  const { data: pricingData, isLoading: pricingLoading } = useRatePricing(
    selectedRatePlanId ? { rate_plan_id: selectedRatePlanId } : undefined
  );
  
  const updatePricing = useUpdateRatePricing();

  const [editMode, setEditMode] = useState(false);
  const [prices, setPrices] = useState<Map<string, number>>(new Map());

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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('th-TH', {
      style: 'currency',
      currency: 'THB',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  if (tiersLoading || roomTypesLoading || ratePlansLoading) {
    return (
      <div className="text-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-muted-foreground">กำลังโหลดข้อมูล...</p>
      </div>
    );
  }

  if (!tiers || tiers.length === 0) {
    return (
      <Card className="p-8 text-center">
        <p className="text-muted-foreground">ยังไม่มีระดับราคา</p>
        <p className="text-sm text-muted-foreground mt-2">
          กรุณาสร้างระดับราคาที่แท็บ "ระดับราคา" ก่อน
        </p>
      </Card>
    );
  }

  if (roomTypes.length === 0 && !roomTypesLoading) {
    return (
      <Card className="p-8 text-center">
        <p className="text-muted-foreground">ยังไม่มีประเภทห้อง</p>
        <p className="text-sm text-muted-foreground mt-2">
          กรุณาสร้างประเภทห้องในระบบก่อน
        </p>
      </Card>
    );
  }

  if (!ratePlans || ratePlans.length === 0) {
    return (
      <Card className="p-8 text-center">
        <p className="text-muted-foreground">ยังไม่มี Rate Plan</p>
        <p className="text-sm text-muted-foreground mt-2">
          กรุณาสร้าง Rate Plan ในระบบก่อน
        </p>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-foreground">ตารางราคา (Pricing Matrix)</h2>
          <p className="text-sm text-muted-foreground mt-1">
            กำหนดราคาสำหรับแต่ละประเภทห้องและระดับราคา
          </p>
        </div>
        {editMode ? (
          <div className="flex gap-2">
            <Button onClick={handleSave} disabled={updatePricing.isPending}>
              {updatePricing.isPending ? "กำลังบันทึก..." : "บันทึก"}
            </Button>
            <Button
              variant="outline"
              onClick={() => {
                setEditMode(false);
                // Reset prices
                if (pricingData) {
                  const priceMap = new Map<string, number>();
                  pricingData.forEach((item: any) => {
                    const key = `${item.room_type_id}-${item.rate_tier_id}`;
                    priceMap.set(key, item.price);
                  });
                  setPrices(priceMap);
                }
              }}
            >
              ยกเลิก
            </Button>
          </div>
        ) : (
          <Button onClick={() => setEditMode(true)}>แก้ไขราคา</Button>
        )}
      </div>

      {/* Rate Plan Selector */}
      <Card className="p-4">
        <label className="block text-sm font-medium text-foreground mb-2">
          เลือก Rate Plan
        </label>
        <select
          value={selectedRatePlanId || ""}
          onChange={(e) => setSelectedRatePlanId(Number(e.target.value))}
          className="w-full px-3 py-2 bg-background border border-border rounded-md text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
        >
          {ratePlans.map((plan: any) => (
            <option key={plan.rate_plan_id} value={plan.rate_plan_id}>
              {plan.name} - {plan.description}
            </option>
          ))}
        </select>
      </Card>

      {/* Pricing Matrix Table */}
      {pricingLoading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">กำลังโหลดราคา...</p>
        </div>
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-border">
              <thead className="bg-muted">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    ประเภทห้อง
                  </th>
                  {tiers.map((tier: any) => (
                    <th
                      key={tier.rate_tier_id}
                      className="px-6 py-3 text-center text-xs font-medium text-muted-foreground uppercase tracking-wider"
                    >
                      {tier.name}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="bg-background divide-y divide-border">
                {roomTypes.map((roomType: any) => (
                  <tr key={roomType.room_type_id} className="hover:bg-muted/50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-foreground">
                        {roomType.name}
                      </div>
                      <div className="text-xs text-muted-foreground">
                        {roomType.description}
                      </div>
                    </td>
                    {tiers.map((tier: any) => {
                      const price = getPrice(roomType.room_type_id, tier.rate_tier_id);
                      return (
                        <td
                          key={`${roomType.room_type_id}-${tier.rate_tier_id}`}
                          className="px-6 py-4 whitespace-nowrap text-center"
                        >
                          {editMode ? (
                            <Input
                              type="number"
                              value={price}
                              onChange={(e) =>
                                setPrice(
                                  roomType.room_type_id,
                                  tier.rate_tier_id,
                                  parseFloat(e.target.value) || 0
                                )
                              }
                              className="w-32 text-center"
                              min="0"
                              step="100"
                            />
                          ) : (
                            <div className="text-sm font-medium text-foreground">
                              {formatCurrency(price)}
                            </div>
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
      )}

      {/* Info Card */}
      <Card className="p-6 bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800">
        <h3 className="font-semibold text-blue-900 dark:text-blue-100 mb-2">
          💡 คำแนะนำ
        </h3>
        <ul className="text-sm text-blue-800 dark:text-blue-200 space-y-1">
          <li>• ตารางนี้แสดงราคาสำหรับแต่ละประเภทห้องและระดับราคา</li>
          <li>• เลือก Rate Plan ที่ต้องการแก้ไข</li>
          <li>• คลิก "แก้ไขราคา" เพื่อเปลี่ยนแปลงราคา</li>
          <li>• ราคาจะถูกนำไปใช้คำนวณเมื่อลูกค้าจองห้อง</li>
        </ul>
      </Card>
    </div>
  );
}
