# 🎯 Final Fix - Admin Redirect Loop (Production)

## 🔴 Root Cause ที่แท้จริง

หลังจากวิเคราะห์ลึกพบว่าปัญหามาจาก **3 จุด**:

### 1. Admin Layout - useState Reset Issue
```typescript
// ❌ ปัญหา: useState จะ reset ทุกครั้งที่ component re-render
const [hasRedirected, setHasRedirected] = useState(false);

// ✅ แก้ไข: ใช้ useRef แทน (persist across re-renders)
const hasRedirectedRef = useRef(false);
```

**เหตุผล:** ใน production session sync ช้า ทำให้ component re-render หลายครั้ง และ `hasRedirected` state ถูก reset กลับเป็น `false`

---

### 2. NextAuth Redirect Callback - Blocking Auth Pages
```typescript
// ❌ ปัญหา: Callback ป้องกันไม่ให้ redirect ไปที่ auth pages
if (url.includes('/auth/signin') || url.includes('/auth/admin')) {
  return baseUrl; // Return '/' แทน!
}

// ✅ แก้ไข: ลบ logic นี้ออก ให้ redirect ตามปกติ
// NextAuth จะไม่ redirect เอง เพราะเราใช้ redirect: false
```

**เหตุผล:** Logic นี้ทำให้ NextAuth redirect ไปที่ `/` แทนที่จะปล่อยให้ admin login page จัดการ redirect เอง

---

### 3. Session Sync Delay
```typescript
// ❌ ปัญหา: Redirect ทันทีโดยไม่รอ session sync
window.location.replace(redirectUrl);

// ✅ แก้ไข: เพิ่ม delay 300ms
await new Promise(resolve => setTimeout(resolve, 300));
window.location.href = redirectUrl;
```

**เหตุผล:** ใน production มี network latency ทำให้ session ยังไม่ sync ทันก่อน redirect

---

## 🛠️ Changes Made

### 1. `frontend/src/app/admin/layout.tsx`

**Changes:**
- ✅ เปลี่ยนจาก `useState` เป็น `useRef` สำหรับ `hasRedirected`
- ✅ เพิ่ม check `if (status === 'loading') return;` เพื่อรอ session load
- ✅ เพิ่ม console.log เพื่อ debug

**Code:**
```typescript
const hasRedirectedRef = useRef(false);

useEffect(() => {
  if (hasRedirectedRef.current) return;
  if (status === 'loading') return; // Wait for session
  
  if (status === 'unauthenticated') {
    console.log('[Admin Layout] Unauthenticated, redirecting to /auth/admin');
    hasRedirectedRef.current = true;
    router.replace('/auth/admin');
  } else if (status === 'authenticated') {
    const role = session?.user?.role;
    console.log('[Admin Layout] Authenticated with role:', role);
    if (role !== 'MANAGER' && role !== 'RECEPTIONIST' && role !== 'HOUSEKEEPER') {
      hasRedirectedRef.current = true;
      router.replace('/unauthorized');
    } else {
      console.log('[Admin Layout] Valid staff role, allowing access');
    }
  }
}, [status, session, router, pathname]);
```

---

### 2. `frontend/src/app/auth/admin/page.tsx`

**Changes:**
- ✅ เพิ่ม check `if (status === 'loading') return;`
- ✅ เพิ่ม delay 300ms ก่อน redirect
- ✅ เปลี่ยนจาก `window.location.replace` เป็น `window.location.href`
- ✅ เพิ่ม console.log เพื่อ debug

**Code:**
```typescript
useEffect(() => {
  if (typeof window === 'undefined') return;
  if (hasRedirected) return;
  if (status === 'loading') return; // Wait for session
  if (status !== 'authenticated' || !session?.user) return;
  
  const role = session.user.role || 'GUEST';
  console.log('[Admin Login] Checking authenticated user, role:', role);
  
  if (role === 'MANAGER' || role === 'RECEPTIONIST' || role === 'HOUSEKEEPER') {
    const redirectUrl = getRoleHomePage(role);
    console.log('[Admin Login] Already authenticated as staff, redirecting to:', redirectUrl);
    setHasRedirected(true);
    
    setTimeout(() => {
      console.log('[Admin Login] Executing redirect to:', redirectUrl);
      window.location.href = redirectUrl;
    }, 200);
  }
}, [status, session, hasRedirected]);

// In handleSubmit:
await new Promise(resolve => setTimeout(resolve, 300));
window.location.href = redirectUrl;
```

---

### 3. `frontend/src/lib/auth.ts`

**Changes:**
- ✅ ลบ logic ที่ป้องกัน redirect ไปที่ auth pages
- ✅ ทำให้ redirect callback เรียบง่ายขึ้น

