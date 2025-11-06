# 🗄️ Database Design Rationale - Guest vs Staff Separation

## 🎯 Design Decision

### ✅ Separate Tables: `guests` และ `staff`

```sql
guests                          staff
├── guest_id                    ├── staff_id
├── first_name                  ├── first_name
├── last_name                   ├── last_name
├── email                       ├── email
├── phone                       ├── phone
├── created_at                  ├── role_id (FK to roles)
└── updated_at                  ├── is_active
                                ├── created_at
guest_accounts                  └── updated_at
├── guest_account_id            
├── guest_id (FK)               staff_accounts
├── hashed_password             ├── staff_account_id
├── last_login                  ├── staff_id (FK)
└── created_at                  ├── hashed_password
                                ├── last_login
                                └── created_at
```

---

## 💡 Why Separate Tables?

### 1. **Clear Separation of Concerns**

**Guests:**
- Focus: Booking and staying at hotel
- Behavior: Make bookings, view history, manage profile
- Relationship: 1-to-many with bookings
- No role needed - always "guest"

**Staff:**
- Focus: Hotel operations
- Behavior: Manage bookings, rooms, housekeeping, reports
- Relationship: May have activity logs, shift records
- Requires role - receptionist, housekeeper, manager

### 2. **Data Integrity**

```sql
-- ❌ BAD: Mixed table with role
users
├── user_id
├── role_id (1=guest, 2=receptionist, 3=housekeeper, 4=manager)
└── ...

-- Problems:
-- - Guest with role_id = 2? Confusing!
-- - Staff making bookings? Doesn't make sense
-- - Foreign keys become ambiguous
```

```sql
-- ✅ GOOD: Separate tables
guests                  staff
├── guest_id           ├── staff_id
└── (no role)          └── role_id

-- Benefits:
-- - Clear: guests are guests, staff are staff
-- - Bookings always reference guest_id
-- - Staff actions reference staff_id
-- - No confusion possible
```

### 3. **Scalability**

**Future Growth:**

```sql
-- Guests might need:
guests
├── loyalty_points
├── membership_tier
├── preferences (JSON)
└── booking_history_summary

-- Staff might need:
staff
├── employee_id
├── department
├── shift_schedule
├── performance_metrics
└── access_permissions (JSON)
```

These are completely different domains!

### 4. **Query Performance**

```sql
-- ❌ BAD: Mixed table
SELECT * FROM users WHERE role_id = 1;  -- Get all guests
-- Problem: Full table scan with role filter

-- ✅ GOOD: Separate tables
SELECT * FROM guests;  -- Get all guests
-- Benefit: Direct table access, no filtering needed
```

### 5. **Foreign Key Clarity**

```sql
-- ❌ BAD: Ambiguous
bookings
├── user_id  -- Is this guest or staff?

-- ✅ GOOD: Clear
bookings
├── guest_id  -- Always a guest
├── created_by_staff_id  -- Optional: which staff created it
```

### 6. **Security & Auditing**

```sql
-- Separate tables allow:
-- - Different audit trails
-- - Different retention policies
-- - Different backup strategies

-- Guest data: GDPR compliance, can be deleted
-- Staff data: Employment records, must be retained
```

---

## 📊 Comparison

### Option A: Single Table with Role (❌ Not Recommended)

```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    role_id INT REFERENCES roles(role_id),
    ...
);

-- Problems:
-- 1. Guests don't need role (always guest)
-- 2. Mixed concerns in one table
-- 3. Confusing foreign keys
-- 4. Hard to add role-specific fields
-- 5. Performance: always need role filter
```

### Option B: Separate Tables (✅ Recommended)

```sql
CREATE TABLE guests (
    guest_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    -- No role_id needed
    ...
);

CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    role_id INT REFERENCES roles(role_id),
    ...
);

-- Benefits:
-- 1. Clear separation
-- 2. No confusion
-- 3. Easy to extend
-- 4. Better performance
-- 5. Cleaner code
```

---

## 🔐 Authentication Strategy

### Unified Login (v_all_users view)

```sql
CREATE VIEW v_all_users AS
-- Guests (always role = GUEST)
SELECT 
    'guest' as user_type,
    guest_id as user_id,
    email,
    'GUEST' as role_code,
    hashed_password
FROM guests g
JOIN guest_accounts ga ON g.guest_id = ga.guest_id

UNION ALL

-- Staff (role from staff.role_id)
SELECT 
    'staff' as user_type,
    staff_id as user_id,
    email,
    r.role_code,
    hashed_password
FROM staff s
JOIN staff_accounts sa ON s.staff_id = sa.staff_id
JOIN roles r ON s.role_id = r.role_id
WHERE s.is_active = true;
```

**Benefits:**
- Single login endpoint
- Automatic role detection
- Type-safe user identification
- Easy to query

---

## 📝 Real-World Examples

### Example 1: Booking Creation

