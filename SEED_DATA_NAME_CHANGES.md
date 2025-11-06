# การเปลี่ยนแปลงชื่อใน Seed Data

## สรุป
แก้ไขชื่อคนและอีเมลในไฟล์ seed data ทั้งหมดเพื่อหลีกเลี่ยงการใช้ชื่อคนจริง โดยเปลี่ยนเป็นชื่อสมมติที่ชัดเจนว่าเป็นข้อมูลทดสอบ

## ไฟล์ที่แก้ไข

### 1. ไฟล์ Seed Data หลัก
- ✅ `database/migrations/013_seed_demo_data.sql` - ใช้ชื่อสมมติอยู่แล้ว (Anan, Benja, Chana, Dara, Ekachai, Fon, Ganda, Hansa, Itsara, Jira)

### 2. ไฟล์ Frontend Seed Script
- ✅ `frontend/scripts/seed-database.ts` - แก้ไขแล้ว

### 3. ไฟล์เอกสาร
- ✅ `docs/user-guides/RECEPTIONIST_GUIDE.md` - แก้ไขแล้ว
- ✅ `docs/user-guides/HOUSEKEEPER_GUIDE.md` - แก้ไขแล้ว
- ✅ `docs/user-guides/GUEST_GUIDE.md` - แก้ไขแล้ว
- ✅ `docs/tasks/phase-1-setup/TASK_3_COMPLETION.md` - แก้ไขแล้ว
- ✅ `database/README.md` - แก้ไขแล้ว
- ✅ `frontend/API_DOCUMENTATION.md` - แก้ไขแล้ว

## รายการชื่อใหม่ (10 คน)

### ไฟล์ SQL (database/migrations/013_seed_demo_data.sql)
ใช้ชื่อสมมติที่ชัดเจนอยู่แล้ว:
1. Anan Testsawat - anan.test@example.com
2. Benja Demowan - benja.demo@example.com
3. Chana Samplekit - chana.sample@example.com
4. Dara Mockporn - dara.mock@example.com
5. Ekachai Fakeboon - ekachai.fake@example.com
6. Fon Testuser - fon.test@example.com
7. Ganda Demodata - ganda.demo@example.com
8. Hansa Sampleset - hansa.sample@example.com
9. Itsara Mockguest - itsara.mock@example.com
10. Jira Fakevisit - jira.fake@example.com

### ไฟล์ TypeScript (frontend/scripts/seed-database.ts)
เปลี่ยนเป็นชื่อภาษาไทยที่เป็นชื่อสมมติชัดเจน:
1. ทดสอบ ระบบหนึ่ง - test.user1@example.com
2. ผู้ใช้ ตัวอย่างสอง - demo.user2@example.com
3. แขก ทดลองสาม - guest.sample3@example.com
4. บุคคล สมมติสี่ - person.mock4@example.com
5. คน จำลองห้า - user.fake5@example.com

## การเปลี่ยนแปลงในเอกสาร

### ชื่อที่ใช้ในตัวอย่างเอกสาร
- เปลี่ยนจาก: "คุณสมชาย ใจดี" → "คุณทดสอบ ระบบหนึ่ง"
- เปลี่ยนจาก: "คุณสมหญิง รักดี" → "คุณผู้ใช้ ตัวอย่างสอง"

### อีเมลที่ใช้ในตัวอย่าง
- เปลี่ยนจาก: somchai@example.com → test.user1@example.com
- เปลี่ยนจาก: somying@example.com → demo.user2@example.com
- เปลี่ยนจาก: prayut@example.com → guest.sample3@example.com

## หมายเหตุ
- ชื่อทั้งหมดเป็นชื่อสมมติที่ชัดเจนว่าเป็นข้อมูลทดสอบ
- ไม่มีการใช้ชื่อคนจริงหรือชื่อที่อาจทำให้เกิดปัญหาทางกฎหมาย
- จำนวนผู้ใช้ยังคงเป็น 10 คนเท่าเดิม
- รูปแบบข้อมูลและโครงสร้างไม่เปลี่ยนแปลง

## Demo Credentials
Email: anan.test@example.com  
Password: password123

---
สร้างเมื่อ: 2025-01-04
