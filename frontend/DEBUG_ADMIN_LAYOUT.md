# 🐛 Debug Guide - Admin Layout

## 🔍 Common Issues & Solutions

### Issue 1: Sidebar Not Showing

**Symptoms:**
- Sidebar is invisible
- Only main content shows
- No menu items

**Check:**
1. Is `AdminSidebar` imported in `admin/layout.tsx`?
```tsx
import { AdminSidebar } from '@/components/admin-sidebar';
```

2. Is sidebar rendered?
```tsx
<AdminSidebar />
```

3. Check browser console for errors

**Solution:**
```bash
# Check if file exists
ls frontend/src/components/admin-sidebar.tsx

# Check imports
grep -r "AdminSidebar" frontend/src/app/admin/layout.tsx
```

---

### Issue 2: Menu Items Not Showing

**Symptoms:**
- Sidebar shows but empty
- No menu items for role
- Wrong menu items

**Check:**
1. Is user logged in?
```tsx
const { data: session } = useSession();
console.log('Session:', session);
```

2. Is role correct?
```tsx
const userRole = session?.user?.role;
console.log('User Role:', userRole);
```

3. Check `getNavigationItems()` logic

**Debug:**
```tsx
// Add to admin-sidebar.tsx
const navigationItems = getNavigationItems();
console.log('Navigation Items:', navigationItems);
console.log('User Role:', userRole);
```

---

### Issue 3: Access Denied / Unauthorized

**Symptoms:**
- Redirected to `/unauthorized`
- Cannot access pages
- 403 errors

**Check:**
1. Middleware configuration
```typescript
// Check roleAccess in middleware.ts
console.log('[Middleware] Path:', pathname);
console.log('[Middleware] User Role:', userRole);
```

2. Role in session
```tsx
// In page component
const { data: session } = useSession();
console.log('Session Role:', session?.user?.role);
```

**Solution:**
```typescript
// Verify middleware.ts has correct paths
const roleAccess: Record<string, string[]> = {
  '/admin/dashboard': ['MANAGER'],
  '/admin/reception': ['RECEPTIONIST', 'MANAGER'],
  // ... etc
};
```

---

### Issue 4: Styling Broken

**Symptoms:**
- Colors wrong
- Layout broken
- Dark mode not working

**Check:**
1. Is `globals.css` imported?
```tsx
// In app/layout.tsx
import './globals.css';
```

2. Are CSS variables defined?
```css
/* In globals.css */
--color-background: #ffffff;
--color-foreground: #171717;
--color-primary: #3b82f6;
```

3. Check Tailwind config
```bash
# Verify tailwind is working
cd frontend
npx tailwindcss -i ./src/app/globals.css -o ./test-output.css
```

---

### Issue 5: Mobile Menu Not Working

**Symptoms:**
- Hamburger button doesn't work
- Sidebar doesn't open on mobile
- Overlay not showing

**Check:**
1. State management
```tsx
const [mobileOpen, setMobileOpen] = useState(false);
console.log('Mobile Open:', mobileOpen);
```

2. Z-index issues
```tsx
// Check z-index values
className="z-40"  // Overlay
className="z-50"  // Sidebar
```

3. Click handlers
```tsx
onClick={() => setMobileOpen(!mobileOpen)}
onClick={() => setMobileOpen(false)}
```

---

### Issue 6: Sidebar Not Collapsing

**Symptoms:**
- Collapse button doesn't work
- Sidebar stays same width
- Icons not centering

**Check:**
1. State management
```tsx
const [collapsed, setCollapsed] = useState(false);
console.log('Collapsed:', collapsed);
```

2. CSS classes
```tsx
className={collapsed ? 'w-20' : 'w-64'}
className={collapsed ? 'justify-center' : ''}
```

---

### Issue 7: Active State Not Working

**Symptoms:**
- Menu items not highlighting
- Active page not shown
- All items same color

**Check:**
1. `isActive` function
```tsx
const isActive = (href: string) => {
  console.log('Checking:', href, 'Current:', pathname);
  return pathname === href || pathname.startsWith(href + '/');
};
```

2. Pathname from router
```tsx
const pathname = usePathname();
console.log('Current Pathname:', pathname);
```

---

### Issue 8: Session Issues

**Symptoms:**
- User not logged in
- Session null
- Role undefined

**Check:**
1. NextAuth configuration
```tsx
// In [...nextauth]/route.ts
callbacks: {
  jwt: async ({ token, user }) => {
    console.log('JWT Callback:', { token, user });
    return token;
  },
  session: async ({ session, token }) => {
    console.log('Session Callback:', { session, token });
    return session;
  }
}
```

2. Session provider
```tsx
// In app/layout.tsx
<SessionProvider>
  {children}
</SessionProvider>
```

---

## 🔧 Debug Tools

### 1. Browser Console
```javascript
// Check session
console.log('Session:', session);

// Check role
console.log('Role:', session?.user?.role);

// Check pathname
console.log('Pathname:', window.location.pathname);
```

### 2. React DevTools
- Install React DevTools extension
- Check component props
- Check state values
- Check context values

### 3. Network Tab
- Check API calls
- Check response status
- Check response data
- Check cookies

### 4. TypeScript Compiler
```bash
cd frontend
npx tsc --noEmit
```

### 5. ESLint
```bash
cd frontend
npm run lint
```

---

## 📊 Debug Checklist

### Before Testing
- [ ] Backend is running (port 8080)
- [ ] Frontend is running (port 3000)
- [ ] Database is running
- [ ] No TypeScript errors
- [ ] No console errors

### During Testing
- [ ] Check browser console
- [ ] Check network tab
- [ ] Check React DevTools
- [ ] Check session data
- [ ] Check role data

### After Issues
- [ ] Clear browser cache
- [ ] Clear cookies
- [ ] Restart frontend
- [ ] Restart backend
- [ ] Check logs

---

## 🚨 Emergency Fixes

### Quick Fix 1: Clear Everything
```bash
# Stop all
Ctrl+C

# Clear node_modules
cd frontend
rm -rf node_modules
rm -rf .next

# Reinstall
npm install

# Restart
npm run dev
```

### Quick Fix 2: Reset Session
```javascript
// In browser console
localStorage.clear();
sessionStorage.clear();
// Then refresh page
```

### Quick Fix 3: Check Ports
```bash
# Check if ports are in use
netstat -ano | findstr :3000
netstat -ano | findstr :8080

# Kill process if needed
taskkill /PID <PID> /F
```

---

## 📝 Debug Log Template

```
Date: ___________
Issue: ___________

Environment:
- OS: ___________
- Browser: ___________
- Node Version: ___________

Steps to Reproduce:
1. ___________
2. ___________
3. ___________

Expected Behavior:
___________

Actual Behavior:
___________

Console Errors:
___________

Network Errors:
___________

Session Data:
___________

Solution Tried:
___________

Result:
___________
```

---

## 🆘 Get Help

### 1. Check Documentation
- `ADMIN_LAYOUT_REFACTOR_COMPLETE.md`
- `สรุป_ADMIN_LAYOUT_ใหม่.md`
- `frontend/TEST_ADMIN_ROLES.md`

### 2. Check Code
- `frontend/src/components/admin-sidebar.tsx`
- `frontend/src/app/admin/layout.tsx`
- `frontend/src/middleware.ts`

### 3. Check Logs
- Browser console
- Terminal output
- Network tab

---

**Happy Debugging! 🐛🔧**
