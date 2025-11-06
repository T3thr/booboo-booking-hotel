# PostgreSQL Auto-Detection Setup

## ปัญหา
ไฟล์ `.bat` ไม่สามารถหา `psql` command ได้เพราะ PostgreSQL ไม่อยู่ใน System PATH

## โซลูชัน

เราได้สร้าง 2 วิธีแก้ปัญหา:

### วิธีที่ 1: ใช้ Setup Environment Script (แนะนำ)

ใช้ `scripts/setup-env.bat` เพื่อตั้งค่า PATH อัตโนมัติ

**วิธีใช้:**
```batch
@echo off
call scripts\setup-env.bat
REM ... rest of your script
psql -U postgres -d hotel_db -f migration.sql
```

**ข้อดี:**
- ตั้งค่า PATH ครั้งเดียวสำหรับทั้ง script
- รองรับ PostgreSQL หลายเวอร์ชัน (14, 15, 16)
- สามารถเพิ่ม tools อื่นๆ ได้

### วิธีที่ 2: ใช้ psql Wrapper Script

ใช้ `scripts/psql.bat` แทน `psql` command โดยตรง

**วิธีใช้:**
```batch
@echo off
REM แทนที่ psql ด้วย scripts\psql.bat
scripts\psql.bat -U postgres -d hotel_db -f migration.sql
```

**ข้อดี:**
- ไม่ต้องแก้ไข PATH
- หา PostgreSQL อัตโนมัติ
- ใช้งานง่าย

## การปรับแต่ง

### เพิ่ม PostgreSQL Version อื่น

แก้ไข `scripts/setup-env.bat`:
```batch
SET PATH=%PATH%;C:\Program Files\PostgreSQL\17\bin
```

หรือแก้ไข `scripts/psql.bat`:
```batch
if exist "C:\Program Files\PostgreSQL\17\bin\psql.exe" (
    SET PSQL_PATH=C:\Program Files\PostgreSQL\17\bin\psql.exe
)
```

### เพิ่ม Tools อื่นๆ

แก้ไข `scripts/setup-env.bat`:
```batch
REM Add Go
SET PATH=%PATH%;C:\Program Files\Go\bin

REM Add Node.js
SET PATH=%PATH%;C:\Program Files\nodejs
```

## Template Script

ใช้ `scripts/migration-template.bat` เป็นตัวอย่างสำหรับ script ใหม่

**ขั้นตอน:**
1. Copy `scripts/migration-template.bat`
2. เปลี่ยนชื่อไฟล์
3. แก้ไข `[MIGRATION_NAME]` และ `[MIGRATION_FILE]`
4. รันได้เลย!

## ตัวอย่างการแปลง Script เดิม

### ก่อน:
```batch
@echo off
psql -U postgres -d hotel_db -f migration.sql
```

### หลัง (วิธีที่ 1):
```batch
@echo off
call scripts\setup-env.bat
psql -U postgres -d hotel_db -f migration.sql
```

### หลัง (วิธีที่ 2):
```batch
@echo off
scripts\psql.bat -U postgres -d hotel_db -f migration.sql
```

## การทดสอบ

ทดสอบว่า setup ทำงานได้:
```batch
scripts\setup-env.bat
psql --version
```

หรือ:
```batch
scripts\psql.bat --version
```

## หมายเหตุ

- ไม่ต้องแก้ไข System PATH
- ทำงานเฉพาะใน script session
- รองรับ PostgreSQL 14, 15, 16
- สามารถเพิ่ม version อื่นได้ง่าย
