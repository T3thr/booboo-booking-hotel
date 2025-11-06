# Tailwind CSS 4.0 Migration - Quick Start

## 🚀 เริ่มต้นอย่างรวดเร็ว

### สำหรับ Windows
```powershell
cd frontend
.\migrate-tailwind.ps1
```

### สำหรับ Linux/Mac
```bash
cd frontend
chmod +x migrate-tailwind.sh
./migrate-tailwind.sh
```

## 📚 เอกสารทั้งหมด

### 1. [TAILWIND_MIGRATION_SUMMARY.md](./TAILWIND_MIGRATION_SUMMARY.md)
**อ่านก่อน** - สรุปภาพรวมทั้งหมด
- วัตถุประสงค์
- สถานะปัจจุบัน
- แผนการดำเนินงาน
- Metrics และ Success Criteria

### 2. [TAILWIND_CSS_MIGRATION_GUIDE.md](./TAILWIND_CSS_MIGRATION_GUIDE.md)
**คู่มือหลัก** - รายละเอียดการแปลง
- CSS Variables ทั้งหมด
- ตัวอย่างการแปลง
- กฎการแปลง
- Best Practices

### 3. [TAILWIND_MIGRATION_CHECKLIST.md](./TAILWIND_MIGRATION_CHECKLIST.md)
**รายการตรวจสอบ** - ติดตามความคืบหน้า
- รายการไฟล์ทั้งหมด
- ขั้นตอนการตรวจสอบ
- Progress Tracking
- Troubleshooting

### 4. Scripts
- `migrate-tailwind.ps1` - PowerShell script สำหรับ Windows
- `migrate-tailwind.sh` - Bash script สำหรับ Linux/Mac

## 🎯 เป้าหมาย

แปลง hardcoded colors เป็น CSS variables:

```tsx
// ❌ Before
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">

// ✅ After
<div className="bg-background text-foreground">
```

## ⚡ Quick Reference

### การแปลงพื้นฐาน
```
bg-white dark:bg-gray-900     → bg-background
bg-gray-50 dark:bg-gray-800   → bg-muted
text-gray-900 dark:text-white → text-foreground
text-gray-600 dark:text-gray-400 → text-muted-foreground
border-gray-200 dark:border-gray-700 → border-border
```

### เก็บ Semantic Colors
```tsx
// ✅ Keep these (status indicators)
bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400
bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400
bg-yellow-100 text-yellow-700 dark:bg-yellow-900/20 dark:text-yellow-400
```

## 📋 ขั้นตอนการทำงาน

### 1. เตรียมการ
```bash
cd frontend
git checkout -b feature/tailwind-migration
```

### 2. รัน Script
```bash
# Windows
.\migrate-tailwind.ps1

# Linux/Mac
./migrate-tailwind.sh
```

### 3. ตรวจสอบ
```bash
# ดูการเปลี่ยนแปลง
git diff

# ทดสอบ
npm run dev
```

### 4. แก้ไขปัญหา (ถ้ามี)
- เปิด browser และตรวจสอบ
- ทดสอบทั้ง light และ dark mode
- แก้ไข semantic colors ที่ถูกแปลงผิด

### 5. Commit
```bash
git add .
git commit -m "refactor: migrate Phase 4 to Tailwind CSS 4.0 variables"
git push origin feature/tailwind-migration
```

## 🧪 การทดสอบ

### ต้องทดสอบ
- [ ] Light mode
- [ ] Dark mode
- [ ] Hover states
- [ ] Active states
- [ ] Responsive design
- [ ] All browsers

### คำสั่งทดสอบ
```bash
# Development
npm run dev

# Build
npm run build

# Type check
npm run type-check

# Lint
npm run lint
```

## ⚠️ สิ่งที่ต้องระวัง

### ❌ อย่าแปลง
- Status colors (green, red, yellow, blue)
- Alert/notification colors
- Badge colors
- Semantic colors ที่มีความหมายเฉพาะ

### ✅ ควรแปลง
- Background colors พื้นฐาน
- Text colors พื้นฐาน
- Border colors
- Primary/accent colors

## 🔧 Troubleshooting

### ปัญหา: สีดูไม่ถูกต้อง
```bash
# Restore จาก backup
find src -name "*.backup" -exec bash -c 'mv "$0" "${0%.backup}"' {} \;
```

### ปัญหา: Dark mode ไม่ทำงาน
- ตรวจสอบว่าใช้ CSS variables
- ตรวจสอบ `globals.css`
- ตรวจสอบ theme provider

### ปัญหา: Build error
```bash
# ตรวจสอบ syntax
npm run type-check

# ตรวจสอบ lint
npm run lint
```

## 📊 ความคืบหน้า

### Phase 4 (Guest Features)
```
Total: 18 files
Done:  18 files (100%) ✅
Todo:  0 files (0%)
```

### ติดตามความคืบหน้า
ดูรายละเอียดใน [TAILWIND_MIGRATION_CHECKLIST.md](./TAILWIND_MIGRATION_CHECKLIST.md)

## 💡 Tips

### สำหรับ Developers
1. ใช้ automated script ก่อน
2. ทดสอบทุกครั้งหลังแก้ไข
3. Commit บ่อยๆ (ทีละไฟล์)
4. เก็บ semantic colors

### สำหรับ Reviewers
1. ตรวจสอบ dark mode
2. ตรวจสอบ semantic colors
3. ทดสอบ interactive elements
4. ตรวจสอบ responsive design

## 📞 ต้องการความช่วยเหลือ?

### เอกสาร
- [TAILWIND_MIGRATION_SUMMARY.md](./TAILWIND_MIGRATION_SUMMARY.md) - ภาพรวม
- [TAILWIND_CSS_MIGRATION_GUIDE.md](./TAILWIND_CSS_MIGRATION_GUIDE.md) - คู่มือละเอียด
- [TAILWIND_MIGRATION_CHECKLIST.md](./TAILWIND_MIGRATION_CHECKLIST.md) - Checklist

### ติดต่อ
- Team Chat
- Issue Tracker
- Code Review

## ✅ Checklist ก่อนเสร็จ

- [ ] รัน migration script
- [ ] ตรวจสอบการเปลี่ยนแปลง
- [ ] ทดสอบ light mode
- [ ] ทดสอบ dark mode
- [ ] แก้ไขปัญหา (ถ้ามี)
- [ ] ทดสอบ responsive
- [ ] ทดสอบ cross-browser
- [ ] Update checklist
- [ ] Commit changes
- [ ] Create PR

## 🎉 เสร็จแล้ว?

ยินดีด้วย! คุณได้ช่วยปรับปรุงโค้ดให้ดีขึ้น 🚀

### ขั้นตอนถัดไป
1. Create Pull Request
2. Request code review
3. Address feedback
4. Merge to main
5. Deploy

---

**Created**: November 4, 2025
**Last Updated**: November 4, 2025
**Status**: 🟡 In Progress
