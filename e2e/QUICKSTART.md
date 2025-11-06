# E2E Tests Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### Step 1: Install Dependencies
```bash
cd e2e
npm install
npx playwright install chromium
```

### Step 2: Start the Application
Make sure both backend and frontend are running:

```bash
# Terminal 1: Start backend
cd backend
go run cmd/server/main.go

# Terminal 2: Start frontend
cd frontend
npm run dev
```

### Step 3: Run Tests
```bash
# In e2e directory
npm test
```

## 📋 Pre-flight Checklist

Before running tests, ensure:

- [ ] PostgreSQL database is running
- [ ] Database has test data (run migrations and seeds)
- [ ] Backend API is running on `http://localhost:8080`
- [ ] Frontend is running on `http://localhost:3000`
- [ ] Test users exist in database:
  - `test.guest@example.com`
  - `receptionist@hotel.com`
  - `housekeeper@hotel.com`
  - `manager@hotel.com`

## 🎯 Quick Test Commands

```bash
# Run all tests
npm test

# Run specific test suite
npm run test:booking        # Booking flow
npm run test:checkin        # Check-in flow
npm run test:cancellation   # Cancellation flow
npm run test:errors         # Error scenarios

# Debug mode (see browser)
npm run test:headed

# Interactive UI mode
npm run test:ui

# View last test report
npm run test:report
```

## 🔍 Verify Setup

Run this command to verify everything is working:

```bash
# Test a simple page load
npx playwright test --grep "should complete full booking flow" --headed
```

If you see a browser open and navigate through the booking flow, you're all set! ✅

## 🐛 Common Issues

### Issue: "Timeout waiting for page"
**Solution:** Make sure frontend is running on port 3000
```bash
cd frontend && npm run dev
```

### Issue: "Connection refused"
**Solution:** Make sure backend is running on port 8080
```bash
cd backend && go run cmd/server/main.go
```

### Issue: "Test user not found"
**Solution:** Create test users in database
```sql
-- Run in PostgreSQL
INSERT INTO guests (first_name, last_name, email, phone) 
VALUES ('Test', 'Guest', 'test.guest@example.com', '+66812345678');

INSERT INTO guest_accounts (guest_id, hashed_password) 
VALUES (
  (SELECT guest_id FROM guests WHERE email = 'test.guest@example.com'),
  '$2a$10$...' -- bcrypt hash of 'TestPassword123!'
);
```

### Issue: "No rooms available"
**Solution:** Ensure room inventory has available rooms
```sql
-- Check inventory
SELECT * FROM room_inventory 
WHERE date >= CURRENT_DATE 
AND (allotment - booked_count - tentative_count) > 0;
```

## 📊 Understanding Test Results

### ✅ Passed Test
```
✓ should complete full booking flow successfully (15s)
```
All assertions passed, test completed successfully.

### ❌ Failed Test
```
✗ should complete full booking flow successfully (5s)
  Error: Timeout 5000ms exceeded.
```
Check the error message and screenshots in `test-results/`.

### ⊘ Skipped Test
```
⊘ should complete check-in process successfully
```
Test was skipped (usually due to missing test data).

## 🎬 Next Steps

1. **Review test results:** `npm run test:report`
2. **Check screenshots:** Look in `test-results/` for failed test screenshots
3. **Run specific tests:** Use `--grep` to run specific tests
4. **Write new tests:** Follow examples in existing test files

## 📚 Learn More

- [Full README](./README.md) - Complete documentation
- [Playwright Docs](https://playwright.dev/) - Official Playwright documentation
- [Test Data](./fixtures/test-data.ts) - Test data configuration

## 💡 Pro Tips

1. **Use headed mode for debugging:**
   ```bash
   npm run test:headed
   ```

2. **Generate tests with Codegen:**
   ```bash
   npm run test:codegen
   ```

3. **Run single test file:**
   ```bash
   npx playwright test tests/01-booking-flow.spec.ts
   ```

4. **Run single test:**
   ```bash
   npx playwright test --grep "should apply voucher code"
   ```

5. **Update snapshots:**
   ```bash
   npx playwright test --update-snapshots
   ```

## 🆘 Need Help?

1. Check the [README](./README.md)
2. Review [Playwright documentation](https://playwright.dev/)
3. Check application logs (backend and frontend)
4. Review test screenshots in `test-results/`

Happy Testing! 🎉
