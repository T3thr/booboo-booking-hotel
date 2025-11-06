import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * GET /api/rooms
 * Proxy to backend - redirect to /api/rooms/types or /api/rooms/search
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const checkIn = searchParams.get('checkIn');
    const checkOut = searchParams.get('checkOut');
    const guests = searchParams.get('guests');

    // If search params provided, redirect to search endpoint
    if (checkIn && checkOut && guests) {
      return NextResponse.redirect(
        new URL(`/api/rooms/search?checkIn=${checkIn}&checkOut=${checkOut}&guests=${guests}`, request.url)
      );
    }

    // Otherwise, get all room types from backend
    const backendUrl = `${BACKEND_URL}/api/rooms/types`;
    
    console.log('[Rooms Proxy] Calling backend:', backendUrl);

    const response = await fetch(backendUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Rooms Proxy] Backend error:', response.status, errorText);
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
    console.error('[Rooms Proxy] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
