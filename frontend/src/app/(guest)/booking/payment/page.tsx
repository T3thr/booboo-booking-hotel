'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useBookingStore } from '@/store/useBookingStore';
import { CountdownTimer } from '@/components/countdown-timer';
import { LoadingSpinner } from '@/components/ui/loading';
import { formatCurrency } from '@/utils/date';

type PaymentMethod = 'bank_transfer' | 'qr_code' | 'credit_card';

export default function PaymentPage() {
  const router = useRouter();
  const {
    searchParams,
    selectedRoomType,
    guestInfo,
    holdExpiry,
    clearBooking,
  } = useBookingStore();

  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('bank_transfer');
  const [paymentProof, setPaymentProof] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Redirect if no booking data
  if (!searchParams || !selectedRoomType || !guestInfo || !holdExpiry) {
    router.push('/rooms/search');
    return null;
  }

  const totalAmount = (selectedRoomType.total_price || 0) * 1.07;

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        setError('ไฟล์มีขนาดใหญ่เกิน 5MB');
        return;
      }
      if (!file.type.startsWith('image/')) {
        setError('กรุณาอัปโหลดไฟล์รูปภาพเท่านั้น');
        return;
      }
      setPaymentProof(file);
      setError(null);
      
      // Create preview URL only in browser
      if (typeof window !== 'undefined' && typeof URL !== 'undefined') {
        try {
          const objectUrl = URL.createObjectURL(file);
          setPreviewUrl(objectUrl);
        } catch (err) {
          console.error('Failed to create object URL:', err);
        }
      }
    }
  };

  const handleSubmit = async () => {
    if (!paymentProof) {
      setError('กรุณาอัปโหลดหลักฐานการโอนเงิน');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      // Create booking first
      const sessionId = `session_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
      
      const bookingResponse = await fetch('/api/bookings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: sessionId,
          details: [{
            room_type_id: selectedRoomType.room_type_id,
            rate_plan_id: 1, // Default rate plan
            check_in: searchParams.check_in_date,
            check_out: searchParams.check_out_date,
            num_guests: guestInfo.length,
            guests: guestInfo,
          }],
        }),
      });

      const bookingData = await bookingResponse.json();

      if (!bookingResponse.ok || !bookingData.success) {
        throw new Error(bookingData.message || 'ไม่สามารถสร้างการจองได้');
      }

      const bookingId = bookingData.data.booking_id;

      // Upload payment proof
      const formData = new FormData();
      formData.append('payment_proof', paymentProof);
      formData.append('booking_id', bookingId.toString());
      formData.append('payment_method', paymentMethod);
      formData.append('amount', totalAmount.toString());

      const uploadResponse = await fetch('/api/bookings/payment-proof', {
        method: 'POST',
        body: formData,
      });

      const uploadData = await uploadResponse.json();

      if (!uploadResponse.ok || !uploadData.success) {
        throw new Error(uploadData.message || 'ไม่สามารถอัปโหลดหลักฐานได้');
      }

      // Clear booking store
      clearBooking();

      // Redirect to confirmation
      router.push(`/booking/confirmation/${bookingId}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'เกิดข้อผิดพลาด');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-muted/30 py-8">
      <div className="container mx-auto px-4 max-w-5xl">
        {/* Timer Banner */}
        <div className="bg-accent border-2 border-accent-foreground/20 rounded-lg p-4 mb-6 shadow-lg">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="flex items-center gap-3">
              <svg className="w-6 h-6 text-accent-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="font-medium text-accent-foreground">เวลาที่เหลือในการชำระเงิน</span>
            </div>
            <CountdownTimer expiryDate={holdExpiry} onExpire={() => router.push('/rooms/search')} />
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Payment Form */}
          <div className="lg:col-span-2 space-y-6">
            {/* Payment Method Selection */}
            <div className="bg-background rounded-lg shadow-lg p-6">
              <h2 className="text-2xl font-bold text-foreground mb-6">เลือกวิธีการชำระเงิน</h2>
              
              <div className="space-y-4">
                {/* Bank Transfer */}
                <label className={`block border-2 rounded-lg p-4 cursor-pointer transition-all ${
                  paymentMethod === 'bank_transfer' 
                    ? 'border-primary bg-primary/5' 
                    : 'border-border hover:border-primary/50'
                }`}>
                  <div className="flex items-center gap-4">
                    <input
                      type="radio"
                      name="payment_method"
                      value="bank_transfer"
                      checked={paymentMethod === 'bank_transfer'}
                      onChange={(e) => setPaymentMethod(e.target.value as PaymentMethod)}
                      className="w-5 h-5 text-primary"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
                          <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                          </svg>
                        </div>
                        <div>
                          <p className="font-semibold text-foreground">โอนเงินผ่านธนาคาร</p>
                          <p className="text-sm text-muted-foreground">โอนเงินผ่านแอปธนาคารหรือ ATM</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </label>

                {/* QR Code */}
                <label className={`block border-2 rounded-lg p-4 cursor-pointer transition-all ${
                  paymentMethod === 'qr_code' 
                    ? 'border-primary bg-primary/5' 
                    : 'border-border hover:border-primary/50'
                }`}>
                  <div className="flex items-center gap-4">
                    <input
                      type="radio"
                      name="payment_method"
                      value="qr_code"
                      checked={paymentMethod === 'qr_code'}
                      onChange={(e) => setPaymentMethod(e.target.value as PaymentMethod)}
                      className="w-5 h-5 text-primary"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
                          <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                          </svg>
                        </div>
                        <div>
                          <p className="font-semibold text-foreground">QR Code พร้อมเพย์</p>
                          <p className="text-sm text-muted-foreground">สแกน QR Code เพื่อชำระเงิน</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </label>

                {/* Credit Card (Mockup) */}
                <label className={`block border-2 rounded-lg p-4 cursor-pointer transition-all opacity-50 ${
                  paymentMethod === 'credit_card' 
                    ? 'border-primary bg-primary/5' 
                    : 'border-border'
                }`}>
                  <div className="flex items-center gap-4">
                    <input
                      type="radio"
                      name="payment_method"
                      value="credit_card"
                      disabled
                      className="w-5 h-5 text-primary"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 bg-muted rounded-lg flex items-center justify-center">
                          <svg className="w-6 h-6 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                          </svg>
                        </div>
                        <div>
                          <p className="font-semibold text-muted-foreground">บัตรเครดิต/เดบิต</p>
                          <p className="text-sm text-muted-foreground">ยังไม่เปิดให้บริการ</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </label>
              </div>
            </div>

            {/* Bank Details */}
            {paymentMethod === 'bank_transfer' && (
              <div className="bg-background rounded-lg shadow-lg p-6">
                <h3 className="text-xl font-bold text-foreground mb-4">ข้อมูลบัญชีธนาคาร</h3>
                <div className="bg-gradient-to-r from-primary/10 to-primary/5 border border-primary/20 rounded-lg p-6">
                  <div className="space-y-3">
                    <div className="flex justify-between items-center">
                      <span className="text-muted-foreground">ธนาคาร</span>
                      <span className="font-semibold text-foreground">ธนาคารกสิกรไทย</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-muted-foreground">ชื่อบัญชี</span>
                      <span className="font-semibold text-foreground">บริษัท โรงแรมตัวอย่าง จำกัด</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-muted-foreground">เลขที่บัญชี</span>
                      <span className="font-mono text-xl font-bold text-primary">123-4-56789-0</span>
                    </div>
                    <div className="flex justify-between items-center pt-3 border-t border-primary/20">
                      <span className="text-muted-foreground">จำนวนเงินที่ต้องโอน</span>
                      <span className="text-2xl font-bold text-primary">{formatCurrency(totalAmount)}</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* QR Code */}
            {paymentMethod === 'qr_code' && (
              <div className="bg-background rounded-lg shadow-lg p-6">
                <h3 className="text-xl font-bold text-foreground mb-4">สแกน QR Code</h3>
                <div className="flex flex-col items-center">
                  <div className="w-64 h-64 bg-muted rounded-lg flex items-center justify-center mb-4">
                    <div className="text-center">
                      <svg className="w-32 h-32 text-muted-foreground mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                      </svg>
                      <p className="text-sm text-muted-foreground">QR Code สำหรับชำระเงิน</p>
                    </div>
                  </div>
                  <p className="text-center text-muted-foreground mb-2">จำนวนเงิน</p>
                  <p className="text-3xl font-bold text-primary mb-4">{formatCurrency(totalAmount)}</p>
                  <p className="text-sm text-muted-foreground text-center">
                    สแกน QR Code ด้วยแอปธนาคารของคุณ<br />
                    หรือแอป Mobile Banking
                  </p>
                </div>
              </div>
            )}

            {/* Upload Payment Proof */}
            <div className="bg-background rounded-lg shadow-lg p-6">
              <h3 className="text-xl font-bold text-foreground mb-4">อัปโหลดหลักฐานการโอนเงิน</h3>
              
              {!previewUrl ? (
                <label className="block border-2 border-dashed border-border rounded-lg p-8 text-center cursor-pointer hover:border-primary transition-colors">
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    className="hidden"
                  />
                  <svg className="w-16 h-16 text-muted-foreground mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                  <p className="text-foreground font-medium mb-1">คลิกเพื่ออัปโหลดหลักฐาน</p>
                  <p className="text-sm text-muted-foreground">รองรับไฟล์ JPG, PNG (ขนาดไม่เกิน 5MB)</p>
                </label>
              ) : (
                <div className="space-y-4">
                  <div className="relative rounded-lg overflow-hidden border-2 border-border">
                    <img src={previewUrl} alt="Payment proof" className="w-full h-auto" />
                  </div>
                  <button
                    onClick={() => {
                      setPaymentProof(null);
                      setPreviewUrl(null);
                    }}
                    className="w-full bg-muted text-foreground px-4 py-2 rounded-lg hover:bg-muted/80 transition-colors"
                  >
                    เปลี่ยนรูปภาพ
                  </button>
                </div>
              )}

              {error && (
                <div className="mt-4 bg-destructive/10 border border-destructive/20 rounded-lg p-4 text-destructive text-sm">
                  {error}
                </div>
              )}
            </div>

            {/* Submit Button */}
            <button
              onClick={handleSubmit}
              disabled={!paymentProof || isSubmitting}
              className="w-full bg-primary text-primary-foreground px-6 py-4 rounded-lg font-semibold text-lg hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed shadow-lg"
            >
              {isSubmitting ? (
                <span className="flex items-center justify-center gap-2">
                  <LoadingSpinner size="sm" />
                  กำลังดำเนินการ...
                </span>
              ) : (
                'ยืนยันการชำระเงิน'
              )}
            </button>
          </div>

          {/* Order Summary */}
          <div className="lg:col-span-1">
            <div className="bg-background rounded-lg shadow-lg p-6 sticky top-4">
              <h3 className="text-xl font-bold text-foreground mb-4">สรุปการจอง</h3>
              
              <div className="space-y-4">
                <div>
                  <p className="font-semibold text-foreground mb-1">{selectedRoomType.name}</p>
                  <p className="text-sm text-muted-foreground">
                    {new Date(searchParams.check_in_date).toLocaleDateString('th-TH', { 
                      day: 'numeric', 
                      month: 'short' 
                    })} - {new Date(searchParams.check_out_date).toLocaleDateString('th-TH', { 
                      day: 'numeric', 
                      month: 'short',
                      year: 'numeric'
                    })}
                  </p>
                </div>

                <div className="border-t border-border pt-4 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">ราคาห้องพัก</span>
                    <span className="text-foreground">{formatCurrency(selectedRoomType.total_price || 0)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">ภาษีและค่าบริการ (7%)</span>
                    <span className="text-foreground">{formatCurrency((selectedRoomType.total_price || 0) * 0.07)}</span>
                  </div>
                </div>

                <div className="border-t border-border pt-4">
                  <div className="flex justify-between items-center">
                    <span className="font-semibold text-foreground">ยอดรวมทั้งหมด</span>
                    <span className="text-2xl font-bold text-primary">{formatCurrency(totalAmount)}</span>
                  </div>
                </div>
              </div>

              <div className="mt-6 bg-accent/30 border border-accent/50 rounded-lg p-4">
                <div className="flex gap-2">
                  <svg className="w-5 h-5 text-accent-foreground flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                  <div className="text-xs text-accent-foreground">
                    <p className="font-medium mb-1">การชำระเงินปลอดภัย</p>
                    <p className="text-accent-foreground/80">
                      ข้อมูลของคุณได้รับการปกป้องด้วยระบบความปลอดภัยระดับสูง
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
