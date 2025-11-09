# Emergency Fix: Loading ค้าง

## ทดสอบด่วน

### 1. เปิด Browser Console แล้วรันคำสั่งนี้
```javascript
// ดูว่ามี hold ใน localStorage ไหม
console.log('Hold in storage:', localStorage.getItem('booking_hold'));

// ถ้ามี ให้ลอง parse
const hold = JSON.parse(localStorage.getItem('booking_hold'));
console.log('Parsed hold:', hold);
console.log('Expiry:', new Date(hold.holdExpiry));
console.log('Is valid:', new Date(hold.holdExpiry) > new Date());
```

### 2. ถ้ามี hold ใน localStorage แต่หน้ายังโหลด
```javascript
// Force reload หน้า
window.location.reload();
```

### 3. ถ้ายังไม่ได้ ลบ hold แล้วลองใหม่
```javascript
// ลบ hold เก่า
localStorage.removeItem('booking_hold');
sessionStorage.removeItem('booking_session_id');

// กลับไปหน้าค้นหา
window.location.href = '/rooms/search';
```

## แก้ปัญหาถาวร

### วิธีที่ 1: ใช้ useEffect แทน inline setState
ปัญหาคือ React 18 strict mode ทำให้ component render 2 ครั้ง

### วิธีที่ 2: ข้าม loading ถ้ามี localStorage
เพิ่มเงื่อนไขนี้ในการแสดง loading:

```typescript
// ถ้ามี hold ใน localStorage ให้ข้าม loading
if (hasHoldInStorage) {
  // Don't show loading, show form directly
  return <GuestInfoForm />;
}
```

### วิธีที่ 3: ใช้ setTimeout force update
```typescript
useEffect(() => {
  if (isCreatingHold) {
    const timer = setTimeout(() => {
      console.warn('[Emergency] Force stop loading');
      setIsCreatingHold(false);
    }, 3000); // 3 วินาที
    
    return () => clearTimeout(timer);
  }
}, [isCreatingHold]);
```

## คำสั่งด่วน

```bash
# 1. Clear browser cache
Ctrl + Shift + Delete

# 2. Hard refresh
Ctrl + Shift + R

# 3. Clear localStorage ใน Console
localStorage.clear()
sessionStorage.clear()
```