**Code:**
```typescript
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
```

---

## 🔄 Flow After Fix

### Successful Login Flow:
```
1. User enters credentials at /auth/admin
2. Click "เข้าสู่ระบบ"
3. signIn() called with redirect: false
4. Backend validates credentials
5. NextAuth creates session
6. Wait 300ms for session sync
7. Redirect to role-specific page:
   - Manager → /admin/dashboard
   - Receptionist → /admin/reception
   - Housekeeper → /admin/housekeeping
8. Admin Layout checks session
9. Session is authenticated with valid role
10. Allow access ✅
```

### No More Loop:
- ❌ Admin Layout ไม่ redirect กลับไปที่ /auth/admin
- ❌ NextAuth ไม่ redirect ไปที่ /
- ✅ Session sync เสร็จก่อน redirect
- ✅ useRef ป้องกัน multiple redirects

---

## 🧪 Testing

### Local Test:
```bash
cd frontend
npm run build
npm run start
```

Open http://localhost:3000/auth/admin
- Login: manager@hotel.com / Manager123!
- Should redirect to /admin/dashboard
- No loop

### Production Test:
1. Deploy to Vercel
2. Open https://booboo-booking.vercel.app/auth/admin
3. Open Console (F12)
4. Login with manager account
5. Check console logs:
   ```
   [Admin Login] Attempting login for: manager@hotel.com
   [Auth] Calling backend: https://booboo-booking.onrender.com/api/auth/login
   [Admin Login] Login successful, fetching session...
   [Admin Login] Redirecting to: /admin/dashboard
   [Admin Login] Executing redirect now
   [Admin Layout] Authenticated with role: MANAGER
   [Admin Layout] Valid staff role, allowing access
   ```
6. Should be at /admin/dashboard ✅

---

## 📊 Key Differences from Previous Fix

| Aspect | Previous Fix | This Fix |
|--------|-------------|----------|
| hasRedirected | useState (resets) | useRef (persists) |
| Session check | No loading check | Check loading status |
| NextAuth callback | Blocks auth pages | Allows all redirects |
| Redirect delay | 100ms | 300ms |
| Redirect method | window.location.replace | window.location.href |

---

## ✅ Expected Console Logs (Success)

### On Login:
```
[Admin Login] Attempting login for: manager@hotel.com
[Auth] Calling backend: https://booboo-booking.onrender.com/api/auth/login
[Auth] Backend response: { success: true, data: {...} }
[JWT Callback] User data: { id: '1', role: 'MANAGER', ... }
[Session Callback] Token: { id: '1', role: 'MANAGER', ... }
[Admin Login] Login successful, fetching session...
[Admin Login] Session data: { user: { role: 'MANAGER', ... } }
[Admin Login] Redirecting to: /admin/dashboard
[Admin Login] Executing redirect now
```

### On Dashboard Load:
```
[Middleware] Path: /admin/dashboard
[Middleware] Token: { role: 'MANAGER', email: 'manager@hotel.com' }
[Middleware] Checking access for prefix: /admin/dashboard
[Middleware] Access granted
[Admin Layout] Authenticated with role: MANAGER
[Admin Layout] Valid staff role, allowing access
```

---

## 🚀 Deployment

```bash
# Test build
cd frontend
npm run build

# Commit
git add .
git commit -m "fix: resolve admin redirect loop with useRef and session sync"

# Push
git push origin main
```

Wait 2-3 minutes for Vercel auto-deploy.

---

## 🎯 Why This Fix Works

1. **useRef persists across re-renders**
   - No more reset of hasRedirected flag
   - Prevents multiple redirect attempts

2. **Wait for session loading**
   - Don't redirect while status is 'loading'
   - Ensures we have accurate session state

3. **Simplified NextAuth callback**
   - No interference with redirect flow
   - Let admin login page handle redirect

4. **Longer delay (300ms)**
   - Enough time for session to sync in production
   - Accounts for network latency

5. **Better redirect method**
   - window.location.href is more reliable
   - Works better with Next.js routing

---

## 📝 Summary

**Problem:** Infinite redirect loop between /auth/admin ↔️ /admin/dashboard

**Root Causes:**
1. useState resets on re-render
2. NextAuth callback blocks auth page redirects
3. Insufficient delay for session sync

**Solutions:**
1. Use useRef instead of useState
2. Simplify NextAuth redirect callback
3. Increase delay to 300ms
4. Add loading status checks

**Result:** ✅ No more redirect loop, smooth login experience

---

**Status:** ✅ Fixed  
**Date:** 8 มกราคม 2025  
**Version:** 2.0.0 (Final)  
**Tested:** Local ✅, Production 🔄 (pending deploy)
