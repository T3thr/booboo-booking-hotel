# Task 17: NextAuth.js Testing Guide

## Overview

This guide provides step-by-step instructions for testing the NextAuth.js implementation.

## Prerequisites

1. **Backend Running**: Ensure the Go backend is running on port 8080
2. **Database Ready**: PostgreSQL should be running with migrations applied
3. **Environment Variables**: Check that `.env.local` is properly configured

## Testing Checklist

### ✅ Phase 1: File Verification

Verify all required files exist:

- [ ] `src/lib/auth.ts` - NextAuth configuration
- [ ] `src/app/api/auth/[...nextauth]/route.ts` - API route
- [ ] `src/app/auth/signin/page.tsx` - Sign-in page
- [ ] `src/app/auth/register/page.tsx` - Register page
- [ ] `src/app/auth/error/page.tsx` - Error page
- [ ] `src/app/auth/test/page.tsx` - Test page
- [ ] `src/components/providers.tsx` - SessionProvider
- [ ] `src/components/protected-route.tsx` - Protected route component
- [ ] `.env.local` - Environment variables

### ✅ Phase 2: Environment Setup

Check environment variables in `.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
BACKEND_URL=http://backend:8080
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=hotel-booking-secret-key-change-in-production-2024
```

### ✅ Phase 3: Start Services

1. **Start Backend**:
   ```bash
   cd backend
   make run
   ```
   
   Expected output:
   ```
   Server running on :8080
   ```

2. **Start Frontend**:
   ```bash
   cd frontend
   npm run dev
   ```
   
   Expected output:
   ```
   ▲ Next.js 16.0.1
   - Local:        http://localhost:3000
   ```

### ✅ Phase 4: Test Registration

1. Navigate to: `http://localhost:3000/auth/register`

2. Fill in the form:
   - First Name: `Test`
   - Last Name: `User`
   - Email: `test@example.com`
   - Phone: `0812345678`
   - Password: `password123`
   - Confirm Password: `password123`

3. Click "ลงทะเบียน" (Register)

4. **Expected Result**:
   - Redirects to `/auth/signin`
   - No error messages

5. **Verify in Backend**:
   ```bash
   # Check if user was created in database
   psql -U postgres -d hotel_booking -c "SELECT * FROM guests WHERE email = 'test@example.com';"
   ```

### ✅ Phase 5: Test Sign In (Success)

1. Navigate to: `http://localhost:3000/auth/signin`

2. Enter credentials:
   - Email: `test@example.com`
   - Password: `password123`

3. Click "เข้าสู่ระบบ" (Sign In)

4. **Expected Result**:
   - Redirects to home page (`/`)
   - No error messages
   - Session is created

5. **Verify Session**:
   - Navigate to: `http://localhost:3000/auth/test`
   - Should show:
     - Status: `authenticated`
     - User ID, Email, Name, Role
     - Access Token (truncated)

### ✅ Phase 6: Test Sign In (Failure)

1. Navigate to: `http://localhost:3000/auth/signin`

2. Enter wrong credentials:
   - Email: `test@example.com`
   - Password: `wrongpassword`

3. Click "เข้าสู่ระบบ" (Sign In)

4. **Expected Result**:
   - Error message displayed: "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
   - Stays on sign-in page
   - No session created

### ✅ Phase 7: Test Session Persistence

1. Sign in successfully (Phase 5)

2. Navigate to different pages:
   - `http://localhost:3000/`
   - `http://localhost:3000/auth/test`

3. **Expected Result**:
   - Session persists across page navigation
   - User remains logged in

4. Refresh the page (F5)

5. **Expected Result**:
   - Session still persists
   - User still logged in

### ✅ Phase 8: Test Sign Out

1. While signed in, navigate to: `http://localhost:3000/auth/test`

2. Click "ออกจากระบบ" (Sign Out)

3. **Expected Result**:
   - Redirects to `/auth/signin`
   - Session is cleared
   - Status changes to `unauthenticated`

4. Try accessing: `http://localhost:3000/auth/test`

5. **Expected Result**:
   - Shows "ยังไม่ได้เข้าสู่ระบบ" message
   - Button to go to sign-in page

### ✅ Phase 9: Test Protected Routes

1. Sign out if logged in

