# Authentication Module Testing Guide

## Overview

This guide provides instructions for testing the authentication module endpoints using curl or Postman.

## Prerequisites

1. Ensure the backend server is running:
   ```bash
   go run cmd/server/main.go
   ```

2. Ensure PostgreSQL is running with the migrations applied (Tasks 3-6)

3. Server should be accessible at `http://localhost:8080`

## Test Endpoints

### 1. Health Check

**Request:**
```bash
curl http://localhost:8080/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "message": "Hotel Booking System API is running"
}
```

### 2. Database Health Check

**Request:**
```bash
curl http://localhost:8080/health/db
```

**Expected Response:**
```json
{
  "status": "ok",
  "total_conns": 10,
  "idle_conns": 5,
  "acquired_conns": 5,
  "constructing_conns": 0
}
```

### 3. Register New Guest

**Request:**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "0812345678",
    "password": "password123"
  }'
```

**Expected Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "john.doe@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "guest",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response (400 - Email exists):**
```json
{
  "success": false,
  "error": "อีเมลนี้ถูกลงทะเบียนแล้ว"
}
```

**Error Response (400 - Validation error):**
```json
{
  "success": false,
  "error": "Validation failed",
  "details": "Key: 'RegisterRequest.Email' Error:Field validation for 'Email' failed on the 'email' tag"
}
```

### 4. Login

**Request:**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "password123"
  }'
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "john.doe@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "guest",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response (401 - Invalid credentials):**
```json
{
  "success": false,
  "error": "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
}
```

### 5. Get Profile (Protected)

**Request:**
```bash
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "guest_id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "0812345678",
    "created_at": "2025-11-02T10:30:00Z",
    "updated_at": "2025-11-02T10:30:00Z"
  }
}
```

**Error Response (401 - No token):**
```json
{
  "success": false,
  "error": "No authorization header provided"
}
```

**Error Response (401 - Invalid token):**
```json
{
  "success": false,
  "error": "Invalid or expired token"
}
```

### 6. Update Profile (Protected)

**Request:**
```bash
curl -X PUT http://localhost:8080/api/auth/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "first_name": "John",
    "last_name": "Smith",
    "phone": "0898765432"
  }'
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "guest_id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "email": "john.doe@example.com",
    "phone": "0898765432",
    "created_at": "2025-11-02T10:30:00Z",
    "updated_at": "2025-11-02T11:45:00Z"
  }
}
```

## Testing Workflow

### Complete Registration and Login Flow

1. **Register a new user:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "first_name": "Jane",
       "last_name": "Smith",
       "email": "jane.smith@example.com",
       "phone": "0823456789",
       "password": "securepass123"
     }'
   ```

2. **Save the access token from the response**

3. **Get profile using the token:**
   ```bash
   curl http://localhost:8080/api/auth/me \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```

4. **Update profile:**
   ```bash
   curl -X PUT http://localhost:8080/api/auth/profile \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -d '{
       "first_name": "Jane",
       "last_name": "Doe",
       "phone": "0899999999"
     }'
   ```

5. **Login again to verify:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "jane.smith@example.com",
       "password": "securepass123"
     }'
   ```

### Testing Error Cases

1. **Try to register with existing email:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "first_name": "Test",
       "last_name": "User",
       "email": "jane.smith@example.com",
       "phone": "0811111111",
       "password": "password123"
     }'
   ```
   Expected: 400 error with "อีเมลนี้ถูกลงทะเบียนแล้ว"

2. **Try to login with wrong password:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "jane.smith@example.com",
       "password": "wrongpassword"
     }'
   ```
   Expected: 401 error with "อีเมลหรือรหัสผ่านไม่ถูกต้อง"

3. **Try to access protected route without token:**
   ```bash
   curl http://localhost:8080/api/auth/me
   ```
   Expected: 401 error with "No authorization header provided"

4. **Try to access protected route with invalid token:**
   ```bash
   curl http://localhost:8080/api/auth/me \
     -H "Authorization: Bearer invalid.token.here"
   ```
   Expected: 401 error with "Invalid or expired token"

## Postman Collection

You can import this collection into Postman for easier testing:

```json
{
  "info": {
    "name": "Hotel Booking System - Auth",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Register",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"first_name\": \"John\",\n  \"last_name\": \"Doe\",\n  \"email\": \"john.doe@example.com\",\n  \"phone\": \"0812345678\",\n  \"password\": \"password123\"\n}"
        },
        "url": {
          "raw": "http://localhost:8080/api/auth/register",
          "protocol": "http",
          "host": ["localhost"],
          "port": "8080",
          "path": ["api", "auth", "register"]
        }
      }
    },
    {
      "name": "Login",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"email\": \"john.doe@example.com\",\n  \"password\": \"password123\"\n}"
        },
        "url": {
          "raw": "http://localhost:8080/api/auth/login",
          "protocol": "http",
          "host": ["localhost"],
          "port": "8080",
          "path": ["api", "auth", "login"]
        }
      }
    },
    {
      "name": "Get Profile",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{accessToken}}"
          }
        ],
        "url": {
          "raw": "http://localhost:8080/api/auth/me",
          "protocol": "http",
          "host": ["localhost"],
          "port": "8080",
          "path": ["api", "auth", "me"]
        }
      }
    },
    {
      "name": "Update Profile",
      "request": {
        "method": "PUT",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{accessToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"first_name\": \"John\",\n  \"last_name\": \"Smith\",\n  \"phone\": \"0898765432\"\n}"
        },
        "url": {
          "raw": "http://localhost:8080/api/auth/profile",
          "protocol": "http",
          "host": ["localhost"],
          "port": "8080",
          "path": ["api", "auth", "profile"]
        }
      }
    }
  ]
}
```

## Running Unit Tests

Run the unit tests for the authentication utilities:

```bash
# Test password utilities
go test -v ./pkg/utils -run TestHashPassword
go test -v ./pkg/utils -run TestCheckPassword

# Test JWT utilities
go test -v ./pkg/utils -run TestGenerateToken
go test -v ./pkg/utils -run TestValidateToken

# Run all tests
go test -v ./pkg/utils/...
```

## Database Verification

After registration, you can verify the data in PostgreSQL:

```sql
-- Check guests table
SELECT * FROM guests WHERE email = 'john.doe@example.com';

-- Check guest_accounts table (password should be hashed)
SELECT ga.guest_account_id, ga.guest_id, ga.last_login
FROM guest_accounts ga
JOIN guests g ON ga.guest_id = g.guest_id
WHERE g.email = 'john.doe@example.com';

-- Verify password is hashed (should start with $2a$ or $2b$)
SELECT hashed_password FROM guest_accounts WHERE guest_id = 1;
```

## Troubleshooting

### Server won't start
- Check if PostgreSQL is running
- Verify database credentials in `.env`
- Check if port 8080 is available

### Registration fails
- Verify database migrations are applied
- Check if email already exists in database
- Verify all required fields are provided

### Login fails
- Verify user exists in database
- Check password is correct
- Verify JWT_SECRET is set in `.env`

### Protected routes return 401
- Verify token is included in Authorization header
- Check token format: `Bearer <token>`
- Verify token hasn't expired (24 hour expiry)
- Check JWT_SECRET matches between token generation and validation

## Next Steps

After verifying the authentication module works correctly:

1. Test with multiple users
2. Verify last_login timestamp updates
3. Test token expiration (wait 24 hours or modify expiry time)
4. Proceed to Task 9: Authentication Middleware (already implemented)
5. Proceed to Task 10: Room Search Module
