import { NextResponse } from 'next/server';

/**
 * GET /api/test-env
 * Test endpoint to check environment variables
 */
export async function GET() {
  return NextResponse.json({
    BACKEND_URL: process.env.BACKEND_URL || 'NOT SET',
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'NOT SET',
    NEXTAUTH_URL: process.env.NEXTAUTH_URL || 'NOT SET',
    NODE_ENV: process.env.NODE_ENV || 'NOT SET',
    timestamp: new Date().toISOString(),
  });
}
