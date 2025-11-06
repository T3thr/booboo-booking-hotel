# 🧪 Test Staff Login Guide

## 📋 Prerequisites

1. ✅ Backend running on `http://localhost:8080`
2. ✅ Frontend running on `http://localhost:3000`
3. ✅ Database with migration 014 applied
4. ✅ Staff users seeded

## 🔑 Demo Credentials

### Manager
```
Email:    manager@hotel.com
Password: staff123
Role:     MANAGER
Redirect: /manager/dashboard
```

### Receptionist
```
Email:    receptionist1@hotel.com
Password: staff123
Role:     RECEPTIONIST
Redirect: /staff/dashboard
```

### Housekeeper
```
Email:    housekeeper1@hotel.com
Password: staff123
Role:     HOUSEKEEPER
Redirect: /staff/housekeeping
```

### Guest
```
Email:    anan.test@example.com
Password: password123
Role:     GUEST
Redirect: /
```

## 🧪 Test Steps

### Test 1: Manager Login
```bash
1. Go to: http://localhost:3000/auth/admin
2. Enter: manager@hotel.com / staff123
3. Click: เข้าสู่ระบบ
4. Expected: Redirect to /manager/dashboard
5. Verify: See "Manager Dashboard" page
```

### Test 2: Receptionist Login
```bash
1. Go to: http://localhost:3000/auth/admin
2. Enter: receptionist1@hotel.com / staff123
3. Click: เข้าสู่ระบบ
4. Expected: Redirect to /staff/dashboard
5. Verify: See "Staff Dashboard" page
```

### Test 3: Housekeeper Login
```bash
1. Go to: http://localhost:3000/auth/admin
2. Enter: housekeeper1@hotel.com / staff123
3. Click: เข้าสู่ระบบ
4. Expected: Redirect to /staff/housekeeping
5. Verify: See "Housekeeping" page
```

### Test 4: Guest Login
```bash
1. Go to: http://localhost:3000/auth/signin
2. Enter: anan.test@example.com / password123
3. Click: เข้าสู่ระบบ
4. Expected: Redirect to /
5. Verify: See homepage
```

### Test 5: Already Logged In
```bash
1. Login as any user
2. Try to go to: /auth/admin or /auth/signin
3. Expected: Auto-redirect to role-specific dashboard
4. Verify: Cannot access auth pages when logged in
```

## 🔍 Backend Verification

### Check v_all_users View
```sql
-- Connect to database
psql -U postgres -d hotel_booking

-- Query all users
SELECT 
    user_type,
    email,
    role_code,
    role_name,
    first_name || ' ' || last_name as full_name
FROM v_all_users
ORDER BY role_code, email;

-- Expected output:
-- user_type | email                        | role_code    | role_name    | full_name
-- ----------|------------------------------|--------------|--------------|------------------
-- guest     | anan.test@example.com        | GUEST        | Guest        | Anan Testsawat
-- staff     | housekeeper1@hotel.com       | HOUSEKEEPER  | Housekeeper  | สมศรี แม่บ้าน
-- staff     | manager@hotel.com            | MANAGER      | Manager      | สมบูรณ์ ผู้จัดการ
-- staff     | receptionist1@hotel.com      | RECEPTIONIST | Receptionist | สมหญิง ต้อนรับ
```

### Test Backend Login API
```bash
# Test Manager Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "manager@hotel.com",
    "password": "staff123"
  }'

# Expected Response:
{
  "id": 6,
  "email": "manager@hotel.com",
  "first_name": "สมบูรณ์",
  "last_name": "ผู้จัดการ",
  "role": "staff",
  "role_code": "MANAGER",
  "user_type": "staff",
  "access_token": "eyJhbGc..."
}
```

## 🐛 Troubleshooting

### Problem 1: "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
```bash
# Check if staff exists in database
psql -U postgres -d hotel_booking -c "SELECT * FROM staff WHERE email = 'manager@hotel.com';"

# Check if staff_account exists
psql -U postgres -d hotel_booking -c "SELECT staff_id FROM staff_accounts WHERE staff_id = 6;"

# Check v_all_users view
psql -U postgres -d hotel_booking -c "SELECT * FROM v_all_users WHERE email = 'manager@hotel.com';"
```

### Problem 2: Redirect Not Working
```bash
# Check browser console for errors
# Check Network tab for API response
# Verify role_code in response matches expected value
```

### Problem 3: Backend Not Detecting Staff
```bash
# Check backend logs
# Look for: "[LOGIN] Found user ID: X, Type: staff, Role: MANAGER"
# If not found, check v_all_users view
```

## ✅ Success Criteria

- [ ] Manager can login and see manager dashboard
- [ ] Receptionist can login and see staff dashboard
- [ ] Housekeeper can login and see housekeeping page
- [ ] Guest can login and see homepage
- [ ] Each role redirects to correct URL
- [ ] Already logged in users cannot access auth pages
- [ ] Backend correctly detects user_type and role_code
- [ ] JWT token contains correct user information

## 📊 Expected URL Structure

```
Role          | Login Page    | Dashboard URL
--------------|---------------|---------------------------
GUEST         | /auth/signin  | /
RECEPTIONIST  | /auth/admin   | /staff/dashboard
HOUSEKEEPER   | /auth/admin   | /staff/housekeeping
MANAGER       | /auth/admin   | /manager/dashboard
```

## 🎯 Quick Test Command

```bash
# Test all logins at once
echo "Testing Manager..."
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"manager@hotel.com","password":"staff123"}' | jq '.role_code'

echo "Testing Receptionist..."
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"receptionist1@hotel.com","password":"staff123"}' | jq '.role_code'

echo "Testing Housekeeper..."
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"housekeeper1@hotel.com","password":"staff123"}' | jq '.role_code'

echo "Testing Guest..."
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"anan.test@example.com","password":"password123"}' | jq '.role_code'

# Expected output:
# "MANAGER"
# "RECEPTIONIST"
# "HOUSEKEEPER"
# "GUEST"
```

---

**Status:** ✅ Ready for Testing  
**Date:** November 5, 2025
