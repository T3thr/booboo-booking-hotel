import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * GET /api/rooms/search
 * Proxy to backend room search API
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const checkIn = searchParams.get('checkIn');
    const checkOut = searchParams.get('checkOut');
    const guests = searchParams.get('guests');

    if (!checkIn || !checkOut || !guests) {
      return NextResponse.json(
        {
          success: false,
          error: 'Missing required parameters: checkIn, checkOut, guests',
        },
        { status: 400 }
      );
    }

    // Build backend URL
    const backendUrl = `${BACKEND_URL}/rooms/search?checkIn=${checkIn}&checkOut=${checkOut}&guests=${guests}`;
    
    console.log('[Room Search Proxy] Calling backend:', backendUrl);

    // Call backend API
    const response = await fetch(backendUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Room Search Proxy] Backend error:', response.status, errorText);
      return NextResponse.json(
        {
          success: false,
          error: `Backend error: ${response.status}`,
        },
        { status: response.status }
      );
    }

    const data = await response.json();
    console.log('[Room Search Proxy] Success, found rooms:', data.data?.room_types?.length || 0);

    return NextResponse.json(data);
  } catch (error) {
    console.error('[Room Search Proxy] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
