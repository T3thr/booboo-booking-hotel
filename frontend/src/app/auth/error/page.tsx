'use client';

import { Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

const errorMessages: Record<string, string> = {
  Configuration: 'เกิดข้อผิดพลาดในการตั้งค่าระบบ',
  AccessDenied: 'คุณไม่มีสิทธิ์เข้าถึง',
  Verification: 'การยืนยันตัวตนล้มเหลว',
  Default: 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ',
};

function ErrorContent() {
  const searchParams = useSearchParams();
  const error = searchParams.get('error') || 'Default';
  const errorMessage = errorMessages[error] || errorMessages.Default;

  return (
    <div className="min-h-screen flex items-center justify-center bg-background py-12 px-4 sm:px-6 lg:px-8">
      <Card className="max-w-md w-full space-y-8 p-8">
        <div className="text-center">
          <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-destructive/10">
            <svg
              className="h-6 w-6 text-destructive"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </div>
          <h2 className="mt-6 text-3xl font-extrabold text-foreground">
            เกิดข้อผิดพลาด
          </h2>
          <p className="mt-2 text-sm text-muted-foreground">
            {errorMessage}
          </p>
        </div>

        <div className="mt-8 space-y-4">
          <Link href="/auth/signin" className="block">
            <Button className="w-full">
              กลับไปหน้าเข้าสู่ระบบ
            </Button>
          </Link>
          
          <Link href="/" className="block">
            <Button variant="outline" className="w-full">
              กลับหน้าหลัก
            </Button>
          </Link>
        </div>
      </Card>
    </div>
  );
}

export default function AuthErrorPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="animate-pulse">กำลังโหลด...</div>
      </div>
    }>
      <ErrorContent />
    </Suspense>
  );
}
