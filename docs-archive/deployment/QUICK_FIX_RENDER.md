# 🚨 แก้ไขปัญหา Render ด่วน!

## ปัญหา
```
ERROR: function release_expired_holds() does not exist (SQLSTATE 42883)
```

## สาเหตุ
Database migrations ยังไม่ได้รัน บน production database

---

## ✅ วิธีแก้ไข (เลือก 1 วิธี)

### วิธีที่ 1: รันจาก Local (ง่ายที่สุด - แนะนำ!)

1. **ติดตั้ง PostgreSQL Client** (ถ้ายังไม่มี)
   ```bash
   # Windows
   choco install postgresql
   
   # หรือดาวน์โหลดจาก
   # https://www.postgresql.org/download/windows/
   ```

2. **ดึง DATABASE_URL จาก Render**
   - เปิด https://dashboard.render.com
   - ไปที่ Database service
   - คัดลอก "External Database URL"

3. **Set Environment Variable**
   ```cmd
   # CMD
   set DATABASE_URL=postgresql://user:password@host:port/database
   
   # PowerShell
   $env:DATABASE_URL="postgresql://user:password@host:port/database"
   ```

4. **รัน Migration Script**
   ```bash
   cd backend\scripts
   run-migrations.bat
   ```

---

### วิธีที่ 2: รันผ่าน Render Shell

1. เปิด https://dashboard.render.com
2. ไปที่ Backend Service → Shell
3. รันคำสั่ง:
   ```bash
   psql $DATABASE_URL -f /app/database/migrations/008_create_release_expired_holds_function.sql
   ```

---

### วิธีที่ 3: รันทุก Migrations พร้อมกัน (แนะนำถ้าเริ่มใหม่)

```bash
# ใน Render Shell
cd /app/database/migrations

# รันทีละไฟล์
psql $DATABASE_URL -f 001_create_guests_tables.sql
psql $DATABASE_URL -f 002_create_room_management_tables.sql
psql $DATABASE_URL -f 003_create_pricing_inventory_tables.sql
psql $DATABASE_URL -f 004_create_bookings_tables.sql
psql $DATABASE_URL -f 005_create_booking_hold_function.sql
psql $DATABASE_URL -f 006_create_confirm_booking_function.sql
psql $DATABASE_URL -f 007_create_cancel_booking_function.sql
psql $DATABASE_URL -f 008_create_release_expired_holds_function.sql
psql $DATABASE_URL -f 009_create_check_in_function.sql
psql $DATABASE_URL -f 010_create_check_out_function.sql
psql $DATABASE_URL -f 011_create_move_room_function.sql
psql $DATABASE_URL -f 012_performance_optimization.sql
```

---

## ✅ ตรวจสอบว่าแก้ไขสำเร็จ

รันคำสั่งนี้:
```bash
psql $DATABASE_URL -c "SELECT routine_name FROM information_schema.routines WHERE routine_name = 'release_expired_holds';"
```

ถ้าเห็น:
```
     routine_name      
-----------------------
 release_expired_holds
(1 row)
```

แสดงว่า **สำเร็จ!** ✅

---

## 🔄 หลังแก้ไขแล้ว

1. **Redeploy Backend** (ถ้าจำเป็น)
   - ไปที่ Render Dashboard
   - คลิก "Manual Deploy" → "Deploy latest commit"

2. **ตรวจสอบ Logs**
   ```
   [HOLD-CLEANUP] Hold cleanup completed successfully
   ```

3. **ไม่ควรเห็น Error นี้อีก**:
   ```
   ERROR: function release_expired_holds() does not exist
   ```

---

## 📝 สำหรับอนาคต: Auto-run Migrations

แก้ไข `render.yaml`:
```yaml
services:
  - type: web
    name: hotel-booking-backend
    env: go
    buildCommand: |
      cd backend
      # Run migrations
      for f in ../database/migrations/*.sql; do
        psql $DATABASE_URL -f "$f" 2>/dev/null || true
      done
      # Build
      go build -o main ./cmd/server
    startCommand: cd backend && ./main
```

จากนั้น commit และ push:
```bash
git add render.yaml
git commit -m "Add auto-migration to Render build"
git push
```

---

## 🎯 Next: Deploy Frontend

หลังแก้ไข backend แล้ว ไปต่อที่:
1. [RENDER_PRODUCTION_SETUP.md](RENDER_PRODUCTION_SETUP.md) - ขั้นตอนที่ 3
2. Deploy frontend บน Vercel
3. เชื่อมต่อ frontend ↔ backend

---

**เวลาที่ใช้**: ~5-10 นาที  
**ความยาก**: ⭐⭐☆☆☆ (ง่าย)
