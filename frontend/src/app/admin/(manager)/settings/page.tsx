'use client';

import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';
import {
  Building2,
  Tag,
  FileText,
  Users,
  Settings as SettingsIcon,
} from 'lucide-react';

export default function ManagerSettingsPage() {
  const settingsCategories = [
    {
      title: 'จัดการห้องพัก',
      description: 'เพิ่ม แก้ไข หรือลบประเภทห้องพัก',
      icon: Building2,
      href: '/manager/settings/rooms',
      color: 'text-blue-600 dark:text-blue-400',
      bgColor: 'bg-blue-50 dark:bg-blue-950',
    },
    {
      title: 'คูปองส่วนลด',
      description: 'สร้างและจัดการคูปองส่วนลด',
      icon: Tag,
      href: '/manager/settings/vouchers',
      color: 'text-green-600 dark:text-green-400',
      bgColor: 'bg-green-50 dark:bg-green-950',
    },
    {
      title: 'นโยบายการยกเลิก',
      description: 'ตั้งค่านโยบายการยกเลิกการจอง',
      icon: FileText,
      href: '/manager/settings/policies',
      color: 'text-purple-600 dark:text-purple-400',
      bgColor: 'bg-purple-50 dark:bg-purple-950',
    },
    {
      title: 'จัดการพนักงาน',
      description: 'เพิ่ม แก้ไข หรือลบบัญชีพนักงาน',
      icon: Users,
      href: '/manager/settings/staff',
      color: 'text-orange-600 dark:text-orange-400',
      bgColor: 'bg-orange-50 dark:bg-orange-950',
    },
    {
      title: 'ตั้งค่าทั่วไป',
      description: 'การตั้งค่าระบบและโรงแรม',
      icon: SettingsIcon,
      href: '/manager/settings/general',
      color: 'text-gray-600 dark:text-gray-400',
      bgColor: 'bg-gray-50 dark:bg-gray-950',
    },
  ];

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Header */}
        <div>
          <h1 className="text-4xl font-bold text-foreground mb-2">
            ตั้งค่าระบบ
          </h1>
          <p className="text-muted-foreground">
            จัดการการตั้งค่าและข้อมูลพื้นฐานของระบบ
          </p>
        </div>

        {/* Settings Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {settingsCategories.map((category, index) => (
            <Link key={index} href={category.href}>
              <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer h-full">
                <div
                  className={`w-14 h-14 rounded-lg ${category.bgColor} flex items-center justify-center mb-4`}
                >
                  <category.icon className={`w-7 h-7 ${category.color}`} />
                </div>
                <h3 className="text-xl font-semibold text-foreground mb-2">
                  {category.title}
                </h3>
                <p className="text-sm text-muted-foreground">
                  {category.description}
                </p>
              </Card>
            </Link>
          ))}
        </div>

        {/* Info Card */}
        <Card className="p-6 bg-muted/50">
          <h2 className="text-lg font-semibold text-foreground mb-2">
            💡 คำแนะนำ
          </h2>
          <p className="text-sm text-muted-foreground">
            การเปลี่ยนแปลงการตั้งค่าบางอย่างอาจส่งผลต่อการทำงานของระบบ
            กรุณาตรวจสอบให้แน่ใจก่อนบันทึกการเปลี่ยนแปลง
          </p>
        </Card>
      </div>
    </div>
  );
}
