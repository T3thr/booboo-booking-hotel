# คู่มือการใช้งาน Theme System

## ภาพรวม

ระบบ Theme ของโปรเจกต์นี้ใช้ Tailwind CSS v4 พร้อมระบบสลับธีมแบบ Light/Dark Mode ที่ไม่มี flickering และรองรับการเปลี่ยนธีมแบบ real-time

## โครงสร้างไฟล์

```
frontend/src/
├── app/
│   ├── globals.css              # การตั้งค่าสีและธีม
│   └── layout.tsx               # Root layout พร้อม blocking script
├── providers/
│   └── theme-provider.tsx       # Context provider สำหรับจัดการธีม
├── hooks/
│   └── use-theme.ts             # Custom hook สำหรับเข้าถึงธีม
└── components/
    └── ui/
        └── theme-toggle.tsx     # ปุ่มสลับธีม
```

## การตั้งค่าสี

### Light Mode (โหมดสว่าง)
```css
--color-background: #ffffff        /* พื้นหลังหลัก */
--color-foreground: #171717        /* ข้อความหลัก */
--color-primary: #3b82f6           /* สีหลัก (น้ำเงิน) */
--color-primary-foreground: #ffffff /* ข้อความบนสีหลัก */
--color-secondary: #f3f4f6         /* สีรอง (เทาอ่อน) */
--color-secondary-foreground: #1f2937 /* ข้อความบนสีรอง */
--color-muted: #f9fafb             /* สีเงียบ */
--color-muted-foreground: #6b7280  /* ข้อความสีเงียบ */
--color-accent: #dbeafe            /* สีเน้น */
--color-accent-foreground: #1e40af /* ข้อความบนสีเน้น */
--color-destructive: #ef4444       /* สีแจ้งเตือน/ลบ (แดง) */
--color-destructive-foreground: #ffffff /* ข้อความบนสีแจ้งเตือน */
--color-border: #e5e7eb            /* สีขอบ */
--color-input: #e5e7eb             /* สีพื้นหลัง input */
--color-ring: #3b82f6              /* สี focus ring */
--color-card: #ffffff              /* พื้นหลังการ์ด */
--color-card-foreground: #171717  /* ข้อความในการ์ด */
```

### Dark Mode (โหมดมืด)
```css
--color-background: #0a0a0a        /* พื้นหลังหลัก (ดำ) */
--color-foreground: #ededed        /* ข้อความหลัก (ขาว) */
--color-primary: #60a5fa           /* สีหลัก (น้ำเงินอ่อน) */
--color-primary-foreground: #1e3a8a /* ข้อความบนสีหลัก */
--color-secondary: #1f2937         /* สีรอง (เทาเข้ม) */
--color-secondary-foreground: #f9fafb /* ข้อความบนสีรอง */
--color-muted: #111827             /* สีเงียบ */
--color-muted-foreground: #9ca3af  /* ข้อความสีเงียบ */
--color-accent: #1e3a8a            /* สีเน้น */
--color-accent-foreground: #dbeafe /* ข้อความบนสีเน้น */
--color-destructive: #dc2626       /* สีแจ้งเตือน/ลบ */
--color-destructive-foreground: #fef2f2 /* ข้อความบนสีแจ้งเตือน */
--color-border: #374151            /* สีขอบ */
--color-input: #374151             /* สีพื้นหลัง input */
--color-ring: #60a5fa              /* สี focus ring */
--color-card: #0a0a0a              /* พื้นหลังการ์ด */
--color-card-foreground: #ededed  /* ข้อความในการ์ด */
```

## Tailwind Classes ที่ใช้ได้

### พื้นหลังและข้อความ
```tsx
// พื้นหลังและข้อความหลัก
<div className="bg-background text-foreground">
  เนื้อหา
</div>

// สีหลัก (Primary)
<button className="bg-primary text-primary-foreground">
  ปุ่ม
</button>

// สีรอง (Secondary)
<div className="bg-secondary text-secondary-foreground">
  เนื้อหารอง
</div>

// สีเงียบ (Muted)
<p className="text-muted-foreground">
  ข้อความเสริม
</p>

// สีเน้น (Accent)
<div className="bg-accent text-accent-foreground">
  เนื้อหาเน้น
</div>

// สีแจ้งเตือน (Destructive)
<button className="bg-destructive text-destructive-foreground">
  ลบ
</button>
```

