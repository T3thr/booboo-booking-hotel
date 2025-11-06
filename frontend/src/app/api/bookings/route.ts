import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * GET /api/bookings
 * Get all bookings
 */
export async function GET(request: NextRequest) {
  try {
    const session = await auth();
    const searchParams = request.nextUrl.searchParams;

    const backendUrl = `${BACKEND_URL}/api/bookings?${searchParams.toString()}`;
    
    console.log('[Bookings Proxy] Calling backend:', backendUrl);

    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    if (session?.accessToken) {
      headers['Authorization'] = `Bearer ${session.accessToken}`;
    }

    const response = await fetch(backendUrl, {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Bookings Proxy] Backend error:', response.status, errorText);
      return NextResponse.json(
        {
          success: false,
          error: `Backend error: ${response.status}`,
        },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('[Bookings Proxy] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

/**
 * POST /api/bookings
 * Create a new booking (works with or without authentication)
 */
export async function POST(request: NextRequest) {
  try {
    const session = await auth();
    const body = await request.json();

    const backendUrl = `${BACKEND_URL}/api/bookings`;
    
    console.log('[Bookings Proxy] Calling backend:', backendUrl);
    console.log('[Bookings Proxy] Session:', session ? 'Authenticated' : 'Guest');

    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };

    // Only add Authorization header if we have a valid session with accessToken
    if (session?.accessToken) {
      headers['Authorization'] = `Bearer ${session.accessToken}`;
      console.log('[Bookings Proxy] Adding auth token');
    } else {
      console.log('[Bookings Proxy] No auth token - guest booking');
    }

    const response = await fetch(backendUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Bookings Proxy POST] Backend error:', response.status, errorText);
      return NextResponse.json(
        {
          success: false,
          error: `Backend error: ${response.status}`,
        },
        { status: response.status }
      );
    }

    const data = await response.json();
    console.log('[Bookings Proxy POST] Backend response:', JSON.stringify(data, null, 2));
    console.log('[Bookings Proxy POST] booking_id:', data.booking_id);
    return NextResponse.json(data);
  } catch (error) {
    console.error('[Bookings Proxy] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
