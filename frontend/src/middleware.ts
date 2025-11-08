import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

// Role-based access control configuration
const roleAccess: Record<string, string[]> = {
  // Profile requires auth
  '/profile': ['GUEST', 'RECEPTIONIST', 'HOUSEKEEPER', 'MANAGER'],
  
  // Admin routes - All staff can access /admin
  '/admin': ['RECEPTIONIST', 'HOUSEKEEPER', 'MANAGER'],
  
  // Manager-only routes
  '/admin/dashboard': ['MANAGER'],
  '/admin/pricing': ['MANAGER'],
  '/admin/inventory': ['MANAGER'],
  '/admin/reports': ['MANAGER'],
  '/admin/settings': ['MANAGER'],
  
  // Receptionist routes (Manager has access to everything)
  '/admin/reception': ['RECEPTIONIST', 'MANAGER'],
  '/admin/checkin': ['RECEPTIONIST', 'MANAGER'],
  '/admin/checkout': ['RECEPTIONIST', 'MANAGER'],
  '/admin/move-room': ['RECEPTIONIST', 'MANAGER'],
  '/admin/no-show': ['RECEPTIONIST', 'MANAGER'],
  
  // Housekeeper routes (Manager has access to everything)
  '/admin/housekeeping': ['HOUSEKEEPER', 'MANAGER'],
};

// Public routes that don't require authentication
const publicRoutes = [
  '/',
  '/rooms',
  '/booking', // Allow anyone to book without signin
  '/bookings', // Allow anyone to view booking history (with phone search)
  '/about',
  '/contact',
  '/auth/signin',
  '/auth/register',
  '/auth/admin',
  '/auth/error',
  '/auth/test',
  '/auth/forgot-password',
  '/unauthorized',
  '/not-found',
  '/test-api',
];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  console.log('[Middleware] Path:', pathname);
  console.log('[Middleware] Environment:', process.env.NODE_ENV);
  
  // Get token with correct configuration for production
  const token = await getToken({ 
    req: request, 
    secret: process.env.NEXTAUTH_SECRET,
    // Important: Must match cookie configuration in auth.ts
    secureCookie: process.env.NODE_ENV === 'production',
    cookieName: process.env.NODE_ENV === 'production' 
      ? '__Secure-next-auth.session-token' 
      : 'next-auth.session-token'
  });
  
  console.log('[Middleware] Token:', token ? { role: token.role, email: token.email } : 'No token');

  // Allow public routes
  if (publicRoutes.some(route => pathname === route || pathname.startsWith(route + '/'))) {
    console.log('[Middleware] Public route, allowing');
    // Don't redirect from auth pages - let the page handle it
    // This prevents redirect loops during login process
    
    // Special handling: If user is authenticated and on /auth/admin, let the page redirect
    // Don't interfere with the redirect process
    if (pathname === '/auth/admin' && token) {
      console.log('[Middleware] Authenticated user on /auth/admin, letting page handle redirect');
    }
    
    return NextResponse.next();
  }

  // Allow API routes to pass through without auth check
  if (pathname.startsWith('/api/')) {
    console.log('[Middleware] API route, allowing');
    return NextResponse.next();
  }

  // Check authentication
  if (!token) {
    console.log('[Middleware] No token, redirecting to signin');
    // For admin routes, redirect to admin signin (without callbackUrl to avoid loops)
    if (pathname.startsWith('/admin')) {
      console.log('[Middleware] Redirecting to /auth/admin');
      return NextResponse.redirect(new URL('/auth/admin', request.url));
    }
    // For other routes, redirect to regular signin
    const url = new URL('/auth/signin', request.url);
    url.searchParams.set('callbackUrl', pathname);
    return NextResponse.redirect(url);
  }

  // Check role-based access
  const userRole = token.role as string;
  console.log('[Middleware] User role:', userRole);
  
  // Check specific role access - sort by path length (longest first) for accurate matching
  const sortedRoleAccess = Object.entries(roleAccess).sort((a, b) => b[0].length - a[0].length);
  
  for (const [prefix, allowedRoles] of sortedRoleAccess) {
    if (pathname === prefix || pathname.startsWith(prefix + '/')) {
      console.log('[Middleware] Checking access for prefix:', prefix, 'Allowed roles:', allowedRoles);
      if (!allowedRoles.includes(userRole)) {
        console.log('[Middleware] Access denied! User role:', userRole);
        return NextResponse.redirect(new URL('/unauthorized', request.url));
      }
      console.log('[Middleware] Access granted');
      return NextResponse.next();
    }
  }

  console.log('[Middleware] No specific rule matched, allowing');
  return NextResponse.next();
}

// Helper function to get role-specific home page
function getRoleHomePage(role: string): string {
  switch (role) {
    case 'GUEST':
      return '/';
    case 'RECEPTIONIST':
      return '/admin/reception';
    case 'HOUSEKEEPER':
      return '/admin/housekeeping';
    case 'MANAGER':
      return '/admin/dashboard';
    default:
      return '/';
  }
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\..*|_next).*)',
  ],
};
