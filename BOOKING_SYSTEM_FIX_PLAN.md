# แผนการแก้ไขและพัฒนาระบบจองห้องพัก

## 🔴 ปัญหาที่พบ

### 1. ปัญหาการค้นหาห้อง (Room Search)
- Query ตรวจสอบ `room_inventory` แต่ seed data มีเพียง 90 วัน
- Logic การคำนวณห้องว่างไม่ถูกต้อง
- ไม่มี fallback เมื่อไม่มีข้อมูล inventory

### 2. ปัญหา UX/UI
- ไม่มีระบบ Hold Booking ที่ชัดเจน
- ไม่มีหน้า Payment Mockup
- ไม่มีระบบแสดงสถานะการจองสำหรับ Admin

### 3. ปัญหา Database
- Inventory ไม่ครอบคลุมทุกวันที่
- ไม่มี trigger สำหรับสร้าง inventory อัตโนมัติ

## ✅ แผนการแก้ไข

### Phase 1: แก้ไข Backend Logic (ทันที)
1. ✅ แก้ไข SearchAvailableRooms query ให้ใช้ default_allotment เมื่อไม่มี inventory
2. ✅ เพิ่ม function สร้าง inventory อัตโนมัติ
3. ✅ แก้ไข logic การคำนวณห้องว่าง

### Phase 2: ปรับปรุง Frontend (ทันที)
1. ✅ แก้ไขหน้า Room Search ให้แสดงข้อมูลถูกต้อง
2. ✅ สร้างหน้า Hold Booking (เหมือน Agoda)
3. ✅ สร้างหน้า Payment Mockup
4. ✅ สร้างหน้า Booking Confirmation

### Phase 3: Admin Features (ทันที)
1. ✅ สร้างหน้าดูรายการจองทั้งหมด
2. ✅ สร้างหน้าตรวจสอบหลักฐานการโอน
3. ✅ สร้างหน้าอนุมัติการจอง

### Phase 4: Database Improvements
1. ✅ สร้าง trigger สำหรับ auto-create inventory
2. ✅ เพิ่ม payment_proof table
3. ✅ ปรับปรุง seed data

## 📋 Implementation Checklist

- [ ] Fix room search query
- [ ] Create auto-inventory function
- [ ] Update room search page
- [ ] Create hold booking flow
- [ ] Create payment mockup page
- [ ] Create booking confirmation page
- [ ] Create admin booking management
- [ ] Create payment verification page
- [ ] Add payment proof upload
- [ ] Update database schema
- [ ] Test end-to-end flow
- [ ] Responsive design check

## 🎯 Success Criteria

1. ผู้ใช้สามารถค้นหาห้องและเห็นห้องว่างได้ถูกต้อง
2. ระบบ Hold Booking ทำงานเหมือน Agoda/Booking.com
3. มีหน้า Payment Mockup ที่ดูเป็นมืออาชีพ
4. Admin สามารถดูและอนุมัติการจองได้
5. Responsive ทุก breakpoint
6. Performance ดี (< 2s load time)
