import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080/api';

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const phone = searchParams.get('phone');

    if (!phone) {
      return NextResponse.json(
        { error: 'Phone number is required' },
        { status: 400 }
      );
    }

    console.log('[Booking Search] Searching for phone:', phone);

    const response = await fetch(`${BACKEND_URL}/bookings/search?phone=${encodeURIComponent(phone)}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Booking Search] Backend error:', response.status, errorText);
      return NextResponse.json(
        { error: 'Failed to search bookings' },
        { status: response.status }
      );
    }

    const data = await response.json();
    console.log('[Booking Search] Found bookings:', data);

    return NextResponse.json(data);
  } catch (error) {
    console.error('[Booking Search] Error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
