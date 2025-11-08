'use client';

import { useSession } from 'next-auth/react';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useRef } from 'react';
import { AdminSidebar } from '@/components/admin-sidebar';
import { LoadingSpinner } from '@/components/ui/loading';

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { data: session, status } = useSession();
  const router = useRouter();
  const pathname = usePathname();
  const hasRedirectedRef = useRef(false);

  useEffect(() => {
    // Prevent multiple redirects using ref (persists across re-renders)
    if (hasRedirectedRef.current) return;
    
    // Only redirect if we're certain about the status
    if (status === 'loading') return;
    
    if (status === 'unauthenticated') {
      // Redirect to admin login WITHOUT callbackUrl to prevent redirect loops
      // The admin login page will handle the redirect after successful login
      console.log('[Admin Layout] Unauthenticated, redirecting to /auth/admin');
      hasRedirectedRef.current = true;
      router.replace('/auth/admin');
    } else if (status === 'authenticated') {
      const role = session?.user?.role;
      console.log('[Admin Layout] Authenticated with role:', role);
      // Only allow staff roles
      if (role !== 'MANAGER' && role !== 'RECEPTIONIST' && role !== 'HOUSEKEEPER') {
        console.log('[Admin Layout] Invalid role:', role, 'redirecting to /unauthorized');
        hasRedirectedRef.current = true;
        router.replace('/unauthorized');
      } else {
        console.log('[Admin Layout] Valid staff role, allowing access');
      }
    }
  }, [status, session, router, pathname]);

  if (status === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  if (status === 'unauthenticated') {
    return null;
  }

  const role = session?.user?.role;
  if (role !== 'MANAGER' && role !== 'RECEPTIONIST' && role !== 'HOUSEKEEPER') {
    return null;
  }

  return (
    <div className="min-h-screen bg-background">
      <AdminSidebar />
      
      {/* Main Content - with responsive margin for sidebar */}
      <main className="lg:ml-64 transition-all duration-300 min-h-screen">
        <div className="p-4 sm:p-6 lg:p-8">
          {children}
        </div>
      </main>
    </div>
  );
}
