-- Quick seed for demo users with correct bcrypt hash
-- Password: password123

-- Delete existing demo data if any
DELETE FROM guest_accounts WHERE guest_id IN (1,2,3,4,5,6,7,8,9,10);
DELETE FROM guests WHERE guest_id IN (1,2,3,4,5,6,7,8,9,10);

-- Insert demo guests
INSERT INTO guests (guest_id, first_name, last_name, email, phone) VALUES
(1, 'Anan', 'Testsawat', 'anan.test@example.com', '0812345001'),
(2, 'Benja', 'Demowan', 'benja.demo@example.com', '0823456002'),
(3, 'Chana', 'Samplekit', 'chana.sample@example.com', '0834567003'),
(4, 'Dara', 'Mockporn', 'dara.mock@example.com', '0845678004'),
(5, 'Ekachai', 'Fakeboon', 'ekachai.fake@example.com', '0856789005'),
(6, 'Fon', 'Testuser', 'fon.test@example.com', '0867890006'),
(7, 'Ganda', 'Demodata', 'ganda.demo@example.com', '0878901007'),
(8, 'Hansa', 'Sampleset', 'hansa.sample@example.com', '0889012008'),
(9, 'Itsara', 'Mockguest', 'itsara.mock@example.com', '0890123009'),
(10, 'Jira', 'Fakevisit', 'jira.fake@example.com', '0801234010');

-- Insert guest accounts with correct bcrypt hash for "password123"
INSERT INTO guest_accounts (guest_account_id, guest_id, hashed_password) VALUES
(1, 1, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(2, 2, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(3, 3, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(4, 4, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(5, 5, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(6, 6, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(7, 7, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(8, 8, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(9, 9, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK'),
(10, 10, '$2a$10$TWHS.qM6JhORZkKx8kYkR.jCxonLpS8l1MpN9hRvLOQAFcGImvDyK');

SELECT 'Demo users created successfully!' as message;
SELECT 'Email: anan.test@example.com' as login_info;
SELECT 'Password: password123' as password_info;
