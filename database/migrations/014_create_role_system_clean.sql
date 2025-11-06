-- ===================================================================
-- Migration 014: Create Role-Based Access Control System (Clean Version)
-- Description: เพิ่มระบบ role สำหรับ 4 กลุ่มผู้ใช้งาน (No psql commands)
-- Date: November 4, 2025
-- ===================================================================

-- ===================================================================
-- SECTION 1: CREATE ROLES TABLE
-- ===================================================================

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

-- ===================================================================
-- SECTION 2: GUEST ACCOUNTS (No Role - Always Guest)
-- ===================================================================

-- Guests don't need role_id - they are always guests
-- This keeps the guest table clean and focused on booking functionality

-- ===================================================================
-- SECTION 3: CREATE STAFF TABLE
-- ===================================================================

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

-- ===================================================================
-- SECTION 4: SEED STAFF DATA
-- ===================================================================

-- Password: "staff123" hashed with bcrypt
-- Hash: $2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq

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
(1, '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'),
(2, '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'),
(3, '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'),
(4, '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'),
(5, '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'),
(6, '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq'),
(7, '$2a$10$WJJBhmpdwdyvNBoSSzX6Ie1srcJOtCFONDLxW4gyOhBntbhDjpJPq')
ON CONFLICT (staff_id) DO NOTHING;

-- ===================================================================
-- SECTION 5: CREATE UNIFIED AUTH VIEW
-- ===================================================================

CREATE OR REPLACE VIEW v_all_users AS
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

-- ===================================================================
-- Migration 014 Completed Successfully!
-- ===================================================================
