'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useBookingStore } from '@/store/useBookingStore';
import { useCreateBookingHold } from '@/hooks/use-bookings';
import { useSession } from 'next-auth/react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { CountdownTimer } from '@/components/countdown-timer';
import { Loading } from '@/components/ui/loading';
import { X } from 'lucide-react';

interface GuestInfo {
  first_name: string;
  last_name: string;
  phone?: string;
  type: 'Adult' | 'Child';
  is_primary: boolean;
}

export default function GuestInfoPage() {
  const router = useRouter();
  const { data: session } = useSession();
  const { searchParams, selectedRoomTypeId, selectedRoomType, holdExpiry, setHoldExpiry } = useBookingStore();
  const createHold = useCreateBookingHold();

  const [guests, setGuests] = useState<GuestInfo[]>([
    { first_name: '', last_name: '', phone: '', type: 'Adult', is_primary: true },
  ]);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isCreatingHold, setIsCreatingHold] = useState(false);
  const [isCanceling, setIsCanceling] = useState(false);
  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState('');

  // Redirect if no search params or room selected
  useEffect(() => {
    if (!searchParams || !selectedRoomTypeId) {
      router.push('/rooms/search');
    }
  }, [searchParams, selectedRoomTypeId, router]);

  // Create hold when page loads (if not already created)
  useEffect(() => {
    if (searchParams && selectedRoomTypeId && !holdExpiry && !isCreatingHold) {
      setIsCreatingHold(true);
      
      // Clear old session ID to prevent conflicts
      sessionStorage.removeItem('booking_session_id');
      console.log('[Hold] Cleared old session ID');
      
      const holdData = {
        room_type_id: selectedRoomTypeId,
        check_in_date: searchParams.check_in_date,
        check_out_date: searchParams.check_out_date,
      };

      createHold.mutate(holdData, {
        onSuccess: (data: any) => {
          console.log('[Hold] Backend response:', data);
          
          // Use expiry from backend if available, otherwise 15 minutes from now
          const expiry = data.hold_expiry 
            ? new Date(data.hold_expiry) 
            : new Date(Date.now() + 15 * 60 * 1000);
          
          setHoldExpiry(expiry);
          setIsCreatingHold(false);
          
          // Save complete hold data to localStorage
          const holdInfo = {
            sessionId: data.session_id || `guest_${Date.now()}`,
            roomTypeId: selectedRoomTypeId,
            roomTypeName: selectedRoomType?.name || 'Room',
            checkIn: searchParams.check_in_date,
            checkOut: searchParams.check_out_date,
            adults: searchParams.adults || 2,
            children: searchParams.children || 0,
            holdExpiry: expiry.toISOString(),
          };
          localStorage.setItem('booking_hold', JSON.stringify(holdInfo));
          console.log('[Hold] Saved to localStorage:', holdInfo);
        },
        onError: (error: any) => {
          console.error('[Hold] Error:', error);
          setIsCreatingHold(false);
          
          // Show user-friendly error message
          const errorMsg = error.message || 'ไม่สามารถจองห้องได้';
          showToastMessage(errorMsg);
          
          // Redirect after showing error
          setTimeout(() => {
            router.push('/rooms/search');
          }, 2000);
        },
      });
    }
  }, [searchParams, selectedRoomTypeId, holdExpiry, createHold, setHoldExpiry, router, isCreatingHold]);

  const totalGuests = (searchParams?.adults || 1) + (searchParams?.children || 0);

  // Initialize guests array based on search params and restore draft if available
  useEffect(() => {
    if (searchParams && guests.length === 1) {
      // Try to restore draft data first
      const draftData = localStorage.getItem('booking_guest_draft');
      if (draftData) {
        try {
          const savedGuests = JSON.parse(draftData);
          // Verify the draft matches current booking (same number of guests)
          const expectedTotal = (searchParams.adults || 1) + (searchParams.children || 0);
          if (savedGuests.length === expectedTotal) {
            console.log('[Guest Info] Restoring draft data:', savedGuests);
            setGuests(savedGuests);
            return;
          }
        } catch (error) {
          console.error('[Guest Info] Failed to restore draft:', error);
        }
      }

      // Create new guest list if no valid draft
      const guestList: GuestInfo[] = [];
      
      // Add adults
      for (let i = 0; i < (searchParams.adults || 1); i++) {
        guestList.push({
          first_name: '',
          last_name: '',
          phone: '',
          type: 'Adult',
          is_primary: i === 0,
        });
      }
      
      // Add children
      for (let i = 0; i < (searchParams.children || 0); i++) {
        guestList.push({
          first_name: '',
          last_name: '',
          phone: '',
          type: 'Child',
          is_primary: false,
        });
      }
      
      setGuests(guestList);
    }
  }, [searchParams, guests.length]);

  // Auto-save guest data as draft
  useEffect(() => {
    if (guests.length > 1 || guests[0].first_name || guests[0].last_name) {
      localStorage.setItem('booking_guest_draft', JSON.stringify(guests));
    }
  }, [guests]);

  const handleGuestChange = (index: number, field: keyof GuestInfo, value: string) => {
    const newGuests = [...guests];
    newGuests[index] = { ...newGuests[index], [field]: value };
    setGuests(newGuests);
    
    // Clear error for this field
    setErrors((prev) => {
      const newErrors = { ...prev };
      delete newErrors[`guest_${index}_${field}`];
      return newErrors;
    });
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    guests.forEach((guest, index) => {
      if (!guest.first_name.trim()) {
        newErrors[`guest_${index}_first_name`] = 'First name is required';
      }
      if (!guest.last_name.trim()) {
        newErrors[`guest_${index}_last_name`] = 'Last name is required';
      }
      if (guest.is_primary && !guest.phone?.trim()) {
        newErrors[`guest_${index}_phone`] = 'Phone number is required for primary guest';
      }
      if (guest.phone && !/^[0-9]{10}$/.test(guest.phone.replace(/[-\s]/g, ''))) {
        newErrors[`guest_${index}_phone`] = 'Please enter a valid 10-digit phone number';
      }
    });

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const { setGuestInfo, clearBooking } = useBookingStore();

  const handleContinue = () => {
    if (!validateForm()) {
      return;
    }

    // Store guest info in booking store
    setGuestInfo(guests);
    
    // Keep draft for potential back navigation
    localStorage.setItem('booking_guest_draft', JSON.stringify(guests));
    
    // Navigate to summary page
    router.push('/booking/summary');
  };

  const handleExpire = () => {
    showToastMessage('Your reservation has expired');
    setTimeout(() => {
      router.push('/rooms/search');
    }, 2000);
  };

  const showToastMessage = (message: string) => {
    setToastMessage(message);
    setShowToast(true);
    setTimeout(() => setShowToast(false), 3000);
  };

  const handleCancelBooking = async () => {
    if (!confirm('คุณแน่ใจหรือไม่ว่าต้องการยกเลิกการจอง?')) {
      return;
    }

    setIsCanceling(true);

    try {
      // Get session ID from localStorage
      const holdData = localStorage.getItem('booking_hold');
      if (holdData) {
        const parsed = JSON.parse(holdData);
        
        // Call cancel API
        await fetch('/api/bookings/hold/cancel', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ session_id: parsed.sessionId }),
        });
      }

      // Save guest info before clearing (for potential resume)
      localStorage.setItem('booking_guest_draft', JSON.stringify(guests));

      // Clear localStorage and booking store
      localStorage.removeItem('booking_hold');
      sessionStorage.removeItem('booking_session_id');
      clearBooking();

      // Show toast
      showToastMessage('ยกเลิกการจองเรียบร้อยแล้ว');

      // Redirect after a short delay
      setTimeout(() => {
        router.push('/rooms/search');
      }, 1500);
    } catch (error) {
      console.error('[Cancel] Error:', error);
      showToastMessage('ไม่สามารถยกเลิกการจองได้');
    } finally {
      setIsCanceling(false);
    }
  };

  if (!searchParams || !selectedRoomTypeId) {
    return <Loading />;
  }

  if (isCreatingHold) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto">
          <Loading />
          <p className="text-center mt-4 text-muted-foreground">
            Reserving your room...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        {/* Timer */}
        {holdExpiry && (
          <div className="mb-6 flex justify-center">
            <CountdownTimer expiryDate={holdExpiry} onExpire={handleExpire} />
          </div>
        )}

        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold mb-2">Guest Information</h1>
          <p className="text-muted-foreground">
            Please provide information for all guests ({totalGuests} guest{totalGuests > 1 ? 's' : ''})
          </p>
        </div>

        {/* Guest Forms */}
        <div className="space-y-6">
          {guests.map((guest, index) => (
            <Card key={index} className="p-6">
              <h3 className="text-lg font-semibold mb-4">
                Guest {index + 1} {guest.is_primary && '(Primary)'}
                <span className="ml-2 text-sm font-normal text-muted-foreground">
                  ({guest.type})
                </span>
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">
                    First Name *
                  </label>
                  <Input
                    value={guest.first_name}
                    onChange={(e) => handleGuestChange(index, 'first_name', e.target.value)}
                    placeholder="Enter first name"
                    className={errors[`guest_${index}_first_name`] ? 'border-red-500' : ''}
                  />
                  {errors[`guest_${index}_first_name`] && (
                    <p className="text-red-500 text-sm mt-1">
                      {errors[`guest_${index}_first_name`]}
                    </p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">
                    Last Name *
                  </label>
                  <Input
                    value={guest.last_name}
                    onChange={(e) => handleGuestChange(index, 'last_name', e.target.value)}
                    placeholder="Enter last name"
                    className={errors[`guest_${index}_last_name`] ? 'border-red-500' : ''}
                  />
                  {errors[`guest_${index}_last_name`] && (
                    <p className="text-red-500 text-sm mt-1">
                      {errors[`guest_${index}_last_name`]}
                    </p>
                  )}
                </div>

                {guest.is_primary && (
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium mb-2">
                      Phone Number *
                    </label>
                    <Input
                      value={guest.phone || ''}
                      onChange={(e) => handleGuestChange(index, 'phone', e.target.value)}
                      placeholder="0812345678"
                      type="tel"
                      className={errors[`guest_${index}_phone`] ? 'border-red-500' : ''}
                    />
                    {errors[`guest_${index}_phone`] && (
                      <p className="text-red-500 text-sm mt-1">
                        {errors[`guest_${index}_phone`]}
                      </p>
                    )}
                  </div>
                )}
              </div>
            </Card>
          ))}
        </div>

        {/* Actions */}
        <div className="mt-8 space-y-4">
          <div className="flex gap-4">
            <Button
              variant="outline"
              onClick={() => router.push('/rooms/search')}
              className="flex-1"
            >
              Back to Search
            </Button>
            <Button onClick={handleContinue} className="flex-1">
              Continue to Payment
            </Button>
          </div>
          
          {/* Cancel Button - Smaller and less prominent */}
          <div className="flex justify-center">
            <Button
              variant="ghost"
              size="sm"
              onClick={handleCancelBooking}
              disabled={isCanceling}
              className="text-muted-foreground hover:text-destructive"
            >
              {isCanceling ? (
                <span className="flex items-center gap-2">
                  <Loading />
                  กำลังยกเลิก...
                </span>
              ) : (
                <span className="flex items-center gap-2">
                  <X className="w-3 h-3" />
                  ยกเลิกการจอง
                </span>
              )}
            </Button>
          </div>
        </div>
      </div>

      {/* Toast Notification - More prominent */}
      {showToast && (
        <div className="fixed top-20 left-1/2 transform -translate-x-1/2 z-[100] animate-in slide-in-from-top-5">
          <div className="bg-card border-2 border-primary rounded-lg shadow-2xl px-8 py-5 min-w-[350px]">
            <div className="flex items-center gap-4">
              <div className="flex-shrink-0 w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <p className="text-base font-semibold text-foreground">{toastMessage}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
