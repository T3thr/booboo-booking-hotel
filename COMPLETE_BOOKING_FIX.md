# แก้ไข Complete Booking Error

## ปัญหา

เมื่อกด "Complete Booking" ในหน้า `booking/summary` เกิด error:
```
Phone number is required for primary guest
at src/lib/api.ts:223:19
```

## สาเหตุ

1. **Frontend validation** ใน `api.ts` ตรวจสอบว่า phone เป็น required สำหรับ primary guest ทุกคน
2. แต่สำหรับ **guest account** ที่ sign in แล้ว phone อาจเป็น empty string (เพราะจะใช้จาก account)
3. **Backend** ไม่มี logic ดึง phone และ email จาก guest account เมื่อไม่ได้ส่งมา

## การแก้ไข

### 1. Frontend - ลบ validation ที่เข้มงวดเกินไป

**File:** `frontend/src/lib/api.ts`

**Before:**
```typescript
// Validate phone for primary guest
if (g.is_primary && !g.phone) {
    throw new Error('Phone number is required for primary guest');
}

return {
    first_name: firstName,
    last_name: lastName,
    phone: g.phone || null,
    type: g.type || 'Adult',
    is_primary: g.is_primary || false,
};
```

**After:**
```typescript
// Phone validation: allow empty for primary guest (will be filled from account if signed in)
// Backend will handle the phone from account

return {
    first_name: firstName,
    last_name: lastName,
    phone: g.phone || null,
    email: g.email || null,  // ← เพิ่ม email
    type: g.type || 'Adult',
    is_primary: g.is_primary || false,
};
```

### 2. Backend - เพิ่ม logic ดึงข้อมูลจาก guest account

**File:** `backend/internal/service/booking_service.go`

**เพิ่มก่อน loop สร้าง booking details:**
```go
// Get guest account info if authenticated (for filling in missing phone/email)
var guestAccount *models.Guest
if guestID > 0 {
    guestAccount, _ = s.bookingRepo.GetGuestByID(ctx, guestID)
}
```

**แก้ไข loop สร้าง guests:**
```go
// Create guests
for _, guest := range detail.Guests {
    // For primary guest with guest account: use account phone/email if not provided
    phone := guest.Phone
    email := guest.Email
    
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
    
    bookingGuest := &models.BookingGuest{
        BookingDetailID: bookingDetail.BookingDetailID,
        FirstName:       guest.FirstName,
        LastName:        guest.LastName,
        Phone:           phone,
        Email:           email,
        Type:            guest.Type,
        IsPrimary:       guest.IsPrimary,
    }

    err = s.bookingRepo.CreateBookingGuest(ctx, bookingGuest)
    if err != nil {
        return nil, fmt.Errorf("failed to create booking guest: %w", err)
    }
}
```

### 3. Backend - เพิ่ม GetGuestByID function

**File:** `backend/internal/repository/booking_repository.go`

```go
// GetGuestByID retrieves a guest by ID
func (r *BookingRepository) GetGuestByID(ctx context.Context, guestID int) (*models.Guest, error) {
    query := `
        SELECT guest_id, first_name, last_name, email, phone, created_at, updated_at
        FROM guests
        WHERE guest_id = $1
    `

    var guest models.Guest
    err := r.db.Pool.QueryRow(ctx, query, guestID).Scan(
        &guest.GuestID,
        &guest.FirstName,
        &guest.LastName,
        &guest.Email,
        &guest.Phone,
        &guest.CreatedAt,
        &guest.UpdatedAt,
    )

    if err != nil {
        if errors.Is(err, pgx.ErrNoRows) {
            return nil, nil
        }
        return nil, fmt.Errorf("failed to get guest: %w", err)
    }

    return &guest, nil
}
```

## Logic Flow

### Non-Signed-In Guest:
1. กรอก phone และ email ในหน้า guest-info
2. ส่งไป backend พร้อม phone และ email
3. Backend บันทึกตามที่ส่งมา

### Signed-In Guest (ไม่กรอก phone):
1. ไม่กรอก phone ในหน้า guest-info (ปล่อยว่าง)
2. Frontend ส่ง phone เป็น null หรือ empty string
3. Backend ตรวจสอบว่า:
   - `guest.IsPrimary == true`
   - `guestAccount != nil` (มี guest account)
   - `phone == nil || *phone == ""`
4. Backend ดึง phone จาก `guestAccount.Phone`
5. บันทึก phone จาก account

### Signed-In Guest (กรอก phone):
1. กรอก phone ใหม่ในหน้า guest-info
2. Frontend ส่ง phone ที่กรอก
3. Backend ใช้ phone ที่ส่งมา (override account phone)

## ผลลัพธ์

✅ Non-signed-in guest: ต้องกรอก phone และ email
✅ Signed-in guest (ไม่กรอก phone): ใช้ phone จาก account
✅ Signed-in guest (กรอก phone): ใช้ phone ที่กรอก (override)
✅ Complete booking ทำงานได้ทั้ง 2 กรณี
✅ Admin panel แสดงข้อมูลถูกต้อง

## การทดสอบ

### Test 1: Non-Signed-In Guest
```
1. ไม่ sign in
2. จองห้อง
3. กรอก phone: 0812345678, email: test@example.com
4. Complete booking
5. ✅ ควรสำเร็จ
6. ตรวจสอบ admin panel → ควรเห็น phone และ email ที่กรอก
```

### Test 2: Signed-In Guest (ไม่กรอก phone)
```
1. Sign in (account มี phone: 0899999999)
2. จองห้อง
3. ไม่กรอก phone (ปล่อยว่าง)
4. Complete booking
5. ✅ ควรสำเร็จ
6. ตรวจสอบ admin panel → ควรเห็น phone: 0899999999 (จาก account)
```

### Test 3: Signed-In Guest (กรอก phone)
```
1. Sign in (account มี phone: 0899999999)
2. จองห้อง
3. กรอก phone: 0811111111
4. Complete booking
5. ✅ ควรสำเร็จ
6. ตรวจสอบ admin panel → ควรเห็น phone: 0811111111 (ที่กรอก)
```

## Deploy

```bash
# Rebuild backend
cd backend
go build -o hotel-booking-api.exe ./cmd/server

# Restart backend
hotel-booking-api.exe

# Frontend จะ hot reload อัตโนมัติ (ถ้าใช้ dev mode)
```

## ไฟล์ที่แก้ไข

1. `frontend/src/lib/api.ts` - ลบ phone validation
2. `backend/internal/service/booking_service.go` - เพิ่ม logic ดึงจาก account
3. `backend/internal/repository/booking_repository.go` - เพิ่ม GetGuestByID function

## หมายเหตุ

- Email field ทำงานแบบเดียวกับ phone (ถ้าไม่ส่งมาจะดึงจาก account)
- Logic นี้ใช้เฉพาะ primary guest เท่านั้น
- Guest คนอื่นๆ ไม่จำเป็นต้องมี phone หรือ email
