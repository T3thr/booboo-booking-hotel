import { NextRequest, NextResponse } from 'next/server';
import { writeFile, mkdir } from 'fs/promises';
import { join } from 'path';
import { existsSync } from 'fs';

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

/**
 * POST /api/bookings/payment-proof
 * Upload payment proof for a booking
 */
export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('payment_proof') as File;
    const bookingId = formData.get('booking_id') as string;
    const paymentMethod = formData.get('payment_method') as string;
    const amount = formData.get('amount') as string;

    if (!file || !bookingId) {
      return NextResponse.json(
        {
          success: false,
          error: 'Missing required fields',
        },
        { status: 400 }
      );
    }

    // Create uploads directory if it doesn't exist
    const uploadsDir = join(process.cwd(), 'public', 'uploads', 'payment-proofs');
    if (!existsSync(uploadsDir)) {
      await mkdir(uploadsDir, { recursive: true });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const fileExt = file.name.split('.').pop();
    const filename = `payment_${bookingId}_${timestamp}.${fileExt}`;
    const filepath = join(uploadsDir, filename);

    // Save file
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);
    await writeFile(filepath, buffer);

    const fileUrl = `/uploads/payment-proofs/${filename}`;

    // Save payment proof info to backend
    const backendResponse = await fetch(`${BACKEND_URL}/bookings/${bookingId}/payment-proof`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        payment_method: paymentMethod,
        amount: parseFloat(amount),
        proof_url: fileUrl,
        status: 'pending',
      }),
    });

    if (!backendResponse.ok) {
      // If backend fails, we still have the file saved locally
      console.error('Backend payment proof save failed:', await backendResponse.text());
    }

    return NextResponse.json({
      success: true,
      data: {
        file_url: fileUrl,
        booking_id: bookingId,
      },
      message: 'อัปโหลดหลักฐานการโอนเงินสำเร็จ',
    });
  } catch (error) {
    console.error('[Payment Proof Upload] Error:', error);
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
 * GET /api/bookings/payment-proof?booking_id=123
 * Get payment proof for a booking
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const bookingId = searchParams.get('booking_id');

    if (!bookingId) {
      return NextResponse.json(
        {
          success: false,
          error: 'Missing booking_id parameter',
        },
        { status: 400 }
      );
    }

    const backendUrl = `${BACKEND_URL}/bookings/${bookingId}/payment-proof`;
    
    const response = await fetch(backendUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[Payment Proof Get] Backend error:', response.status, errorText);
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
    console.error('[Payment Proof Get] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
