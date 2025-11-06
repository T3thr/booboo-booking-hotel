'use client';

import { useSession, signOut } from 'next-auth/react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useRouter } from 'next/navigation';

export default function AuthTestPage() {
  const { data: session, status } = useSession();
  const router = useRouter();

  const handleSignOut = async () => {
    await signOut({ redirect: false });
    router.push('/auth/signin');
  };

  if (status === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p>กำลังโหลด...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background py-12 px-4">
      <Card className="max-w-2xl w-full p-8">
        <h1 className="text-3xl font-bold mb-6">ทดสอบ NextAuth.js</h1>
        
        <div className="space-y-6">
          <div>
            <h2 className="text-xl font-semibold mb-2">สถานะการเข้าสู่ระบบ</h2>
            <p className="text-lg">
              <span className="font-medium">Status:</span>{' '}
              <span className={status === 'authenticated' ? 'text-green-600' : 'text-red-600'}>
                {status}
              </span>
            </p>
          </div>

          {status === 'authenticated' && session ? (
            <div className="space-y-4">
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <h3 className="font-semibold text-green-900 mb-2">✓ เข้าสู่ระบบสำเร็จ</h3>
                <div className="space-y-2 text-sm">
                  <p><span className="font-medium">User ID:</span> {session.user.id}</p>
                  <p><span className="font-medium">Email:</span> {session.user.email}</p>
                  <p><span className="font-medium">Name:</span> {session.user.name}</p>
                  <p><span className="font-medium">Role:</span> {session.user.role}</p>
                  <p><span className="font-medium">Access Token:</span> {session.accessToken.substring(0, 20)}...</p>
                </div>
              </div>

              <div className="space-y-2">
                <h3 className="font-semibold">Session Object (JSON):</h3>
                <pre className="bg-muted p-4 rounded-lg overflow-auto text-xs">
                  {JSON.stringify(session, null, 2)}
                </pre>
              </div>

              <Button onClick={handleSignOut} variant="destructive" className="w-full">
                ออกจากระบบ
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                <h3 className="font-semibold text-yellow-900 mb-2">⚠ ยังไม่ได้เข้าสู่ระบบ</h3>
                <p className="text-sm text-yellow-800">
                  กรุณาเข้าสู่ระบบเพื่อทดสอบ NextAuth.js
                </p>
              </div>

              <Button onClick={() => router.push('/auth/signin')} className="w-full">
                ไปหน้าเข้าสู่ระบบ
              </Button>
            </div>
          )}

          <div className="border-t pt-4">
            <h3 className="font-semibold mb-2">การทดสอบ</h3>
            <ul className="list-disc list-inside space-y-1 text-sm text-muted-foreground">
              <li>ทดสอบการเข้าสู่ระบบด้วยข้อมูลที่ถูกต้อง</li>
              <li>ทดสอบการเข้าสู่ระบบด้วยข้อมูลที่ผิด</li>
              <li>ตรวจสอบว่า JWT token ถูกส่งกลับมา</li>
              <li>ตรวจสอบว่า session มีข้อมูล user และ role</li>
              <li>ทดสอบการออกจากระบบ</li>
              <li>ทดสอบ protected routes</li>
            </ul>
          </div>
        </div>
      </Card>
    </div>
  );
}
