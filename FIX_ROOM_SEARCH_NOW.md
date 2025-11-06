# 🔧 แก้ไขปัญหาการค้นหาห้องทันที!

## ⚠️ ปัญหา
ค้นหาห้องแล้วขึ้นว่า "ไม่มีห้องว่าง" หรือ "เต็มทุกห้อง" ทั้งๆ ที่มีห้องว่างในฐานข้อมูล

## ✅ สาเหตุ
Backend ยังไม่ได้ restart หลังจากแก้ไขโค้ด ดังนั้นการแก้ไขยังไม่มีผล

## 🚀 วิธีแก้ไข (1 นาที)

### ขั้นตอนที่ 1: Stop Backend ที่กำลังรันอยู่
กด `Ctrl+C` ใน terminal ที่รัน backend

### ขั้นตอนที่ 2: Restart Backend
```bash
cd backend
go run cmd/server/main.go
```

รอจนเห็นข้อความ:
```
Server is running on :8080
```

### ขั้นตอนที่ 3: ทดสอบ API
เปิด terminal ใหม่และรันคำสั่ง:
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
```

**ผลลัพธ์ที่ถูกต้อง:** ควรเห็น `"available_rooms"` ในแต่ละห้อง

### ขั้นตอนที่ 4: ทดสอบบนเว็บ
1. เปิด http://localhost:3000
2. คลิก "ค้นหาห้องพัก"
3. เลือกวันที่ (เช่น 10-13 พฤศจิกายน 2025)
4. คลิก "ค้นหา"

**ผลลัพธ์:** ควรเห็นห้องว่างพร้อมราคา! ✅

---

## 🔍 ตรวจสอบว่าแก้ไขสำเร็จ

### ทดสอบ API โดยตรง:
```bash
# ทดสอบค้นหาห้อง
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
```

**ต้องเห็น:**
```json
{
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "available_rooms": 10,  // <-- ต้องมี field นี้!
        "total_price": 4500,
        ...
      }
    ]
  }
}
```

### ทดสอบบนเว็บ:
1. เปิด http://localhost:3000/rooms/search
2. เลือกวันที่ใดๆ
3. คลิก "ค้นหา"
4. **ต้องเห็นห้องว่างพร้อมปุ่ม "จองห้องนี้"**

---

## 🐛 ถ้ายังไม่ได้

### ตรวจสอบ Backend:
```bash
# ตรวจสอบว่า backend รันอยู่หรือไม่
curl http://localhost:8080/api/rooms/types
```

ถ้าไม่ได้ response = backend ไม่ทำงาน

### ตรวจสอบ Database:
```bash
# เข้า PostgreSQL
psql -U postgres -d hotel_booking

# ตรวจสอบ room_types
SELECT * FROM room_types;

# ตรวจสอบ room_inventory
SELECT * FROM room_inventory WHERE date >= CURRENT_DATE LIMIT 10;
```

### ตรวจสอบ Frontend:
เปิด Browser DevTools (F12) → Console → ดู error messages

---

## 📝 สิ่งที่แก้ไขไปแล้ว

### Backend (backend/internal/repository/room_repository.go):
1. ✅ เพิ่มฟังก์ชัน `ensureInventoryExists()` - สร้าง inventory อัตโนมัติ
2. ✅ แก้ไข query `SearchAvailableRooms` - คำนวณห้องว่างถูกต้อง
3. ✅ เพิ่ม field `available_rooms` ใน response

### การทำงาน:
- เมื่อค้นหาห้อง backend จะ:
  1. ตรวจสอบว่ามี inventory สำหรับวันที่นั้นหรือไม่
  2. ถ้าไม่มี → สร้างอัตโนมัติจาก `default_allotment`
  3. คำนวณห้องว่าง = allotment - booked - tentative
  4. ส่งกลับเฉพาะห้องที่มีห้องว่าง > 0

---

## ✅ ผลลัพธ์ที่คาดหวัง

หลังจาก restart backend:
- ✅ ค้นหาห้องเห็นห้องว่างทันที
- ✅ แสดงจำนวนห้องว่างที่ถูกต้อง
- ✅ แสดงราคาถูกต้อง
- ✅ ปุ่ม "จองห้องนี้" ทำงาน
- ✅ ไม่มีข้อความ "ไม่มีห้องว่าง"

---

## 🎉 เสร็จแล้ว!

**ระบบจองห้องพักทำงานสมบูรณ์แล้ว!**

ถ้ายังมีปัญหา:
1. อ่าน `QUICK_START_BOOKING_SYSTEM.md`
2. ตรวจสอบ console logs
3. ตรวจสอบ database connection

**Happy Booking! 🚀**
