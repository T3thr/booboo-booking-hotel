# 🔧 แก้ไขปัญหาห้องเต็ม - Complete Solution

## 🎯 ปัญหา
- ไม่สามารถกดปุ่มจองได้ในหน้า `/rooms/search`
- ห้องแสดงว่าเต็มทั้งหมด
- `available_rooms` = 0 ทุกห้อง

## 🔍 สาเหตุ
1. **Database:** ไม่มี `room_inventory` records สำหรับวันที่ในอนาคต
2. **Backend:** คำนวณ `available_rooms` จาก `allotment - booked_count - tentative_count`
3. **Frontend:** ใช้ `room.available_rooms` เพื่อ enable/disable ปุ่มจอง

## ✅ วิธีแก้ไข

### Step 1: สร้าง Inventory Records

```bash
# รันไฟล์นี้
fix-room-availability-complete.bat
```

หรือรัน SQL โดยตรง:
```bash
psql -U postgres -d hotel_booking -f fix-room-availability-complete.sql
```

### Step 2: Restart Backend

```bash
cd backend
go run cmd/server/main.go
```

### Step 3: ทดสอบ

1. เปิด http://localhost:3000/rooms/search
2. เลือกวันที่ในอนาคต (เช่น 10-12 พ.ย. 2025)
3. กรอกจำนวนผู้เข้าพัก
4. กดค้นหา
5. ✅ ควรเห็นปุ่ม "จองห้องนี้" สีเขียว (ไม่ disabled)

## 🔬 การทำงานของระบบ

### Database Calculation:
```sql
-- ห้องว่าง = allotment - booked_count - tentative_count
SELECT 
    (allotment - booked_count - tentative_count) as available
FROM room_inventory
WHERE room_type_id = 1 AND date = '2025-11-10';
```

### Backend Response:
```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "available_rooms": 10,  // ✅ มีห้องว่าง
        "total_price": 6000.00
      }
    ]
  }
}
```

### Frontend Logic:
```typescript
// room-card.tsx
const availableRooms = room.available_rooms ?? 0;

<Button
  disabled={availableRooms === 0}  // ✅ Enable ถ้า > 0
>
  {availableRooms === 0 ? 'เต็ม' : 'จองห้องนี้'}
</Button>
```

## 📊 ตรวจสอบข้อมูล

### ดู Inventory ใน Database:
```sql
SELECT 
    rt.name,
    ri.date,
    ri.allotment,
    ri.booked_count,
    ri.tentative_count,
    (ri.allotment - ri.booked_count - ri.tentative_count) as available
FROM room_inventory ri
JOIN room_types rt ON ri.room_type_id = rt.room_type_id
WHERE ri.date >= CURRENT_DATE
ORDER BY rt.name, ri.date
LIMIT 20;
```

### ทดสอบ Backend API:
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-12&guests=2"
```

## 🎉 ผลลัพธ์ที่คาดหวัง

- ✅ ห้องทุกประเภทมี `available_rooms > 0`
- ✅ ปุ่ม "จองห้องนี้" สามารถกดได้
- ✅ แสดงจำนวนห้องว่าง (เช่น "ห้องว่าง: 10 ห้อง")
- ✅ สามารถเข้าสู่ขั้นตอนการจองได้

## 🚨 หากยังไม่ได้

1. ตรวจสอบ Console ใน Browser (F12) ดู error
2. ตรวจสอบ Backend logs
3. รัน `test-room-availability.bat` เพื่อดูข้อมูลโดยตรง
4. ตรวจสอบว่า Backend ทำงานที่ port 8080
5. ตรวจสอบว่า Frontend เชื่อมต่อ Backend ถูกต้อง (`.env`)
