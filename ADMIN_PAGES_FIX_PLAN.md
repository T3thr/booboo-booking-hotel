# แผนการแก้ไข Admin Pages ให้ทำงานกับ Database จริง

## ปัญหาที่พบ

### 1. Inventory Page - Empty Response
- Error: `[useInventory] Unexpected response format: {}`
- สาเหตุ: ไม่มีข้อมูล inventory ใน database หรือ API ไม่ return ข้อมูลถูกต้อง

### 2. Reception Page - ไม่มีข้อมูล
- ต้องแสดงสถานะห้องจริงจาก database
- ต้องเชื่อมกับ housekeeping system

### 3. Pricing Tiers - ไม่สามารถจัดราคาได้
- ต้องมี CRUD operations สำหรับ rate tiers
- ต้องเชื่อมกับ pricing matrix

### 4. Bookings Page - ต้องแสดง Payment Proofs
- ต้องดึงข้อมูล bookings ที่มี payment proofs
- ต้องมีระบบ approve/reject

## แผนการแก้ไข

### Phase 1: ตรวจสอบ Database Schema (15 นาที)
- [x] เช็ค tables ที่มีใน database
- [ ] เช็คว่า seed data ครบหรือไม่
- [ ] เช็ค relationships ระหว่าง tables

### Phase 2: แก้ไข Backend APIs (30 นาที)
- [ ] Inventory API - ให้ return ข้อมูลถูกต้อง
- [ ] Room Status API - เพิ่ม endpoint สำหรับ reception
- [ ] Pricing API - เพิ่ม CRUD operations
- [ ] Booking API - เพิ่ม payment proof endpoints

### Phase 3: แก้ไข Frontend Hooks (20 นาที)
- [ ] use-inventory.ts - handle empty data
- [ ] use-room-status.ts - เชื่อมกับ API จริง
- [ ] use-pricing.ts - เพิ่ม mutations
- [ ] use-bookings.ts - เพิ่ม payment proof queries

### Phase 4: แก้ไข Admin Pages (45 นาที)
- [ ] inventory/page.tsx - แสดงข้อมูลจริง + CRUD
- [ ] reception/page.tsx - แสดงสถานะห้อง + filters
- [ ] pricing/tiers/page.tsx - เพิ่ม CRUD operations
- [ ] pricing/matrix/page.tsx - แสดง matrix จริง
- [ ] bookings/page.tsx - แสดง payment proofs + approve/reject

### Phase 5: Testing (20 นาที)
- [ ] ทดสอบแต่ละหน้าว่าดึงข้อมูลได้
- [ ] ทดสอบ CRUD operations
- [ ] ทดสอบ error handling

## Database Tables ที่เกี่ยวข้อง

### Inventory System
```sql
- room_inventory (room_type_id, date, allotment, available)
- room_types (room_type_id, type_name, base_price)
```

### Room Status System
```sql
- rooms (room_id, room_number, room_type_id, status)
- housekeeping_logs (log_id, room_id, status, staff_id)
```

### Pricing System
```sql
- rate_plans (rate_plan_id, plan_name, description)
- pricing_tiers (tier_id, tier_name, multiplier)
- pricing_calendar (room_type_id, date, tier_id, rate_plan_id)
```

### Booking System
```sql
- bookings (booking_id, guest_account_id, status)
- booking_details (detail_id, booking_id, room_type_id)
- payment_proofs (proof_id, booking_id, image_url, status)
```

## API Endpoints ที่ต้องมี

### Inventory
- GET /api/inventory?start_date=X&end_date=Y
- PUT /api/inventory (update single)
- POST /api/inventory/bulk (bulk update)

### Room Status
- GET /api/rooms/status
- GET /api/housekeeping/tasks
- PUT /api/housekeeping/rooms/:id/status

### Pricing
- GET /api/pricing/tiers
- POST /api/pricing/tiers
- PUT /api/pricing/tiers/:id
- DELETE /api/pricing/tiers/:id
- GET /api/pricing/matrix
- PUT /api/pricing/rates

### Bookings
- GET /api/bookings?status=pending_payment
- GET /api/admin/payment-proofs
- POST /api/admin/payment-proofs/:id/approve
- POST /api/admin/payment-proofs/:id/reject

## Flow การทำงานของแต่ละหน้า

### 1. Manager Dashboard
```
1. แสดง summary cards (occupancy, revenue, bookings)
2. แสดง recent bookings
3. แสดง alerts (pending payments, maintenance)
```

### 2. Inventory Management
```
1. เลือก room type
2. เลือกเดือน/ปี
3. แสดง calendar view ของ allotment
4. คลิกวันเพื่อแก้ไข allotment
5. Save changes → update database
```

### 3. Reception (Room Status)
```
1. แสดงรายการห้องทั้งหมด
2. Filter by status (Available, Occupied, Dirty, Maintenance)
3. Search by room number
4. คลิกห้องเพื่อดู details
5. Update status (ถ้าเป็น receptionist)
```

### 4. Pricing Tiers
```
1. แสดงรายการ tiers ทั้งหมด
2. Create new tier (name, multiplier)
3. Edit existing tier
4. Delete tier (ถ้าไม่มีการใช้งาน)
```

### 5. Pricing Matrix
```
1. แสดง matrix: room types × rate plans
2. แสดงราคาปัจจุบัน
3. แก้ไขราคาได้ทีละ cell
4. Save changes → update database
```

### 6. Bookings Management
```
1. แสดง bookings ที่รอ approve payment
2. คลิกดู payment proof image
3. Approve → update booking status to 'Confirmed'
4. Reject → update status to 'Cancelled' + เพิ่ม reason
```

### 7. Housekeeping
```
1. แสดง tasks ของวันนี้
2. Filter by status
3. Update room status (Dirty → Cleaning → Clean)
4. Report maintenance issues
```

### 8. Check-in
```
1. แสดง arrivals ของวันที่เลือก
2. เลือก booking
3. เลือกห้องที่ available
4. Confirm check-in → call backend function
```

### 9. Check-out
```
1. แสดง departures ของวันที่เลือก
2. เลือก booking
3. Confirm check-out → call backend function
4. ห้องเปลี่ยนสถานะเป็น Dirty
```

## Next Steps

1. เริ่มจาก Phase 1: ตรวจสอบ database
2. แก้ไข backend APIs ให้ครบ
3. แก้ไข frontend hooks
4. แก้ไข admin pages ทีละหน้า
5. Test ทุกหน้า