```sql
-- ✅ GOOD: Clear relationship
INSERT INTO bookings (guest_id, ...)
VALUES (123, ...);

-- We know 123 is a guest_id
-- No ambiguity
```

### Example 2: Check-in Action

```sql
-- ✅ GOOD: Clear actors
UPDATE bookings 
SET status = 'CheckedIn',
    checked_in_by_staff_id = 456  -- Staff who did check-in
WHERE booking_id = 789 
  AND guest_id = 123;  -- Guest being checked in

-- Clear: guest 123 checked in by staff 456
```

### Example 3: Audit Trail

```sql
-- ✅ GOOD: Separate audit tables
CREATE TABLE guest_activity_log (
    guest_id INT REFERENCES guests(guest_id),
    action VARCHAR(50),
    ...
);

CREATE TABLE staff_activity_log (
    staff_id INT REFERENCES staff(staff_id),
    action VARCHAR(50),
    ...
);

-- Different retention policies possible
```

---

## 🎨 Code Benefits

### Backend Models

```go
// ✅ GOOD: Clear types
type Guest struct {
    GuestID   int
    Email     string
    // No Role field - always guest
}

type Staff struct {
    StaffID   int
    Email     string
    RoleCode  string  // RECEPTIONIST, HOUSEKEEPER, MANAGER
}

// Clear distinction in code
```

### Frontend Types

```typescript
// ✅ GOOD: Type safety
interface Guest {
  guestId: number;
  email: string;
  // No role - always guest
}

interface Staff {
  staffId: number;
  email: string;
  role: 'RECEPTIONIST' | 'HOUSEKEEPER' | 'MANAGER';
}

// TypeScript can enforce correct usage
```

---

## ⚡ Performance Impact

### Query Performance

```sql
-- Guests table (no role filter needed)
SELECT * FROM guests WHERE email = 'user@example.com';
-- Fast: Direct lookup

-- Staff table (with role)
SELECT * FROM staff WHERE email = 'staff@hotel.com';
-- Fast: Direct lookup + role is already there

-- vs Mixed table
SELECT * FROM users WHERE email = 'user@example.com' AND role_id = 1;
-- Slower: Need role filter every time
```

### Index Efficiency

```sql
-- ✅ GOOD: Separate tables
CREATE INDEX idx_guests_email ON guests(email);
CREATE INDEX idx_staff_email ON staff(email);
CREATE INDEX idx_staff_role ON staff(role_id);

-- Each index is smaller and more efficient
```

---

## 🔄 Migration Path

### From Mixed to Separated

```sql
-- If you had mixed table, migration would be:
INSERT INTO guests (guest_id, email, ...)
SELECT user_id, email, ...
FROM users
WHERE role_id = 1;

INSERT INTO staff (staff_id, email, role_id, ...)
SELECT user_id, email, role_id, ...
FROM users
WHERE role_id IN (2, 3, 4);

-- Clean separation
```

---

## ✅ Best Practices

### 1. **Never Mix User Types**
```sql
-- ❌ DON'T
CREATE TABLE users (user_id, role_id, ...);

-- ✅ DO
CREATE TABLE guests (guest_id, ...);
CREATE TABLE staff (staff_id, role_id, ...);
```

### 2. **Use Clear Foreign Keys**
```sql
-- ❌ DON'T
bookings.user_id  -- Ambiguous

-- ✅ DO
bookings.guest_id  -- Clear
bookings.created_by_staff_id  -- Clear
```

### 3. **Separate Concerns**
```sql
-- ✅ DO
-- Guest-specific fields in guests table
-- Staff-specific fields in staff table
-- Shared fields? Use view or separate table
```

### 4. **Use Views for Unified Access**
```sql
-- ✅ DO
CREATE VIEW v_all_users AS ...
-- For authentication only
-- Not for business logic
```

---

## 📊 Summary

| Aspect | Single Table | Separate Tables |
|--------|-------------|-----------------|
| Clarity | ❌ Confusing | ✅ Clear |
| Maintainability | ❌ Hard | ✅ Easy |
| Scalability | ❌ Limited | ✅ Flexible |
| Performance | ❌ Slower | ✅ Faster |
| Type Safety | ❌ Weak | ✅ Strong |
| Foreign Keys | ❌ Ambiguous | ✅ Clear |
| Code Quality | ❌ Mixed | ✅ Clean |

---

## 🎯 Conclusion

**Separate `guests` and `staff` tables is the correct design because:**

1. ✅ **Clear separation** - No confusion between user types
2. ✅ **Better performance** - No role filtering needed
3. ✅ **Type safety** - Compiler/DB can enforce correctness
4. ✅ **Scalability** - Easy to add type-specific fields
5. ✅ **Maintainability** - Easier to understand and modify
6. ✅ **Industry standard** - Common pattern in hotel systems

**This is not over-engineering - it's proper engineering!**

---

**Status:** ✅ Design Approved  
**Pattern:** Separate Tables for Different User Types  
**Date:** November 4, 2025
