# 🔧 แก้ไข Available Rooms ทันที!

## ปัญหา
API ส่งข้อมูลห้องกลับมา แต่**ไม่มี `available_rooms` field** ทำให้ RoomCard แสดงว่าเต็มทุกห้อง

## สาเหตุ
Backend ไม่ได้ restart หลังแก้ไขโค้ด `available_rooms` field

---

## ✅ วิธีแก้ไข (1 นาที)

### วิธีที่ 1: ใช้สคริปต์ (แนะนำ)

**Double-click:**
```
restart-backend-now.bat
```

รอจนเห็น backend start แล้วดูผลลัพธ์

---

### วิธีที่ 2: Manual

**1. Stop Backend**
- ไปที่ terminal ที่รัน backend
- กด `Ctrl+C`

**2. Start Backend ใหม่**
```bash
cd backend
go run cmd/server/main.go
```

**3. รอจนเห็น:**
```
Server is running on :8080
```

**4. ทดสอบ API:**
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
```

---

## 🎯 ผลลัพธ์ที่ถูกต้อง

**ต้องเห็น `available_rooms` field:**

```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "available_rooms": 10,  // ← ต้องมี field นี้!
        "total_price": 4500,
        ...
      }
    ]
  }
}
```

---

## 🧪 ทดสอบบนเว็บ

1. เปิด http://localhost:3000/rooms/search
2. เลือกวันที่
3. คลิก "ค้นหาห้องพัก"
4. **ต้องเห็น:**
   - ห้องว่างพร้อมราคา
   - ปุ่ม "จองห้องนี้" (ไม่ disabled)
   - จำนวนห้องว่าง (เช่น "ห้องว่าง 10 ห้อง")

---

## ✅ เสร็จแล้ว!

หลังจาก restart backend:
- ✅ API ส่ง available_rooms field
- ✅ RoomCard แสดงห้องว่าง
- ✅ ปุ่มจองทำงาน
- ✅ ระบบจองห้องพักสมบูรณ์!

**พร้อมใช้งาน! 🚀**
