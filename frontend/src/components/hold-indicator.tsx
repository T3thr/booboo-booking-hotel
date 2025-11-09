'use client';

import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { Clock, X, ArrowRight } from 'lucide-react';
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
  const pathname = usePathname();
  const [holdData, setHoldData] = useState<HoldData | null>(null);
  const [timeLeft, setTimeLeft] = useState<string>('');
  const [isVisible, setIsVisible] = useState(false);

  // Don't show on booking pages (already have timer there)
  const isBookingPage = pathname?.startsWith('/booking/');

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
            console.log('[HoldIndicator] Active hold found:', {
              roomType: data.roomTypeName,
              expiry: expiry.toISOString(),
            });
          } else {
            // Expired, remove it
            console.log('[HoldIndicator] Hold expired, removing');
            localStorage.removeItem('booking_hold');
            sessionStorage.removeItem('booking_session_id');
            localStorage.removeItem('booking_guest_draft');
            setHoldData(null);
            setIsVisible(false);
          }
        } else {
          // No hold data, hide indicator
          setHoldData(null);
          setIsVisible(false);
        }
      } catch (error) {
        console.error('[HoldIndicator] Error checking hold:', error);
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

  // Don't show if on booking pages or no hold data
  if (!isVisible || !holdData || isBookingPage) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50 animate-in slide-in-from-bottom-5 duration-300">
      <div className="bg-gradient-to-br from-primary/10 to-primary/5 border-2 border-primary/20 rounded-xl shadow-2xl p-4 max-w-sm backdrop-blur-sm">
        <div className="flex items-start gap-3">
          <div className="flex-shrink-0 w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center animate-pulse">
            <Clock className="w-6 h-6 text-primary" />
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2 mb-1">
              <div>
                <h3 className="font-bold text-sm text-foreground">🔒 Active Booking Hold</h3>
                <p className="text-xs text-muted-foreground mt-0.5">
                  Complete your booking before time runs out
                </p>
              </div>
              <button
                onClick={handleDismiss}
                className="text-muted-foreground hover:text-destructive transition-colors p-1 hover:bg-destructive/10 rounded"
                aria-label="Cancel booking"
                title="Cancel booking"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            
            <div className="mt-3 p-2 bg-background/50 rounded-lg">
              <p className="text-xs font-medium text-foreground mb-1">
                📍 {holdData.roomTypeName}
              </p>
              <p className="text-xs text-muted-foreground">
                {new Date(holdData.checkIn).toLocaleDateString()} - {new Date(holdData.checkOut).toLocaleDateString()}
              </p>
              <p className="text-xs text-muted-foreground">
                👥 {holdData.adults} Adult{holdData.adults > 1 ? 's' : ''}{holdData.children > 0 ? `, ${holdData.children} Child${holdData.children > 1 ? 'ren' : ''}` : ''}
              </p>
            </div>
            
            <div className="flex items-center gap-2 mt-3 p-2 bg-primary/10 rounded-lg">
              <Clock className="w-4 h-4 text-primary flex-shrink-0" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Time remaining</p>
                <p className="font-mono font-bold text-lg text-primary leading-none">
                  {timeLeft}
                </p>
              </div>
            </div>
            
            <Button
              onClick={handleResume}
              size="sm"
              className="w-full mt-3 font-semibold"
            >
              <span>Continue Booking</span>
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
