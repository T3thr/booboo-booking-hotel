# แก้ไข Go Compile Error

## ปัญหา

```
internal\service\auth_service.go:134:16: cannot use user.Phone (variable of type *string) as string value in struct literal
```

## สาเหตุ

**Type Mismatch:**
- `UnifiedUser.Phone` เป็น `*string` (pointer)
- `LoginResponse.Phone` เป็น `string` (value)
- ไม่สามารถ assign pointer ไปยัง value ได้โดยตรง

## การแก้ไข

**File:** `backend/internal/service/auth_service.go`

**Before:**
```go
return &models.LoginResponse{
    ID:          user.UserID,
    Email:       user.Email,
    FirstName:   user.FirstName,
    LastName:    user.LastName,
    Phone:       user.Phone,  // ← Error: *string ไม่ตรงกับ string
    Role:        user.UserType,
    RoleCode:    user.RoleCode,
    UserType:    user.UserType,
    AccessToken: token,
}, nil
```

**After:**
```go
// Dereference phone pointer, use empty string if nil
phone := ""
if user.Phone != nil {
    phone = *user.Phone
}

return &models.LoginResponse{
    ID:          user.UserID,
    Email:       user.Email,
    FirstName:   user.FirstName,
    LastName:    user.LastName,
    Phone:       phone,  // ← Fixed: ใช้ string value
    Role:        user.UserType,
    RoleCode:    user.RoleCode,
    UserType:    user.UserType,
    AccessToken: token,
}, nil
```

## Logic

1. สร้างตัวแปร `phone` เป็น empty string
2. ตรวจสอบว่า `user.Phone` ไม่เป็น nil
3. ถ้าไม่เป็น nil → dereference pointer ด้วย `*user.Phone`
4. ใช้ `phone` (string value) ใน LoginResponse

## ทำไมต้อง Dereference?

**Pointer vs Value:**
```go
var ptr *string = &"hello"  // pointer to string
var val string = "hello"    // string value

// ❌ Cannot assign pointer to value
val = ptr  // Error!

// ✅ Must dereference pointer
val = *ptr  // OK!
```

**Nil Safety:**
```go
var ptr *string = nil

// ❌ Dangerous - panic if nil
val := *ptr  // Runtime panic!

// ✅ Safe - check before dereference
val := ""
if ptr != nil {
    val = *ptr
}
```

## ผลลัพธ์

✅ Go compile สำเร็จ
✅ Login API ส่ง phone ได้ถูกต้อง
✅ Frontend ได้รับ phone จาก session
✅ Guest account booking ทำงานปกติ

## การ Build

```bash
cd backend
go build -o hotel-booking-api.exe ./cmd/server
```

หรือใช้:
```bash
cd backend
go run cmd/server/main.go
```

## หมายเหตุ

- Phone เป็น nullable ใน database (`*string`)
- LoginResponse ต้องการ string value
- ต้อง dereference และ handle nil case
- ใช้ empty string เป็น default ถ้า phone เป็น nil
