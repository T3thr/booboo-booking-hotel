'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Clock, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useBookingStore } from '@/store/useBookingStore';

interface HoldData {
  sessionId: string;
  roomTypeId: number;
  roomTypeName: string;
  checkIn: string;
  checkOut: string;
  adults: number;
  children: number;
  holdExpiry: string;
}

export function HoldIndicator() {
  const router = useRouter();
  const [holdData, setHoldData] = useState<HoldData | null>(null);
  const [timeLeft, setTimeLeft] = useState<string>('');
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    // Check for hold data in localStorage
    const checkHold = () => {
      try {
        const stored = localStorage.getItem('booking_hold');
        if (stored) {
          const data: HoldData = JSON.parse(stored);
          const expiry = new Date(data.holdExpiry);
          
          if (expiry > new Date()) {
            setHoldData(data);
            setIsVisible(true);
          } else {
            // Expired, remove it
            localStorage.removeItem('booking_hold');
            sessionStorage.removeItem('booking_session_id');
            setHoldData(null);
            setIsVisible(false);
          }
        } else {
          // No hold data, hide indicator
          setHoldData(null);
          setIsVisible(false);
        }
      } catch (error) {
        console.error('Error checking hold:', error);
      }
    };

    checkHold();
    const interval = setInterval(checkHold, 1000);

    // Listen for storage changes (when hold is canceled from another tab/component)
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === 'booking_hold') {
        checkHold();
      }
    };

    window.addEventListener('storage', handleStorageChange);

    return () => {
      clearInterval(interval);
      window.removeEventListener('storage', handleStorageChange);
    };
  }, []);

  useEffect(() => {
    if (!holdData) return;

    const updateTimer = () => {
      const now = new Date();
      const expiry = new Date(holdData.holdExpiry);
      const diff = expiry.getTime() - now.getTime();

      if (diff <= 0) {
        setTimeLeft('Expired');
        localStorage.removeItem('booking_hold');
        setIsVisible(false);
        return;
      }

      const minutes = Math.floor(diff / 60000);
      const seconds = Math.floor((diff % 60000) / 1000);
      setTimeLeft(`${minutes}:${seconds.toString().padStart(2, '0')}`);
    };

    updateTimer();
    const timer = setInterval(updateTimer, 1000);

    return () => clearInterval(timer);
  }, [holdData]);

  const handleResume = () => {
    if (!holdData) return;
    
    // Restore booking data to store with correct guest counts
    const bookingStore = useBookingStore.getState();
    bookingStore.setSearchParams({
      check_in_date: holdData.checkIn,
      check_out_date: holdData.checkOut,
      adults: holdData.adults || 2,
      children: holdData.children || 0,
    });
    bookingStore.setSelectedRoomType(holdData.roomTypeId, {
      room_type_id: holdData.roomTypeId,
      name: holdData.roomTypeName,
    } as any);
    bookingStore.setHoldExpiry(new Date(holdData.holdExpiry));
    
    console.log('[HoldIndicator] Restored booking data:', {
      adults: holdData.adults,
      children: holdData.children,
      roomType: holdData.roomTypeName,
    });
    
    // Navigate to guest info page
    router.push('/booking/guest-info');
  };

  const handleDismiss = () => {
    localStorage.removeItem('booking_hold');
    localStorage.removeItem('booking_guest_draft');
    sessionStorage.removeItem('booking_session_id');
    setIsVisible(false);
    setHoldData(null);
    
    // Clear booking store
    const bookingStore = useBookingStore.getState();
    bookingStore.clearBooking();
  };

  if (!isVisible || !holdData) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50 animate-in slide-in-from-bottom-5">
      <div className="bg-card border border-border rounded-lg shadow-lg p-4 max-w-sm">
        <div className="flex items-start gap-3">
          <div className="flex-shrink-0 w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <Clock className="w-5 h-5 text-primary" />
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2 mb-1">
              <h3 className="font-semibold text-sm">Active Hold</h3>
              <button
                onClick={handleDismiss}
                className="text-muted-foreground hover:text-foreground transition-colors"
                aria-label="Dismiss"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            
            <p className="text-xs text-muted-foreground mb-2">
              {holdData.roomTypeName}
            </p>
            
            <div className="flex items-center gap-2 mb-3">
              <div className="flex items-center gap-1 text-xs">
                <Clock className="w-3 h-3" />
                <span className="font-mono font-semibold text-primary">
                  {timeLeft}
                </span>
              </div>
              <span className="text-xs text-muted-foreground">remaining</span>
            </div>
            
            <Button
              onClick={handleResume}
              size="sm"
              className="w-full"
            >
              Resume Booking
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
