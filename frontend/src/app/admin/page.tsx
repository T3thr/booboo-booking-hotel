'use client';

import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { LoadingSpinner } from '@/components/ui/loading';

export default function AdminPage() {
  const { data: session, status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === 'loading') return;

    if (status === 'unauthenticated') {
      // Not logged in, redirect to admin login
      if (typeof window !== 'undefined') {
        window.location.href = '/auth/admin';
      }
      return;
    }

    if (status === 'authenticated' && session?.user?.role) {
      const role = session.user.role;
      
      // Redirect based on role using window.location for reliability
      let redirectUrl = '/unauthorized';
      
      switch (role) {
        case 'MANAGER':
          redirectUrl = '/admin/dashboard';
          break;
        case 'RECEPTIONIST':
          redirectUrl = '/admin/reception';
          break;
        case 'HOUSEKEEPER':
          redirectUrl = '/admin/housekeeping';
          break;
      }
      
      console.log('[Admin Page] Redirecting to:', redirectUrl);
      
      // Use window.location for reliable redirect in production
      if (typeof window !== 'undefined') {
        window.location.href = redirectUrl;
      } else {
        router.replace(redirectUrl);
      }
    }
  }, [status, session, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <LoadingSpinner size="lg" />
    </div>
  );
}
