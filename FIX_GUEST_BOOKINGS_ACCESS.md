# แก้ไขปัญหา Guest ไม่สามารถเข้าหน้า Bookings ได้

## ปัญหาที่พบ
ผู้ใช้ guest ที่ sign in แล้วไม่สามารถเข้าหน้า "การจองของฉัน" (/bookings) ได้ แต่ถูก redirect ไปหน้า /unauthorized แทน ทั้งๆ ที่มี session อยู่แล้ว

## สาเหตุ
1. **Backend ไม่ส่ง role_code**: Auth service ไม่ได้ส่ง `role_code` ใน login response
2. **Repository ไม่ query role**: Auth repository query จาก table `guests` โดยตรง แทนที่จะใช้ view `v_all_users` ที่มี role_code
3. **Model ไม่มี field role**: Guest model ไม่มี field `RoleCode` และ `RoleName`
4. **Middleware ตรวจสอบ role**: Middleware ตรวจสอบ role แต่ token ไม่มี role_code ที่ถูกต้อง

## การแก้ไข

### 1. อัพเดท Guest Model (`backend/internal/models/guest.go`)
เพิ่ม field สำหรับ role:
```go
type Guest struct {
    GuestID   int       `json:"guest_id" db:"guest_id"`
    FirstName string    `json:"first_name" db:"first_name"`
    LastName  string    `json:"last_name" db:"last_name"`
    Email     string    `json:"email" db:"email"`
    Phone     string    `json:"phone" db:"phone"`
    RoleCode  string    `json:"role_code,omitempty" db:"role_code"`      // เพิ่มใหม่
    RoleName  string    `json:"role_name,omitempty" db:"role_name"`      // เพิ่มใหม่
    CreatedAt time.Time `json:"created_at" db:"created_at"`
    UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type LoginResponse struct {
    ID          int    `json:"id"`
    Email       string `json:"email"`
    FirstName   string `json:"first_name"`
    LastName    string `json:"last_name"`
    Role        string `json:"role"`
    RoleCode    string `json:"role_code"`    // เพิ่มใหม่
    UserType    string `json:"user_type"`    // เพิ่มใหม่
    AccessToken string `json:"accessToken"`
}
```

### 2. อัพเดท Auth Repository (`backend/internal/repository/auth_repository.go`)
เปลี่ยนจาก query table `guests` เป็น view `v_all_users`:
```go
func (r *AuthRepository) GetGuestByEmail(ctx context.Context, email string) (*models.Guest, error) {
    query := `
        SELECT 
            user_id as guest_id, 
            first_name, 
            last_name, 
            email, 
            phone, 
            role_code,
            role_name,
            hashed_password,
            created_at
        FROM v_all_users
        WHERE email = $1 AND user_type = 'guest'
    `
    // ... scan ข้อมูลรวมถึง role_code และ role_name
}
```

### 3. อัพเดท Auth Service (`backend/internal/service/auth_service.go`)
ส่ง role_code และ user_type ใน login response:
```go
func (s *AuthService) Login(ctx context.Context, req *models.LoginRequest) (*models.LoginResponse, error) {
    // ... authentication logic ...
    
    roleCode := guest.RoleCode
    if roleCode == "" {
        roleCode = "GUEST"
    }

    return &models.LoginResponse{
        ID:          guest.GuestID,
        Email:       guest.Email,
        FirstName:   guest.FirstName,
        LastName:    guest.LastName,
        Role:        "guest",
        RoleCode:    roleCode,      // ส่ง role_code
        UserType:    "guest",       // ส่ง user_type
        AccessToken: token,
    }, nil
}
```

### 4. อัพเดท Middleware (`frontend/src/middleware.ts`)
เพิ่ม routes ที่ guest สามารถเข้าถึงได้:
```typescript
const roleAccess: Record<string, string[]> = {
  '/bookings': ['GUEST', 'RECEPTIONIST', 'MANAGER'],
  '/booking': ['GUEST', 'RECEPTIONIST', 'MANAGER'],     // เพิ่มใหม่
  '/rooms/search': ['GUEST', 'RECEPTIONIST', 'MANAGER'], // เพิ่มใหม่
  // ... other routes
};
```

## วิธีทดสอบ

### 1. Build Backend ใหม่
```bash
cd backend
go build -o ../bin/server.exe ./cmd/server
```

### 2. Restart Backend
```bash
# หยุด backend ที่กำลังรันอยู่
# จากนั้นรันใหม่
start-backend-local.bat
```

### 3. ทดสอบ Login
1. เปิดเบราว์เซอร์ไปที่ http://localhost:3000
2. Login ด้วย:
   - Email: `anan.test@example.com`
   - Password: `password123`
3. หลัง login สำเร็จ ไปที่หน้า "การจองของฉัน" (/bookings)
4. ควรเห็นหน้า bookings ได้ปกติ ไม่ถูก redirect ไป /unauthorized

### 4. ตรวจสอบ Session
เปิด Developer Console และตรวจสอบ:
```javascript
// ตรวจสอบ session
fetch('/api/auth/session')
  .then(r => r.json())
  .then(console.log)

// ควรเห็น role: "GUEST" ใน response
```

## ผลลัพธ์ที่คาดหวัง
- ✅ Guest สามารถ login ได้
- ✅ Session มี role_code = "GUEST"
- ✅ Guest สามารถเข้าหน้า /bookings ได้
- ✅ Guest สามารถเข้าหน้า /booking/* (booking flow) ได้
- ✅ Guest สามารถเข้าหน้า /rooms/search ได้
- ✅ ไม่ถูก redirect ไป /unauthorized อีกต่อไป

## ไฟล์ที่แก้ไข
1. `backend/internal/models/guest.go` - เพิ่ม role fields
2. `backend/internal/repository/auth_repository.go` - ใช้ v_all_users view
3. `backend/internal/service/auth_service.go` - ส่ง role_code ใน response
4. `frontend/src/middleware.ts` - อัพเดท role access rules

## หมายเหตุ
- การแก้ไขนี้ใช้ view `v_all_users` ที่สร้างไว้ใน migration 014
- View นี้รวมข้อมูล guests และ staff พร้อม role_code
- Guest จะมี role_code = "GUEST" โดยอัตโนมัติ
