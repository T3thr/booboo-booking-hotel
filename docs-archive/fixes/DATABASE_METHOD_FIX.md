# แก้ไขปัญหา Database Method Calls

## ปัญหาที่เกิดขึ้น
หลังจากแก้ไข struct duplication แล้ว เกิด error ใหม่:
```
r.db.Query undefined (type *database.DB has no field or method Query)
r.db.QueryRow undefined (type *database.DB has no field or method QueryRow)
r.db.Exec undefined (type *database.DB has no field or method Exec)
```

## สาเหตุ
Database struct (`*database.DB`) ไม่มี method `Query`, `QueryRow`, `Exec` โดยตรง
แต่มี field `Pool` ที่เป็น `*pgxpool.Pool` ซึ่งมี method เหล่านี้

## การแก้ไข
เปลี่ยนจาก:
```go
r.db.Query(ctx, query)
r.db.QueryRow(ctx, query)
r.db.Exec(ctx, query)
```

เป็น:
```go
r.db.Pool.Query(ctx, query)
r.db.Pool.QueryRow(ctx, query)
r.db.Pool.Exec(ctx, query)
```

## ไฟล์ที่ต้องแก้ไข
- ✅ `backend/internal/repository/inventory_repository.go` - แก้ไขแล้ว
- ✅ `backend/internal/repository/policy_repository.go` - แก้ไขแล้ว
- ⏳ `backend/internal/repository/pricing_repository.go` - ต้องแก้ไข
- ⏳ `backend/internal/repository/report_repository.go` - ต้องแก้ไข

## วิธีแก้ไขอัตโนมัติ
รัน script ใดๆ ต่อไปนี้:

### Windows PowerShell:
```powershell
./fix-db-methods.ps1
```

### Windows Batch:
```batch
./quick-fix.bat
```

### Manual Fix:
ใช้ Find & Replace ในไฟล์:
- Find: `r.db.Query(`
- Replace: `r.db.Pool.Query(`

- Find: `r.db.QueryRow(`
- Replace: `r.db.Pool.QueryRow(`

- Find: `r.db.Exec(`
- Replace: `r.db.Pool.Exec(`

## การทดสอบ
หลังจากแก้ไขแล้ว ทดสอบด้วย:
```bash
cd backend
go build -o main ./cmd/server
```

หรือ
```bash
cd backend
docker build -t test-backend .
```

## ผลลัพธ์ที่คาดหวัง
- Backend จะ compile สำเร็จ
- ไม่มี database method errors
- พร้อม deploy ใน Render