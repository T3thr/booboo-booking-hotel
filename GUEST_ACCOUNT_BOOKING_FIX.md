# แก้ไขระบบ Booking สำหรับ Guest Account

## ปัญหาที่พบ
1. Guest account ที่ sign in แล้วกำลังส่งข้อมูล email/phone ปลอม (Fon Testuser) แทนที่จะใช้ข้อมูลจริงจาก database
2. ข้อมูลที่แสดงในหน้า admin/reception ไม่ตรงกับข้อมูลจริงของ guest account

## การแก้ไข

### 1. หน้า Guest Info (`frontend/src/app/(guest)/booking/guest-info/page.tsx`)

#### เปลี่ยนแปลง:
- **Pre-fill ข้อมูล**: เมื่อ guest account sign in แล้ว ระบบจะ pre-fill ชื่อ, นามสกุล, เบอร์โทร, และอีเมลจาก account อัตโนมัติ
- **Phone เป็น Optional**: สำหรับ guest account phone จะเป็น optional (ถ้าไม่กรอกจะใช้จาก account)
- **Email จาก Account**: Email จะใช้จาก account เสมอสำหรับ signed-in users (แสดงเป็น disabled field)
- **ส่งข้อมูลที่ถูกต้อง**: เมื่อกด Continue จะส่งข้อมูลจาก account ไปยัง backend

#### โค้ดที่แก้ไข:

**1. Initialize guests with account data:**
```typescript
// For signed-in users, pre-fill primary guest with account info
const accountFirstName = session?.user ? ((session.user as any).first_name || session.user.name?.split(' ')[0] || '') : '';
const accountLastName = session?.user ? ((session.user as any).last_name || session.user.name?.split(' ').slice(1).join(' ') || '') : '';
const accountPhone = session?.user ? ((session.user as any).phone || '') : '';
const accountEmail = session?.user ? (session.user.email || '') : '';

// Add adults with account info for primary guest
for (let i = 0; i < (searchParams.adults || 1); i++) {
  guestList.push({
    first_name: i === 0 && session ? accountFirstName : '',
    last_name: i === 0 && session ? accountLastName : '',
    phone: i === 0 && session ? accountPhone : '',
    email: i === 0 && session ? accountEmail : '',
    type: 'Adult',
    is_primary: i === 0,
  });
}
```

**2. Handle Continue with account data:**
```typescript
if (session?.user) {
  // For signed-in users: Use account info
  const accountPhone = (session.user as any).phone || '';
  const accountEmail = session.user.email || '';
  const accountFirstName = (session.user as any).first_name || session.user.name?.split(' ')[0] || '';
  const accountLastName = (session.user as any).last_name || session.user.name?.split(' ').slice(1).join(' ') || '';
  
  // Update primary guest with account information
  finalGuests[0] = {
    ...finalGuests[0],
    // Use account name if form is empty, otherwise use form data
    first_name: finalGuests[0].first_name?.trim() || accountFirstName,
    last_name: finalGuests[0].last_name?.trim() || accountLastName,
    // Use phone from form if provided, otherwise use account phone
    phone: finalGuests[0].phone?.trim() || accountPhone,
    // Always use account email for signed-in users
    email: accountEmail,
  };
}
```

**3. UI Labels:**
```typescript
<label className="block text-sm font-medium mb-2">
  First Name *
  {guest.is_primary && session && (
    <span className="text-xs text-muted-foreground ml-2">
      (from account)
    </span>
  )}
</label>
```

### 2. Backend Service (`backend/internal/service/booking_service.go`)

Backend มีการจัดการอยู่แล้ว (บรรทัด 176-186):
```go
// For primary guest with guest account: use account phone/email if not provided
if guest.IsPrimary && guestAccount != nil {
    // Use account phone if not provided
    if phone == nil || *phone == "" {
        phone = &guestAccount.Phone
    }
    // Use account email if not provided
    if email == nil || *email == "" {
        email = &guestAccount.Email
    }
}
```

### 3. API Layer (`frontend/src/lib/api.ts`)

API layer ส่งข้อมูลถูกต้องแล้ว:
```typescript
guests: data.guests.map((g: any) => ({
  first_name: firstName,
  last_name: lastName,
  phone: g.phone || null,  // ส่ง null ถ้าไม่มี
  email: g.email || null,  // ส่ง null ถ้าไม่มี
  type: g.type || 'Adult',
  is_primary: g.is_primary || false,
}))
```

## การทำงานของระบบหลังแก้ไข

### สำหรับ Guest Account (Signed In):
1. เมื่อเข้าหน้า Guest Info ระบบจะ pre-fill ข้อมูลจาก account อัตโนมัติ
2. ชื่อ-นามสกุล: แสดงจาก account (สามารถแก้ไขได้ถ้าต้องการ)
3. Phone: แสดงจาก account (optional - สามารถแก้ไขหรือเว้นว่างได้)
4. Email: แสดงจาก account (disabled - ไม่สามารถแก้ไขได้)
5. เมื่อกด Continue ระบบจะส่งข้อมูลจาก account ไปยัง backend
6. Backend จะใช้ข้อมูลจาก account ถ้า phone/email ไม่ได้กรอกมา

### สำหรับ Non-Session Guest:
1. ต้องกรอกชื่อ-นามสกุล, phone, email ทั้งหมด
2. Phone และ Email เป็น required fields
3. ข้อมูลจะถูกส่งไปยัง backend ตามที่กรอก

## การทดสอบ

### Test Case 1: Guest Account Booking
1. Sign in ด้วย guest account (เช่น fon.test@example.com)
2. ค้นหาห้องและเลือกห้อง
3. ในหน้า Guest Info ควรเห็น:
   - ชื่อ-นามสกุลจาก account
   - Phone จาก account (สามารถแก้ไขได้)
   - Email จาก account (disabled)
4. กด Continue และทำการจองให้เสร็จ
5. ตรวจสอบในหน้า admin/reception ว่าข้อมูลถูกต้อง:
   - ชื่อผู้จอง: ชื่อจริงจาก account (ไม่ใช่ Fon Testuser)
   - Email: อีเมลจริงจาก account
   - Phone: เบอร์จริงจาก account

### Test Case 2: Non-Session Guest Booking
1. ไม่ต้อง sign in
2. ค้นหาห้องและเลือกห้อง
3. ในหน้า Guest Info ต้องกรอก:
   - ชื่อ-นามสกุล (required)
   - Phone (required)
   - Email (required)
4. กด Continue และทำการจองให้เสร็จ
5. ตรวจสอบในหน้า admin/reception ว่าข้อมูลตรงกับที่กรอก

### Test Case 3: Guest Account with Phone Override
1. Sign in ด้วย guest account
2. ค้นหาห้องและเลือกห้อง
3. ในหน้า Guest Info แก้ไข phone เป็นเบอร์อื่น
4. กด Continue และทำการจองให้เสร็จ
5. ตรวจสอบในหน้า admin/reception ว่าใช้เบอร์ที่แก้ไข (ไม่ใช่เบอร์จาก account)

## สรุป
การแก้ไขนี้ทำให้:
- ✅ Guest account ใช้ข้อมูลจริงจาก database
- ✅ Phone เป็น optional สำหรับ guest account
- ✅ Email ใช้จาก account เสมอสำหรับ signed-in users
- ✅ ข้อมูลที่แสดงใน admin/reception ถูกต้อง
- ✅ Non-session guest ยังคงทำงานปกติ
