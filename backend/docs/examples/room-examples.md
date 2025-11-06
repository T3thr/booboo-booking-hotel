# Room API Examples

## Search Available Rooms

### Request
```http
GET /api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2 HTTP/1.1
Host: localhost:8080
```

### Success Response (200 OK)
```json
{
  "availableRooms": [
    {
      "roomTypeId": 1,
      "name": "Deluxe Room",
      "description": "ห้องพักหรูพร้อมวิวทะเล",
      "maxOccupancy": 2,
      "defaultAllotment": 10,
      "amenities": [
        {
          "amenityId": 1,
          "name": "WiFi"
        },
        {
          "amenityId": 2,
          "name": "Air Conditioning"
        },
        {
          "amenityId": 3,
          "name": "TV"
        }
      ],
      "images": [
        "/images/deluxe-1.jpg",
        "/images/deluxe-2.jpg"
      ],
      "basePrice": 2500.00,
      "totalPrice": 10000.00,
      "pricePerNight": [
        {
          "date": "2025-12-01",
          "price": 2500.00,
          "tier": "Standard"
        },
        {
          "date": "2025-12-02",
          "price": 2500.00,
          "tier": "Standard"
        },
        {
          "date": "2025-12-03",
          "price": 2500.00,
          "tier": "Standard"
        },
        {
          "date": "2025-12-04",
          "price": 2500.00,
          "tier": "Standard"
        }
      ],
      "availableCount": 5
    },
    {
      "roomTypeId": 2,
      "name": "Suite Room",
      "description": "ห้องสวีทพร้อมห้องนั่งเล่นแยก",
      "maxOccupancy": 4,
      "defaultAllotment": 5,
      "amenities": [
        {
          "amenityId": 1,
          "name": "WiFi"
        },
        {
          "amenityId": 2,
          "name": "Air Conditioning"
        },
        {
          "amenityId": 3,
          "name": "TV"
        },
        {
          "amenityId": 4,
          "name": "Mini Bar"
        }
      ],
      "images": [
        "/images/suite-1.jpg",
        "/images/suite-2.jpg"
      ],
      "basePrice": 4500.00,
      "totalPrice": 18000.00,
      "pricePerNight": [
        {
          "date": "2025-12-01",
          "price": 4500.00,
          "tier": "Standard"
        },
        {
          "date": "2025-12-02",
          "price": 4500.00,
          "tier": "Standard"
        },
        {
          "date": "2025-12-03",
          "price": 4500.00,
          "tier": "Standard"
        },
        {
          "date": "2025-12-04",
          "price": 4500.00,
          "tier": "Standard"
        }
      ],
      "availableCount": 3
    }
  ],
  "checkIn": "2025-12-01",
  "checkOut": "2025-12-05",
  "nights": 4
}
```

### Error Response - Invalid Date (400 Bad Request)
```json
{
  "error": "รูปแบบวันที่ check-in ไม่ถูกต้อง"
}
```

### Error Response - Past Date (400 Bad Request)
```json
{
  "error": "วันที่ check-in ต้องไม่อยู่ในอดีต"
}
```

## Get All Room Types

### Request
```http
GET /api/rooms/types HTTP/1.1
Host: localhost:8080
```

### Success Response (200 OK)
```json
[
  {
    "roomTypeId": 1,
    "name": "Deluxe Room",
    "description": "ห้องพักหรูพร้อมวิวทะเล",
    "maxOccupancy": 2,
    "defaultAllotment": 10,
    "amenities": [
      {
        "amenityId": 1,
        "name": "WiFi"
      },
      {
        "amenityId": 2,
        "name": "Air Conditioning"
      }
    ],
    "images": ["/images/deluxe-1.jpg"],
    "basePrice": 2500.00
  },
  {
    "roomTypeId": 2,
    "name": "Suite Room",
    "description": "ห้องสวีทพร้อมห้องนั่งเล่นแยก",
    "maxOccupancy": 4,
    "defaultAllotment": 5,
    "amenities": [
      {
        "amenityId": 1,
        "name": "WiFi"
      },
      {
        "amenityId": 2,
        "name": "Air Conditioning"
      },
      {
        "amenityId": 4,
        "name": "Mini Bar"
      }
    ],
    "images": ["/images/suite-1.jpg"],
    "basePrice": 4500.00
  }
]
```

