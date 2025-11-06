# 🧪 Authentication Flow - Test Checklist

## Pre-requisites

- [ ] Backend running on port 8080
- [ ] Frontend running on port 3000
- [ ] Database seeded with demo data

## Test 1: Initial State (Not Logged In)

### Steps
1. Open http://localhost:3000
2. Check navbar

### Expected Results
- [ ] Navbar shows "เข้าสู่ระบบ" button
- [ ] Navbar shows "ลงทะเบียน" button
- [ ] Navbar shows "ค้นหาห้องพัก" button
- [ ] No user name displayed
- [ ] No "การจองของฉัน" button

## Test 2: Login Flow

### Steps
1. Click "เข้าสู่ระบบ"
2. Enter credentials:
   - Email: `anan.test@example.com`
   - Password: `password123`
3. Click "เข้าสู่ระบบ" button

### Expected Results
- [ ] Redirects to home page (/)
- [ ] Navbar updates immediately
- [ ] Shows "Anan Testsawat" or email
- [ ] Shows "การจองของฉัน" button
- [ ] Shows "ออกจากระบบ" button
- [ ] No "เข้าสู่ระบบ" button
- [ ] No "ลงทะเบียน" button

### Backend Logs
```
[POST] 200 | <time>ms | ::1 | /api/auth/login
```

## Test 3: Protected Route Access (Logged In)

### Steps
1. While logged in, navigate to http://localhost:3000/bookings

### Expected Results
- [ ] Page loads successfully
- [ ] Shows "My Bookings" or "การจองของฉัน"
- [ ] May show empty state if no bookings
- [ ] No redirect to signin

### Backend Logs
```
[GET] 200 | <time>ms | ::1 | /api/bookings
```

## Test 4: Auth Page Redirect (Logged In)

### Steps
1. While logged in, navigate to http://localhost:3000/auth/signin

### Expected Results
- [ ] Immediately redirects to home page (/)
- [ ] Does not show signin form
- [ ] Navbar still shows logged-in state

## Test 5: Session Persistence

### Steps
1. While logged in, refresh the page (F5)

### Expected Results
- [ ] Navbar still shows logged-in state
- [ ] User name still displayed
- [ ] No flash of "เข้าสู่ระบบ" button
- [ ] Session persists

## Test 6: Sign Out Flow

### Steps
1. Click "ออกจากระบบ" button

### Expected Results
- [ ] Redirects to home page (/)
- [ ] Navbar updates immediately
- [ ] Shows "เข้าสู่ระบบ" button again
- [ ] Shows "ลงทะเบียน" button again
- [ ] No user name displayed
- [ ] No "การจองของฉัน" button

## Test 7: Protected Route Access (Not Logged In)

### Steps
1. After signing out, navigate to http://localhost:3000/bookings

### Expected Results
- [ ] Redirects to /auth/signin?callbackUrl=/bookings
- [ ] Shows signin form
- [ ] URL contains callbackUrl parameter

## Test 8: Callback URL After Login

### Steps
1. From the signin page with callbackUrl, login again
2. Use same credentials

### Expected Results
- [ ] After login, redirects to /bookings (the callbackUrl)
- [ ] Not redirected to home page
- [ ] Bookings page loads

## Test 9: API Authentication

### Steps
1. Login
2. Open browser DevTools (F12)
3. Go to Network tab
4. Navigate to /bookings
5. Check the request to /api/bookings

### Expected Results
- [ ] Request includes `Authorization: Bearer <token>` header
- [ ] Token is a valid JWT
- [ ] Backend returns 200 status
- [ ] Response format: `{data: [...], success: true}`

## Test 10: Invalid Credentials

### Steps
1. Go to signin page
2. Enter wrong password
3. Click login

### Expected Results
- [ ] Shows error message
- [ ] Error in Thai: "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
- [ ] Does not redirect
- [ ] Stays on signin page

### Backend Logs
```
[POST] 401 | <time>ms | ::1 | /api/auth/login
```

## Test 11: Session Expiry (Optional)

### Steps
1. Login
2. Wait 24 hours (or modify JWT expiry to 1 minute for testing)
3. Try to access /bookings

### Expected Results
- [ ] Session expires
- [ ] Redirects to signin
- [ ] Shows "Session expired" message (if implemented)

## Test 12: Multiple Tabs

### Steps
1. Open two browser tabs
2. Login in tab 1
3. Check tab 2

### Expected Results
- [ ] Tab 2 navbar updates automatically (within 5 minutes)
- [ ] Both tabs show logged-in state
- [ ] Session synced across tabs

## Test 13: Browser Back Button

### Steps
1. Login
2. Navigate to /bookings
3. Click browser back button
4. Click browser forward button

### Expected Results
- [ ] Navigation works correctly
- [ ] Session persists
- [ ] No re-authentication required
- [ ] Navbar state consistent

## Test 14: Direct URL Access

### Steps
1. Not logged in
2. Type http://localhost:3000/bookings directly in address bar

### Expected Results
- [ ] Redirects to signin with callbackUrl
- [ ] After login, returns to /bookings

## Test 15: Performance Check

### Steps
1. Login
2. Open DevTools Performance tab
3. Navigate between pages

### Expected Results
- [ ] Navbar updates < 100ms
- [ ] No unnecessary re-renders
- [ ] Session check is fast
- [ ] No layout shift

## 🎯 Success Criteria

All tests should pass:
- [ ] 15/15 tests passed
- [ ] No console errors
- [ ] No TypeScript errors
- [ ] No layout shifts
- [ ] Fast and responsive

## 🐛 Common Issues

### Issue: Navbar doesn't update after login
**Solution:** Restart Next.js dev server

### Issue: 401 errors on API calls
**Solution:** Check backend is running and JWT_SECRET matches

### Issue: Session doesn't persist
**Solution:** Check NEXTAUTH_SECRET is set in .env

### Issue: Middleware not working
**Solution:** Check middleware.ts is in src/ directory

---

**Test Date:** ___________  
**Tester:** ___________  
**Result:** ⬜ Pass / ⬜ Fail  
**Notes:** ___________
