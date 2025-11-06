# ⚡ Migration 014 - Quick Start

## 🎯 เป้าหมาย

เพิ่มระบบ role-based access control (4 roles: Guest, Receptionist, Housekeeper, Manager)

---

## 🚀 วิธีที่ง่ายที่สุด: Neon Console

### Step 1: เปิด Neon Console
```
https://console.neon.tech
```

### Step 2: เลือก Database
- Project: `booking-hotel`
- Database: `neondb`

### Step 3: เปิด SQL Editor
คลิก **SQL Editor** ในเมนูซ้าย

### Step 4: Copy & Run SQL
1. เปิดไฟล์: `database/migrations/014_create_role_system.sql`
2. Copy ทั้งหมด (Ctrl+A, Ctrl+C)
3. Paste ใน SQL Editor (Ctrl+V)
4. คลิก **Run** หรือกด F5

### Step 5: ตรวจสอบผลลัพธ์
ควรเห็น output:
```
Created roles table with 4 default roles
Created staff and staff_accounts tables
Seeded 7 staff members
...
Migration 014 Completed Successfully!
```

---

## ✅ Verify

Run SQL นี้เพื่อตรวจสอบ:

```sql
-- Check roles
SELECT * FROM roles;

-- Check staff
SELECT * FROM staff;

-- Check all users
SELECT user_type, email, role_code 
FROM v_all_users 
ORDER BY role_code;
```

**Expected Results:**
- 4 roles (GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
- 7 staff members
- 10 guests (existing)
- Total 17 users in v_all_users

---

## 🔐 Test Login

### Guest
```
Email: anan.test@example.com
Password: password123
Expected: Login success, redirect to /
```

### Receptionist
```
Email: receptionist1@hotel.com
Password: staff123
Expected: Login success, redirect to /staff
```

### Housekeeper
```
Email: housekeeper1@hotel.com
Password: staff123
Expected: Login success, redirect to /staff/housekeeping
```

### Manager
```
Email: manager@hotel.com
Password: staff123
Expected: Login success, redirect to /admin
```

---

## 🔄 Alternative Methods

### Method 1: Go Script
```cmd
cd backend\scripts
go run run-migration-014.go
```

### Method 2: Batch File (from root)
```cmd
run-migration-014.bat
```

### Method 3: Node.js
```cmd
node run-migration-014.js
```

### Method 4: DBeaver / pgAdmin
1. Connect to Neon database
2. Open SQL Editor
3. Copy & Run SQL from `014_create_role_system.sql`

---

## 📊 What Gets Created

### Tables
- `roles` - 4 roles
- `staff` - Staff information
- `staff_accounts` - Staff authentication

### Views
- `v_all_users` - Unified authentication view

### Data
- 4 roles
- 7 staff members (2 receptionists, 3 housekeepers, 2 managers)
- Existing 10 guests remain unchanged

---

## 🐛 Common Issues

### Issue: "psql not found"
**Solution:** Use Neon Console (easiest) or Go script

### Issue: "table already exists"
**Solution:** Migration already run, skip it

### Issue: "connection error"
**Solution:** Check internet connection and Neon status

---

## 📝 Next Steps

After migration:
1. ✅ Test login with all 4 roles
2. ✅ Update backend auth service
3. ✅ Update frontend middleware
4. ✅ Test protected routes

---

**Time Required:** 2-5 minutes  
**Difficulty:** Easy  
**Status:** Ready to Run
