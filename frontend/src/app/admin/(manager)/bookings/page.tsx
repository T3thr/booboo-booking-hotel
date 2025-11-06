'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LoadingSpinner } from '@/components/ui/loading';

/**
 * หน้านี้ถูกย้ายไปยัง Reception Dashboard แล้ว
 * เพื่อให้พนักงาน Reception จัดการการจองและการชำระเงิน
 * ผู้จัดการสามารถเข้าถึงได้ผ่าน Reception Dashboard เช่นกัน
 */
export default function AdminBookingsPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to reception page
    router.push('/admin/reception');
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <LoadingSpinner size="lg" />
        <p className="mt-4 text-muted-foreground">
          กำลังเปลี่ยนเส้นทางไปยัง Reception Dashboard...
        </p>
      </div>
    </div>
  );
}
