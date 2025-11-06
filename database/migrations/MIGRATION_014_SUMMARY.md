# Migration 014: Role-Based Access Control System

## 📋 Overview

สร้างระบบ role-based access control โดยแยก `guests` และ `staff` เป็น tables ต่างหาก

## 🗄️ Database Changes

### New Tables

1. **roles** - 4 roles (GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
2. **staff** - ข้อมูลพนักงาน
3. **staff_accounts** - authentication สำหรับพนักงาน

### New Views

1. **v_all_users** - Unified view สำหรับ authentication

### Existing Tables

- **guests** - ไม่เปลี่ยนแปลง (ไม่มี role_id)
- **guest_accounts** - ไม่เปลี่ยนแปลง

## 🎯 Design Decision

### ✅ Separate Tables (guests vs staff)

**Reasons:**
1. Clear separation of concerns
2. Better data integrity
3. Easier to maintain
4. Better performance
5. Type safety

**See:** `DATABASE_DESIGN_RATIONALE.md` for detailed explanation

## 📊 Schema

```sql
roles
├── role_id (PK)
├── role_name
├── role_code (GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
└── description

guests (unchanged)
├── guest_id (PK)
├── email
└── ... (no role_id)

guest_accounts (unchanged)
├── guest_account_id (PK)
├── guest_id (FK)
└── hashed_password

staff (new)
├── staff_id (PK)
├── email
├── role_id (FK to roles)
├── is_active
└── ...

staff_accounts (new)
├── staff_account_id (PK)
├── staff_id (FK)
└── hashed_password

v_all_users (view)
├── user_type ('guest' or 'staff')
├── user_id
├── email
├── role_code
└── hashed_password
```

## 🔐 Authentication Flow

```
1. User enters email + password
2. Query v_all_users view
3. Check password
4. Return user_type + role_code
5. Frontend redirects based on role
```

## 👥 Roles

| Role | Code | Access | Home Page |
|------|------|--------|-----------|
| Guest | GUEST | /, /bookings | / |
| Receptionist | RECEPTIONIST | /staff/* | /staff |
| Housekeeper | HOUSEKEEPER | /staff/housekeeping/* | /staff/housekeeping |
| Manager | MANAGER | /admin/* | /admin |

## 📝 Seed Data

### Guests (10 accounts)
```
Email: anan.test@example.com
Password: password123
Role: GUEST (implicit)
```

### Staff (7 accounts)

**Receptionists (2):**
```
Email: receptionist1@hotel.com
Password: staff123
Role: RECEPTIONIST
```

**Housekeepers (3):**
```
Email: housekeeper1@hotel.com
Password: staff123
Role: HOUSEKEEPER
```

**Managers (2):**
```
Email: manager@hotel.com
Password: staff123
Role: MANAGER
```

## 🚀 Running Migration

### Windows
```cmd
cd database\migrations
run_migration_014.bat
```

### Linux/Mac
```bash
cd database/migrations
chmod +x run_migration_014.sh
./run_migration_014.sh
```

### Manual
```bash
psql -U postgres -d hotel_booking -f 014_create_role_system.sql
```

## ✅ Verification

```sql
-- Check roles
SELECT * FROM roles;

-- Check staff
SELECT * FROM staff;

-- Check unified view
SELECT user_type, email, role_code 
FROM v_all_users 
ORDER BY role_code, email;

-- Count by role
SELECT 
    role_code,
    COUNT(*) as user_count
FROM v_all_users
GROUP BY role_code
ORDER BY role_code;
```

## 🔄 Rollback

```sql
-- Drop in reverse order
DROP VIEW IF EXISTS v_all_users;
DROP TABLE IF EXISTS staff_accounts CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- Guests and guest_accounts remain unchanged
```

## 📚 Related Files

- `014_create_role_system.sql` - Migration script
- `DATABASE_DESIGN_RATIONALE.md` - Design explanation
- `run_migration_014.bat` - Windows script
- `run_migration_014.sh` - Linux/Mac script

## 🎯 Next Steps

1. Run migration
2. Update backend auth service
3. Update frontend middleware
4. Test all 4 roles
5. Update documentation

---

**Status:** ✅ Ready to Run  
**Date:** November 4, 2025  
**Version:** 014
