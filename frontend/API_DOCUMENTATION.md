# 📡 API Documentation - Hotel Booking System

> **REST API Endpoints สำหรับระบบจองห้องพัก**

---

## 🌐 Base URL

```
Local: http://localhost:3000/api
Production: https://your-app.vercel.app/api
```

---

## 📋 Table of Contents

1. [Test Endpoints](#test-endpoints)
2. [Room Endpoints](#room-endpoints)
3. [Booking Endpoints](#booking-endpoints)
4. [Guest Endpoints](#guest-endpoints)
5. [Error Handling](#error-handling)
6. [Type Definitions](#type-definitions)

---

## 🧪 Test Endpoints

### Test Database Connection

```http
GET /api/test-db
```

**Response**:
```json
{
  "success": true,
  "message": "✅ Database connection successful!",
  "timestamp": "2025-11-04T10:00:00.000Z",
  "database": {
    "version": "PostgreSQL 16.0",
    "database": "neondb",
    "user": "username"
  },
  "counts": {
    "guests": 5,
    "roomTypes": 4,
    "rooms": 15,
    "bookings": 0,
    "amenities": 10
  },
  "samples": {
    "guests": [...],
    "roomTypes": [...],
    "rooms": [...]
  }
}
```

---

## 🏨 Room Endpoints

### 1. Get All Room Types

```http
GET /api/rooms
```

**Description**: ดูห้องพักทั้งหมด พร้อม Amenities, Images, และ Rate Plans

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "roomTypeId": 1,
      "name": "Standard Room",
      "description": "ห้องพักมาตรฐาน สะดวกสบาย",
      "maxOccupancy": 2,
      "basePrice": "1500.00",
      "sizeSqm": "25.00",
      "bedType": "Queen Bed",
      "amenities": [
        {
          "amenity": {
            "amenityId": 1,
            "name": "WiFi",
            "icon": "📶",
            "category": "Technology"
          }
        }
      ],
      "images": [...],
      "ratePlans": [...]
    }
  ]
}
```

---

### 2. Search Available Rooms

```http
GET /api/rooms?checkIn=2025-11-10&checkOut=2025-11-12&guests=2
```

**Query Parameters**:
- `checkIn` (required): วันเช็คอิน (YYYY-MM-DD)
- `checkOut` (required): วันเช็คเอาท์ (YYYY-MM-DD)
- `guests` (optional): จำนวนผู้เข้าพัก (default: 2)

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "roomTypeId": 1,
      "name": "Standard Room",
      "availability": {
        "available": true,
        "minAvailableRooms": 8,
        "details": [
          {
            "stayDate": "2025-11-10",
            "availableRooms": 10,
            "totalRooms": 10
          },
          {
            "stayDate": "2025-11-11",
            "availableRooms": 8,
            "totalRooms": 10
          }
        ]
      }
    }
  ],
  "filters": {
    "checkIn": "2025-11-10",
    "checkOut": "2025-11-12",
    "guests": 2
  }
}
```

---

### 3. Get Room Type Details

```http
GET /api/rooms/[id]
```

**Parameters**:
- `id`: Room Type ID

**Example**:
```http
GET /api/rooms/1
```

**Response**:
```json
{
  "success": true,
  "data": {
    "roomTypeId": 1,
    "name": "Standard Room",
    "description": "ห้องพักมาตรฐาน สะดวกสบาย",
    "maxOccupancy": 2,
    "basePrice": "1500.00",
    "sizeSqm": "25.00",
    "bedType": "Queen Bed",
    "amenities": [...],
    "images": [...],
    "ratePlans": [...],
    "rooms": [
      {
        "roomId": 1,
        "roomNumber": "101",
        "floor": 1,
        "occupancyStatus": "Vacant",
        "housekeepingStatus": "Clean"
      }
    ]
  }
}
```

---

## 📅 Booking Endpoints

### 1. Create Booking

```http
POST /api/bookings
```

**Request Body**:
```json
{
  "guestId": 1,
  "roomTypeId": 1,
  "ratePlanId": 1,
  "checkIn": "2025-11-10",
  "checkOut": "2025-11-12",
  "adults": 2,
  "children": 0,
  "specialRequests": "Late check-in"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "bookingId": 1,
    "guestId": 1,
    "roomTypeId": 1,
    "ratePlanId": 1,
    "arrivalDate": "2025-11-10",
    "departureDate": "2025-11-12",
    "adults": 2,
    "children": 0,
    "totalAmount": "3000.00",
    "status": "Hold",
    "holdExpiresAt": "2025-11-04T10:15:00.000Z",
    "createdAt": "2025-11-04T10:00:00.000Z"
  },
  "message": "Booking created successfully. Please confirm within 15 minutes."
}
```

---

### 2. Get Guest Bookings

```http
GET /api/bookings?guestId=1
```

**Query Parameters**:
- `guestId` (required): Guest ID

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "bookingId": 1,
      "status": "Confirmed",
      "arrivalDate": "2025-11-10",
      "departureDate": "2025-11-12",
      "totalAmount": "3000.00",
      "roomType": {
        "name": "Standard Room"
      },
      "room": {
        "roomNumber": "101"
      }
    }
  ]
}
```

---

### 3. Get Booking Details

```http
GET /api/bookings/[id]
```

**Parameters**:
- `id`: Booking ID

**Example**:
```http
GET /api/bookings/1
```

**Response**:
```json
{
  "success": true,
  "data": {
    "bookingId": 1,
    "guest": {
      "guestId": 1,
      "firstName": "ทดสอบ",
      "lastName": "ระบบหนึ่ง",
      "email": "test.user1@example.com"
    },
    "roomType": {
      "name": "Standard Room",
      "amenities": [...]
    },
    "room": {
      "roomNumber": "101",
      "floor": 1
    },
    "ratePlan": {
      "name": "Best Available Rate",
      "baseRate": "1500.00"
    },
    "arrivalDate": "2025-11-10",
    "departureDate": "2025-11-12",
    "adults": 2,
    "children": 0,
    "totalAmount": "3000.00",
    "status": "Confirmed",
    "confirmedAt": "2025-11-04T10:05:00.000Z"
  }
}
```

---

### 4. Confirm Booking

```http
POST /api/bookings/[id]/confirm
```

**Request Body**:
```json
{
  "roomId": 1
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "bookingId": 1,
    "roomId": 1,
    "status": "Confirmed",
    "confirmedAt": "2025-11-04T10:05:00.000Z"
  },
  "message": "Booking confirmed successfully"
}
```

---

### 5. Cancel Booking

```http
POST /api/bookings/[id]/cancel
```

**Response**:
```json
{
  "success": true,
  "data": {
    "bookingId": 1,
    "status": "Cancelled",
    "cancelledAt": "2025-11-04T10:10:00.000Z"
  },
  "message": "Booking cancelled successfully"
}
```

---

## 👤 Guest Endpoints

### 1. Create Guest

```http
POST /api/guests
```

**Request Body**:
```json
{
  "firstName": "ทดสอบ",
  "lastName": "ระบบหนึ่ง",
  "email": "test.user1@example.com",
  "phone": "0812345678"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "guestId": 1,
    "firstName": "สมชาย",
    "lastName": "ใจดี",
    "email": "somchai@example.com",
    "phone": "0812345678",
    "createdAt": "2025-11-04T10:00:00.000Z"
  }
}
```

---

### 2. Get Guest by Email

```http
GET /api/guests?email=somchai@example.com
```

**Response**:
```json
{
  "success": true,
  "data": {
    "guestId": 1,
    "firstName": "สมชาย",
    "lastName": "ใจดี",
    "email": "somchai@example.com",
    "phone": "0812345678",
    "account": {
      "lastLogin": "2025-11-04T09:00:00.000Z"
    }
  }
}
```

---

## ❌ Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": "Error message here"
}
```

