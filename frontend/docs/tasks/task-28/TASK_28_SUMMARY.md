# Task 28: สร้างหน้า Receptionist - Check-in/out Interface - สรุปการทำงาน

## ภาพรวม

Task นี้สร้างหน้า Interface สำหรับพนักงานต้อนรับ (Receptionist) ในการจัดการ Check-in, Check-out, การย้ายห้อง และ No-Show Management

## ไฟล์ที่สร้าง

### 1. หน้า Check-in (`frontend/src/app/(staff)/checkin/page.tsx`)

**ฟีเจอร์:**
- แสดงรายการแขกที่จะมาถึงตามวันที่เลือก
- เลือกแขกและเลือกห้องที่พร้อมสำหรับ check-in
- แสดงห้องที่มีสถานะ "Inspected" ก่อนห้อง "Clean"
- ยืนยัน check-in และอัปเดตสถานะห้องทันที

**การทำงาน:**
1. เลือกวันที่ (default: วันนี้)
2. แสดงรายการแขกที่จะมาถึง
3. คลิกเลือกแขก
4. เลือกห้องจากรายการห้องว่าง
5. กดปุ่ม "ยืนยันเช็คอิน"

### 2. หน้า Check-out (`frontend/src/app/(staff)/checkout/page.tsx`)

**ฟีเจอร์:**
- แสดงรายการแขกที่จะ check-out ตามวันที่เลือก
- แสดงรายละเอียดการจองและยอดรวม
- ยืนยัน check-out พร้อมคำเตือน
- ห้องจะถูกทำเครื่องหมายเป็น "Dirty" อัตโนมัติ

**การทำงาน:**
1. เลือกวันที่ (default: วันนี้)
2. แสดงรายการแขกที่จะ check-out
3. คลิกเลือกแขก
4. ตรวจสอบรายละเอียดและยอดรวม
5. กดปุ่ม "ดำเนินการเช็คเอาท์"
6. ยืนยันอีกครั้ง

### 3. หน้าย้ายห้อง (`frontend/src/app/(staff)/move-room/page.tsx`)

**ฟีเจอร์:**
- แสดงรายการแขกที่เข้าพักอยู่
- เลือกห้องใหม่จากห้องว่างประเภทเดียวกัน
- กรอกเหตุผลในการย้ายห้อง (ไม่บังคับ)
- ห้องเก่าจะถูกทำเครื่องหมายเป็น "Dirty" อัตโนมัติ

**การทำงาน:**
1. เลือกแขกที่ต้องการย้ายห้อง
2. เลือกห้องใหม่จากรายการห้องว่าง
3. กรอกเหตุผล (ถ้ามี)
4. กดปุ่ม "ดำเนินการย้ายห้อง"
5. ยืนยันอีกครั้ง

### 4. หน้า No-Show Management (`frontend/src/app/(staff)/no-show/page.tsx`)

**ฟีเจอร์:**
- แสดงการจองที่ยืนยันแล้วแต่แขกยังไม่มา check-in
- แสดงจำนวนวันที่เกินกำหนด
- แสดงข้อมูลติดต่อแขก
- ทำเครื่องหมาย No-Show พร้อมคำเตือน

**การทำงาน:**
1. ระบบแสดงการจองที่เกินกำหนด check-in
2. เลือกการจองที่ต้องการทำเครื่องหมาย No-Show
3. อ่านคำเตือนและคำแนะนำ
4. กดปุ่ม "ทำเครื่องหมาย No-Show"
5. ยืนยันอีกครั้ง

## การอัปเดตไฟล์

### 1. อัปเดต `frontend/src/hooks/use-rooms.ts`

เพิ่ม hook `useRooms()` สำหรับดึงห้องที่พร้อมสำหรับ check-in:

```typescript
export function useRooms(params: { roomTypeId?: number; status?: string })
```

### 2. อัปเดต `frontend/src/lib/api.ts`

