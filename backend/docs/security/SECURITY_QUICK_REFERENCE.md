# Security Quick Reference - Hotel Booking System

Quick reference guide for security features and testing.

---

## Running Security Tests

### Backend Security Tests

```bash
# Run all security tests
cd backend
go test ./internal/security/... -v

# Run rate limiter tests
go test ./internal/middleware/rate_limiter_test.go -v

# Run security audit script (PowerShell)
.\test_security_audit.ps1

# Run security audit script (Bash)
chmod +x test_security_audit.sh
./test_security_audit.sh
```

### Frontend Security Tests

```bash
cd frontend
npm run test
```

---

## Security Features Overview

### 1. SQL Injection Protection
- **Method:** Parameterized queries via pgx
- **Location:** All repository files
- **Test:** `backend/internal/security/security_test.go`

### 2. XSS Protection
- **Method:** React auto-escaping, JSON encoding
- **Location:** Frontend components, backend handlers
- **Test:** `backend/internal/security/security_test.go`

### 3. CSRF Protection
- **Method:** JWT in Authorization header, CORS
- **Location:** `backend/internal/middleware/cors.go`
- **Test:** `backend/internal/security/security_test.go`

### 4. Authentication
- **Method:** bcrypt + JWT
- **Location:** `backend/internal/middleware/auth.go`
- **Test:** `backend/internal/middleware/auth_test.go`

### 5. Rate Limiting
- **Method:** In-memory rate limiter
- **Location:** `backend/internal/middleware/rate_limiter.go`
- **Limits:**
  - Auth: 5 req/min
  - Search: 30 req/min
  - Booking: 10 req/min
  - General: 100 req/min

### 6. Security Headers
- **Location:** `backend/internal/middleware/security_headers.go`
- **Headers:**
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY
  - X-XSS-Protection: 1; mode=block
  - Content-Security-Policy
  - Referrer-Policy
  - Permissions-Policy

---

## Common Security Tasks

### Check Security Headers

```bash
curl -I http://localhost:8080/api/
```

Expected headers:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'...
```

### Test Rate Limiting

```bash
# Make 10 rapid requests
for i in {1..10}; do
  curl -X POST http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"password123"}'
  echo ""
done
```

Expected: 429 Too Many Requests after 5 requests

### Test Authentication

```bash
# Without token (should fail)
curl http://localhost:8080/api/bookings

# With invalid token (should fail)
curl http://localhost:8080/api/bookings \
  -H "Authorization: Bearer invalid-token"

# With valid token (should succeed)
curl http://localhost:8080/api/bookings \
  -H "Authorization: Bearer YOUR_VALID_TOKEN"
```

### Test CORS

```bash
# From unauthorized origin
curl http://localhost:8080/api/rooms/types \
  -H "Origin: http://malicious-site.com"
```

### Test SQL Injection

```bash
# Should fail safely
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'"'"'; DROP TABLE guests; --","password":"test"}'
```

---

## Environment Variables

### Required for Security

```bash
# JWT Secret (MUST be strong and unique)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Database credentials
DB_HOST=localhost
DB_PORT=5432
DB_USER=hotel_user
DB_PASSWORD=secure_password_here
DB_NAME=hotel_booking

# CORS allowed origins
CORS_ALLOWED_ORIGINS=http://localhost:3000

# Server mode (development/production)
GIN_MODE=release  # Use 'release' in production
```

### Security Best Practices

1. **Never commit .env files**
2. **Use strong, random JWT secrets**
3. **Rotate secrets regularly**
4. **Use different secrets per environment**
5. **Store secrets in secure vault (production)**

---

## Role-Based Access Control

### Guest
- ✅ View own bookings
- ✅ Create bookings
- ✅ Cancel own bookings
- ❌ Access staff features
- ❌ Access manager features

### Receptionist
- ✅ Check-in/check-out
- ✅ View room status
- ✅ Move rooms
- ✅ Mark no-shows
- ❌ Access manager features

### Housekeeper
- ✅ View cleaning tasks
- ✅ Update room status
- ✅ Inspect rooms
- ✅ Report maintenance
- ❌ Access manager features

### Manager
- ✅ All receptionist features
- ✅ Pricing management
- ✅ Inventory management
- ✅ Policy management
- ✅ Reports and analytics

---

## Security Monitoring

### What to Monitor

1. **Failed Login Attempts**
   - Location: Application logs
   - Alert: >10 failures from same IP in 5 minutes

2. **Rate Limit Hits**
   - Location: Application logs
   - Alert: Frequent 429 responses

3. **Invalid Token Attempts**
   - Location: Application logs
   - Alert: >20 invalid tokens in 1 hour

4. **Database Errors**
   - Location: Application logs
   - Alert: Any database connection errors

5. **Unusual API Usage**
   - Location: Application logs
   - Alert: Sudden spike in requests

### Log Locations

```bash
# Application logs
backend/logs/app.log

# Error logs
backend/logs/error.log

# Access logs
backend/logs/access.log
```

---

## Incident Response

### If Security Breach Detected

1. **Immediate Actions**
   - Isolate affected systems
   - Revoke compromised tokens
   - Change all secrets/passwords
   - Enable additional logging

2. **Investigation**
   - Review logs for entry point
   - Identify affected data
   - Document timeline

3. **Remediation**
   - Patch vulnerabilities
   - Update security measures
   - Notify affected users (if required)

4. **Post-Incident**
   - Update security procedures
   - Conduct security review
   - Implement additional controls

---

## Security Updates

### Regular Maintenance

```bash
# Update Go dependencies
cd backend
go get -u ./...
go mod tidy

# Update Node dependencies
cd frontend
npm audit fix
npm update

# Check for security vulnerabilities
npm audit
```

### Security Patches

1. Monitor security advisories
2. Test patches in staging
3. Deploy to production
4. Verify functionality
5. Document changes

---

## Quick Security Checklist

Before deploying:

- [ ] HTTPS enabled
- [ ] Environment variables secured
- [ ] Rate limiting active
- [ ] Security headers enabled
- [ ] Authentication working
- [ ] Authorization tested
- [ ] Input validation active
- [ ] Error handling tested
- [ ] Logs configured
- [ ] Monitoring set up

---

## Useful Commands

```bash
# Check Go security
go list -m all | nancy sleuth

# Check npm security
npm audit

# Run all tests
go test ./... -v

# Check test coverage
go test ./... -cover

# Generate security report
go test ./internal/security/... -v > security_report.txt
```

---

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Go Security Best Practices](https://golang.org/doc/security/)
- [React Security](https://reactjs.org/docs/dom-elements.html#dangerouslysetinnerhtml)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

## Contact

For security issues:
- Email: security@example.com
- Emergency: +1-XXX-XXX-XXXX

**Do not disclose security vulnerabilities publicly.**
