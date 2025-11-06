# 🚀 Run Migration 014 - Quick Guide

## ปัญหา: psql ไม่ได้ติดตั้ง

ถ้า `psql` ไม่ได้ติดตั้งบน Windows ให้ใช้วิธีอื่นแทน

---

## วิธีที่ 1: ใช้ Go Script (แนะนำ)

### จาก Root Directory

```cmd
cd backend\scripts
go run run-migration-014.go
```

### หรือใช้ batch file

```cmd
run-migration-014.bat
```

---

## วิธีที่ 2: ใช้ Neon Console (ง่ายที่สุด)

1. เปิด https://console.neon.tech
2. เลือก project: `booking-hotel`
3. ไปที่ **SQL Editor**
4. Copy SQL จาก `database/migrations/014_create_role_system.sql`
5. Paste และ Run

---

## วิธีที่ 3: ใช้ DBeaver / pgAdmin

1. เปิด DBeaver หรือ pgAdmin
2. Connect to Neon database:
   ```
   Host: ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech
   Port: 5432
   Database: neondb
   User: neondb_owner
   Password: npg_8kHamXSLKg1x
   SSL: require
   ```
3. Open SQL Editor
4. Copy SQL from `database/migrations/014_create_role_system.sql`
5. Execute

---

## วิธีที่ 4: ใช้ Node.js Script

สร้างไฟล์ `run-migration-014.js`:

```javascript
const { Client } = require('pg');
const fs = require('fs');

const client = new Client({
  connectionString: 'postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require'
});

async function runMigration() {
  try {
    await client.connect();
    console.log('Connected to database');
    
    const sql = fs.readFileSync('database/migrations/014_create_role_system.sql', 'utf8');
    await client.query(sql);
    
    console.log('Migration completed successfully!');
  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    await client.end();
  }
}

runMigration();
```

Run:
```cmd
node run-migration-014.js
```

---

## ✅ Verify Migration

หลังจาก run migration แล้ว ตรวจสอบว่าสำเร็จ:

```sql
-- Check roles
SELECT * FROM roles;

-- Check staff
SELECT * FROM staff;

-- Check unified view
SELECT * FROM v_all_users;
```

---

## 🔐 Test Credentials

หลัง migration สำเร็จ ทดสอบ login:

```
Guest:
  Email: anan.test@example.com
  Password: password123

Receptionist:
  Email: receptionist1@hotel.com
  Password: staff123

Housekeeper:
  Email: housekeeper1@hotel.com
  Password: staff123

Manager:
  Email: manager@hotel.com
  Password: staff123
```

---

## 🐛 Troubleshooting

### Error: "psql not found"
→ ใช้วิธีที่ 1, 2, 3, หรือ 4 แทน

### Error: "connection refused"
→ ตรวจสอบ internet connection และ Neon database status

### Error: "permission denied"
→ ตรวจสอบ database credentials ใน `.env`

---

## 📝 Manual SQL Execution

ถ้าทุกวิธีไม่ได้ผล copy SQL ด้านล่างและ run ใน Neon Console:

```sql
-- Copy entire content from:
database/migrations/014_create_role_system.sql
```

---

**Status:** Ready to Run  
**Date:** November 4, 2025
