'use client';

import { useState, useEffect, useRef } from 'react';
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
  email?: string;
  type: 'Adult' | 'Child';
  is_primary: boolean;
}

export default function GuestInfoPage() {
  const router = useRouter();
  const { data: session } = useSession();
  const { searchParams, selectedRoomTypeId, selectedRoomType, holdExpiry, setHoldExpiry } = useBookingStore();
  const createHold = useCreateBookingHold();

  const [guests, setGuests] = useState<GuestInfo[]>([
    { first_name: '', last_name: '', phone: '', email: '', type: 'Adult', is_primary: true },
  ]);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isCanceling, setIsCanceling] = useState(false);
  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const holdCreatedRef = useRef(false); // Prevent duplicate hold creation
  
  // Use mutation status directly
  const isCreatingHold = createHold.isPending;

  // Redirect if no search params or room selected
  useEffect(() => {
    if (!searchParams || !selectedRoomTypeId) {
      router.push('/rooms/search');
    }
  }, [searchParams, selectedRoomTypeId, router]);

  // Create hold when page loads (if not already created)
  useEffect(() => {
    // Prevent duplicate calls using ref
    if (holdCreatedRef.current) {
      console.log('[Hold] Already created, skipping');
      return;
    }
    
    // Check if we already have a valid hold in localStorage
    const existingHold = localStorage.getItem('booking_hold');
    if (existingHold) {
      try {
        const parsed = JSON.parse(existingHold);
        const expiry = new Date(parsed.holdExpiry);
        if (expiry > new Date()) {
          console.log('[Hold] Using existing hold from localStorage');
          setHoldExpiry(expiry);
          holdCreatedRef.current = true;
          return;
        }
      } catch (error) {
        console.error('[Hold] Failed to parse existing hold:', error);
      }
    }
    
    if (searchParams && selectedRoomTypeId && !holdExpiry && !isCreatingHold) {
      holdCreatedRef.current = true; // Mark as creating
      
      console.log('[Hold] Creating new hold...');
      
      const holdData = {
        room_type_id: selectedRoomTypeId,
        check_in_date: searchParams.check_in_date,
        check_out_date: searchParams.check_out_date,
      };

      createHold.mutate(holdData);
    }
  }, [searchParams, selectedRoomTypeId, holdExpiry, isCreatingHold, createHold]);
  
  // Handle mutation success
  useEffect(() => {
    if (createHold.isSuccess && createHold.data && !holdExpiry) {
      const data = createHold.data;
      console.log('[Hold] Processing success:', data);
      
      // Parse expiry
      let expiry: Date;
      if (data.hold_expiry) {
        expiry = new Date(data.hold_expiry);
      } else if (data.expiry_time) {
        expiry = new Date(data.expiry_time);
      } else if (data.data?.hold_expiry) {
        expiry = new Date(data.data.hold_expiry);
      } else {
        expiry = new Date(Date.now() + 15 * 60 * 1000);
      }
      
      // Save to localStorage
      const holdInfo = {
        sessionId: data.session_id || `guest_${Date.now()}`,
        roomTypeId: selectedRoomTypeId!,
        roomTypeName: selectedRoomType?.name || 'Room',
        checkIn: searchParams!.check_in_date,
        checkOut: searchParams!.check_out_date,
        adults: searchParams!.adults || 2,
        children: searchParams!.children || 0,
        holdExpiry: expiry.toISOString(),
      };
      localStorage.setItem('booking_hold', JSON.stringify(holdInfo));
      
      // Update state
      setHoldExpiry(expiry);
      console.log('[Hold] Hold created successfully');
    }
  }, [createHold.isSuccess, createHold.data, holdExpiry, setHoldExpiry, selectedRoomTypeId, selectedRoomType, searchParams]);
  
  // Handle mutation error
  useEffect(() => {
    if (createHold.isError) {
      console.error('[Hold] Error:', createHold.error);
      holdCreatedRef.current = false;
      
      showToastMessage((createHold.error as any)?.message || 'ไม่สามารถจองห้องได้');
      
      setTimeout(() => {
        router.push('/rooms/search');
      }, 2000);
    }
  }, [createHold.isError, createHold.error, router]);

  const totalGuests = (searchParams?.adults || 1) + (searchParams?.children || 0);

  // No need for this useEffect anymore - handled in main useEffect above

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
      
      // For signed-in users, pre-fill primary guest with account info
      const accountFirstName = session?.user ? ((session.user as any).first_name || session.user.name?.split(' ')[0] || '') : '';
      const accountLastName = session?.user ? ((session.user as any).last_name || session.user.name?.split(' ').slice(1).join(' ') || '') : '';
      const accountPhone = session?.user ? ((session.user as any).phone || '') : '';
      const accountEmail = session?.user ? (session.user.email || '') : '';
      
      // Add adults
      for (let i = 0; i < (searchParams.adults || 1); i++) {
        guestList.push({
          first_name: i === 0 && session ? accountFirstName : '',
          last_name: i === 0 && session ? accountLastName : '',
          phone: i === 0 && session ? accountPhone : '',
          email: i === 0 && session ? accountEmail : '',
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
          email: '',
          type: 'Child',
          is_primary: false,
        });
      }
      
      setGuests(guestList);
    }
  }, [searchParams, guests.length, session]);

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
      
      // Phone validation for primary guest
      if (guest.is_primary && !session) {
        // Non-signed-in: phone is required
        if (!guest.phone?.trim()) {
          newErrors[`guest_${index}_phone`] = 'Phone number is required for primary guest';
        }
      }
      // For signed-in users, phone is optional (will use account phone if not provided)
      
      if (guest.phone && !/^[0-9]{10}$/.test(guest.phone.replace(/[-\s]/g, ''))) {
        newErrors[`guest_${index}_phone`] = 'Please enter a valid 10-digit phone number';
      }
      
      // Email validation for primary guest (first guest only)
      if (index === 0 && !session && !guest.email?.trim()) {
        newErrors[`guest_${index}_email`] = 'Email is required for primary guest';
      }
      if (guest.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(guest.email)) {
        newErrors[`guest_${index}_email`] = 'Please enter a valid email address';
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

    // Prepare guest info based on session status
    let finalGuests = [...guests];
    
    if (session?.user) {
      // For signed-in users: Use account info
      const accountPhone = (session.user as any).phone || '';
      const accountEmail = session.user.email || '';
      const accountFirstName = (session.user as any).first_name || session.user.name?.split(' ')[0] || '';
      const accountLastName = (session.user as any).last_name || session.user.name?.split(' ').slice(1).join(' ') || '';
      
      // Update primary guest with account information
      finalGuests[0] = {
        ...finalGuests[0],
        // Use account name if form is empty, otherwise use form data
        first_name: finalGuests[0].first_name?.trim() || accountFirstName,
        last_name: finalGuests[0].last_name?.trim() || accountLastName,
        // Use phone from form if provided, otherwise use account phone
        phone: finalGuests[0].phone?.trim() || accountPhone,
        // Always use account email for signed-in users
        email: accountEmail,
      };
      
      console.log('[Guest Info] Using account data for primary guest:', {
        name: `${finalGuests[0].first_name} ${finalGuests[0].last_name}`,
        email: finalGuests[0].email,
        phone: finalGuests[0].phone,
      });
    } else {
      // For non-signed-in users: Ensure email and phone are provided
      console.log('[Guest Info] Non-signed-in user, using form data:', {
        email: finalGuests[0].email,
        phone: finalGuests[0].phone,
      });
    }

    // Store guest info in booking store
    setGuestInfo(finalGuests);
    
    // Keep draft for potential back navigation
    localStorage.setItem('booking_guest_draft', JSON.stringify(finalGuests));
    
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
        
        // Call cancel API (don't wait for response)
        fetch('/api/bookings/hold/cancel', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ session_id: parsed.sessionId }),
        }).catch(err => console.error('[Cancel] API error:', err));
      }

      // Clear localStorage and booking store
      localStorage.removeItem('booking_hold');
      localStorage.removeItem('booking_guest_draft');
      sessionStorage.removeItem('booking_session_id');
      clearBooking();

      // Show toast
      showToastMessage('ยกเลิกการจองเรียบร้อยแล้ว');

      // Redirect immediately (don't wait)
      router.push('/rooms/search');
    } catch (error) {
      console.error('[Cancel] Error:', error);
      showToastMessage('ไม่สามารถยกเลิกการจองได้');
      setIsCanceling(false);
    }
  };

  if (!searchParams || !selectedRoomTypeId) {
    return <Loading />;
  }

  // Show loading only if actually creating hold (simplified)
  if (isCreatingHold && !holdExpiry) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto text-center">
          <Loading />
          <p className="mt-4 text-muted-foreground">
            Reserving your room...
          </p>
          <p className="mt-2 text-sm text-muted-foreground">
            This should only take a moment
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
                    {guest.is_primary && session && (
                      <span className="text-xs text-muted-foreground ml-2">
                        (from account)
                      </span>
                    )}
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
                    {guest.is_primary && session && (
                      <span className="text-xs text-muted-foreground ml-2">
                        (from account)
                      </span>
                    )}
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
                  <>
                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium mb-2">
                        Phone Number {!session && '*'}
                        {session && (
                          <span className="text-xs text-muted-foreground ml-2">
                            (Optional - will use account phone if not provided)
                          </span>
                        )}
                      </label>
                      <Input
                        value={guest.phone || ''}
                        onChange={(e) => handleGuestChange(index, 'phone', e.target.value)}
                        placeholder={session ? `${(session.user as any)?.phone || '0812345678'} (from account)` : '0812345678'}
                        type="tel"
                        className={errors[`guest_${index}_phone`] ? 'border-red-500' : ''}
                      />
                      {errors[`guest_${index}_phone`] && (
                        <p className="text-red-500 text-sm mt-1">
                          {errors[`guest_${index}_phone`]}
                        </p>
                      )}
                      {session && (
                        <p className="text-xs text-muted-foreground mt-1">
                          Leave blank to use: {(session.user as any)?.phone || 'account phone'}
                        </p>
                      )}
                    </div>
                    
                    {/* Email field for first guest only when not signed in */}
                    {index === 0 && !session && (
                      <div className="md:col-span-2">
                        <label className="block text-sm font-medium mb-2">
                          Email Address *
                        </label>
                        <Input
                          value={guest.email || ''}
                          onChange={(e) => handleGuestChange(index, 'email', e.target.value)}
                          placeholder="your.email@example.com"
                          type="email"
                          className={errors[`guest_${index}_email`] ? 'border-red-500' : ''}
                        />
                        {errors[`guest_${index}_email`] && (
                          <p className="text-red-500 text-sm mt-1">
                            {errors[`guest_${index}_email`]}
                          </p>
                        )}
                      </div>
                    )}
                    
                    {/* Show account email for signed-in users */}
                    {index === 0 && session && (
                      <div className="md:col-span-2">
                        <label className="block text-sm font-medium mb-2">
                          Email Address
                        </label>
                        <Input
                          value={session.user?.email || ''}
                          disabled
                          className="bg-muted"
                        />
                        <p className="text-xs text-muted-foreground mt-1">
                          Using email from your account
                        </p>
                      </div>
                    )}
                  </>
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
