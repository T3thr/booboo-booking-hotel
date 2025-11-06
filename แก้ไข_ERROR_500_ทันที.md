# 🔧 แก้ไข Error 500 ทันที!

## ปัญหา
API `/rooms/search` ส่ง **Error 500** กลับมา แต่ไม่แสดง error message ใน backend log

## สาเหตุที่เป็นไปได้
1. **Database query error** - ตาราง room_inventory ไม่มีข้อมูล
2. **Redis connection error** - Redis ไม่ทำงาน (แต่ควร fallback ได้)
3. **Backend ไม่ได้ restart** หลังแก้โค้ด

---

## ✅ วิธีแก้ไข

### ขั้นตอนที่ 1: Restart Backend

**Stop backend:**
- ไปที่ terminal ที่รัน backend
- กด `Ctrl+C`

**Start backend ใหม่:**
```bash
cd backend
go run cmd/server/main.go
```

**รอจนเห็น:**
```
Database connection established
Redis cache connection established (หรือ running without cache)
Server is running on :8080
```

---

### ขั้นตอนที่ 2: ตรวจสอบ Backend Log

เมื่อ frontend เรียก API ให้ดู backend terminal:

**ถ้าเห็น error message:**
- อ่าน error และแก้ไขตาม
- ส่วนใหญ่จะเป็น database query error

**ถ้าไม่เห็น error message:**
- Backend อาจไม่ได้ log error
- ลองขั้นตอนที่ 3

---

### ขั้นตอนที่ 3: ทดสอบ Database Query

**Run:**
```bash
test-db-connection.bat
```

**ถ้าเห็น error:**
- ตาราง `room_inventory` อาจไม่มีข้อมูล
- ต้อง seed data ใหม่

**วิธีแก้:**
```bash
cd database/migrations
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

---

### ขั้นตอนที่ 4: ทดสอบ API อีกครั้ง

**Test with curl:**
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
```

**ผลลัพธ์ที่ถูกต้อง:**
```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "name": "Standard Room",
        "available_rooms": 10,
        "total_price": 4500,
        ...
      }
    ]
  }
}
```

---

## 🔍 Debug เพิ่มเติม

### ตรวจสอบ Backend Error Detail

**เพิ่ม log ใน handler:**

แก้ไข `backend/internal/handlers/room_handler.go`:

```go
func (h *RoomHandler) SearchRooms(c *gin.Context) {
    var req models.SearchRoomsRequest

    if err := c.ShouldBindQuery(&req); err != nil {
        log.Printf("ERROR: Bind query failed: %v", err) // เพิ่มบรรทัดนี้
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error":   "Invalid request parameters",
            "message": err.Error(),
        })
        return
    }

    response, err := h.roomService.SearchAvailableRooms(c.Request.Context(), &req)
    if err != nil {
        log.Printf("ERROR: SearchAvailableRooms failed: %v", err) // เพิ่มบรรทัดนี้
        c.Error(err)
        // ... rest of code
    }
}
```

**Restart backend และดู log อีกครั้ง**

---

## ✅ สรุป

1. **Restart backend** (สำคัญที่สุด!)
2. **ดู backend log** เมื่อเรียก API
3. **ทดสอบ database query** ถ้ายังไม่ได้
4. **Seed data ใหม่** ถ้า inventory ไม่มีข้อมูล
5. **เพิ่ม log** ถ้ายังหา error ไม่เจอ

**หลังแก้ไขแล้ว:**
- ✅ API ส่ง available_rooms field
- ✅ RoomCard แสดงห้องว่าง
- ✅ ปุ่มจองทำงาน
- ✅ ระบบจองห้องพักสมบูรณ์!

**พร้อมใช้งาน! 🚀**
