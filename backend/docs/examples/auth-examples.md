# Authentication API Examples

## Register New Guest

### Request
```http
POST /api/auth/register HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "email": "somchai@example.com",
  "password": "SecurePass123!",
  "firstName": "สมชาย",
  "lastName": "ใจดี",
  "phone": "0812345678"
}
```

### Success Response (201 Created)
```json
{
  "guestId": 1,
  "email": "somchai@example.com",
  "firstName": "สมชาย",
  "lastName": "ใจดี",
  "role": "guest",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJlbWFpbCI6InNvbWNoYWlAZXhhbXBsZS5jb20iLCJyb2xlIjoiZ3Vlc3QiLCJleHAiOjE3MzA3MjQwMDB9.abc123xyz"
}
```

### Error Response - Email Already Exists (400 Bad Request)
```json
{
  "error": "อีเมลนี้ถูกลงทะเบียนแล้ว"
}
```

### Error Response - Validation Error (400 Bad Request)
```json
{
  "error": "Key: 'RegisterRequest.Email' Error:Field validation for 'Email' failed on the 'email' tag"
}
```

## Login

### Request
```http
POST /api/auth/login HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "email": "somchai@example.com",
  "password": "SecurePass123!"
}
```

### Success Response (200 OK)
```json
{
  "guestId": 1,
  "email": "somchai@example.com",
  "firstName": "สมชาย",
  "lastName": "ใจดี",
  "role": "guest",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJlbWFpbCI6InNvbWNoYWlAZXhhbXBsZS5jb20iLCJyb2xlIjoiZ3Vlc3QiLCJleHAiOjE3MzA3MjQwMDB9.abc123xyz"
}
```

### Error Response - Invalid Credentials (401 Unauthorized)
```json
{
  "error": "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
}
```

## Get Current User Profile

### Request
```http
GET /api/auth/me HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Success Response (200 OK)
```json
{
  "guestId": 1,
  "firstName": "สมชาย",
  "lastName": "ใจดี",
  "email": "somchai@example.com",
  "phone": "0812345678",
  "createdAt": "2025-11-01T10:00:00Z",
  "updatedAt": "2025-11-01T10:00:00Z"
}
```

### Error Response - Unauthorized (401 Unauthorized)
```json
{
  "error": "Unauthorized"
}
```

## Update Profile

### Request
```http
PUT /api/auth/profile HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "firstName": "สมชาย",
  "lastName": "มีสุข",
  "phone": "0898765432"
}
```

### Success Response (200 OK)
```json
{
  "guestId": 1,
  "firstName": "สมชาย",
  "lastName": "มีสุข",
  "email": "somchai@example.com",
  "phone": "0898765432",
  "createdAt": "2025-11-01T10:00:00Z",
  "updatedAt": "2025-11-03T14:30:00Z"
}
```

## cURL Examples

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "somchai@example.com",
    "password": "SecurePass123!",
    "firstName": "สมชาย",
    "lastName": "ใจดี",
    "phone": "0812345678"
  }'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "somchai@example.com",
    "password": "SecurePass123!"
  }'

# Get Profile (replace <TOKEN> with actual token)
curl -X GET http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer <TOKEN>"

# Update Profile
curl -X PUT http://localhost:8080/api/auth/profile \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "สมชาย",
    "lastName": "มีสุข",
    "phone": "0898765432"
  }'
```
