import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8080';

export async function GET(
  request: NextRequest,
  { params }: { params: { roomTypeId: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    
    if (!session?.user?.accessToken) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const roomTypeId = params.roomTypeId;

    const response = await fetch(`${BACKEND_URL}/api/checkin/available-rooms/${roomTypeId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${session.user.accessToken}`,
      },
    });

    const data = await response.json();

    if (!response.ok) {
      return NextResponse.json(
        { error: data.error || 'Failed to fetch available rooms' },
        { status: response.status }
      );
    }

    return NextResponse.json(data.rooms || []);
  } catch (error: any) {
    console.error('Fetch available rooms error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