### การ์ดและ Popover
```tsx
// การ์ด
<div className="bg-card text-card-foreground border border-border rounded-lg p-4">
  เนื้อหาการ์ด
</div>

// Popover
<div className="bg-popover text-popover-foreground">
  เนื้อหา Popover
</div>
```

### ขอบและ Input
```tsx
// ขอบ
<div className="border border-border">
  เนื้อหา
</div>

// Input
<input className="bg-input border-border focus:ring-ring" />
```

### Hover และ State
```tsx
// Hover
<button className="bg-primary hover:bg-primary/90">
  ปุ่ม
</button>

// Opacity
<div className="bg-destructive/10 border-destructive/20">
  พื้นหลังแจ้งเตือนแบบโปร่งใส
</div>
```

## การใช้งาน Theme Hook

### ในคอมโพเนนต์
```tsx
'use client';

import { useTheme } from '@/hooks/use-theme';

export function MyComponent() {
  const { theme, toggleTheme } = useTheme();

  return (
    <div>
      <p>ธีมปัจจุบัน: {theme}</p>
      <button onClick={toggleTheme}>
        สลับธีม
      </button>
    </div>
  );
}
```

### ตรวจสอบธีมปัจจุบัน
```tsx
const { theme } = useTheme();

if (theme === 'dark') {
  // ทำอะไรสักอย่างในโหมดมืด
}
```

## ปุ่มสลับธีม

ปุ่มสลับธีมจะแสดงที่มุมล่างขวาของหน้าจออัตโนมัติ:
- ตำแหน่ง: `fixed bottom-6 right-6`
- ขนาด: 12x12 (mobile), 14x14 (desktop)
- ไอคอน: พระจันทร์ (โหมดสว่าง) / พระอาทิตย์ (โหมดมืด)
- Responsive: ปรับขนาดตามหน้าจอ

## วิธีการทำงาน

### 1. Blocking Script (ป้องกัน Flickering)
```tsx
// ใน layout.tsx
<script
  dangerouslySetInnerHTML={{
    __html: `
      (function() {
        const theme = localStorage.getItem('theme');
        if (theme === 'dark') {
          document.documentElement.classList.add('dark');
        }
      })();
    `,
  }}
/>
```

Script นี้ทำงานก่อน React hydrate เพื่อป้องกันการกระพริบของสี

### 2. Theme Provider
```tsx
// ใน providers.tsx
<ThemeProvider>
  <SessionProvider>
    <QueryClientProvider>
      {children}
      <ThemeToggle />
    </QueryClientProvider>
  </SessionProvider>
</ThemeProvider>
```

### 3. การบันทึกธีม
ธีมจะถูกบันทึกใน `localStorage` โดยอัตโนมัติ:
```javascript
localStorage.setItem('theme', 'dark'); // หรือ 'light'
```

## ตัวอย่างการใช้งาน

### หน้า Landing Page
```tsx
export default function Home() {
  return (
    <main className="min-h-screen bg-background">
      <div className="container mx-auto p-8">
        <h1 className="text-4xl font-bold text-foreground">
          ยินดีต้อนรับ
        </h1>
        <p className="text-muted-foreground">
          ข้อความเสริม
        </p>
      </div>
    </main>
  );
}
```

### ฟอร์ม Login
```tsx
<div className="min-h-screen bg-background">
  <Card className="max-w-md mx-auto">
    <CardHeader>
      <CardTitle className="text-foreground">เข้าสู่ระบบ</CardTitle>
      <CardDescription className="text-muted-foreground">
        กรอกข้อมูลเพื่อเข้าสู่ระบบ
      </CardDescription>
    </CardHeader>
    <CardContent>
      <Input 
        className="bg-input border-border text-foreground"
        placeholder="อีเมล"
      />
      <Button className="bg-primary text-primary-foreground">
        เข้าสู่ระบบ
      </Button>
    </CardContent>
  </Card>
</div>
```