2. Try accessing a protected route (we'll create one for testing):
   ```
   http://localhost:3000/dashboard
   ```

3. **Expected Result**:
   - Redirects to `/auth/signin`
   - Shows sign-in page

4. Sign in successfully

5. Try accessing the protected route again

6. **Expected Result**:
   - Access granted
   - Page loads successfully

### ✅ Phase 10: Test JWT Token

1. Sign in successfully

2. Open browser DevTools (F12)

3. Go to Application/Storage → Cookies

4. Look for cookies from `localhost:3000`

5. **Expected Result**:
   - Should see NextAuth session cookies:
     - `next-auth.session-token` (or similar)
     - `next-auth.csrf-token`

6. Navigate to: `http://localhost:3000/auth/test`

7. **Expected Result**:
   - Access Token is displayed (truncated)
   - Token format: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### ✅ Phase 11: Test API Integration

1. Sign in successfully

2. Open browser DevTools → Network tab

3. Navigate to: `http://localhost:3000/auth/test`

4. Look for API calls to backend

5. **Expected Result**:
   - POST request to `/api/auth/login` (during sign-in)
   - Response includes: `id`, `email`, `role`, `accessToken`
   - Status: 200 OK

### ✅ Phase 12: Test Error Handling

1. Stop the backend server

2. Try to sign in

3. **Expected Result**:
   - Error message: "เกิดข้อผิดพลาดในการเข้าสู่ระบบ"
   - No crash or blank page

4. Start the backend server again

5. Try to sign in

6. **Expected Result**:
   - Sign in works normally

## Test Results Template

Copy this template and fill in your test results:

```
# NextAuth.js Test Results

Date: _______________
Tester: _______________

## Phase 1: File Verification
- [ ] All files exist

## Phase 2: Environment Setup
- [ ] Environment variables configured

## Phase 3: Start Services
- [ ] Backend started successfully
- [ ] Frontend started successfully

## Phase 4: Test Registration
- [ ] Registration form loads
- [ ] Registration succeeds
- [ ] User created in database

## Phase 5: Test Sign In (Success)
- [ ] Sign-in form loads
- [ ] Sign-in succeeds
- [ ] Session created
- [ ] Redirects correctly

## Phase 6: Test Sign In (Failure)
- [ ] Error message displayed
- [ ] No session created

## Phase 7: Test Session Persistence
- [ ] Session persists across navigation
- [ ] Session persists after refresh

## Phase 8: Test Sign Out
- [ ] Sign out succeeds
- [ ] Session cleared
- [ ] Redirects correctly

## Phase 9: Test Protected Routes
- [ ] Redirects when not authenticated
- [ ] Access granted when authenticated

## Phase 10: Test JWT Token
- [ ] Cookies created
- [ ] Token format correct

## Phase 11: Test API Integration
- [ ] API calls successful
- [ ] Response format correct

## Phase 12: Test Error Handling
- [ ] Handles backend down gracefully
- [ ] Recovers when backend up

## Overall Result
- [ ] All tests passed
- [ ] Ready for production

## Notes:
_____________________________________
_____________________________________
_____________________________________
```

## Common Issues and Solutions

### Issue 1: "Invalid token" error

**Cause**: NEXTAUTH_SECRET mismatch or not set

**Solution**:
```bash
# Check .env.local has NEXTAUTH_SECRET
# Restart Next.js dev server
npm run dev
```

### Issue 2: Cannot connect to backend

**Cause**: Backend not running or wrong URL

**Solution**:
```bash
# Check backend is running
curl http://localhost:8080/api/health

# Check BACKEND_URL in .env.local
# Should be: http://backend:8080 (for Docker) or http://localhost:8080 (for local)
```

### Issue 3: Session not persisting

**Cause**: Cookies blocked or NEXTAUTH_URL wrong

**Solution**:
```bash
# Check browser allows cookies
# Check NEXTAUTH_URL matches your frontend URL
# Clear browser cookies and try again
```

### Issue 4: TypeScript errors

**Cause**: Type definitions not loaded

**Solution**:
```bash
# Restart TypeScript server in VS Code
# Or rebuild
npm run build
```

### Issue 5: "Module not found" errors

**Cause**: Dependencies not installed

**Solution**:
```bash
npm install
```

## Success Criteria

All tests must pass:

- ✅ Registration works
- ✅ Sign in with correct credentials works
- ✅ Sign in with wrong credentials fails gracefully
- ✅ Session persists across navigation
- ✅ Session persists after refresh
- ✅ Sign out works
- ✅ Protected routes redirect when not authenticated
- ✅ JWT token is created and stored
- ✅ API integration works
- ✅ Error handling works

## Next Steps

After all tests pass:

1. Mark task 17 as complete
2. Update task status in tasks.md
3. Proceed to task 18: API Client and React Query Setup
4. Document any issues or improvements needed

## References

- NextAuth.js Documentation: https://next-auth.js.org/
- Task 17 Requirements: See `.kiro/specs/hotel-reservation-system/requirements.md` (1.1-1.6)
- NextAuth Setup Guide: See `NEXTAUTH_SETUP.md`
