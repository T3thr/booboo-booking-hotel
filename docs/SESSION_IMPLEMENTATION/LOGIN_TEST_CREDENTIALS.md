# 🔑 Login Test Credentials

## ✅ Working Credentials

All demo guest accounts use the password: **password123**

### Guest Accounts

| Email | Password | Guest ID | Name |
|-------|----------|----------|------|
| anan.test@example.com | password123 | 1 | Anan Testsawat |
| benja.demo@example.com | password123 | 2 | Benja Demowan |
| chana.sample@example.com | password123 | 3 | Chana Samplekit |
| dara.mock@example.com | password123 | 4 | Dara Mockporn |
| ekachai.fake@example.com | password123 | 5 | Ekachai Fakeboon |
| fon.test@example.com | password123 | 6 | Fon Testuser |
| ganda.demo@example.com | password123 | 7 | Ganda Demodata |
| hansa.sample@example.com | password123 | 8 | Hansa Sampleset |
| itsara.mock@example.com | password123 | 9 | Itsara Mockguest |
| jira.fake@example.com | password123 | 10 | Jira Fakevisit |

## 🧪 Test Login via API

### Using curl (Windows CMD)
```cmd
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"anan.test@example.com\",\"password\":\"password123\"}"
```

### Using curl (PowerShell)
```powershell
curl -X POST http://localhost:8080/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"anan.test@example.com","password":"password123"}'
```

### Expected Response
```json
{
  "data": {
    "id": 1,
    "email": "anan.test@example.com",
    "first_name": "Anan",
    "last_name": "Testsawat",
    "role": "guest",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "success": true
}
```

## 🌐 Test Login via Frontend

1. Go to: http://localhost:3000/auth/signin
2. Enter:
   - Email: `anan.test@example.com`
   - Password: `password123`
3. Click "เข้าสู่ระบบ"

## ✅ Fixed Issues

### Issue: Frontend authentication was failing
**Root Cause:** The backend returns data in a wrapper object `{data: {...}, success: true}`, but the frontend was trying to access properties directly.

**Fix Applied:** Updated `frontend/src/lib/auth.ts` to properly extract data from the response wrapper:
```typescript
const response = await res.json();
const data = response.data || response;
```

## 🔧 Troubleshooting

### Problem: Still getting "ข้อมูลการเข้าสู่ระบบไม่ถูกต้อง"
**Solutions:**
1. Make sure backend is running on port 8080
2. Check that frontend .env has: `BACKEND_URL=http://localhost:8080`
3. Restart the Next.js dev server after changing .env
4. Clear browser cache and cookies

### Problem: Backend returns 401
**Solutions:**
1. Verify the password hash in database matches bcrypt hash for "password123"
2. Run the fix-passwords script: `.\fix-passwords.bat`
3. Check backend logs for detailed error messages

### Problem: CORS errors
**Solutions:**
1. Verify backend .env has: `ALLOWED_ORIGINS=http://localhost:3000`
2. Restart the Go backend server

## 📝 Notes

- All passwords are hashed using bcrypt with DefaultCost (10)
- The bcrypt hash for "password123" is: `$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy`
- JWT tokens expire after 24 hours
- The JWT secret is configured in both backend and frontend .env files

---

**Last Updated:** November 4, 2025  
**Status:** ✅ Working