### แจ้งเตือนข้อผิดพลาด
```tsx
{error && (
  <div className="bg-destructive/10 border border-destructive/20 rounded-md p-4">
    <p className="text-destructive">
      {error}
    </p>
  </div>
)}
```

### ปุ่มต่างๆ
```tsx
// ปุ่มหลัก
<Button className="bg-primary text-primary-foreground hover:bg-primary/90">
  บันทึก
</Button>

// ปุ่มรอง
<Button className="bg-secondary text-secondary-foreground hover:bg-secondary/80">
  ยกเลิก
</Button>

// ปุ่มลบ
<Button className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
  ลบ
</Button>

// ปุ่มขอบ
<Button className="border border-border bg-background hover:bg-accent">
  ดูเพิ่มเติม
</Button>
```

## การปรับแต่งสี

### แก้ไขสีในไฟล์ `globals.css`
```css
@theme {
  /* เปลี่ยนสีหลัก */
  --color-primary: #your-color;
  
  /* เปลี่ยนสีพื้นหลัง */
  --color-background: #your-color;
}

.dark {
  /* เปลี่ยนสีสำหรับโหมดมืด */
  --color-primary: #your-dark-color;
}
```

### เพิ่มสีใหม่
```css
@theme {
  --color-success: #10b981;
  --color-success-foreground: #ffffff;
  --color-warning: #f59e0b;
  --color-warning-foreground: #ffffff;
}

.dark {
  --color-success: #34d399;
  --color-warning: #fbbf24;
}
```

จากนั้นใช้งานได้เลย:
```tsx
<div className="bg-success text-success-foreground">
  สำเร็จ!
</div>
```

## Best Practices

1. **ใช้สีจาก Theme เสมอ**: หลีกเลี่ยงการใช้สีแบบ hardcode เช่น `bg-blue-500`
   ```tsx
   // ❌ ไม่ดี
   <div className="bg-blue-500 text-white">
   
   // ✅ ดี
   <div className="bg-primary text-primary-foreground">
   ```

2. **ใช้ Opacity สำหรับสีโปร่งใส**:
   ```tsx
   <div className="bg-primary/10 border-primary/20">
   ```

3. **ใช้ `text-muted-foreground` สำหรับข้อความเสริม**:
   ```tsx
   <p className="text-muted-foreground">ข้อความเสริม</p>
   ```

4. **ใช้ `bg-card` สำหรับการ์ด**:
   ```tsx
   <div className="bg-card text-card-foreground border border-border">
   ```

5. **ทดสอบทั้งสองโหมด**: ตรวจสอบให้แน่ใจว่า UI ดูดีทั้งโหมดสว่างและมืด

## การแก้ไขปัญหา

### สีไม่เปลี่ยนตามธีม
- ตรวจสอบว่าใช้ class จาก theme (`bg-background`) ไม่ใช่สีแบบ hardcode (`bg-white`)
- ตรวจสอบว่า component อยู่ใน `ThemeProvider`

### มี Flickering เมื่อโหลดหน้า
- ตรวจสอบว่ามี blocking script ใน `layout.tsx`
- ตรวจสอบว่า `suppressHydrationWarning` อยู่ใน `<html>` tag

### ปุ่มสลับธีมไม่ทำงาน
- ตรวจสอบว่า `ThemeToggle` อยู่ใน `ThemeProvider`
- เปิด Console ดู error

### สีไม่ตรงกับที่ตั้งไว้
- ล้าง cache ของ browser
- Restart dev server
- ตรวจสอบว่าไม่มี CSS อื่นที่ override

## สรุป

ระบบ Theme นี้ให้คุณ:
- ✅ สลับธีมได้แบบ real-time ไม่มี flickering
- ✅ บันทึกการตั้งค่าอัตโนมัติ
- ✅ ใช้งานง่ายด้วย Tailwind classes
- ✅ รองรับ responsive
- ✅ ปรับแต่งสีได้ง่าย
- ✅ เป็นมาตรฐาน Tailwind CSS v4

สนุกกับการพัฒนา! 🎨
