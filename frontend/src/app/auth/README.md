# Authentication Pages

This directory contains all authentication-related pages for the hotel booking system.

## Pages

### `/auth/signin` - Sign In Page
**File**: `signin/page.tsx`

Custom sign-in page with:
- Email and password form
- Client-side validation
- Error handling
- Loading states
- Redirect to callback URL after successful login
- Link to registration page

**Usage**:
```tsx
// Redirect to sign-in
router.push('/auth/signin');

// With callback URL
router.push('/auth/signin?callbackUrl=/dashboard');
```

### `/auth/register` - Registration Page
**File**: `register/page.tsx`

User registration page with:
- Full registration form (first name, last name, email, phone, password)
- Password confirmation
- Client-side validation
- Backend API integration
- Redirect to sign-in after successful registration

**Form Fields**:
- First Name (required)
- Last Name (required)
- Email (required, validated)
- Phone (optional)
- Password (required, min 6 characters)
- Confirm Password (required, must match)

### `/auth/error` - Error Page
**File**: `error/page.tsx`

Authentication error page with:
- Error message display
- Different messages for different error types
- Links to sign-in and home page

**Error Types**:
- `Configuration` - System configuration error
- `AccessDenied` - Access denied
- `Verification` - Verification failed
- `Default` - Generic error

**Usage**:
```tsx
// Redirect to error page
router.push('/auth/error?error=AccessDenied');
```

### `/auth/test` - Test Page
**File**: `test/page.tsx`

Testing and debugging page with:
- Current session display
- Authentication status
- User information
- JWT token (truncated)
- Sign out button
- Testing checklist

**Usage**:
```
http://localhost:3000/auth/test
```

## Authentication Flow

### Sign In Flow
1. User navigates to `/auth/signin`
2. User enters email and password
3. Form validates input
4. Calls `signIn('credentials', {...})`
5. NextAuth sends credentials to backend
6. Backend validates and returns JWT token
7. NextAuth creates session
8. User redirected to callback URL

### Registration Flow
1. User navigates to `/auth/register`
2. User fills registration form
3. Form validates input (client-side)
4. Sends POST request to backend `/api/auth/register`
5. Backend creates user account
6. User redirected to `/auth/signin`

### Sign Out Flow
1. User clicks sign out button
2. Calls `signOut({callbackUrl: '/'})`
3. NextAuth clears session
4. User redirected to home page

## Components Used

All pages use shared UI components:
- `Button` from `@/components/ui/button`
- `Input` from `@/components/ui/input`
- `Card` from `@/components/ui/card`

## Styling

All pages use:
- Tailwind CSS for styling
- Responsive design
- Consistent color scheme
- Accessible forms

## Error Handling

All pages implement:
- Try-catch blocks
- Error state management
- User-friendly error messages (Thai language)
- Loading states
- Disabled states during submission

## Security

All pages implement:
- Client-side validation
- CSRF protection (NextAuth)
- Secure password handling
- No password storage in state longer than necessary
- Proper redirect handling

## Testing

Test each page:
1. **Sign In**: Try valid and invalid credentials
2. **Register**: Try new and existing emails
3. **Error**: Navigate with different error types
4. **Test**: Check session data display

## Environment Variables

Required for these pages:
```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key
```

## API Endpoints

These pages interact with:
- `POST /api/auth/login` - Sign in (via NextAuth)
- `POST /api/auth/register` - Registration
- `GET /api/auth/session` - Get session (NextAuth)
- `POST /api/auth/signout` - Sign out (NextAuth)

## TypeScript Types

```typescript
// Sign in form
interface SignInForm {
  email: string;
  password: string;
}

// Registration form
interface RegisterForm {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  password: string;
  confirmPassword: string;
}

// Session
interface Session {
  user: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
  accessToken: string;
  expires: string;
}
```

## Customization

To customize these pages:

1. **Styling**: Edit Tailwind classes
2. **Validation**: Update validation logic
3. **Messages**: Change error/success messages
4. **Fields**: Add/remove form fields
5. **Redirects**: Change callback URLs

## Troubleshooting

### Sign in not working
- Check backend is running
- Verify BACKEND_URL in .env.local
- Check credentials are correct
- Look at browser console for errors

### Registration not working
- Check NEXT_PUBLIC_API_URL is correct
- Verify backend /api/auth/register endpoint
- Check form validation passes
- Look at network tab for API errors

### Session not persisting
- Check cookies are enabled
- Verify NEXTAUTH_SECRET is set
- Check NEXTAUTH_URL matches your domain
- Clear browser cookies and try again

## Related Files

- **NextAuth Config**: `src/lib/auth.ts`
- **API Route**: `src/app/api/auth/[...nextauth]/route.ts`
- **Protected Route**: `src/components/protected-route.tsx`
- **Providers**: `src/components/providers.tsx`

## Documentation

- **Setup Guide**: `frontend/NEXTAUTH_SETUP.md`
- **Testing Guide**: `frontend/TASK_17_TESTING.md`
- **Quick Reference**: `frontend/NEXTAUTH_QUICK_REFERENCE.md`
- **Flow Diagrams**: `frontend/NEXTAUTH_FLOW_DIAGRAM.md`

## Next Steps

After authentication is working:
1. Implement role-based dashboards
2. Add profile management
3. Implement password reset
4. Add email verification
5. Create booking flows

## Support

For issues or questions:
1. Check documentation files
2. Review test page output
3. Check browser console
4. Verify backend logs
5. Review NextAuth.js documentation
