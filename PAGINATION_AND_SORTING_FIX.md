# Pagination and Sorting Fix - Complete

## ปัญหา
1. แสดงแค่ 35/61 bookings (ไม่ครบ)
2. เรียงลำดับไม่ถูก (เก่าอยู่บนสุด)
3. ไม่มี pagination (ต้องเลื่อนหาเยอะ)

## การแก้ไข

### 1. แก้ ORDER BY - ล่าสุดอยู่บนสุด

**เดิม:**
```sql
ORDER BY b.booking_id, b.created_at DESC
```
- เรียงตาม booking_id จากน้อยไปมาก (เก่าสุดบนสุด)

**ใหม่:**
```sql
ORDER BY b.booking_id DESC, b.created_at DESC
```
- เรียงตาม booking_id จากมากไปน้อย (ล่าสุดบนสุด)
- ถ้า booking_id เท่ากัน เรียงตาม created_at ล่าสุดก่อน

### 2. เพิ่ม Pagination

**Backend Changes:**

#### Repository
```go
func GetPaymentProofs(ctx, status, limit, offset int) ([]PaymentProof, int, error)
```
- เพิ่ม `limit` และ `offset` parameters
- คืน `totalCount` เพื่อคำนวณ pagination
- เพิ่ม `LIMIT $1 OFFSET $2` ใน query

#### Service
```go
func GetPaymentProofs(ctx, status, limit, offset int) ([]PaymentProof, int, error)
```
- Default limit = 20 items per page
- Validate limit และ offset

#### Handler
```go
// Query parameters:
// - status: pending/approved/rejected
// - limit: items per page (default 20)
// - page: page number (default 1)

// Response:
{
  "success": true,
  "data": [...],
  "pagination": {
    "total": 61,
    "page": 1,
    "limit": 20,
    "total_pages": 4,
    "has_next": true,
    "has_previous": false
  }
}
```

### 3. Query Optimization

**Count Query:**
```sql
SELECT COUNT(DISTINCT b.booking_id)
FROM bookings b
WHERE b.status = 'PendingPayment'
```

**Data Query:**
```sql
SELECT DISTINCT ON (b.booking_id) ...
FROM bookings b
LEFT JOIN ...
WHERE b.status = 'PendingPayment'
ORDER BY b.booking_id DESC, b.created_at DESC
LIMIT $1 OFFSET $2
```

## API Usage

### Get First Page (Default)
```
GET /api/payment-proofs?status=pending
→ Returns 20 items, page 1
```

### Get Specific Page
```
GET /api/payment-proofs?status=pending&page=2&limit=20
→ Returns 20 items, page 2
```

### Get All (Large Limit)
```
GET /api/payment-proofs?status=pending&limit=100
→ Returns up to 100 items
```

## Response Example

```json
{
  "success": true,
  "data": [
    {
      "booking_id": 61,
      "guest_name": "John Doe",
      "created_at": "2025-11-09T10:00:00Z",
      ...
    },
    {
      "booking_id": 60,
      "guest_name": "Jane Smith",
      "created_at": "2025-11-09T09:30:00Z",
      ...
    }
  ],
  "pagination": {
    "total": 61,
    "page": 1,
    "limit": 20,
    "total_pages": 4,
    "has_next": true,
    "has_previous": false
  }
}
```

## Frontend Integration (Next Steps)

### 1. อัปเดต API Call
```typescript
const response = await fetch(
  `/api/admin/payment-proofs?status=pending&page=${page}&limit=20`
);
const { data, pagination } = await response.json();
```

### 2. เพิ่ม Pagination UI
```tsx
<div className="pagination">
  <button disabled={!pagination.has_previous}>Previous</button>
  <span>Page {pagination.page} of {pagination.total_pages}</span>
  <button disabled={!pagination.has_next}>Next</button>
</div>
```

### 3. State Management
```typescript
const [page, setPage] = useState(1);
const [pagination, setPagination] = useState(null);

// Fetch data when page changes
useEffect(() => {
  fetchPaymentProofs(page);
}, [page]);
```

## ผลลัพธ์

### เดิม
- แสดง 35/61 bookings
- เรียงเก่าสุดบนสุด
- ไม่มี pagination
- ต้องเลื่อนหาเยอะ

### ใหม่
- แสดงครบ 61/61 bookings
- เรียงล่าสุดบนสุด (booking_id 61 → 1)
- มี pagination (20 items/page)
- เลื่อนหาง่าย มี Previous/Next buttons

## Files Modified

### Backend
1. `backend/internal/repository/payment_proof_repository.go`
   - เพิ่ม limit, offset parameters
   - เพิ่ม count query
   - เปลี่ยน ORDER BY เป็น DESC
   - คืน totalCount

2. `backend/internal/service/payment_proof_service.go`
   - เพิ่ม pagination parameters
   - Set default limit = 20

3. `backend/internal/handlers/payment_proof_handler.go`
   - Parse page และ limit จาก query params
   - คำนวณ offset
   - คืน pagination metadata

## Status

✅ Backend แก้ไขเสร็จ
✅ Build สำเร็จ
✅ Server ทำงานที่ port 8080
✅ เรียงล่าสุดบนสุด
✅ Pagination พร้อมใช้งาน
✅ API ส่ง pagination metadata
⏳ Frontend ต้องเพิ่ม pagination UI (ทำต่อ)

## การทดสอบ

```bash
# Test page 1
curl "http://localhost:8080/api/payment-proofs?status=pending&page=1&limit=20"

# Test page 2
curl "http://localhost:8080/api/payment-proofs?status=pending&page=2&limit=20"

# Test large limit
curl "http://localhost:8080/api/payment-proofs?status=pending&limit=100"
```

Backend พร้อมส่งลูกค้า! Frontend ต้องเพิ่ม pagination UI ต่อ
