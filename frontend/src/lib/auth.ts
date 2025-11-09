import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";

export const { handlers, signIn, signOut, auth } = NextAuth({
  trustHost: true, // Required for Next.js 15+ to handle host headers properly
  debug: process.env.NODE_ENV === 'development', // Enable debug in development
  providers: [
    Credentials({
      name: "Credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          console.log('[Auth] Missing credentials');
          return null;
        }

        try {
          // Use BACKEND_URL for server-side calls (Docker service name)
          // Use NEXT_PUBLIC_API_URL for client-side calls (localhost)
          const baseUrl = process.env.BACKEND_URL 
            || process.env.NEXT_PUBLIC_API_URL 
            || 'http://localhost:8080';
          
          const apiUrl = `${baseUrl}/api/auth/login`;
          
          console.log('[Auth] Calling backend:', apiUrl);
          
          const res = await fetch(apiUrl, {
            method: "POST",
            body: JSON.stringify({
              email: credentials.email,
              password: credentials.password
            }),
            headers: { 
              "Content-Type": "application/json",
              "Accept": "application/json"
            },
            cache: 'no-store' // Prevent caching issues
          });

          if (!res.ok) {
            console.log('[Auth] Backend response not OK:', res.status);
            return null;
          }

          const response = await res.json();
          console.log('[Auth] Backend response:', response);
          
          if (response.success && response.data) {
            const user = {
              id: response.data.id.toString(),
              email: response.data.email,
              name: `${response.data.first_name} ${response.data.last_name}`,
              role: response.data.role_code,
              userType: response.data.user_type,
              phone: response.data.phone,
              accessToken: response.data.access_token || response.data.accessToken
            };
            console.log('[Auth] Returning user:', user);
            return user;
          }

          console.log('[Auth] Invalid response format');
          return null;
        } catch (error) {
          console.error("[Auth] Exception:", error);
          return null;
        }
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        console.log('[JWT Callback] User data:', user);
        token.id = user.id;
        token.role = user.role;
        token.userType = user.userType;
        token.phone = user.phone;
        token.accessToken = user.accessToken;
        console.log('[JWT Callback] Token after update:', { id: token.id, role: token.role, userType: token.userType, phone: token.phone });
      }
      return token;
    },
    async session({ session, token }) {
      console.log('[Session Callback] Token:', { id: token.id, role: token.role, userType: token.userType, phone: token.phone });
      if (session.user) {
        session.user.id = token.id as string;
        session.user.role = token.role as string;
        session.user.userType = token.userType as string;
        session.user.phone = token.phone as string;
      }
      session.accessToken = token.accessToken as string;
      console.log('[Session Callback] Session after update:', { user: session.user });
      return session;
    },
    async redirect({ url, baseUrl }) {
      console.log('[Redirect Callback] URL:', url, 'Base:', baseUrl);
      
      // If URL starts with baseUrl, use it
      if (url.startsWith(baseUrl)) {
        console.log('[Redirect Callback] URL starts with baseUrl, using:', url);
        return url;
      }
      
      // If URL is a relative path, append to baseUrl
      if (url.startsWith('/')) {
        const fullUrl = `${baseUrl}${url}`;
        console.log('[Redirect Callback] Relative URL, using:', fullUrl);
        return fullUrl;
      }
      
      // Default to baseUrl
      console.log('[Redirect Callback] Defaulting to baseUrl');
      return baseUrl;
    }
  },
  pages: {
    signIn: '/auth/signin',
    error: '/auth/error',
  },
  session: {
    strategy: "jwt",
    maxAge: 24 * 60 * 60, // 24 hours
  },
  secret: process.env.NEXTAUTH_SECRET,
  cookies: {
    sessionToken: {
      name: `${process.env.NODE_ENV === 'production' ? '__Secure-' : ''}next-auth.session-token`,
      options: {
        httpOnly: true,
        sameSite: 'lax',
        path: '/',
        secure: process.env.NODE_ENV === 'production',
      },
    },
  },
  useSecureCookies: process.env.NODE_ENV === 'production',
});

// Helper function to get role-specific home page
export function getRoleHomePage(role: string): string {
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

// Helper function to check if user can access a route
export function canAccessRoute(userRole: string, requiredRoles: string[]): boolean {
  return requiredRoles.includes(userRole);
}
