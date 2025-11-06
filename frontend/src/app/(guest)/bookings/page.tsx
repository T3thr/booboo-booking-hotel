'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useSession } from 'next-auth/react';
import { useBookings } from '@/hooks/use-bookings';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Loading } from '@/components/ui/loading';
import { formatDate } from '@/utils/date';
import { Calendar, Phone, User, Search, CheckCircle, Clock, XCircle } from 'lucide-react';

export default function BookingsPage() {
  const router = useRouter();
  const { data: session, status } = useSession();
  const { data: accountBookings, isLoading, error } = useBookings();
  
  const [activeTab, setActiveTab] = useState<'account' | 'phone'>('account');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [phoneBookings, setPhoneBookings] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [searchError, setSearchError] = useState('');
  const [showSyncPrompt, setShowSyncPrompt] = useState(false);

  // Check if user has phone bookings that can be synced
  useEffect(() => {
    if (session?.user?.phone && accountBookings) {
      const hasPhone = session.user.phone;
      if (hasPhone) {
        setShowSyncPrompt(true);
      }
    }
  }, [session, accountBookings]);

  const handlePhoneSearch = async () => {
    if (!phoneNumber || phoneNumber.length < 10) {
      setSearchError('Please enter a valid 10-digit phone number');
      return;
    }

    setIsSearching(true);
    setSearchError('');

    try {
      const response = await fetch(`/api/bookings/search?phone=${phoneNumber}`);
      if (!response.ok) {
        throw new Error('Failed to search bookings');
      }

      const data = await response.json();
      const bookings = data.bookings || [];
      setPhoneBookings(bookings);
      
      if (bookings.length === 0) {
        setSearchError('ไม่พบการจองที่ใช้เบอร์โทรนี้');
      }
    } catch (error) {
      console.error('Search error:', error);
      setSearchError('Failed to search bookings. Please try again.');
    } finally {
      setIsSearching(false);
    }
  };

  const handleSyncBookings = async () => {
    try {
      const response = await fetch('/api/bookings/sync', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: session?.user?.phone }),
      });

      if (response.ok) {
        alert('Bookings synced successfully!');
        setShowSyncPrompt(false);
        window.location.reload();
      }
    } catch (error) {
      console.error('Sync error:', error);
      alert('Failed to sync bookings');
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'Confirmed':
      case 'CheckedIn':
      case 'Completed':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'PendingPayment':
        return <Clock className="w-5 h-5 text-yellow-500" />;
      case 'Cancelled':
      case 'NoShow':
        return <XCircle className="w-5 h-5 text-red-500" />;
      default:
        return <Calendar className="w-5 h-5 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Confirmed':
        return 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400';
      case 'CheckedIn':
        return 'bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400';
      case 'Completed':
        return 'bg-purple-100 text-purple-700 dark:bg-purple-900/20 dark:text-purple-400';
      case 'PendingPayment':
        return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/20 dark:text-yellow-400';
      case 'Cancelled':
      case 'NoShow':
        return 'bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400';
      default:
        return 'bg-gray-100 text-gray-700 dark:bg-gray-900/20 dark:text-gray-400';
    }
  };

  const renderBookingCard = (booking: any) => {
    const detail = booking.details?.[0];
    const checkIn = detail?.check_in_date;
    const checkOut = detail?.check_out_date;
    const primaryGuest = booking.booking_guests?.find((g: any) => g.is_primary);

    return (
      <Card key={booking.booking_id} className="p-6 hover:shadow-lg transition-shadow">
        <div className="flex justify-between items-start mb-4">
          <div className="flex items-start gap-3">
            {getStatusIcon(booking.status)}
            <div>
              <p className="text-sm text-muted-foreground">
                Booking #{booking.booking_id}
              </p>
              <h3 className="text-xl font-semibold">
                {detail?.room_type_name || 'Room'}
              </h3>
            </div>
          </div>
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(booking.status)}`}>
            {booking.status}
          </span>
        </div>

        {primaryGuest && (
          <div className="flex items-center gap-2 mb-3 text-sm text-muted-foreground">
            <User className="w-4 h-4" />
            <span>{primaryGuest.first_name} {primaryGuest.last_name}</span>
            {primaryGuest.phone && (
              <>
                <span>•</span>
                <Phone className="w-4 h-4" />
                <span>{primaryGuest.phone}</span>
              </>
            )}
          </div>
        )}

        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <p className="text-sm text-muted-foreground flex items-center gap-1">
              <Calendar className="w-4 h-4" />
              Check-in
            </p>
            <p className="font-medium">
              {checkIn ? formatDate(checkIn) : '-'}
            </p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground flex items-center gap-1">
              <Calendar className="w-4 h-4" />
              Check-out
            </p>
            <p className="font-medium">
              {checkOut ? formatDate(checkOut) : '-'}
            </p>
          </div>
        </div>

        <div className="flex justify-between items-center pt-4 border-t">
          <div>
            <p className="text-sm text-muted-foreground">Total Amount</p>
            <p className="text-xl font-bold">
              ฿{booking.total_amount.toLocaleString()}
            </p>
          </div>
          <Button
            variant="outline"
            onClick={() => router.push(`/booking/confirmation/${booking.booking_id}`)}
          >
            View Details
          </Button>
        </div>
      </Card>
    );
  };

  if (status === 'loading' || isLoading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Loading />
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">My Bookings</h1>

        {/* Sync Prompt */}
        {showSyncPrompt && session?.user?.phone && (
          <Card className="p-4 mb-6 bg-blue-50 dark:bg-blue-900/10 border-blue-200 dark:border-blue-800">
            <div className="flex items-start gap-3">
              <div className="flex-shrink-0 w-10 h-10 bg-blue-100 dark:bg-blue-900/20 rounded-full flex items-center justify-center">
                <Phone className="w-5 h-5 text-blue-600 dark:text-blue-400" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold mb-1">Sync Your Bookings</h3>
                <p className="text-sm text-muted-foreground mb-3">
                  We found bookings associated with your phone number ({session.user.phone}). 
                  Would you like to link them to your account for easier access?
                </p>
                <div className="flex gap-2">
                  <Button size="sm" onClick={handleSyncBookings}>
                    Sync Now
                  </Button>
                  <Button size="sm" variant="ghost" onClick={() => setShowSyncPrompt(false)}>
                    Maybe Later
                  </Button>
                </div>
              </div>
            </div>
          </Card>
        )}

        {/* Tabs */}
        <div className="flex gap-2 mb-6 border-b">
          <button
            onClick={() => setActiveTab('account')}
            className={`px-4 py-2 font-medium transition-colors relative ${
              activeTab === 'account'
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            <div className="flex items-center gap-2">
              <User className="w-4 h-4" />
              My Account
            </div>
            {activeTab === 'account' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />
            )}
          </button>
          <button
            onClick={() => setActiveTab('phone')}
            className={`px-4 py-2 font-medium transition-colors relative ${
              activeTab === 'phone'
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            <div className="flex items-center gap-2">
              <Phone className="w-4 h-4" />
              Search by Phone
            </div>
            {activeTab === 'phone' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />
            )}
          </button>
        </div>

        {/* Account Bookings Tab */}
        {activeTab === 'account' && (
          <>
            {status === 'unauthenticated' ? (
              <Card className="p-8 text-center">
                <User className="w-16 h-16 mx-auto mb-4 text-muted-foreground" />
                <h2 className="text-xl font-semibold mb-2">Sign In Required</h2>
                <p className="text-muted-foreground mb-4">
                  Please sign in to view your bookings
                </p>
                <Button onClick={() => router.push('/auth/signin?callbackUrl=/bookings')}>
                  Sign In
                </Button>
              </Card>
            ) : !accountBookings || accountBookings.length === 0 ? (
              <Card className="p-8 text-center">
                <Calendar className="w-16 h-16 mx-auto mb-4 text-muted-foreground" />
                <h2 className="text-xl font-semibold mb-2">No Bookings Yet</h2>
                <p className="text-muted-foreground mb-4">
                  You don't have any bookings yet
                </p>
                <Button onClick={() => router.push('/rooms/search')}>
                  Search for Rooms
                </Button>
              </Card>
            ) : (
              <div className="space-y-4">
                {accountBookings.map(renderBookingCard)}
              </div>
            )}
          </>
        )}

        {/* Phone Search Tab */}
        {activeTab === 'phone' && (
          <>
            <Card className="p-6 mb-6">
              <h2 className="text-lg font-semibold mb-4">Search Bookings by Phone Number</h2>
              <p className="text-sm text-muted-foreground mb-4">
                Enter the phone number used during booking to view your reservations
              </p>
              <div className="flex gap-2">
                <Input
                  type="tel"
                  placeholder="0812345678"
                  value={phoneNumber}
                  onChange={(e) => {
                    setPhoneNumber(e.target.value);
                    setSearchError('');
                  }}
                  onKeyPress={(e) => e.key === 'Enter' && handlePhoneSearch()}
                  className="flex-1"
                />
                <Button onClick={handlePhoneSearch} disabled={isSearching}>
                  <Search className="w-4 h-4 mr-2" />
                  {isSearching ? 'Searching...' : 'Search'}
                </Button>
              </div>
              {searchError && (
                <p className="text-sm text-red-500 mt-2">{searchError}</p>
              )}
            </Card>

            {phoneBookings.length > 0 && (
              <div className="space-y-4">
                {phoneBookings.map(renderBookingCard)}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
