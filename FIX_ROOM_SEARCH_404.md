# API 404 Errors - Fixed

## Problem
Multiple API calls were returning 404 errors:
```
[API Error] "/api/rooms/search" "Request failed with status code 404"
[API Error] "/api/bookings/hold" "Request failed with status code 404"
```

## Root Cause
The API functions in `frontend/src/lib/api.ts` were using the axios `apiClient` which has `baseURL` set to the backend URL (`http://localhost:8080/api`). This meant they were trying to call the backend directly instead of going through Next.js API routes.

The issue: Frontend → Backend directly ❌
Should be: Frontend → Next.js API routes → Backend ✅

## Solution

### 1. Updated API Client Functions
Changed `roomApi` and `bookingApi` to use native `fetch()` instead of axios, calling Next.js API routes:

**Room API:**
- `roomApi.search()` → `/api/rooms/search`
- `roomApi.getTypes()` → `/api/rooms/types`
- `roomApi.getType()` → `/api/rooms/types/${id}`
- `roomApi.getPricing()` → `/api/rooms/types/${id}/pricing`

**Booking API:**
- `bookingApi.createHold()` → `/api/bookings/hold`
- `bookingApi.create()` → `/api/bookings`
- `bookingApi.confirm()` → `/api/bookings/${id}/confirm`
- `bookingApi.cancel()` → `/api/bookings/${id}/cancel`
- `bookingApi.getAll()` → `/api/bookings`
- `bookingApi.getById()` → `/api/bookings/${id}`

### 2. Created Missing Next.js API Routes
Added proxy routes that forward requests to the backend with proper auth:

- `frontend/src/app/api/bookings/hold/route.ts`
- `frontend/src/app/api/bookings/route.ts`
- `frontend/src/app/api/bookings/[id]/route.ts`
- `frontend/src/app/api/bookings/[id]/confirm/route.ts`
- `frontend/src/app/api/bookings/[id]/cancel/route.ts`

All routes:
- Get session from NextAuth
- Forward auth token to backend
- Proxy requests/responses
- Handle errors properly

## Files Changed
- `frontend/src/lib/api.ts` - Updated roomApi and bookingApi to use fetch
- `frontend/src/app/api/bookings/hold/route.ts` - Created
- `frontend/src/app/api/bookings/route.ts` - Created
- `frontend/src/app/api/bookings/[id]/route.ts` - Created
- `frontend/src/app/api/bookings/[id]/confirm/route.ts` - Created
- `frontend/src/app/api/bookings/[id]/cancel/route.ts` - Created

## Testing
All API calls should now work correctly:
1. Room search - Enter dates and search for rooms
2. Booking hold - Select a room and create a hold
3. Booking creation - Complete guest info and create booking
4. Booking management - View, confirm, and cancel bookings
