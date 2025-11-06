import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * GET /api/rooms/types
 * Proxy to backend room types API
 */
export async function GET(request: NextRequest) {
  try {
    const backendUrl = `${BACKEND_URL}/api/rooms/types`;
    
    console.log('[Room Types Proxy] Calling backend:', backendUrl);

    const response = await fetch(backendUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Room Types Proxy] Backend error:', response.status, errorText);
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
    console.error('[Room Types Proxy] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
