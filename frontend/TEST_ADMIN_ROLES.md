# 🧪 Admin Layout Testing Guide

## 📋 Test Credentials

### Manager (ผู้จัดการ)
```
Email: manager@hotel.com
Password: manager123
Expected: Full access to all features
```

### Receptionist (พนักงานต้อนรับ)
```
Email: receptionist@hotel.com
Password: receptionist123
Expected: Access to reception features only
```

### Housekeeper (แม่บ้าน)
```
Email: housekeeper@hotel.com
Password: housekeeper123
Expected: Access to housekeeping features only
```

---

## 🧪 Test Scenarios

### Test 1: Manager Access
1. Login as manager
2. Should redirect to `/admin/dashboard`
3. Sidebar should show:
   - Dashboard ✓
   - จัดการราคา ✓
   - สต็อกห้องพัก ✓
   - รายงาน ✓
   - ตั้งค่า ✓
   - ต้อนรับ ✓
   - เช็คอิน ✓
   - เช็คเอาท์ ✓
   - ย้ายห้อง ✓
   - No-Show ✓
   - ทำความสะอาด ✓
   - ตรวจสอบห้อง ✓
4. Try accessing all pages - should work
5. Click "กลับหน้าหลัก" - should go to `/`
6. From home, click "จัดการโรงแรม" - should go to `/admin`

### Test 2: Receptionist Access
1. Login as receptionist
2. Should redirect to `/admin/reception`
3. Sidebar should show:
   - ต้อนรับ ✓
   - เช็คอิน ✓
   - เช็คเอาท์ ✓
   - ย้ายห้อง ✓
   - No-Show ✓
4. Try accessing `/admin/dashboard` - should redirect to unauthorized
5. Try accessing `/admin/pricing` - should redirect to unauthorized
6. Click "กลับหน้าหลัก" - should go to `/`

### Test 3: Housekeeper Access
1. Login as housekeeper
2. Should redirect to `/admin/housekeeping`
3. Sidebar should show:
   - ทำความสะอาด ✓
   - ตรวจสอบห้อง ✓
4. Try accessing `/admin/dashboard` - should redirect to unauthorized
5. Try accessing `/admin/reception` - should redirect to unauthorized
6. Click "กลับหน้าหลัก" - should go to `/`

### Test 4: Guest Access
1. Login as guest
2. Try accessing `/admin` - should redirect to unauthorized
3. Should see "ค้นหาห้องพัก" and "การจองของฉัน" in navbar
4. Should NOT see "จัดการโรงแรม" button

### Test 5: Responsive Design
1. Desktop (1920px):
   - Sidebar visible on left
   - Can collapse/expand
   - Main content adjusts margin
2. Tablet (768px):
   - Hamburger menu appears
   - Sidebar becomes overlay
   - Closes on navigation
3. Mobile (375px):
   - Hamburger menu appears
   - Sidebar full width overlay
   - Closes on navigation

### Test 6: Dark Mode
1. Toggle dark mode
2. Check sidebar colors
3. Check card colors
4. Check button colors
5. Check text readability

### Test 7: Navigation
1. Click menu items
2. Active state should highlight
3. URL should change
4. Page content should load
5. Sidebar should stay visible

### Test 8: Logout
1. Click logout button
2. Should redirect to `/`
3. Session should be cleared
4. Accessing `/admin` should redirect to signin

---

## 🐛 Common Issues

### Issue 1: Sidebar not showing
**Solution:** Check if `AdminSidebar` is imported in `admin/layout.tsx`

### Issue 2: Menu items not showing
**Solution:** Check role in session and `getNavigationItems()` logic

### Issue 3: Access denied
**Solution:** Check middleware role access configuration

### Issue 4: Styling broken
**Solution:** Check if globals.css is imported in root layout

### Issue 5: Mobile menu not working
**Solution:** Check z-index and overlay click handler

---

## 📊 Test Results Template

```
Date: ___________
Tester: ___________

Manager Tests:
[ ] Login successful
[ ] Dashboard accessible
[ ] All menus visible
[ ] All pages accessible
[ ] Sidebar collapsible
[ ] Logout works

Receptionist Tests:
[ ] Login successful
[ ] Reception accessible
[ ] Only reception menus visible
[ ] Manager pages blocked
[ ] Logout works

Housekeeper Tests:
[ ] Login successful
[ ] Housekeeping accessible
[ ] Only housekeeping menus visible
[ ] Other pages blocked
[ ] Logout works

Responsive Tests:
[ ] Desktop layout works
[ ] Tablet layout works
[ ] Mobile layout works
[ ] Hamburger menu works

Dark Mode Tests:
[ ] Sidebar readable
[ ] Cards readable
[ ] Buttons readable
[ ] Text readable

Notes:
_________________________________
_________________________________
_________________________________
```

---

## 🚀 Quick Test Commands

### Start Frontend
```bash
cd frontend
npm run dev
```

### Check TypeScript
```bash
cd frontend
npx tsc --noEmit
```

### Check Linting
```bash
cd frontend
npm run lint
```

### Build Production
```bash
cd frontend
npm run build
```

---

## ✅ Success Criteria

- [ ] All roles can login
- [ ] Sidebar shows correct menus per role
- [ ] Access control works correctly
- [ ] Responsive design works
- [ ] Dark mode works
- [ ] No TypeScript errors
- [ ] No console errors
- [ ] Performance is good
- [ ] UX is smooth

---

**Happy Testing! 🎉**
