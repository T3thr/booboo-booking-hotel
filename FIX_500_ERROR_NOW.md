# 🚨 FIX ERROR 500 NOW!

## Quick Fix (1 minute)

### 1. Restart Backend
```bash
# Stop: Ctrl+C in backend terminal
cd backend
go run cmd/server/main.go
```

### 2. Watch Backend Log
When you search rooms on frontend, check backend terminal for error message.

### 3. If Still Error 500

**Most likely cause: Missing room_inventory data**

**Fix:**
```bash
cd database/migrations
psql -U postgres -d hotel_booking -f 013_seed_demo_data.sql
```

### 4. Test API
```bash
curl "http://localhost:8080/api/rooms/search?checkIn=2025-11-10&checkOut=2025-11-13&guests=2"
```

**Expected response:**
```json
{
  "success": true,
  "data": {
    "room_types": [
      {
        "room_type_id": 1,
        "available_rooms": 10,
        ...
      }
    ]
  }
}
```

## Done! ✅

If you see `available_rooms` field, the system is working!

Test on web: http://localhost:3000/rooms/search
