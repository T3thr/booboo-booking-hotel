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
  const { searchParams, selectedRoomTypeId, holdExpiry, setHoldExpiry } = useBookingStore();
  const createHold = useCreateBookingHold();

  const [guests, setGuests] = useState<GuestInfo[]>([
    { first_name: '', last_name: '', phone: '', type: 'Adult', is_primary: true },
  ]);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isCreatingHold, setIsCreatingHold] = useState(false);

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
      
      const holdData = {
        room_type_id: selectedRoomTypeId,
        check_in_date: searchParams.check_in_date,
        check_out_date: searchParams.check_out_date,
      };

      createHold.mutate(holdData, {
        onSuccess: (data: any) => {
          // Set hold expiry (15 minutes from now)
          const expiry = new Date(Date.now() + 15 * 60 * 1000);
          setHoldExpiry(expiry);
          setIsCreatingHold(false);
          
          // Save hold data to localStorage
          const holdInfo = {
            sessionId: `guest_${Date.now()}`,
            roomTypeId: selectedRoomTypeId,
            roomTypeName: 'Room',
            checkIn: searchParams.check_in_date,
            checkOut: searchParams.check_out_date,
            holdExpiry: expiry.toISOString(),
          };
          localStorage.setItem('booking_hold', JSON.stringify(holdInfo));
        },
        onError: (error: any) => {
          alert('Failed to reserve room: ' + error.message);
          router.push('/rooms/search');
        },
      });
    }
  }, [searchParams, selectedRoomTypeId, holdExpiry, createHold, setHoldExpiry, router, isCreatingHold]);

  const totalGuests = (searchParams?.adults || 1) + (searchParams?.children || 0);

  // Initialize guests array based on search params
  useEffect(() => {
    if (searchParams && guests.length === 1) {
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

  const { setGuestInfo } = useBookingStore();

  const handleContinue = () => {
    if (!validateForm()) {
      return;
    }

    // Store guest info in booking store
    setGuestInfo(guests);
    
    // Navigate to summary page
    router.push('/booking/summary');
  };

  const handleExpire = () => {
    alert('Your reservation has expired. Please search again.');
    router.push('/rooms/search');
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
        <div className="mt-8 flex gap-4">
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
      </div>
    </div>
  );
}
