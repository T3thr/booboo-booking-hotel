import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * GET /api/bookings/[id]/public
 * Get booking by ID without authentication (for guest bookings)
 * Requires phone number for verification
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const searchParams = request.nextUrl.searchParams;
    const phone = searchParams.get('phone');

    if (!phone) {
      return NextResponse.json(
        {
          success: false,
          error: 'Phone number is required',
        },
        { status: 400 }
      );
    }

    // First, search bookings by phone to verify ownership
    const searchUrl = `${BACKEND_URL}/api/bookings/search?phone=${encodeURIComponent(phone)}`;
    console.log('[Booking Public] Searching by phone:', searchUrl);

    const searchResponse = await fetch(searchUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!searchResponse.ok) {
      const errorText = await searchResponse.text();
      console.error('[Booking Public] Search error:', searchResponse.status, errorText);
      return NextResponse.json(
        {
          success: false,
          error: `Search failed: ${searchResponse.status}`,
        },
        { status: searchResponse.status }
      );
    }

    const searchData = await searchResponse.json();
    console.log('[Booking Public] Search results:', searchData);

    // Check if the booking ID matches any of the bookings found
    const booking = searchData.bookings?.find((b: any) => b.booking_id === parseInt(id));

    if (!booking) {
      return NextResponse.json(
        {
          success: false,
          error: 'Booking not found or phone number does not match',
        },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      data: booking,
    });
  } catch (error) {
    console.error('[Booking Public] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
