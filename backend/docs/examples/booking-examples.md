# Booking API Examples

## Create Booking Hold

### Request
```http
POST /api/bookings/hold HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "sessionId": "sess_abc123xyz",
  "roomTypeId": 1,
  "checkIn": "2025-12-01",
  "checkOut": "2025-12-05"
}
```

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "สร้าง hold สำเร็จ",
  "holdId": 123,
  "holdExpiry": "2025-11-03T14:45:00Z"
}
```

### Error Response - Room Not Available (400 Bad Request)
```json
{
  "error": "ห้องไม่ว่างแล้ว กรุณาเลือกห้องอื่น"
}
```

## Create Booking

### Request
```http
POST /api/bookings HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "sessionId": "sess_abc123xyz",
  "voucherCode": "SUMMER2025",
  "bookingDetails": [
    {
      "roomTypeId": 1,
      "ratePlanId": 1,
      "checkInDate": "2025-12-01",
      "checkOutDate": "2025-12-05",
      "numGuests": 2
    }
  ],
  "guests": [
    {
      "firstName": "สมชาย",
      "lastName": "ใจดี",
      "type": "Adult",
      "isPrimary": true
    },
    {
      "firstName": "สมหญิง",
      "lastName": "ใจดี",
      "type": "Adult",
      "isPrimary": false
    }
  ]
}
```

### Success Response (201 Created)
```json
{
  "bookingId": 1,
  "guestId": 1,
  "totalAmount": 9000.00,
  "status": "PendingPayment",
  "policyName": "Standard Cancellation Policy",
  "policyDescription": "ยกเลิกฟรีก่อน 7 วัน คืนเงิน 100%",
  "createdAt": "2025-11-03T14:30:00Z",
  "updatedAt": "2025-11-03T14:30:00Z",
  "details": [
    {
      "bookingDetailId": 1,
      "roomTypeId": 1,
      "roomTypeName": "Deluxe Room",
      "checkInDate": "2025-12-01",
      "checkOutDate": "2025-12-05",
      "numGuests": 2,
      "roomNumber": null
    }
  ]
}
```

## Confirm Booking

### Request
```http
POST /api/bookings/1/confirm HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "paymentMethod": "credit_card"
}
```

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "ยืนยันการจองสำเร็จ"
}
```

### Error Response - Cannot Confirm (400 Bad Request)
```json
{
  "error": "การจองนี้ไม่สามารถยืนยันได้"
}
```

## Get User Bookings

### Request
```http
GET /api/bookings?status=Confirmed&limit=10&offset=0 HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Success Response (200 OK)
```json
{
  "bookings": [
    {
      "bookingId": 1,
      "guestId": 1,
      "totalAmount": 9000.00,
      "status": "Confirmed",
      "policyName": "Standard Cancellation Policy",
      "policyDescription": "ยกเลิกฟรีก่อน 7 วัน คืนเงิน 100%",
      "createdAt": "2025-11-03T14:30:00Z",
      "updatedAt": "2025-11-03T14:35:00Z",
      "details": [
        {
          "bookingDetailId": 1,
          "roomTypeId": 1,
          "roomTypeName": "Deluxe Room",
          "checkInDate": "2025-12-01",
          "checkOutDate": "2025-12-05",
          "numGuests": 2,
          "roomNumber": null
        }
      ]
    }
  ],
  "total": 1
}
```

## Get Booking by ID

### Request
```http
GET /api/bookings/1 HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Success Response (200 OK)
```json
{
  "bookingId": 1,
  "guestId": 1,
  "totalAmount": 9000.00,
  "status": "Confirmed",
  "policyName": "Standard Cancellation Policy",
  "policyDescription": "ยกเลิกฟรีก่อน 7 วัน คืนเงิน 100%",
  "createdAt": "2025-11-03T14:30:00Z",
  "updatedAt": "2025-11-03T14:35:00Z",
  "details": [
    {
      "bookingDetailId": 1,
      "roomTypeId": 1,
      "roomTypeName": "Deluxe Room",
      "checkInDate": "2025-12-01",
      "checkOutDate": "2025-12-05",
      "numGuests": 2,
      "roomNumber": null
    }
  ]
}
```

## Cancel Booking

### Request
```http
POST /api/bookings/1/cancel HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "reason": "Change of plans"
}
```

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "ยกเลิกการจองสำเร็จ",
  "refundAmount": 9000.00
}
```

### Error Response - Cannot Cancel (400 Bad Request)
```json
{
  "error": "ไม่สามารถยกเลิกการจองนี้ได้"
}
```

## cURL Examples

```bash
# Create Hold
curl -X POST http://localhost:8080/api/bookings/hold \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "sess_abc123xyz",
    "roomTypeId": 1,
    "checkIn": "2025-12-01",
    "checkOut": "2025-12-05"
  }'

# Create Booking
curl -X POST http://localhost:8080/api/bookings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "sess_abc123xyz",
    "bookingDetails": [{
      "roomTypeId": 1,
      "ratePlanId": 1,
      "checkInDate": "2025-12-01",
      "checkOutDate": "2025-12-05",
      "numGuests": 2
    }],
    "guests": [{
      "firstName": "สมชาย",
      "lastName": "ใจดี",
      "type": "Adult",
      "isPrimary": true
    }]
  }'

# Confirm Booking
curl -X POST http://localhost:8080/api/bookings/1/confirm \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"paymentMethod": "credit_card"}'

# Get Bookings
curl -X GET "http://localhost:8080/api/bookings?status=Confirmed" \
  -H "Authorization: Bearer <TOKEN>"

# Cancel Booking
curl -X POST http://localhost:8080/api/bookings/1/cancel \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Change of plans"}'
```
