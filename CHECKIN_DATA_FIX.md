# แก้ไขปัญหา Check-in Page ไม่แสดงข้อมูล

## ปัญหา
1. หน้า admin/checkin ไม่แสดงรายการแขกที่จะมาถึง
2. ข้อมูล payment proof ไม่ถูกส่งมาจาก backend
3. Frontend ต้องการข้อมูล `room_type_id`, `payment_status`, `payment_proof_url` แต่ backend ไม่ส่ง

## สาเหตุ
Backend model `ArrivalInfo` ไม่มีฟิลด์ที่ frontend ต้องการ:
- `room_type_id` - สำหรับเลือกห้องว่าง
- `payment_status` - สถานะการชำระเงิน
- `payment_proof_url` - รูปหลักฐานการชำระเงิน
- `payment_proof_id` - ID สำหรับอนุมัติ/ปฏิเสธ

## วิธีแก้ไข

### ขั้นตอนที่ 1: อัปเดต Backend Model

แก้ไขไฟล์ `backend/internal/models/booking.go`:

```go
// ArrivalInfo represents information about an arriving guest
type ArrivalInfo struct {
	BookingID        int       `json:"booking_id" db:"booking_id"`
	BookingDetailID  int       `json:"booking_detail_id" db:"booking_detail_id"`
	GuestName        string    `json:"guest_name" db:"guest_name"`
	RoomTypeName     string    `json:"room_type_name" db:"room_type_name"`
	RoomTypeID       int       `json:"room_type_id" db:"room_type_id"`
	CheckInDate      time.Time `json:"check_in_date" db:"check_in_date"`
	CheckOutDate     time.Time `json:"check_out_date" db:"check_out_date"`
	NumGuests        int       `json:"num_guests" db:"num_guests"`
	Status           string    `json:"status" db:"status"`
	RoomNumber       *string   `json:"room_number,omitempty" db:"room_number"`
	PaymentStatus    string    `json:"payment_status" db:"payment_status"`
	PaymentProofURL  *string   `json:"payment_proof_url,omitempty" db:"payment_proof_url"`
	PaymentProofID   *int      `json:"payment_proof_id,omitempty" db:"payment_proof_id"`
}
```

### ขั้นตอนที่ 2: อัปเดต Repository Query

แก้ไขไฟล์ `backend/internal/repository/booking_repository.go` ฟังก์ชัน `GetArrivals`:

```go
// GetArrivals retrieves bookings arriving on a specific date
func (r *BookingRepository) GetArrivals(ctx context.Context, date time.Time) ([]models.ArrivalInfo, error) {
	query := `
		SELECT 
			b.booking_id,
			bd.booking_detail_id,
			CONCAT(g.first_name, ' ', g.last_name) as guest_name,
			rt.name as room_type_name,
			bd.room_type_id,
			bd.check_in_date,
			bd.check_out_date,
			bd.num_guests,
			b.status,
			r.room_number,
			COALESCE(pp.status, 'none') as payment_status,
			pp.image_url as payment_proof_url,
			pp.payment_proof_id
		FROM bookings b
		JOIN guests g ON b.guest_id = g.guest_id
		JOIN booking_details bd ON b.booking_id = bd.booking_id
		JOIN room_types rt ON bd.room_type_id = rt.room_type_id
		LEFT JOIN room_assignments ra ON bd.booking_detail_id = ra.booking_detail_id AND ra.status = 'Active'
		LEFT JOIN rooms r ON ra.room_id = r.room_id
		LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
		WHERE bd.check_in_date = $1
		  AND b.status IN ('Confirmed', 'CheckedIn')
		ORDER BY b.status DESC, bd.check_in_date
	`

	rows, err := r.db.Pool.Query(ctx, query, date)
	if err != nil {
		return nil, fmt.Errorf("failed to get arrivals: %w", err)
	}
	defer rows.Close()

	var arrivals []models.ArrivalInfo
	for rows.Next() {
		var arrival models.ArrivalInfo
		err := rows.Scan(
			&arrival.BookingID,
			&arrival.BookingDetailID,
			&arrival.GuestName,
			&arrival.RoomTypeName,
			&arrival.RoomTypeID,
			&arrival.CheckInDate,
			&arrival.CheckOutDate,
			&arrival.NumGuests,
			&arrival.Status,
			&arrival.RoomNumber,
			&arrival.PaymentStatus,
			&arrival.PaymentProofURL,
			&arrival.PaymentProofID,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan arrival: %w", err)
		}
		arrivals = append(arrivals, arrival)
	}

	return arrivals, nil
}
```

