import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * POST /api/bookings/hold
 * Create a booking hold (works with or without authentication)
 */
export async function POST(request: NextRequest) {
  try {
    const session = await auth();
    const body = await request.json();

    const backendUrl = `${BACKEND_URL}/api/bookings/hold`;
    
    console.log('[Booking Hold Proxy] Calling backend:', backendUrl);
    console.log('[Booking Hold Proxy] Session:', session ? 'Authenticated' : 'Guest');

    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    // Only add Authorization header if we have a valid session with accessToken
    if (session?.accessToken) {
      headers['Authorization'] = `Bearer ${session.accessToken}`;
      console.log('[Booking Hold Proxy] Adding auth token');
    } else {
      console.log('[Booking Hold Proxy] No auth token - guest hold');
    }

    const response = await fetch(backendUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Booking Hold Proxy] Backend error:', response.status, errorText);
      return NextResponse.json(
        {
          success: false,
          error: `Backend error: ${response.status}`,
        },
        { status: response.status }
      );
    }

    const data = await response.json();
    console.log('[Booking Hold Proxy] Success');

    return NextResponse.json(data);
  } catch (error) {
    console.error('[Booking Hold Proxy] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
