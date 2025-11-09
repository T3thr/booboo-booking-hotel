# สรุปการแก้ไข Guest Account Booking

## ปัญหา

Guest account ที่ sign in แล้วกลับส่งข้อมูลปลอม (เช่น fon.test@example.com, 0867890006) ไปยัง admin panel แทนที่จะส่งข้อมูลจาก guest account จริง

## สาเหตุ

1. Backend login response ไม่ส่ง phone field
2. Frontend session ไม่มี phone data
3. Guest-info page ไม่มี logic สำหรับ guest account

## การแก้ไข

### 1. Backend Changes

#### `backend/internal/models/guest.go`
```go
type LoginResponse struct {
    ID          int    `json:"id"`
    Email       string `json:"email"`
    FirstName   string `json:"first_name"`
    LastName    string `json:"last_name"`
    Phone       string `json:"phone"`  // ← เพิ่มใหม่
    Role        string `json:"role"`
    RoleCode    string `json:"role_code"`
    UserType    string `json:"user_type"`
    AccessToken string `json:"accessToken"`
}
```

#### `backend/internal/service/auth_service.go`
- อัพเดท Login function เพื่อส่ง `Phone: user.Phone`
- อัพเดท Register function เพื่อส่ง `Phone: guest.Phone`

### 2. Frontend Changes

#### `frontend/src/lib/auth.ts`
```typescript
// ใน authorize callback
const user = {
    id: response.data.id.toString(),
    email: response.data.email,
    name: `${response.data.first_name} ${response.data.last_name}`,
    role: response.data.role_code,
    userType: response.data.user_type,
    phone: response.data.phone,  // ← เพิ่มใหม่
    accessToken: response.data.access_token || response.data.accessToken
};

// ใน jwt callback
token.phone = user.phone;  // ← เพิ่มใหม่

// ใน session callback
session.user.phone = token.phone as string;  // ← เพิ่มใหม่
```

#### `frontend/src/types/next-auth.d.ts`
```typescript
interface JWT {
    id: string;
    role: string;
    userType: string;
    phone?: string;  // ← เพิ่มใหม่
    accessToken: string;
}
```

#### `frontend/src/app/(guest)/booking/guest-info/page.tsx`

**Phone Field:**
- สำหรับ non-signed-in: Required field
- สำหรับ signed-in: Optional field (แสดง placeholder จาก account)
- ถ้าไม่กรอก: ใช้ phone จาก account
- ถ้ากรอก: ใช้ phone ที่กรอก (override)

**Email Field:**
- สำหรับ non-signed-in: Required input field
- สำหรับ signed-in: Disabled field แสดง email จาก account

**Validation:**
```typescript
// Phone validation
if (guest.is_primary && !session) {
    // Non-signed-in: phone is required
    if (!guest.phone?.trim()) {
        newErrors[`guest_${index}_phone`] = 'Phone number is required';
    }
}
// For signed-in users, phone is optional
```

**handleContinue Logic:**
```typescript
if (session?.user) {
    const accountPhone = (session.user as any).phone || '';
    const accountEmail = session.user.email || '';
    
    finalGuests[0] = {
        ...finalGuests[0],
        // Use phone from form if provided, otherwise use account phone
        phone: finalGuests[0].phone?.trim() || accountPhone,
        // Always use account email for signed-in users
        email: accountEmail,
    };
}
```

## ผลลัพธ์

### Non-Signed-In Guest:
- ✅ ต้องกรอก phone และ email
- ✅ ข้อมูลที่กรอกจะถูกส่งไป admin panel

### Signed-In Guest:
- ✅ Email ดึงจาก account (disabled field)
- ✅ Phone เป็น optional:
  - ไม่กรอก → ใช้ phone จาก account
  - กรอก → ใช้ phone ที่กรอก (override)
- ✅ ข้อมูลจาก account จะถูกส่งไป admin panel

### Admin Panel:
- ✅ แสดงข้อมูลจริงจาก guest account (ไม่ใช่ข้อมูลปลอม)
- ✅ แสดงข้อมูลที่ non-signed-in guest กรอก

## การทดสอบ

### Test 1: Non-Signed-In Guest
1. ไม่ sign in
2. จองห้อง
3. กรอก phone และ email
4. ตรวจสอบ admin panel → ควรเห็นข้อมูลที่กรอก

### Test 2: Signed-In Guest (ไม่กรอก phone)
1. Sign in ด้วย guest account
2. จองห้อง
3. ไม่กรอก phone (ปล่อยว่าง)
4. ตรวจสอบ admin panel → ควรเห็น phone จาก account

### Test 3: Signed-In Guest (กรอก phone)
1. Sign in ด้วย guest account
2. จองห้อง
3. กรอก phone ใหม่
4. ตรวจสอบ admin panel → ควรเห็น phone ที่กรอก (override)

## Deploy

```bash
# 1. Rebuild backend
cd backend
go build -o hotel-booking-api.exe ./cmd/server

# 2. Restart backend
hotel-booking-api.exe

# 3. Restart frontend (if needed)
cd frontend
npm run dev
```

## หมายเหตุ

- Phone field จะแสดง placeholder จาก account เพื่อให้ user รู้ว่าจะใช้เบอร์ไหนถ้าไม่กรอก
- Email field สำหรับ signed-in users จะเป็น disabled เพื่อป้องกันการแก้ไข
- ระบบจะใช้ข้อมูลจาก account เป็นหลัก แต่อนุญาตให้ override phone ได้
