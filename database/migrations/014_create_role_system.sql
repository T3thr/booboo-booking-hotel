-- ===================================================================
-- Migration 014: Create Role-Based Access Control System
-- Description: เพิ่มระบบ role สำหรับ 4 กลุ่มผู้ใช้งาน
-- Date: November 4, 2025
-- ===================================================================

\echo '============================================================================'
\echo 'Migration 014: Creating Role-Based Access Control System'
\echo '============================================================================'

-- ===================================================================
-- SECTION 1: CREATE ROLES TABLE
-- ===================================================================
\echo ''
\echo 'Section 1: Creating roles table...'

CREATE TABLE IF NOT EXISTS roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    role_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default roles
INSERT INTO roles (role_id, role_name, role_code, description) VALUES
(1, 'Guest', 'GUEST', 'ผู้เข้าพัก - สามารถจองห้องและดูประวัติการจองของตนเอง'),
(2, 'Receptionist', 'RECEPTIONIST', 'พนักงานต้อนรับ - จัดการการจอง เช็คอิน/เช็คเอาท์'),
(3, 'Housekeeper', 'HOUSEKEEPER', 'แม่บ้าน - จัดการการทำความสะอาดและสถานะห้อง'),
(4, 'Manager', 'MANAGER', 'ผู้จัดการ - เข้าถึงทุกฟังก์ชันและดูรายงาน')
ON CONFLICT (role_id) DO NOTHING;

\echo 'Created roles table with 4 default roles'

-- ===================================================================
-- SECTION 2: GUEST ACCOUNTS (No Role - Always Guest)
-- ===================================================================
\echo ''
\echo 'Section 2: Guest accounts remain simple (no role column)...'

-- Guests don't need role_id - they are always guests
-- This keeps the guest table clean and focused on booking functionality

\echo 'Guest accounts remain unchanged - always GUEST role by default'

-- ===================================================================
-- SECTION 3: CREATE STAFF TABLE
-- ===================================================================
\echo ''
\echo 'Section 3: Creating staff table...'

CREATE TABLE IF NOT EXISTS staff (
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    role_id INT NOT NULL REFERENCES roles(role_id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff_accounts (
    staff_account_id SERIAL PRIMARY KEY,
    staff_id INT UNIQUE NOT NULL REFERENCES staff(staff_id) ON DELETE CASCADE,
    hashed_password VARCHAR(255) NOT NULL,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_staff_email ON staff(email);
CREATE INDEX IF NOT EXISTS idx_staff_role_id ON staff(role_id);
CREATE INDEX IF NOT EXISTS idx_staff_accounts_staff_id ON staff_accounts(staff_id);

\echo 'Created staff and staff_accounts tables'

-- ===================================================================
-- SECTION 4: SEED STAFF DATA
-- ===================================================================
\echo ''
\echo 'Section 4: Seeding staff data...'

-- Password: "staff123" hashed with bcrypt
-- Hash: $2a$10$rKJ8TqZ5vHxQxQxQxQxQxOeKqZ5vHxQxQxQxQxQxQxQxQxQxQxQxQ

-- Receptionists
INSERT INTO staff (staff_id, first_name, last_name, email, phone, role_id) VALUES
(1, 'สมหญิง', 'ต้อนรับ', 'receptionist1@hotel.com', '0821111111', 2),
(2, 'สมชาย', 'ต้อนรับ', 'receptionist2@hotel.com', '0821111112', 2)
ON CONFLICT (email) DO NOTHING;

-- Housekeepers
INSERT INTO staff (staff_id, first_name, last_name, email, phone, role_id) VALUES
(3, 'สมศรี', 'แม่บ้าน', 'housekeeper1@hotel.com', '0822222221', 3),
(4, 'สมพร', 'แม่บ้าน', 'housekeeper2@hotel.com', '0822222222', 3),
(5, 'สมใจ', 'แม่บ้าน', 'housekeeper3@hotel.com', '0822222223', 3)
ON CONFLICT (email) DO NOTHING;

-- Managers
INSERT INTO staff (staff_id, first_name, last_name, email, phone, role_id) VALUES
(6, 'สมบูรณ์', 'ผู้จัดการ', 'manager@hotel.com', '0823333331', 4),
(7, 'สมบัติ', 'ผู้ช่วย', 'assistant.manager@hotel.com', '0823333332', 4)
ON CONFLICT (email) DO NOTHING;

-- Staff accounts (password: "staff123")
INSERT INTO staff_accounts (staff_id, hashed_password) VALUES
(1, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(2, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(3, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(4, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(5, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(6, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
(7, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy')
ON CONFLICT (staff_id) DO NOTHING;

\echo 'Seeded 7 staff members (2 receptionists, 3 housekeepers, 2 managers)'

-- ===================================================================
-- SECTION 5: CREATE UNIFIED AUTH VIEW
-- ===================================================================
\echo ''
\echo 'Section 5: Creating unified authentication view...'

CREATE OR REPLACE VIEW v_all_users AS
-- Guests (always GUEST role)
SELECT 
    'guest' as user_type,
    g.guest_id as user_id,
    g.first_name,
    g.last_name,
    g.email,
    g.phone,
    'GUEST' as role_code,
    'Guest' as role_name,
    ga.hashed_password,
    ga.last_login,
    g.created_at
FROM guests g
JOIN guest_accounts ga ON g.guest_id = ga.guest_id
WHERE ga.hashed_password IS NOT NULL

UNION ALL

-- Staff (role from staff.role_id)
SELECT 
    'staff' as user_type,
    s.staff_id as user_id,
    s.first_name,
    s.last_name,
    s.email,
    s.phone,
    r.role_code,
    r.role_name,
    sa.hashed_password,
    sa.last_login,
    s.created_at
FROM staff s
JOIN staff_accounts sa ON s.staff_id = sa.staff_id
JOIN roles r ON s.role_id = r.role_id
WHERE s.is_active = true AND sa.hashed_password IS NOT NULL;

\echo 'Created unified authentication view'

-- ===================================================================
-- SECTION 6: VERIFICATION
-- ===================================================================
\echo ''
\echo '============================================================================'
\echo 'Verification'
\echo '============================================================================'

-- Count by role
\echo ''
\echo 'Users by Role:'
SELECT 
    r.role_name,
    COUNT(*) as user_count
FROM v_all_users v
JOIN roles r ON v.role_code = r.role_code
GROUP BY r.role_name, r.role_id
ORDER BY r.role_id;

-- List all users
\echo ''
\echo 'All Users:'
SELECT 
    user_type,
    email,
    role_name,
    first_name || ' ' || last_name as full_name
FROM v_all_users
ORDER BY role_code, email;

\echo ''
\echo '============================================================================'
\echo 'Migration 014 Completed Successfully!'
\echo '============================================================================'
\echo ''
\echo 'Demo Credentials:'
\echo '  Manager:      manager@hotel.com / staff123'
\echo '  Receptionist: receptionist1@hotel.com / staff123'
\echo '  Housekeeper:  housekeeper1@hotel.com / staff123'
\echo '  Guest:        anan.test@example.com / password123'
\echo '============================================================================'
