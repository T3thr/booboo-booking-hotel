'use client';

import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { LoadingSpinner } from '@/components/ui/loading';

export default function AdminPage() {
  const { data: session, status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === 'authenticated' && session?.user?.role) {
      const role = session.user.role;
      
      // Redirect based on role
      switch (role) {
        case 'MANAGER':
          router.replace('/admin/dashboard');
          break;
        case 'RECEPTIONIST':
          router.replace('/admin/reception');
          break;
        case 'HOUSEKEEPER':
          router.replace('/admin/housekeeping');
          break;
        default:
          router.replace('/unauthorized');
      }
    }
  }, [status, session, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <LoadingSpinner size="lg" />
    </div>
  );
}
