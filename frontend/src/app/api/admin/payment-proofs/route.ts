import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * GET /api/admin/payment-proofs
 * Get all payment proofs (admin only)
 */
export async function GET(request: NextRequest) {
  try {
    const session = await auth();

    const userRole = session?.user?.role?.toUpperCase();
    if (!session || !session.accessToken || (userRole !== 'MANAGER' && userRole !== 'RECEPTIONIST')) {
      return NextResponse.json(
        {
          success: false,
          error: 'Unauthorized',
        },
        { status: 401 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const status = searchParams.get('status') || 'pending';
    const page = searchParams.get('page') || '1';
    const limit = searchParams.get('limit') || '20';

    // Forward all query params to backend
    const backendParams = new URLSearchParams();
    backendParams.set('status', status);
    backendParams.set('page', page);
    backendParams.set('limit', limit);

    const backendUrl = `${BACKEND_URL}/api/payment-proofs?${backendParams.toString()}`;
    
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
      console.error('[Admin Payment Proofs] Backend error:', response.status, errorText);
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
    console.error('[Admin Payment Proofs] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
