'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useBookingStore } from '@/store/useBookingStore';
import { CountdownTimer } from '@/components/countdown-timer';
import { LoadingSpinner } from '@/components/ui/loading';
import { formatCurrency, formatDate } from '@/utils/date';

export default function BookingHoldPage() {
  const router = useRouter();
  const {
    searchParams,
    selectedRoomType,
    guestInfo,
    holdExpiry,
    setHoldExpiry,
  } = useBookingStore();

  const [isCreatingHold, setIsCreatingHold] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Redirect if no booking data
    if (!searchParams || !selectedRoomType || !guestInfo) {
      router.push('/rooms/search');
      return;
    }

    // Create hold if not exists
    if (!holdExpiry) {
      createBookingHold();
    }
  }, []);

  const createBookingHold = async () => {
    if (!searchParams || !selectedRoomType) {
      setError('ข้อมูลการจองไม่ครบถ้วน');
      return;
    }

    setIsCreatingHold(true);
    setError(null);

    try {
      const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      const response = await fetch('/api/bookings/hold', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: sessionId,
          room_type_id: selectedRoomType.room_type_id,
          check_in: searchParams.check_in_date,
          check_out: searchParams.check_out_date,
        }),
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(data.message || 'ไม่สามารถจองห้องชั่วคราวได้');
      }

      // Set hold expiry (15 minutes from now)
      const expiry = new Date(data.data.hold_expiry || Date.now() + 15 * 60 * 1000);
      setHoldExpiry(expiry);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'เกิดข้อผิดพลาด');
    } finally {
      setIsCreatingHold(false);
    }
  };

  const handleContinueToPayment = () => {
    router.push('/booking/payment');
  };

  const handleCancel = () => {
    router.push('/rooms/search');
  };

  if (isCreatingHold) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-muted/30">
        <div className="text-center">
          <LoadingSpinner size="lg" />
          <p className="mt-4 text-muted-foreground">กำลังจองห้องชั่วคราว...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-muted/30 px-4">
        <div className="max-w-md w-full bg-background rounded-lg shadow-lg p-8 text-center">
          <div className="w-16 h-16 bg-destructive/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-destructive" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-foreground mb-2">เกิดข้อผิดพลาด</h2>
          <p className="text-muted-foreground mb-6">{error}</p>
          <button
            onClick={handleCancel}
            className="w-full bg-primary text-primary-foreground px-6 py-3 rounded-lg font-medium hover:bg-primary/90 transition-colors"
          >
            กลับไปค้นหาห้องใหม่
          </button>
        </div>
      </div>
    );
  }

  if (!holdExpiry || !selectedRoomType || !searchParams) {
    return null;
  }

  const nights = Math.ceil(
    (new Date(searchParams.check_out_date).getTime() - 
     new Date(searchParams.check_in_date).getTime()) / 
    (1000 * 60 * 60 * 24)
  );

  return (
    <div className="min-h-screen bg-muted/30 py-8">
      <div className="container mx-auto px-4 max-w-4xl">
        {/* Timer Banner */}
        <div className="bg-accent border-2 border-accent-foreground/20 rounded-lg p-6 mb-6 shadow-lg">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-accent-foreground/10 rounded-full flex items-center justify-center">
                <svg className="w-6 h-6 text-accent-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h3 className="font-semibold text-accent-foreground">ห้องของคุณถูกจองชั่วคราวแล้ว</h3>
                <p className="text-sm text-accent-foreground/80">กรุณาชำระเงินภายในเวลาที่กำหนด</p>
              </div>
            </div>
            <CountdownTimer expiryDate={holdExpiry} onExpire={handleCancel} />
          </div>
        </div>

        {/* Booking Summary */}
        <div className="bg-background rounded-lg shadow-lg overflow-hidden">
          <div className="bg-primary text-primary-foreground px-6 py-4">
            <h2 className="text-2xl font-bold">สรุปการจอง</h2>
          </div>

          <div className="p-6 space-y-6">
            {/* Room Details */}
            <div className="border-b border-border pb-6">
              <h3 className="font-semibold text-lg text-foreground mb-4">รายละเอียดห้องพัก</h3>
              <div className="flex gap-4">
                <div className="w-32 h-32 bg-muted rounded-lg flex items-center justify-center">
                  <svg className="w-16 h-16 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </svg>
                </div>
                <div className="flex-1">
                  <h4 className="font-semibold text-foreground text-xl mb-2">{selectedRoomType.name}</h4>
                  <p className="text-muted-foreground text-sm mb-3">{selectedRoomType.description}</p>
                  <div className="flex flex-wrap gap-2">
                    {selectedRoomType.amenities?.slice(0, 4).map((amenity: any) => (
                      <span key={amenity.amenity_id} className="text-xs bg-muted px-3 py-1 rounded-full text-muted-foreground">
                        {amenity.name}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Date Details */}
            <div className="border-b border-border pb-6">
              <h3 className="font-semibold text-lg text-foreground mb-4">วันที่เข้าพัก</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-muted/50 rounded-lg p-4">
                  <p className="text-sm text-muted-foreground mb-1">เช็คอิน</p>
                  <p className="font-semibold text-foreground">{formatDate(searchParams.check_in_date)}</p>
                  <p className="text-xs text-muted-foreground mt-1">หลัง 14:00 น.</p>
                </div>
                <div className="bg-muted/50 rounded-lg p-4">
                  <p className="text-sm text-muted-foreground mb-1">เช็คเอาท์</p>
                  <p className="font-semibold text-foreground">{formatDate(searchParams.check_out_date)}</p>
                  <p className="text-xs text-muted-foreground mt-1">ก่อน 12:00 น.</p>
                </div>
                <div className="bg-muted/50 rounded-lg p-4">
                  <p className="text-sm text-muted-foreground mb-1">จำนวนคืน</p>
                  <p className="font-semibold text-foreground text-2xl">{nights}</p>
                  <p className="text-xs text-muted-foreground mt-1">คืน</p>
                </div>
              </div>
            </div>

            {/* Guest Details */}
            <div className="border-b border-border pb-6">
              <h3 className="font-semibold text-lg text-foreground mb-4">ข้อมูลผู้เข้าพัก</h3>
              <div className="space-y-3">
                {guestInfo?.map((guest, index) => (
                  <div key={index} className="flex items-center gap-3 bg-muted/30 rounded-lg p-3">
                    <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                      <svg className="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                      </svg>
                    </div>
                    <div>
                      <p className="font-medium text-foreground">{guest.first_name} {guest.last_name}</p>
                      <p className="text-sm text-muted-foreground">{guest.type} {guest.is_primary && '(ผู้จองหลัก)'}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Price Summary */}
            <div>
              <h3 className="font-semibold text-lg text-foreground mb-4">สรุปราคา</h3>
              <div className="space-y-3">
                <div className="flex justify-between text-muted-foreground">
                  <span>{selectedRoomType.name} x {nights} คืน</span>
                  <span>{formatCurrency(selectedRoomType.total_price || 0)}</span>
                </div>
                <div className="flex justify-between text-muted-foreground">
                  <span>ภาษีและค่าบริการ</span>
                  <span>{formatCurrency((selectedRoomType.total_price || 0) * 0.07)}</span>
                </div>
                <div className="border-t border-border pt-3 flex justify-between items-center">
                  <span className="text-xl font-bold text-foreground">ยอดรวมทั้งหมด</span>
                  <span className="text-2xl font-bold text-primary">
                    {formatCurrency((selectedRoomType.total_price || 0) * 1.07)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="bg-muted/30 px-6 py-4 flex gap-4 flex-wrap">
            <button
              onClick={handleCancel}
              className="flex-1 min-w-[200px] bg-background border-2 border-border text-foreground px-6 py-3 rounded-lg font-medium hover:bg-muted transition-colors"
            >
              ยกเลิก
            </button>
            <button
              onClick={handleContinueToPayment}
              className="flex-1 min-w-[200px] bg-primary text-primary-foreground px-6 py-3 rounded-lg font-medium hover:bg-primary/90 transition-colors shadow-lg"
            >
              ดำเนินการชำระเงิน
            </button>
          </div>
        </div>

        {/* Info Box */}
        <div className="mt-6 bg-accent/30 border border-accent/50 rounded-lg p-4">
          <div className="flex gap-3">
            <svg className="w-5 h-5 text-accent-foreground flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div className="text-sm text-accent-foreground">
              <p className="font-medium mb-1">ข้อมูลสำคัญ</p>
              <ul className="list-disc list-inside space-y-1 text-accent-foreground/80">
                <li>การจองนี้จะถูกยกเลิกอัตโนมัติหากไม่ชำระเงินภายในเวลาที่กำหนด</li>
                <li>กรุณาเตรียมหลักฐานการโอนเงินสำหรับการยืนยันการจอง</li>
                <li>ทีมงานจะตรวจสอบและยืนยันการจองภายใน 24 ชั่วโมง</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
