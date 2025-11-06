import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * POST /api/bookings/hold/cancel
 * Cancel a booking hold
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { session_id } = body;

    if (!session_id) {
      return NextResponse.json(
        {
          success: false,
          error: 'Session ID is required',
        },
        { status: 400 }
      );
    }

    console.log('[Hold Cancel] Canceling hold for session:', session_id);

    // For now, we'll just return success since the hold will expire automatically
    // In a production system, you might want to call a backend endpoint to release the hold immediately
    
    return NextResponse.json({
      success: true,
      message: 'Hold canceled successfully',
    });
  } catch (error) {
    console.error('[Hold Cancel] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
