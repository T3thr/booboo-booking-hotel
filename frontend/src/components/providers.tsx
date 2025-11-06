'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { SessionProvider } from 'next-auth/react';
import { useState } from 'react';
import { ThemeProvider } from '@/providers/theme-provider';
import { ThemeToggle } from '@/components/ui/theme-toggle';
import { Toaster } from 'sonner';

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1 minute
            gcTime: 5 * 60 * 1000, // 5 minutes (formerly cacheTime)
            refetchOnWindowFocus: false,
            refetchOnReconnect: true,
            retry: (failureCount, error: any) => {
              // Don't retry on 401, 403, 404
              if (error?.response?.status && [401, 403, 404].includes(error.response.status)) {
                return false;
              }
              return failureCount < 2;
            },
          },
          mutations: {
            retry: false,
            onError: (error: any) => {
              // Global error handling for mutations
              console.error('Mutation error:', error);
            },
          },
        },
      })
  );

  return (
    <ThemeProvider>
      <SessionProvider refetchInterval={5 * 60} refetchOnWindowFocus={true}>
        <QueryClientProvider client={queryClient}>
          {children}
          <Toaster 
            position="top-center" 
            richColors 
            closeButton
            duration={4000}
          />
          <ThemeToggle />
          {process.env.NODE_ENV === 'development' && (
            <ReactQueryDevtools initialIsOpen={false} />
          )}
        </QueryClientProvider>
      </SessionProvider>
    </ThemeProvider>
  );
}
