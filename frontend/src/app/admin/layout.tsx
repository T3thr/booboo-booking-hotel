'use client';

import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { AdminSidebar } from '@/components/admin-sidebar';
import { LoadingSpinner } from '@/components/ui/loading';

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { data: session, status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/auth/signin?callbackUrl=/admin');
    } else if (status === 'authenticated') {
      const role = session?.user?.role;
      // Only allow staff roles
      if (role !== 'MANAGER' && role !== 'RECEPTIONIST' && role !== 'HOUSEKEEPER') {
        router.push('/unauthorized');
      }
    }
  }, [status, session, router]);

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