## Get Room Type by ID

### Request
```http
GET /api/rooms/types/1 HTTP/1.1
Host: localhost:8080
```

### Success Response (200 OK)
```json
{
  "roomTypeId": 1,
  "name": "Deluxe Room",
  "description": "ห้องพักหรูพร้อมวิวทะเล พร้อมเตียงคิงไซส์ ห้องน้ำแยก และระเบียงส่วนตัว",
  "maxOccupancy": 2,
  "defaultAllotment": 10,
  "amenities": [
    {
      "amenityId": 1,
      "name": "WiFi"
    },
    {
      "amenityId": 2,
      "name": "Air Conditioning"
    },
    {
      "amenityId": 3,
      "name": "TV"
    },
    {
      "amenityId": 5,
      "name": "Safe Box"
    }
  ],
  "images": [
    "/images/deluxe-1.jpg",
    "/images/deluxe-2.jpg",
    "/images/deluxe-3.jpg"
  ],
  "basePrice": 2500.00
}
```

### Error Response - Not Found (404 Not Found)
```json
{
  "error": "Room type not found"
}
```

## Get Room Type Pricing

### Request
```http
GET /api/rooms/types/1/pricing?checkIn=2025-12-01&checkOut=2025-12-05 HTTP/1.1
Host: localhost:8080
```

### Success Response (200 OK)
```json
{
  "roomTypeId": 1,
  "name": "Deluxe Room",
  "description": "ห้องพักหรูพร้อมวิวทะเล",
  "maxOccupancy": 2,
  "totalPrice": 11000.00,
  "pricePerNight": [
    {
      "date": "2025-12-01",
      "price": 2500.00,
      "tier": "Standard"
    },
    {
      "date": "2025-12-02",
      "price": 2500.00,
      "tier": "Standard"
    },
    {
      "date": "2025-12-03",
      "price": 3000.00,
      "tier": "High Season"
    },
    {
      "date": "2025-12-04",
      "price": 3000.00,
      "tier": "High Season"
    }
  ],
  "nights": 4
}
```

## Get Room Status Dashboard (Receptionist Only)

### Request
```http
GET /api/rooms/status HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Success Response (200 OK)
```json
{
  "rooms": [
    {
      "roomId": 1,
      "roomNumber": "101",
      "roomTypeName": "Deluxe Room",
      "occupancyStatus": "Occupied",
      "housekeepingStatus": "Dirty",
      "guestName": "สมชาย ใจดี",
      "checkOutDate": "2025-11-05"
    },
    {
      "roomId": 2,
      "roomNumber": "102",
      "roomTypeName": "Deluxe Room",
      "occupancyStatus": "Vacant",
      "housekeepingStatus": "Inspected",
      "guestName": null,
      "checkOutDate": null
    },
    {
      "roomId": 3,
      "roomNumber": "103",
      "roomTypeName": "Deluxe Room",
      "occupancyStatus": "Vacant",
      "housekeepingStatus": "Cleaning",
      "guestName": null,
      "checkOutDate": null
    }
  ],
  "summary": {
    "total": 20,
    "occupied": 8,
    "vacant": 12,
    "clean": 5,
    "dirty": 4,
    "cleaning": 2,
    "inspected": 5,
    "maintenance": 1
  }
}
```

## cURL Examples

```bash
# Search Rooms
curl -X GET "http://localhost:8080/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-05&guests=2"

# Get All Room Types
curl -X GET http://localhost:8080/api/rooms/types

# Get Room Type by ID
curl -X GET http://localhost:8080/api/rooms/types/1

# Get Room Type Pricing
curl -X GET "http://localhost:8080/api/rooms/types/1/pricing?checkIn=2025-12-01&checkOut=2025-12-05"

# Get Room Status Dashboard (Receptionist)
curl -X GET http://localhost:8080/api/rooms/status \
  -H "Authorization: Bearer <TOKEN>"
```
