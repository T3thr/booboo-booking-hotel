# E2E Tests - Hotel Booking System

## 🎯 Overview

End-to-End tests for the Hotel Booking System have been implemented using Playwright. These tests cover all critical user flows and error scenarios.

## 📍 Location

All E2E tests are located in the `e2e/` directory.

## 🚀 Quick Start

```bash
# Navigate to E2E directory
cd e2e

# Install dependencies
npm install

# Install Playwright browsers
npx playwright install chromium

# Run all tests
npm test
```

## 📚 Documentation

- **[Quick Start Guide](./e2e/QUICKSTART.md)** - Get started in 5 minutes
- **[Complete README](./e2e/README.md)** - Full documentation
- **[Task Index](./e2e/TASK_41_INDEX.md)** - Navigation and quick reference
- **[Completion Summary](./e2e/TASK_41_COMPLETION_SUMMARY.md)** - Implementation details
- **[Verification Checklist](./e2e/TASK_41_VERIFICATION_CHECKLIST.md)** - Verification steps

## 🧪 Test Suites

### 1. Booking Flow (5 tests)
Complete guest booking journey from search to confirmation.

```bash
npm run test:booking
```

**Coverage:** Requirements 2.1-2.8, 3.1-3.8, 4.1-4.9

### 2. Check-in Flow (7 tests)
Receptionist check-in process and room management.

```bash
npm run test:checkin
```

**Coverage:** Requirements 7.1-7.8, 12.1-12.7

### 3. Cancellation Flow (7 tests)
Booking cancellation with refund calculation.

```bash
npm run test:cancellation
```

**Coverage:** Requirements 6.1-6.9

### 4. Error Scenarios (15+ tests)
Comprehensive error handling and validation.

```bash
npm run test:errors
```

**Coverage:** All requirements (quality assurance)

## 📊 Test Statistics

- **Total Tests:** 34+
- **Test Files:** 4
- **Helper Files:** 2
- **Documentation:** 4 comprehensive guides
- **Requirements Coverage:** All critical flows

## 🎬 Running Tests

### All Tests
```bash
cd e2e && npm test
```

### Specific Suite
```bash
cd e2e && npm run test:booking
cd e2e && npm run test:checkin
cd e2e && npm run test:cancellation
cd e2e && npm run test:errors
```

### Debug Mode
```bash
cd e2e && npm run test:headed    # See browser
cd e2e && npm run test:debug     # Debug mode
cd e2e && npm run test:ui        # Interactive UI
```

### View Report
```bash
cd e2e && npm run test:report
```

### Using Scripts
```bash
# Windows
cd e2e
run_e2e_tests.bat [suite]

# Linux/Mac
cd e2e
chmod +x run_e2e_tests.sh
./run_e2e_tests.sh [suite]
```

## 📋 Prerequisites

Before running tests, ensure:

1. **Backend is running** on `http://localhost:8080`
   ```bash
   cd backend && go run cmd/server/main.go
   ```

2. **Frontend is running** on `http://localhost:3000`
   ```bash
   cd frontend && npm run dev
   ```

3. **Database has test data**
   - Run migrations
   - Seed test data
   - Create test users

4. **Test users exist:**
   - `test.guest@example.com`
   - `receptionist@hotel.com`
   - `housekeeper@hotel.com`
   - `manager@hotel.com`

## 🔍 Test Structure

```
e2e/
├── tests/
│   ├── 01-booking-flow.spec.ts      # Booking tests
│   ├── 02-checkin-flow.spec.ts      # Check-in tests
│   ├── 03-cancellation-flow.spec.ts # Cancellation tests
│   └── 04-error-scenarios.spec.ts   # Error tests
├── fixtures/
│   ├── test-data.ts                 # Test data
│   └── auth-helpers.ts              # Auth utilities
├── playwright.config.ts             # Configuration
├── package.json                     # Dependencies
├── README.md                        # Full docs
├── QUICKSTART.md                    # Quick guide
└── run_e2e_tests.{bat,sh}          # Run scripts
```

## 🎯 Key Features

- ✅ Comprehensive test coverage
- ✅ All critical flows tested
- ✅ Extensive error scenarios
- ✅ Reusable test utilities
- ✅ Complete documentation
- ✅ Easy to run and debug
- ✅ CI/CD ready
- ✅ Production quality

## 🐛 Troubleshooting

### Tests fail with timeout
- Ensure backend and frontend are running
- Check database has test data
- Increase timeout in config if needed

### Element not found errors
- Verify selectors match actual HTML
- Check if UI has changed
- Use `data-testid` attributes

### Authentication issues
- Verify test users exist in database
- Check credentials in `fixtures/test-data.ts`
- Ensure NextAuth is configured correctly

For more troubleshooting, see [README.md](./e2e/README.md#troubleshooting)

## 📖 Learn More

- [Playwright Documentation](https://playwright.dev/)
- [Project Requirements](../.kiro/specs/hotel-reservation-system/requirements.md)
- [Project Design](../.kiro/specs/hotel-reservation-system/design.md)

## ✅ Task Status

**Task 41: E2E Tests - Critical Flows**  
Status: ✅ COMPLETED

All sub-tasks implemented:
- ✅ Playwright test สำหรับ booking flow
- ✅ Test สำหรับ check-in flow
- ✅ Test สำหรับ cancellation flow
- ✅ ทดสอบ error scenarios

## 🎉 Ready to Use!

The E2E test suite is production-ready and fully documented. Start testing now:

```bash
cd e2e
npm install
npx playwright install
npm test
```

For detailed instructions, see [QUICKSTART.md](./e2e/QUICKSTART.md)

---

**Implementation Date:** November 3, 2025  
**Version:** 1.0.0  
**Status:** Production Ready ✅