เพิ่ม endpoint `getAvailableRooms()` ใน `checkinApi`:

```typescript
getAvailableRooms: (roomTypeId: number) => api.get(`/checkin/available-rooms/${roomTypeId}`)
```

### 3. อัปเดต `frontend/src/app/(staff)/layout.tsx`

เพิ่มเมนูนำทางสำหรับ Receptionist:
- แดชบอร์ดห้องพัก
- เช็คอิน
- เช็คเอาท์
- ย้ายห้อง
- No-Show

## API Endpoints ที่ใช้

### Check-in
- `GET /api/checkin/arrivals?date=YYYY-MM-DD` - ดึงรายการแขกที่จะมาถึง
- `GET /api/checkin/available-rooms/:roomTypeId` - ดึงห้องว่างสำหรับ check-in
- `POST /api/checkin` - ทำการ check-in

### Check-out
- `GET /api/checkout/departures?date=YYYY-MM-DD` - ดึงรายการแขกที่จะ check-out
- `POST /api/checkout` - ทำการ check-out

### Move Room
- `GET /api/bookings?status=CheckedIn` - ดึงรายการแขกที่เข้าพักอยู่
- `GET /api/checkin/available-rooms/:roomTypeId` - ดึงห้องว่างสำหรับย้าย
- `POST /api/checkin/move-room` - ย้ายห้อง

### No-Show
- `GET /api/bookings?status=Confirmed` - ดึงรายการการจองที่ยืนยันแล้ว
- `POST /api/bookings/:id/no-show` - ทำเครื่องหมาย No-Show

## UI/UX Features

### 1. Real-time Updates
- ใช้ React Query refetchInterval (30 วินาที) สำหรับข้อมูลที่เปลี่ยนแปลงบ่อย
- Auto-invalidate queries หลังจากทำ mutation

### 2. Visual Feedback
- สีแยกตามสถานะห้อง (เขียว = Inspected, เหลือง = Clean)
- Highlight การเลือก (ring-2 ring-blue-500)
- Loading states และ disabled buttons

### 3. Confirmation Dialogs
- คำเตือนก่อนทำการเปลี่ยนแปลงสำคัญ
- แสดงผลกระทบของการกระทำ
- ปุ่มยกเลิกสำหรับทุก action

### 4. Responsive Design
- Grid layout ปรับตามขนาดหน้าจอ
- Mobile-friendly
- Touch-friendly buttons

## Business Rules

### Check-in Rules
1. ห้องต้องมีสถานะ Vacant
2. ห้องต้องมีสถานะ Clean หรือ Inspected
3. การจองต้องมีสถานะ Confirmed
4. ห้อง Inspected จะแสดงก่อนห้อง Clean

### Check-out Rules
1. การจองต้องมีสถานะ CheckedIn
2. ห้องจะถูกทำเครื่องหมายเป็น Dirty อัตโนมัติ
3. แสดงยอดรวมก่อนยืนยัน

### Move Room Rules
1. ห้องใหม่ต้องว่างและสะอาด
2. ห้องใหม่ต้องเป็นประเภทเดียวกันหรือสูงกว่า
3. ห้องเก่าจะถูกทำเครื่องหมายเป็น Dirty อัตโนมัติ
4. สามารถกรอกเหตุผลได้

### No-Show Rules
1. การจองต้องมีสถานะ Confirmed
2. วันเช็คอินต้องผ่านไปแล้ว
3. แสดงจำนวนวันที่เกินกำหนด
4. ควรติดต่อแขกก่อนทำเครื่องหมาย

## Error Handling

### 1. API Errors
- แสดง error message จาก backend
- Alert สำหรับ user-friendly message
- Retry mechanism สำหรับ network errors

### 2. Validation
- Client-side validation ก่อนส่ง request
- Disable buttons เมื่อข้อมูลไม่ครบ
- แสดง loading state ระหว่างรอ response

