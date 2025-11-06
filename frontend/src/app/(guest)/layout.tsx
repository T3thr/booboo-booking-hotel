import { ReactNode } from 'react';
import { Navbar } from '@/components/navbar';
import { HoldIndicator } from '@/components/hold-indicator';

export default function GuestLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      {/* Main Content */}
      <main>{children}</main>

      {/* Hold Indicator */}
      <HoldIndicator />

      {/* Footer */}
      <footer className="border-t border-border bg-card mt-12">
        <div className="container mx-auto px-4 py-8">
          <div className="text-center text-sm text-muted-foreground">
            <p>&copy; 2025 Hotel Booking System. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
