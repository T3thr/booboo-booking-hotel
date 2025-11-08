'use client';

import { Suspense, useState, useEffect } from 'react';
import { signIn, useSession } from 'next-auth/react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { Eye, EyeOff, Shield, Lock, Mail } from 'lucide-react';
import { getRoleHomePage } from '@/utils/role-redirect';
import { toast } from 'sonner';

function AdminSignInForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { data: session, status } = useSession();
  
  // Redirect if already logged in
  useEffect(() => {
    if (typeof window === 'undefined') return; // Only run in browser
    
    if (status === 'authenticated' && session?.user) {
      const role = session.user.role || 'GUEST';
      // Only redirect staff roles
      if (role === 'MANAGER' || role === 'RECEPTIONIST' || role === 'HOUSEKEEPER') {
        const redirectUrl = getRoleHomePage(role);
        console.log('[Admin Login] Already authenticated as staff, redirecting to:', redirectUrl);
        router.push(redirectUrl);
      }
    }
  }, [status, session, router]);
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      console.log('[Admin Login] Attempting login for:', email);
      toast.loading('กำลังเข้าสู่ระบบ...', { id: 'admin-signin' });
      
      const result = await signIn('credentials', {
        email,
        password,
        redirect: false,
      });

      console.log('[Admin Login] SignIn result:', result);

      if (result?.error) {
        console.error('[Admin Login] Error:', result.error);
        const errorMsg = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        setError(errorMsg);
        toast.error(errorMsg, { id: 'admin-signin' });
        setIsLoading(false); // Reset loading state
        return; // Exit early
      }
      
      if (result?.ok) {
        console.log('[Admin Login] Login successful, waiting for session...');
        toast.success('เข้าสู่ระบบสำเร็จ!', { id: 'admin-signin' });
        
        // Wait a bit for session to be established
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Get fresh session
        const response = await fetch('/api/auth/session');
        
        if (!response.ok) {
          console.error('[Admin Login] Failed to fetch session');
          const errorMsg = 'ไม่สามารถดึงข้อมูล session ได้';
          setError(errorMsg);
          toast.error(errorMsg, { id: 'admin-signin' });
          setIsLoading(false);
          return;
        }
        
        const sessionData = await response.json();
        console.log('[Admin Login] Session data:', sessionData);
        
        if (!sessionData?.user?.role) {
          console.error('[Admin Login] No role in session!');
          const errorMsg = 'ไม่พบข้อมูล role กรุณาลองใหม่';
          setError(errorMsg);
          toast.error(errorMsg, { id: 'admin-signin' });
          setIsLoading(false);
          return;
        }
        
        const role = sessionData.user.role;
        
        // ✅ Check if user is STAFF (not GUEST)
        if (role === 'MANAGER' || role === 'RECEPTIONIST' || role === 'HOUSEKEEPER') {
          const redirectUrl = getRoleHomePage(role);
          console.log('[Admin Login] Valid staff role:', role, 'redirecting to:', redirectUrl);
          
          // Don't reset loading - let redirect happen
          // Use router.push with window.location fallback
          router.push(redirectUrl);
          // Force reload after a short delay to ensure middleware processes the new session
          setTimeout(() => {
            if (typeof window !== 'undefined') {
              window.location.href = redirectUrl;
            }
          }, 100);
          return; // Don't reset loading, let redirect happen
        }
        
        if (role === 'GUEST') {
          // ❌ Guest trying to login via admin page
          console.error('[Admin Login] Guest detected! Rejecting login');
          const errorMsg = 'บัญชีนี้เป็นบัญชีแขก กรุณาใช้หน้า Guest Login';
          setError(errorMsg);
          toast.error(errorMsg, { id: 'admin-signin' });
          // Sign out the guest user
          await fetch('/api/auth/signout', { method: 'POST' });
          setIsLoading(false);
          return;
        }
        
        // Unknown role
        console.error('[Admin Login] Unknown role:', role);
        const errorMsg = 'ไม่สามารถระบุประเภทบัญชีได้';
        setError(errorMsg);
        toast.error(errorMsg, { id: 'admin-signin' });
        setIsLoading(false);
      }
    } catch (err) {
      console.error('[Admin Login] Exception:', err);
      const errorMsg = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ กรุณาตรวจสอบการเชื่อมต่อ';
      setError(errorMsg);
      toast.error(errorMsg, { id: 'admin-signin' });
      setIsLoading(false);
    }
    // Note: Don't use finally block - we want to keep loading during redirect
  };

  // Show loading while checking session
  if (status === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-muted via-accent/30 to-muted">
        <div className="animate-pulse text-muted-foreground">กำลังตรวจสอบ...</div>
      </div>
    );
  }

  // Don't render form if already authenticated
  if (status === 'authenticated') {
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-muted via-accent/30 to-muted py-12 px-4 sm:px-6 lg:px-8">
      <Card className="max-w-md w-full p-8 shadow-xl border bg-card/80 backdrop-blur-sm">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-primary to-primary/80 mb-4 shadow-lg">
            <Shield className="w-8 h-8 text-primary-foreground" />
          </div>
          <h2 className="text-3xl font-bold text-foreground">
            Admin Portal
          </h2>
          <p className="mt-2 text-sm text-muted-foreground">
            สำหรับเจ้าหน้าที่และผู้จัดการเท่านั้น
          </p>
        </div>
        
        <form className="space-y-5" onSubmit={handleSubmit}>
          {/* Error Message */}
          {error && (
            <div className="rounded-lg bg-destructive/10 border border-destructive/20 p-4">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <svg className="h-5 w-5 text-destructive" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                  </svg>
                </div>
                <div className="ml-3">
                  <p className="text-sm font-medium text-destructive">
                    {error}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Email Field */}
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-foreground mb-2">
              อีเมล
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Mail className="h-5 w-5 text-muted-foreground" />
              </div>
              <Input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="staff@hotel.com"
                disabled={isLoading}
                className="pl-10 h-11 bg-background border-input focus:border-primary focus:ring-primary"
              />
            </div>
          </div>
          
          {/* Password Field */}
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-foreground mb-2">
              รหัสผ่าน
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Lock className="h-5 w-5 text-muted-foreground" />
              </div>
              <Input
                id="password"
                name="password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="รหัสผ่านของคุณ"
                disabled={isLoading}
                className="pl-10 pr-10 h-11 bg-background border-input focus:border-primary focus:ring-primary"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-0 pr-3 flex items-center text-muted-foreground hover:text-foreground transition-colors"
                disabled={isLoading}
              >
                {showPassword ? (
                  <EyeOff className="h-5 w-5" />
                ) : (
                  <Eye className="h-5 w-5" />
                )}
              </button>
            </div>
          </div>

          {/* Submit Button */}
          <div className="pt-2">
            <Button
              type="submit"
              className="w-full h-11 bg-primary hover:bg-primary/90 text-primary-foreground font-medium shadow-lg hover:shadow-xl transition-all duration-200"
              disabled={isLoading}
            >
              {isLoading ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  กำลังเข้าสู่ระบบ...
                </span>
              ) : (
                'เข้าสู่ระบบ'
              )}
            </Button>
          </div>

          {/* Info Text */}
          <div className="pt-4 border-t border-border">
            <p className="text-xs text-center text-muted-foreground">
              หากคุณเป็นแขก กรุณาใช้{' '}
              <a 
                href="/auth/signin" 
                className="font-medium text-primary hover:text-primary/80 underline"
              >
                หน้าเข้าสู่ระบบสำหรับแขก
              </a>
            </p>
          </div>
        </form>
      </Card>
    </div>
  );
}

export default function AdminSignInPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-muted via-accent/30 to-muted">
        <div className="animate-pulse text-muted-foreground">กำลังโหลด...</div>
      </div>
    }>
      <AdminSignInForm />
    </Suspense>
  );
}
