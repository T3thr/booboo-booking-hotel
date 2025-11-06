'use client';

import { useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useBooking } from '@/hooks/use-bookings';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Loading } from '@/components/ui/loading';
import { formatDate } from '@/utils/date';

export default function BookingConfirmationPage() {
  const router = useRouter();
  const params = useParams();
  const bookingId = parseInt(params.id as string);

  const { data: booking, isLoading, error } = useBooking(bookingId);

  if (isLoading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto">
          <Loading />
        </div>
      </div>
    );
  }

  if (error || !booking) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto">
          <Card className="p-8 text-center">
            <div className="text-red-500 mb-4">
              <svg
                className="w-16 h-16 mx-auto"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <h1 className="text-2xl font-bold mb-2">Booking Not Found</h1>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              We couldn't find the booking you're looking for.
            </p>
            <Button onClick={() => router.push('/rooms/search')}>
              Search for Rooms
            </Button>
          </Card>
        </div>
      </div>
    );
  }

  const bookingDetail = booking.booking_details?.[0];
  const checkIn = bookingDetail?.check_in_date;
  const checkOut = bookingDetail?.check_out_date;
  const nights = checkIn && checkOut
    ? Math.ceil(
        (new Date(checkOut).getTime() - new Date(checkIn).getTime()) /
          (1000 * 60 * 60 * 24)
      )
    : 0;

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        {/* Success Icon */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-20 h-20 bg-green-100 dark:bg-green-900/20 rounded-full mb-4">
            <svg
              className="w-12 h-12 text-green-600 dark:text-green-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
          <h1 className="text-3xl font-bold mb-2">Booking Confirmed!</h1>
          <p className="text-gray-600 dark:text-gray-400">
            Your reservation has been successfully confirmed
          </p>
        </div>

        {/* Booking Details */}
        <Card className="p-6 mb-6">
          <div className="flex justify-between items-start mb-6 pb-6 border-b">
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Booking Number
              </p>
              <p className="text-2xl font-bold">#{booking.booking_id}</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-gray-500 dark:text-gray-400">Status</p>
              <span className="inline-block px-3 py-1 bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400 rounded-full text-sm font-medium">
                {booking.status}
              </span>
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">Room Type</p>
              <p className="font-medium">
                {bookingDetail?.room_type?.name || 'Room'}
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Check-in</p>
                <p className="font-medium">{checkIn ? formatDate(checkIn) : '-'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Check-out</p>
                <p className="font-medium">{checkOut ? formatDate(checkOut) : '-'}</p>
              </div>
            </div>

            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">Duration</p>
              <p className="font-medium">
                {nights} night{nights !== 1 ? 's' : ''}
              </p>
            </div>

            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">Guests</p>
              <p className="font-medium">{bookingDetail?.num_guests || 0} guest(s)</p>
            </div>

            <div className="pt-4 border-t">
              <div className="flex justify-between items-center">
                <p className="text-lg font-semibold">Total Amount</p>
                <p className="text-2xl font-bold">
                  ฿{booking.total_amount.toLocaleString()}
                </p>
              </div>
            </div>
          </div>
        </Card>

        {/* Cancellation Policy */}
        {booking.policy_name && (
          <Card className="p-6 mb-6">
            <h2 className="text-lg font-semibold mb-3">Cancellation Policy</h2>
            <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              {booking.policy_name}
            </p>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              {booking.policy_description}
            </p>
          </Card>
        )}

        {/* Important Information */}
        <Card className="p-6 mb-6 bg-blue-50 dark:bg-blue-900/10 border-blue-200 dark:border-blue-800">
          <h2 className="text-lg font-semibold mb-3 flex items-center gap-2">
            <svg
              className="w-5 h-5 text-blue-600 dark:text-blue-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            Important Information
          </h2>
          <ul className="space-y-2 text-sm text-gray-700 dark:text-gray-300">
            <li className="flex items-start gap-2">
              <span className="text-blue-600 dark:text-blue-400">•</span>
              <span>
                A confirmation email has been sent to your registered email address
              </span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-blue-600 dark:text-blue-400">•</span>
              <span>Check-in time is from 2:00 PM</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-blue-600 dark:text-blue-400">•</span>
              <span>Check-out time is until 12:00 PM</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-blue-600 dark:text-blue-400">•</span>
              <span>
                Please bring a valid ID and this booking confirmation on check-in
              </span>
            </li>
          </ul>
        </Card>

        {/* Guest Information */}
        {booking.booking_guests && booking.booking_guests.length > 0 && (
          <Card className="p-6 mb-6">
            <h2 className="text-lg font-semibold mb-3">Guest Information</h2>
            <div className="space-y-3">
              {booking.booking_guests.map((guest: any, idx: number) => (
                <div key={idx} className="flex flex-col gap-1">
                  <div className="flex items-center gap-2">
                    <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <span className="font-medium">
                      {guest.first_name} {guest.last_name}
                    </span>
                    {guest.is_primary && (
                      <span className="text-xs bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400 px-2 py-1 rounded">
                        Primary Guest
                      </span>
                    )}
                  </div>
                  {guest.phone && guest.is_primary && (
                    <div className="flex items-center gap-2 ml-7 text-sm text-gray-600 dark:text-gray-400">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                      </svg>
                      <span>{guest.phone}</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </Card>
        )}

        {/* Nightly Breakdown */}
        {booking.booking_nightly_log && booking.booking_nightly_log.length > 0 && (
          <Card className="p-6 mb-6">
            <h2 className="text-lg font-semibold mb-3">Nightly Rate Breakdown</h2>
            <div className="space-y-2">
              {booking.booking_nightly_log.map((log: any, idx: number) => (
                <div key={idx} className="flex justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">
                    {formatDate(log.date)}
                  </span>
                  <span className="font-medium">
                    ฿{log.quoted_price.toLocaleString()}
                  </span>
                </div>
              ))}
              <div className="pt-2 border-t flex justify-between font-semibold">
                <span>Total</span>
                <span>฿{booking.total_amount.toLocaleString()}</span>
              </div>
            </div>
          </Card>
        )}

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-4">
          <Button
            onClick={() => router.push('/bookings')}
            className="flex-1"
            size="lg"
          >
            View My Bookings
          </Button>
          <Button
            variant="outline"
            onClick={() => router.push('/rooms/search')}
            className="flex-1"
            size="lg"
          >
            Book Another Room
          </Button>
        </div>
      </div>
    </div>
  );
}
