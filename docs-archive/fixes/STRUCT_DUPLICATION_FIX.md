# แก้ไขปัญหา Struct Duplication ใน Backend

## ปัญหาที่เกิดขึ้น
เมื่อ deploy backend ผ่าน Render เกิด error:
```
CancellationPolicy redeclared in this block
Voucher redeclared in this block  
RatePlan redeclared in this block
RoomInventory redeclared in this block
```

## สาเหตุ
มี struct ที่ถูก declare ซ้ำในหลายไฟล์:
- `CancellationPolicy` - อยู่ใน booking.go, policy.go, และ pricing.go
- `Voucher` - อยู่ใน booking.go และ policy.go
- `RatePlan` - อยู่ใน booking.go และ pricing.go  
- `RoomInventory` - อยู่ใน room.go และ inventory.go

## การแก้ไข

### 1. ลบ struct ที่ซ้ำออกจาก booking.go
- ลบ `CancellationPolicy`
- ลบ `Voucher` 
- ลบ `RatePlan`

### 2. ลบ struct ที่ซ้ำออกจาก pricing.go
- ลบ `CancellationPolicy`
- ลบ `RatePlan`

### 3. ลบ struct ที่ซ้ำออกจาก room.go
- ลบ `RoomInventory`
- ลบ unused import "time"

### 4. เพิ่ม RatePlan กลับใน policy.go
- เพิ่ม `RatePlan` struct ที่สมบูรณ์

## ผลลัพธ์
- `CancellationPolicy` - อยู่ใน policy.go เท่านั้น
- `Voucher` - อยู่ใน policy.go เท่านั้น
- `RatePlan` - อยู่ใน policy.go เท่านั้น
- `RoomInventory` - อยู่ใน inventory.go เท่านั้น

## การทดสอบ
รันคำสั่งเหล่านี้เพื่อทดสอบ:

```bash
# ทดสอบ compilation
cd backend
go build -o main ./cmd/server

# ทดสอบ Docker build
cd ..
docker build -t hotel-backend ./backend
```

## การ Deploy
1. Push การเปลี่ยนแปลงไปยัง GitHub
2. Render จะ auto-deploy ใหม่
3. Backend ควรจะ build สำเร็จแล้ว

## ไฟล์ที่แก้ไข
- `backend/internal/models/booking.go` - ลบ struct ที่ซ้ำ
- `backend/internal/models/pricing.go` - ลบ struct ที่ซ้ำ  
- `backend/internal/models/room.go` - ลบ struct ที่ซ้ำ และ unused import "time"
- `backend/internal/models/policy.go` - เพิ่ม RatePlan กลับ

## หมายเหตุ
การแก้ไขนี้ไม่ได้เปลี่ยนแปลง functionality ใดๆ เพียงแค่จัดระเบียบ struct definitions ให้ไม่ซ้ำกัน