### HTTP Status Codes

- `200` - Success
- `400` - Bad Request (Invalid parameters)
- `404` - Not Found
- `500` - Internal Server Error

### Common Errors

#### 400 Bad Request
```json
{
  "success": false,
  "error": "Missing required fields"
}
```

#### 404 Not Found
```json
{
  "success": false,
  "error": "Room type not found"
}
```

#### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Database connection failed"
}
```

---

## 📝 Type Definitions

### RoomType
```typescript
interface RoomType {
  roomTypeId: number;
  name: string;
  description: string | null;
  maxOccupancy: number;
  defaultAllotment: number;
  basePrice: string;
  sizeSqm: string | null;
  bedType: string | null;
  createdAt: Date;
  updatedAt: Date;
}
```

### Booking
```typescript
interface Booking {
  bookingId: number;
  guestId: number;
  roomTypeId: number;
  roomId: number | null;
  ratePlanId: number;
  arrivalDate: Date;
  departureDate: Date;
  adults: number;
  children: number;
  totalAmount: string;
  status: 'Hold' | 'Confirmed' | 'CheckedIn' | 'CheckedOut' | 'Cancelled' | 'NoShow';
  specialRequests: string | null;
  createdAt: Date;
  updatedAt: Date;
  confirmedAt: Date | null;
  checkedInAt: Date | null;
  checkedOutAt: Date | null;
  cancelledAt: Date | null;
  holdExpiresAt: Date | null;
}
```

### Guest
```typescript
interface Guest {
  guestId: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string | null;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## 🔐 Authentication (Coming Soon)

Authentication endpoints จะถูกเพิ่มในอนาคต:

- `POST /api/auth/register` - สมัครสมาชิก
- `POST /api/auth/login` - เข้าสู่ระบบ
- `POST /api/auth/logout` - ออกจากระบบ
- `GET /api/auth/session` - ตรวจสอบ Session

---

## 📊 Statistics Endpoints (Coming Soon)

- `GET /api/statistics/bookings` - สถิติการจอง
- `GET /api/statistics/rooms` - สถิติห้องพัก
- `GET /api/statistics/occupancy` - Occupancy Rate

---

## 🧪 Testing

### Using cURL

```bash
# Test database connection
curl http://localhost:3000/api/test-db

# Get all rooms
curl http://localhost:3000/api/rooms

# Search available rooms
curl "http://localhost:3000/api/rooms?checkIn=2025-11-10&checkOut=2025-11-12&guests=2"

# Get room details
curl http://localhost:3000/api/rooms/1

# Create booking
curl -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "guestId": 1,
    "roomTypeId": 1,
    "ratePlanId": 1,
    "checkIn": "2025-11-10",
    "checkOut": "2025-11-12",
    "adults": 2
  }'
```

### Using Postman

1. Import collection จาก `postman_collection.json` (Coming Soon)
2. Set environment variables:
   - `base_url`: `http://localhost:3000/api`
3. Run tests

---

## 📚 Additional Resources

- [Database Schema](./frontend/src/db/schema.ts)
- [Query Helpers](./frontend/src/db/queries.ts)
- [Type Definitions](./frontend/src/types/database.ts)
- [Database Migrations](../database/migrations/)

---

**Created**: 2025-11-04  
**Version**: 1.0.0  
**Status**: ✅ Active Development