### ขั้นตอนที่ 3: Rebuild และ Redeploy Backend

```bash
# ใน local
cd backend
go build -o main ./cmd/server

# ทดสอบ local
./main

# Deploy ไป Render
git add .
git commit -m "fix: Add payment proof fields to arrivals API"
git push origin main
```

### ขั้นตอนที่ 4: ตรวจสอบว่ามีข้อมูลใน Database

```sql
-- ตรวจสอบว่ามี bookings ที่ confirmed
SELECT 
    b.booking_id,
    b.status,
    bd.check_in_date,
    bd.check_out_date,
    CONCAT(g.first_name, ' ', g.last_name) as guest_name,
    rt.name as room_type_name,
    COALESCE(pp.status, 'none') as payment_status
FROM bookings b
JOIN guests g ON b.guest_id = g.guest_id
JOIN booking_details bd ON b.booking_id = bd.booking_id
JOIN room_types rt ON bd.room_type_id = rt.room_type_id
LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
WHERE b.status IN ('Confirmed', 'CheckedIn')
ORDER BY bd.check_in_date;
```

ถ้าไม่มีข้อมูล ให้รัน seed data:

```bash
cd database/migrations
psql $DATABASE_URL -f 020_seed_checkin_test_data.sql
```

## ทดสอบ API

### 1. ทดสอบ arrivals endpoint:

```bash
# Get token first
TOKEN="your_jwt_token_here"

# Test arrivals
curl "https://booboo-booking.onrender.com/api/checkin/arrivals?date=2025-01-15" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Origin: https://booboo-booking.vercel.app"
```

ควรได้ response:
```json
{
  "arrivals": [
    {
      "booking_id": 1,
      "booking_detail_id": 1,
      "guest_name": "John Doe",
      "room_type_name": "Deluxe Room",
      "room_type_id": 1,
      "check_in_date": "2025-01-15T00:00:00Z",
      "check_out_date": "2025-01-17T00:00:00Z",
      "num_guests": 2,
      "status": "Confirmed",
      "payment_status": "approved",
      "payment_proof_url": "https://...",
      "payment_proof_id": 1
    }
  ],
  "count": 1
}
```

### 2. ทดสอบ available rooms:

```bash
curl "https://booboo-booking.onrender.com/api/checkin/available-rooms/1" \
  -H "Authorization: Bearer $TOKEN"
```

## สรุปการแก้ไข

1. **เพิ่มฟิลด์ใน Model**: `room_type_id`, `payment_status`, `payment_proof_url`, `payment_proof_id`
2. **อัปเดต SQL Query**: JOIN กับ `payment_proofs` table และ SELECT ฟิลด์ที่ต้องการ
3. **อัปเดต Scan**: เพิ่มการ scan ฟิลด์ใหม่
4. **Seed Test Data**: ถ้าไม่มีข้อมูลให้รัน migration 020

## หมายเหตุ

- ถ้า `payment_proofs` table ไม่มี ให้ตรวจสอบว่ารัน migration 015 แล้วหรือยัง
- Payment status จะเป็น 'none' ถ้าไม่มีการอัปโหลดหลักฐาน
- Frontend จะแสดงปุ่มอนุมัติ/ปฏิเสธเฉพาะเมื่อ status เป็น 'pending'
