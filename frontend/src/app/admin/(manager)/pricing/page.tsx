"use client";

import { useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

// Import components from existing pages
import TiersTab from "./components/TiersTab";
import CalendarTab from "./components/CalendarTab";
import MatrixTab from "./components/MatrixTab";

type TabType = "tiers" | "calendar" | "matrix";

export default function PricingManagementPage() {
  const [activeTab, setActiveTab] = useState<TabType>("tiers");

  const tabs = [
    { id: "tiers" as TabType, label: "ระดับราคา", icon: "📊" },
    { id: "calendar" as TabType, label: "ปฏิทินราคา", icon: "📅" },
    { id: "matrix" as TabType, label: "ตารางราคา", icon: "💰" },
  ];

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-foreground">จัดการราคาห้องพัก</h1>
        <p className="mt-2 text-muted-foreground">
          กำหนดระดับราคา ปฏิทินราคา และตารางราคาสำหรับแต่ละประเภทห้อง
        </p>
      </div>

      {/* Tabs */}
      <Card className="mb-6">
        <div className="border-b border-border">
          <div className="flex space-x-1 p-2">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`
                  flex items-center gap-2 px-6 py-3 rounded-lg font-medium transition-all
                  ${
                    activeTab === tab.id
                      ? "bg-primary text-primary-foreground shadow-sm"
                      : "text-muted-foreground hover:text-foreground hover:bg-muted"
                  }
                `}
              >
                <span className="text-xl">{tab.icon}</span>
                <span>{tab.label}</span>
              </button>
            ))}
          </div>
        </div>
      </Card>

      {/* Tab Content */}
      <div className="mt-6">
        {activeTab === "tiers" && <TiersTab />}
        {activeTab === "calendar" && <CalendarTab />}
        {activeTab === "matrix" && <MatrixTab />}
      </div>
    </div>
  );
}
