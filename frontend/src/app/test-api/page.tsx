'use client';

import { useRoomTypes, useBookings } from '@/hooks';
import { ProtectedRoute } from '@/components/protected-route';

export default function TestApiPage() {
  const { data: roomTypes, isLoading: roomTypesLoading, error: roomTypesError } = useRoomTypes();
  const { data: bookings, isLoading: bookingsLoading, error: bookingsError } = useBookings();

  return (
    <ProtectedRoute>
      <div className="container mx-auto p-8">
        <h1 className="text-3xl font-bold mb-8">API Client Test Page</h1>

        {/* Room Types Test */}
        <div className="mb-8 p-6 border rounded-lg">
          <h2 className="text-2xl font-semibold mb-4">Room Types</h2>
          {roomTypesLoading && <p className="text-muted-foreground">Loading room types...</p>}
          {roomTypesError && (
            <p className="text-destructive">Error: {roomTypesError.message}</p>
          )}
          {roomTypes && (
            <div>
              <p className="text-green-600 dark:text-green-400 mb-2">✓ Successfully loaded {roomTypes.length} room types</p>
              <pre className="bg-muted p-4 rounded overflow-auto max-h-64">
                {JSON.stringify(roomTypes, null, 2)}
              </pre>
            </div>
          )}
        </div>

        {/* Bookings Test */}
        <div className="mb-8 p-6 border rounded-lg">
          <h2 className="text-2xl font-semibold mb-4">Bookings</h2>
          {bookingsLoading && <p className="text-muted-foreground">Loading bookings...</p>}
          {bookingsError && (
            <p className="text-destructive">Error: {bookingsError.message}</p>
          )}
          {bookings && (
            <div>
              <p className="text-green-600 dark:text-green-400 mb-2">✓ Successfully loaded {bookings.length} bookings</p>
              <pre className="bg-muted p-4 rounded overflow-auto max-h-64">
                {JSON.stringify(bookings, null, 2)}
              </pre>
            </div>
          )}
        </div>

        {/* API Client Info */}
        <div className="p-6 border rounded-lg bg-accent/50">
          <h2 className="text-2xl font-semibold mb-4">API Configuration</h2>
          <div className="space-y-2">
            <p><strong>API Base URL:</strong> {process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api'}</p>
            <p><strong>Environment:</strong> {process.env.NODE_ENV}</p>
            <p className="text-sm text-muted-foreground mt-4">
              This page tests the API client and React Query setup. If you see data above, 
              the integration is working correctly.
            </p>
          </div>
        </div>
      </div>
    </ProtectedRoute>
  );
}
