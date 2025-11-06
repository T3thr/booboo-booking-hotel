import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080/api';

export async function POST(request: NextRequest) {
  try {
    const session = await auth();

    if (!session || !session.user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const body = await request.json();
    const { phone } = body;

    if (!phone) {
      return NextResponse.json(
        { error: 'Phone number is required' },
        { status: 400 }
      );
    }

    console.log('[Booking Sync] Syncing bookings for phone:', phone);

    const response = await fetch(`${BACKEND_URL}/api/bookings/sync`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session.accessToken}`,
      },
      body: JSON.stringify({ phone }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Booking Sync] Backend error:', response.status, errorText);
      return NextResponse.json(
        { error: 'Failed to sync bookings' },
        { status: response.status }
      );
    }

    const data = await response.json();
    console.log('[Booking Sync] Sync result:', data);

    return NextResponse.json(data);
  } catch (error) {
    console.error('[Booking Sync] Error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
