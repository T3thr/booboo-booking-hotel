'use client';

import { Suspense, useState, useEffect } from 'react';
import { signIn, useSession } from 'next-auth/react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { getRoleHomePage } from '@/utils/role-redirect';

function SignInForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { data: session, status } = useSession();
  const callbackUrl = searchParams.get('callbackUrl') || '/';
  
  // Redirect if already logged in
  useEffect(() => {
    if (status === 'authenticated' && session?.user) {
      const redirectUrl = getRoleHomePage(session.user.role || 'GUEST');
      router.replace(redirectUrl);
    }
  }, [status, session, router]);
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      console.log('[Guest Login] Attempting login for:', email);
      
      const result = await signIn('credentials', {
        email,
        password,
        redirect: false,
      });

      console.log('[Guest Login] SignIn result:', result);

      if (result?.error) {
        console.error('[Guest Login] Error:', result.error);
        setError('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      } else if (result?.ok) {
        // Wait for session to be updated
        await new Promise(resolve => setTimeout(resolve, 100));
        
        // Get fresh session to determine redirect
        const response = await fetch('/api/auth/session');
        const sessionData = await response.json();
        
        console.log('[Guest Login] Session data:', sessionData);
        
        if (sessionData?.user?.role) {
          const role = sessionData.user.role;
          
          // ✅ Check if user is GUEST
          if (role === 'GUEST') {
            console.log('[Guest Login] Valid GUEST role, redirecting to home');
            router.push(callbackUrl);
            router.refresh();
          } else {
            // ❌ Staff trying to login via guest page
            console.error('[Guest Login] Staff detected! Role:', role);
            setError('บัญชีนี้เป็นบัญชีเจ้าหน้าที่ กรุณาใช้หน้า Admin Login');
            // Sign out the staff user
            await fetch('/api/auth/signout', { method: 'POST' });
          }
        } else {
          console.error('[Guest Login] No role in session!');
          setError('ไม่พบข้อมูล role กรุณาลองใหม่');
        }
      }
    } catch (err) {
      console.error('[Guest Login] Exception:', err);
      setError('เกิดข้อผิดพลาดในการเข้าสู่ระบบ');
    } finally {
      setIsLoading(false);
    }
  };

  // Show loading while checking session
  if (status === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="animate-pulse text-muted-foreground">กำลังตรวจสอบ...</div>
      </div>
    );
  }

  // Don't render form if already authenticated
  if (status === 'authenticated') {
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background py-12 px-4 sm:px-6 lg:px-8">
      <Card className="max-w-md w-full space-y-8 p-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-foreground">
            เข้าสู่ระบบ
          </h2>
          <p className="mt-2 text-center text-sm text-muted-foreground">
            ระบบจองโรงแรมและที่พัก
          </p>
        </div>
        
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && (
            <div className="rounded-md bg-destructive/10 border border-destructive/20 p-4">
              <div className="flex">
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-destructive">
                    {error}
                  </h3>
                </div>
              </div>
            </div>
          )}

          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-foreground mb-1">
                อีเมล
              </label>
              <Input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="your@email.com"
                disabled={isLoading}
              />
            </div>
            
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-foreground mb-1">
                รหัสผ่าน
              </label>
              <Input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                disabled={isLoading}
              />
            </div>
          </div>

          <div>
            <Button
              type="submit"
              className="w-full"
              disabled={isLoading}
            >
              {isLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ'}
            </Button>
          </div>

          <div className="text-center space-y-2">
            <p className="text-sm text-muted-foreground">
              ยังไม่มีบัญชี?{' '}
              <a href="/auth/register" className="font-medium text-primary hover:text-primary/80">
                ลงทะเบียน
              </a>
            </p>
            <div className="pt-3 border-t border-border">
              <p className="text-xs text-muted-foreground">
                หากคุณเป็นเจ้าหน้าที่ กรุณาใช้{' '}
                <a 
                  href="/auth/admin" 
                  className="font-medium text-primary hover:text-primary/80 underline"
                >
                  หน้า Admin Login
                </a>
              </p>
            </div>
          </div>
        </form>
      </Card>
    </div>
  );
}

export default function SignInPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="animate-pulse">กำลังโหลด...</div>
      </div>
    }>
      <SignInForm />
    </Suspense>
  );
}