### 3. Edge Cases
- ไม่มีแขกที่จะมาถึง/check-out
- ไม่มีห้องว่าง
- การจองที่ไม่สามารถดำเนินการได้

## Testing Checklist

### Check-in Flow
- [ ] แสดงรายการแขกที่จะมาถึงถูกต้อง
- [ ] เลือกวันที่ทำงานถูกต้อง
- [ ] แสดงห้องว่างถูกต้อง (Inspected ก่อน Clean)
- [ ] Check-in สำเร็จและอัปเดตสถานะ
- [ ] แสดง error เมื่อห้องไม่พร้อม

### Check-out Flow
- [ ] แสดงรายการแขกที่จะ check-out ถูกต้อง
- [ ] แสดงยอดรวมถูกต้อง
- [ ] Check-out สำเร็จและอัปเดตสถานะ
- [ ] ห้องถูกทำเครื่องหมายเป็น Dirty

### Move Room Flow
- [ ] แสดงรายการแขกที่เข้าพักอยู่ถูกต้อง
- [ ] แสดงห้องว่างสำหรับย้ายถูกต้อง
- [ ] ย้ายห้องสำเร็จและอัปเดตสถานะ
- [ ] ห้องเก่าถูกทำเครื่องหมายเป็น Dirty

### No-Show Flow
- [ ] แสดงการจองที่เกินกำหนดถูกต้อง
- [ ] คำนวณจำนวนวันที่เกินถูกต้อง
- [ ] ทำเครื่องหมาย No-Show สำเร็จ
- [ ] แสดงคำเตือนและคำแนะนำ

## Performance Considerations

### 1. Data Fetching
- ใช้ React Query caching
- Refetch interval 30 วินาที
- Invalidate queries หลัง mutation

### 2. Rendering
- Conditional rendering สำหรับ empty states
- Loading states สำหรับ async operations
- Optimistic updates (ถ้าเหมาะสม)

### 3. Network
- Debounce search inputs (ถ้ามี)
- Cancel pending requests on unmount
- Retry failed requests

## Security

### 1. Authentication
- ทุก endpoint ต้อง authenticate
- ใช้ JWT token จาก NextAuth

### 2. Authorization
- ทุก endpoint ต้องมี role "receptionist"
- Frontend ตรวจสอบ role ใน layout

### 3. Input Validation
- Validate ทั้ง client และ server side
- Sanitize user inputs
- Prevent SQL injection (ใช้ parameterized queries)

## Future Enhancements

### 1. Advanced Features
- Early check-in / Late check-out
- Room preference tracking
- Automatic room assignment
- Key card integration

### 2. Notifications
- SMS/Email notifications
- Real-time alerts สำหรับ staff
- Push notifications

### 3. Reporting
- Check-in/out statistics
- No-show patterns
- Room utilization reports

### 4. Mobile
- Mobile app สำหรับ staff
- Digital check-in kiosks
- QR code check-in

## Dependencies

### Frontend
- Next.js 16
- React Query (TanStack Query)
- NextAuth.js
- Tailwind CSS

### Backend
- Go API endpoints (มีอยู่แล้ว)
- PostgreSQL functions (มีอยู่แล้ว)

## Deployment Notes

### 1. Environment Variables
```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

### 2. Build
```bash
cd frontend
npm run build
```

### 3. Testing
```bash
npm run test
```

## Conclusion

Task 28 สร้าง Interface ที่สมบูรณ์สำหรับพนักงานต้อนรับในการจัดการ Check-in, Check-out, การย้ายห้อง และ No-Show Management โดยมีการออกแบบ UI/UX ที่ใช้งานง่าย มี error handling ที่ดี และรองรับ real-time updates

หน้าทั้งหมดพร้อมใช้งานและเชื่อมต่อกับ Backend API ที่มีอยู่แล้ว สามารถทดสอบได้ทันทีหลังจาก deploy
