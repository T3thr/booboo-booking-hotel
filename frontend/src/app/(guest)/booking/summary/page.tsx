'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useBookingStore } from '@/store/useBookingStore';
import { useCreateBooking, useConfirmBooking } from '@/hooks/use-bookings';
import { useSession } from 'next-auth/react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { CountdownTimer } from '@/components/countdown-timer';
import { Loading } from '@/components/ui/loading';
import { formatDate } from '@/utils/date';

export default function BookingSummaryPage() {
  const router = useRouter();
  const { data: session } = useSession();
  const {
    searchParams,
    selectedRoomTypeId,
    selectedRoomType,
    holdExpiry,
    guestInfo,
    voucherCode,
    setVoucherCode,
    clearBooking,
  } = useBookingStore();

  const createBooking = useCreateBooking();
  const confirmBooking = useConfirmBooking();

  const [voucher, setVoucher] = useState(voucherCode || '');
  const [isProcessing, setIsProcessing] = useState(false);
  const [bookingId, setBookingId] = useState<number | null>(null);
  const [isNavigating, setIsNavigating] = useState(false);

  // Mock payment details
  const [cardNumber, setCardNumber] = useState('');
  const [cardName, setCardName] = useState('');
  const [expiryDate, setExpiryDate] = useState('');
  const [cvv, setCvv] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Redirect if missing required data (but not if we're processing or navigating)
  useEffect(() => {
    if (!isProcessing && !isNavigating && (!searchParams || !selectedRoomTypeId || !guestInfo)) {
      console.log('[Summary] Missing required data, redirecting to search');
      router.push('/rooms/search');
    }
  }, [searchParams, selectedRoomTypeId, guestInfo, router, isProcessing, isNavigating]);

  if (!searchParams || !selectedRoomTypeId || !guestInfo) {
    return <Loading />;
  }

  // Calculate nights and total
  const checkIn = new Date(searchParams.check_in_date);
  const checkOut = new Date(searchParams.check_out_date);
  const nights = Math.ceil((checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24));
  
  // Mock pricing - in real app, this would come from API
  const nightlyRate = selectedRoomType?.base_price || 1500;
  const subtotal = nightlyRate * nights;
  const discount = 0; // Would be calculated based on voucher
  const total = subtotal - discount;

  const handleExpire = () => {
    alert('Your reservation has expired. Please search again.');
    clearBooking();
    router.push('/rooms/search');
  };

  const validatePayment = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!cardNumber || cardNumber.replace(/\s/g, '').length !== 16) {
      newErrors.cardNumber = 'Please enter a valid 16-digit card number';
    }
    if (!cardName.trim()) {
      newErrors.cardName = 'Cardholder name is required';
    }
    if (!expiryDate || !/^\d{2}\/\d{2}$/.test(expiryDate)) {
      newErrors.expiryDate = 'Please enter expiry date as MM/YY';
    }
    if (!cvv || cvv.length !== 3) {
      newErrors.cvv = 'Please enter a valid 3-digit CVV';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handlePayment = async () => {
    if (!validatePayment()) {
      return;
    }

    setIsProcessing(true);

    try {
      // Step 1: Create booking
      const bookingData = {
        room_type_id: selectedRoomTypeId,
        rate_plan_id: 1, // Default rate plan
        check_in_date: searchParams.check_in_date,
        check_out_date: searchParams.check_out_date,
        num_guests: (searchParams.adults || 1) + (searchParams.children || 0),
        guests: guestInfo,
        voucher_code: voucher || undefined,
      };
      
      console.log('[Summary] Sending booking data:', JSON.stringify(bookingData, null, 2));

      const bookingResponse: any = await createBooking.mutateAsync(bookingData);
      console.log('[Summary] Full booking response:', JSON.stringify(bookingResponse, null, 2));
      
      // Handle different response structures
      let newBookingId = bookingResponse.booking_id || 
                        bookingResponse.data?.booking_id || 
                        bookingResponse.bookingId ||
                        bookingResponse.id;
      
      // If response has success wrapper, unwrap it
      if (!newBookingId && bookingResponse.success && bookingResponse.data) {
        newBookingId = bookingResponse.data.booking_id || bookingResponse.data.bookingId || bookingResponse.data.id;
      }
      
      console.log('[Summary] Extracted booking ID:', newBookingId, 'Type:', typeof newBookingId);
      
      if (!newBookingId || newBookingId === 'undefined') {
        console.error('[Summary] Failed to extract booking ID from response');
        console.error('[Summary] Response keys:', Object.keys(bookingResponse));
        throw new Error('Booking ID not found in response. Please check browser console for details.');
      }
      
      // Ensure it's a number
      const bookingIdNumber = typeof newBookingId === 'string' ? parseInt(newBookingId, 10) : newBookingId;
      console.log('[Summary] Final booking ID (number):', bookingIdNumber);
      
      setBookingId(bookingIdNumber);

      // Step 2: Mock payment processing (2 second delay)
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Step 3: Confirm booking with mock payment data
      console.log('[Summary] Confirming booking with ID:', bookingIdNumber);
      const paymentData = {
        payment_method: 'Credit Card (Mock)',
        payment_id: `MOCK_PAYMENT_${Date.now()}_${bookingIdNumber}`,
      };
      await confirmBooking.mutateAsync({ id: bookingIdNumber, paymentData });
      console.log('[Summary] Booking confirmed successfully');

      // Success! Save phone for confirmation page access (non-signed-in users)
      if (!session && guestInfo) {
        const primaryGuest = guestInfo.find(g => g.is_primary);
        if (primaryGuest?.phone) {
          sessionStorage.setItem(`booking_${bookingIdNumber}_phone`, primaryGuest.phone);
          console.log('[Summary] Saved phone for confirmation access');
        }
      }
      
      // Set navigating flag FIRST to prevent useEffect redirect
      setIsNavigating(true);
      console.log('[Summary] Set navigating flag');
      
      // Clear booking state and hold from localStorage
      clearBooking();
      localStorage.removeItem('booking_hold');
      localStorage.removeItem('booking_guest_draft');
      console.log('[Summary] Cleared booking data');
      
      // Mark this booking as viewable once for non-signed-in users
      if (!session) {
        sessionStorage.setItem(`booking_${bookingIdNumber}_viewed`, 'false');
        console.log('[Summary] Marked booking as viewable once');
      }
      
      // Stop processing
      setIsProcessing(false);
      
      // Navigate to confirmation page
      console.log('[Summary] Navigating to confirmation page:', `/booking/confirmation/${bookingIdNumber}`);
      
      // Use window.location for more reliable navigation
      window.location.href = `/booking/confirmation/${bookingIdNumber}`;
    } catch (error: any) {
      console.error('[Summary] Error during booking:', error);
      alert('Payment failed: ' + error.message);
      setIsProcessing(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        {/* Timer */}
        {holdExpiry && (
          <div className="mb-6 flex justify-center">
            <CountdownTimer expiryDate={holdExpiry} onExpire={handleExpire} />
          </div>
        )}

        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold mb-2">Booking Summary</h1>
          <p className="text-muted-foreground">
            Review your booking details and complete payment
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column - Booking Details */}
          <div className="lg:col-span-2 space-y-6">
            {/* Room Details */}
            <Card className="p-6">
              <h2 className="text-xl font-semibold mb-4">Room Details</h2>
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-muted-foreground">Room Type</p>
                  <p className="font-medium">
                    {selectedRoomType?.name || 'Selected Room'}
                  </p>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Check-in</p>
                    <p className="font-medium">{formatDate(searchParams.check_in_date)}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Check-out</p>
                    <p className="font-medium">{formatDate(searchParams.check_out_date)}</p>
                  </div>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Guests</p>
                  <p className="font-medium">
                    {searchParams.adults || 1} Adult{(searchParams.adults || 1) > 1 ? 's' : ''}
                    {searchParams.children ? `, ${searchParams.children} Child${searchParams.children > 1 ? 'ren' : ''}` : ''}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Nights</p>
                  <p className="font-medium">{nights} night{nights > 1 ? 's' : ''}</p>
                </div>
              </div>
            </Card>

            {/* Guest Information */}
            <Card className="p-6">
              <h2 className="text-xl font-semibold mb-4">Guest Information</h2>
              <div className="space-y-3">
                {guestInfo.map((guest, index) => (
                  <div key={index} className="flex justify-between items-center py-2 border-b last:border-b-0">
                    <div>
                      <p className="font-medium">
                        {guest.first_name} {guest.last_name}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        {guest.type} {guest.is_primary && '(Primary Guest)'}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* Payment Details */}
            <Card className="p-6">
              <h2 className="text-xl font-semibold mb-4">Payment Details</h2>
              <p className="text-sm text-yellow-600 dark:text-yellow-400 mb-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded">
                ⚠️ This is a mock payment form. No real payment will be processed.
              </p>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Card Number *
                  </label>
                  <Input
                    value={cardNumber}
                    onChange={(e) => {
                      const value = e.target.value.replace(/\s/g, '');
                      const formatted = value.match(/.{1,4}/g)?.join(' ') || value;
                      setCardNumber(formatted);
                      setErrors((prev) => ({ ...prev, cardNumber: '' }));
                    }}
                    placeholder="1234 5678 9012 3456"
                    maxLength={19}
                    className={errors.cardNumber ? 'border-red-500' : ''}
                    disabled={isProcessing}
                  />
                  {errors.cardNumber && (
                    <p className="text-red-500 text-sm mt-1">{errors.cardNumber}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Cardholder Name *
                  </label>
                  <Input
                    value={cardName}
                    onChange={(e) => {
                      setCardName(e.target.value);
                      setErrors((prev) => ({ ...prev, cardName: '' }));
                    }}
                    placeholder="John Doe"
                    className={errors.cardName ? 'border-red-500' : ''}
                    disabled={isProcessing}
                  />
                  {errors.cardName && (
                    <p className="text-red-500 text-sm mt-1">{errors.cardName}</p>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Expiry Date *
                    </label>
                    <Input
                      value={expiryDate}
                      onChange={(e) => {
                        let value = e.target.value.replace(/\D/g, '');
                        if (value.length >= 2) {
                          value = value.slice(0, 2) + '/' + value.slice(2, 4);
                        }
                        setExpiryDate(value);
                        setErrors((prev) => ({ ...prev, expiryDate: '' }));
                      }}
                      placeholder="MM/YY"
                      maxLength={5}
                      className={errors.expiryDate ? 'border-red-500' : ''}
                      disabled={isProcessing}
                    />
                    {errors.expiryDate && (
                      <p className="text-red-500 text-sm mt-1">{errors.expiryDate}</p>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">CVV *</label>
                    <Input
                      value={cvv}
                      onChange={(e) => {
                        const value = e.target.value.replace(/\D/g, '');
                        setCvv(value);
                        setErrors((prev) => ({ ...prev, cvv: '' }));
                      }}
                      placeholder="123"
                      maxLength={3}
                      type="password"
                      className={errors.cvv ? 'border-red-500' : ''}
                      disabled={isProcessing}
                    />
                    {errors.cvv && (
                      <p className="text-red-500 text-sm mt-1">{errors.cvv}</p>
                    )}
                  </div>
                </div>
              </div>
            </Card>
          </div>

          {/* Right Column - Price Summary */}
          <div className="lg:col-span-1">
            <Card className="p-6 sticky top-4">
              <h2 className="text-xl font-semibold mb-4">Price Summary</h2>
              
              <div className="space-y-3 mb-4">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">
                    ฿{nightlyRate.toLocaleString()} × {nights} night{nights > 1 ? 's' : ''}
                  </span>
                  <span className="font-medium">฿{subtotal.toLocaleString()}</span>
                </div>
                
                {discount > 0 && (
                  <div className="flex justify-between text-green-600">
                    <span>Discount</span>
                    <span>-฿{discount.toLocaleString()}</span>
                  </div>
                )}
              </div>

              {/* Voucher Code */}
              <div className="mb-4 pb-4 border-b">
                <label className="block text-sm font-medium mb-2">
                  Voucher Code (Optional)
                </label>
                <div className="flex gap-2">
                  <Input
                    value={voucher}
                    onChange={(e) => setVoucher(e.target.value.toUpperCase())}
                    placeholder="Enter code"
                    disabled={isProcessing}
                  />
                  <Button
                    variant="outline"
                    onClick={() => setVoucherCode(voucher)}
                    disabled={isProcessing}
                  >
                    Apply
                  </Button>
                </div>
              </div>

              <div className="flex justify-between text-lg font-bold mb-6 pt-4 border-t">
                <span>Total</span>
                <span>฿{total.toLocaleString()}</span>
              </div>

              <Button
                onClick={handlePayment}
                disabled={isProcessing}
                className="w-full"
                size="lg"
              >
                {isProcessing ? (
                  <>
                    <svg
                      className="animate-spin -ml-1 mr-3 h-5 w-5"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      ></circle>
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      ></path>
                    </svg>
                    Processing Payment...
                  </>
                ) : (
                  'Complete Booking'
                )}
              </Button>

              <Button
                variant="outline"
                onClick={() => router.push('/booking/guest-info')}
                disabled={isProcessing}
                className="w-full mt-3"
              >
                Back to Guest Info
              </Button>

              <p className="text-xs text-muted-foreground mt-4 text-center">
                By completing this booking, you agree to our terms and conditions
              </p>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
