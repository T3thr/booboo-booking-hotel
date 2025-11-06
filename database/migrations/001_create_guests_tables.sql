-- ===================================================================
-- Migration: Create Guests and Authentication Tables
-- Description: สร้างตารางสำหรับจัดการข้อมูลผู้เข้าพักและการยืนยันตัวตน
-- Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6
-- ===================================================================

-- Table: guests
-- เก็บข้อมูลส่วนตัวของผู้เข้าพัก
CREATE TABLE IF NOT EXISTS guests (
    guest_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: guest_accounts
-- เก็บข้อมูลการเข้าสู่ระบบของผู้เข้าพัก
CREATE TABLE IF NOT EXISTS guest_accounts (
    guest_account_id SERIAL PRIMARY KEY,
    guest_id INT UNIQUE NOT NULL REFERENCES guests(guest_id) ON DELETE CASCADE,
    hashed_password VARCHAR(255) NOT NULL,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_guests_email ON guests(email);
CREATE INDEX IF NOT EXISTS idx_guest_accounts_guest_id ON guest_accounts(guest_id);

-- Comments for documentation
COMMENT ON TABLE guests IS 'เก็บข้อมูลส่วนตัวของผู้เข้าพัก';
COMMENT ON TABLE guest_accounts IS 'เก็บข้อมูลการยืนยันตัวตนและการเข้าสู่ระบบ';

COMMENT ON COLUMN guests.guest_id IS 'รหัสผู้เข้าพักอัตโนมัติ';
COMMENT ON COLUMN guests.email IS 'อีเมลที่ไม่ซ้ำกันสำหรับการเข้าสู่ระบบ';
COMMENT ON COLUMN guest_accounts.hashed_password IS 'รหัสผ่านที่เข้ารหัสด้วย bcrypt';
COMMENT ON COLUMN guest_accounts.last_login IS 'เวลาเข้าสู่ระบบครั้งล่าสุด';

-- ===================================================================
-- Seed Data: ข้อมูลทดสอบสำหรับผู้เข้าพัก
-- ===================================================================

-- เพิ่มผู้เข้าพักตัวอย่าง (5-10 guests)
INSERT INTO guests (first_name, last_name, email, phone) VALUES
('สมชาย', 'ใจดี', 'somchai@example.com', '0812345678'),
('สมหญิง', 'รักสวย', 'somying@example.com', '0823456789'),
('ประยุทธ', 'มั่นคง', 'prayut@example.com', '0834567890'),
('ยิ่งลักษณ์', 'ชินวัตร', 'yingluck@example.com', '0845678901'),
('อภิสิทธิ์', 'เวชชาชีวะ', 'abhisit@example.com', '0856789012'),
('ทักษิณ', 'ชินวัตร', 'thaksin@example.com', '0867890123'),
('พิธา', 'ลิ้มเจริญรัตน์', 'pitha@example.com', '0878901234'),
('เศรษฐา', 'ทวีสิน', 'srettha@example.com', '0889012345'),
('จุรินทร์', 'ลักษณวิศิษฏ์', 'jurin@example.com', '0890123456'),
('อนุทิน', 'ชาญวีรกูล', 'anutin@example.com', '0801234567')
ON CONFLICT (email) DO NOTHING;

-- เพิ่มบัญชีสำหรับผู้เข้าพัก
-- รหัสผ่านทั้งหมดคือ "password123" (hashed ด้วย bcrypt cost 10)
-- Hash: $2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K
INSERT INTO guest_accounts (guest_id, hashed_password) VALUES
(1, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(2, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(3, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(4, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(5, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(6, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(7, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(8, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(9, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K'),
(10, '$2a$10$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vhHvhE6Q9p3JqG5kF5kF5K')
ON CONFLICT (guest_id) DO NOTHING;

-- ===================================================================
-- Verification Queries
-- ===================================================================

-- ตรวจสอบจำนวนผู้เข้าพัก
SELECT COUNT(*) as total_guests FROM guests;

-- ตรวจสอบจำนวนบัญชี
SELECT COUNT(*) as total_accounts FROM guest_accounts;

-- แสดงผู้เข้าพักพร้อมสถานะบัญชี
SELECT 
    g.guest_id,
    g.first_name,
    g.last_name,
    g.email,
    g.phone,
    CASE 
        WHEN ga.guest_account_id IS NOT NULL THEN 'มีบัญชี'
        ELSE 'ยังไม่มีบัญชี'
    END as account_status,
    g.created_at
FROM guests g
LEFT JOIN guest_accounts ga ON g.guest_id = ga.guest_id
ORDER BY g.guest_id;
