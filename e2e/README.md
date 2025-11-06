# E2E Tests - Hotel Booking System

## Overview

This directory contains End-to-End (E2E) tests for the Hotel Booking System using Playwright. The tests cover critical user flows and error scenarios to ensure the system works correctly from a user's perspective.

## Test Coverage

### 1. Booking Flow (`01-booking-flow.spec.ts`)
Tests the complete guest booking journey:
- ✅ Room search with date and guest selection
- ✅ Room selection and booking hold creation
- ✅ Guest information form submission
- ✅ Payment processing (mock)
- ✅ Booking confirmation
- ✅ Voucher code application
- ✅ Booking hold expiration handling
- ✅ Form validation

**Requirements Covered:** 2.1-2.8, 3.1-3.8, 4.1-4.9

### 2. Check-in Flow (`02-checkin-flow.spec.ts`)
Tests the receptionist check-in process:
- ✅ Login as receptionist
- ✅ View arrivals list
- ✅ Room assignment
- ✅ Check-in completion
- ✅ Room status updates
- ✅ Dashboard functionality
- ✅ Room filtering by status

**Requirements Covered:** 7.1-7.8, 12.1-12.7

### 3. Cancellation Flow (`03-cancellation-flow.spec.ts`)
Tests the booking cancellation process:
- ✅ View booking history
- ✅ Cancellation policy display
- ✅ Refund calculation
- ✅ Cancellation confirmation
- ✅ Status updates
- ✅ Prevention of invalid cancellations

**Requirements Covered:** 6.1-6.9

### 4. Error Scenarios (`04-error-scenarios.spec.ts`)
Tests error handling and edge cases:
- ✅ Invalid date selections
- ✅ Invalid form inputs
- ✅ Invalid voucher codes
- ✅ Authentication errors
- ✅ Authorization checks
- ✅ Loading states
- ✅ Empty results handling

**Requirements Covered:** All requirements (quality assurance)

## Prerequisites

### System Requirements
- Node.js 18+ or Bun
- npm or yarn or bun
- Running backend API (Go server on port 8080)
- Running frontend (Next.js on port 3000)
- PostgreSQL database with test data

### Environment Setup

1. **Install Dependencies**
   ```bash
   cd e2e
   npm install
   # or
   bun install
   ```

2. **Install Playwright Browsers**
   ```bash
   npx playwright install
   ```

3. **Set Environment Variables**
   Create a `.env` file in the `e2e` directory:
   ```env
   FRONTEND_URL=http://localhost:3000
   BACKEND_URL=http://localhost:8080
   ```

## Running Tests

### Run All Tests
```bash
npm test
# or
bun test
```

### Run Specific Test Suite
```bash
# Booking flow only
npm run test:booking

# Check-in flow only
npm run test:checkin

# Cancellation flow only
npm run test:cancellation

# Error scenarios only
npm run test:errors
```

### Run Tests in Headed Mode (See Browser)
```bash
npm run test:headed
```

### Run Tests in Debug Mode
```bash
npm run test:debug
```

### Run Tests with UI Mode (Interactive)
```bash
npm run test:ui
```

### View Test Report
```bash
npm run test:report
```

## Test Data

### Test Users
The tests use predefined test users defined in `fixtures/test-data.ts`:

- **Guest User**
  - Email: `test.guest@example.com`
  - Password: `TestPassword123!`

- **Receptionist**
  - Email: `receptionist@hotel.com`
  - Password: `ReceptionistPass123!`

- **Housekeeper**
  - Email: `housekeeper@hotel.com`
  - Password: `HousekeeperPass123!`

- **Manager**
  - Email: `manager@hotel.com`
  - Password: `ManagerPass123!`

### Test Booking Data
- Check-in: Tomorrow
- Check-out: 3 days from tomorrow
- Guests: 2
- Test voucher: `TEST10` (10% discount)

## Project Structure

```
e2e/
├── fixtures/
│   ├── test-data.ts          # Test data constants
│   └── auth-helpers.ts       # Authentication utilities
├── tests/
│   ├── 01-booking-flow.spec.ts
│   ├── 02-checkin-flow.spec.ts
│   ├── 03-cancellation-flow.spec.ts
│   └── 04-error-scenarios.spec.ts
├── playwright.config.ts      # Playwright configuration
├── package.json
└── README.md
```

## Writing New Tests

### Basic Test Structure
```typescript
import { test, expect } from '@playwright/test';
import { AuthHelper } from '../fixtures/auth-helpers';

test.describe('Feature Name', () => {
  test('should do something', async ({ page }) => {
    // Navigate
    await page.goto('/some-page');
    
    // Interact
    await page.click('button');
    
    // Assert
    await expect(page.locator('text=Success')).toBeVisible();
  });
});
```

### Using Auth Helper
```typescript
import { AuthHelper } from '../fixtures/auth-helpers';

test('authenticated test', async ({ page }) => {
  const authHelper = new AuthHelper(page);
  await authHelper.loginAsGuest();
  
  // Now you're logged in as a guest
  await page.goto('/bookings');
});
```

## Best Practices

### 1. Use Data Test IDs
Prefer `data-testid` attributes over CSS selectors:
```typescript
// Good
await page.click('[data-testid="submit-button"]');

// Avoid
await page.click('.btn.btn-primary.submit');
```

### 2. Wait for Elements
Always wait for elements before interacting:
```typescript
await page.waitForSelector('[data-testid="room-card"]');
await page.click('[data-testid="room-card"]');
```

### 3. Handle Async Operations
Use appropriate timeouts for slow operations:
```typescript
await page.waitForURL('/confirmation', { timeout: 15000 });
```

### 4. Clean Up Test Data
Tests should be independent and not rely on previous test state.

### 5. Use Descriptive Test Names
```typescript
// Good
test('should display error when booking with invalid dates', ...)

// Avoid
test('test1', ...)
```

## Debugging Tests

### 1. Run in Headed Mode
See the browser while tests run:
```bash
npm run test:headed
```

### 2. Use Debug Mode
Step through tests with Playwright Inspector:
```bash
npm run test:debug
```

### 3. Screenshots and Videos
Failed tests automatically capture:
- Screenshots
- Videos
- Traces

Find them in `test-results/` directory.

### 4. Console Logs
Add console logs in tests:
```typescript
console.log('Current URL:', page.url());
```

### 5. Pause Execution
Add breakpoints:
```typescript
await page.pause();
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd e2e
          npm ci
          npx playwright install --with-deps
      
      - name: Start services
        run: docker-compose up -d
      
      - name: Run E2E tests
        run: |
          cd e2e
          npm test
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: e2e/playwright-report/
```

## Troubleshooting

### Tests Fail with "Timeout"
- Ensure backend and frontend are running
- Check if database has test data
- Increase timeout in `playwright.config.ts`

### "Element not found" Errors
- Check if selectors match the actual HTML
- Use `data-testid` attributes for stability
- Wait for elements before interacting

### Authentication Issues
- Verify test user credentials exist in database
- Check if NextAuth is configured correctly
- Ensure JWT secrets match between frontend and backend

### Race Conditions
- Tests are configured to run sequentially
- Use proper wait conditions
- Avoid hardcoded `waitForTimeout` when possible

## Performance Optimization

### Parallel Execution
For faster test runs (after ensuring no race conditions):
```typescript
// playwright.config.ts
export default defineConfig({
  workers: 4, // Run 4 tests in parallel
  fullyParallel: true,
});
```

### Reuse Authentication State
Save authentication state to avoid repeated logins:
```typescript
// In setup file
await page.context().storageState({ path: 'auth.json' });

// In tests
use: {
  storageState: 'auth.json'
}
```

## Reporting

### HTML Report
Generated automatically after test run:
```bash
npm run test:report
```

### JSON Report
For programmatic access:
```bash
cat test-results/results.json
```

### Custom Reporters
Add to `playwright.config.ts`:
```typescript
reporter: [
  ['html'],
  ['json', { outputFile: 'results.json' }],
  ['junit', { outputFile: 'results.xml' }],
],
```

## Maintenance

### Updating Test Data
Edit `fixtures/test-data.ts` to update test constants.

### Adding New Test Users
1. Create users in database
2. Add credentials to `fixtures/test-data.ts`
3. Update `auth-helpers.ts` if needed

### Updating Selectors
When UI changes, update selectors in test files. Consider using `data-testid` attributes for stability.

## Resources

- [Playwright Documentation](https://playwright.dev/)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Playwright API Reference](https://playwright.dev/docs/api/class-playwright)
- [Project Requirements](../.kiro/specs/hotel-reservation-system/requirements.md)
- [Project Design](../.kiro/specs/hotel-reservation-system/design.md)

## Support

For issues or questions:
1. Check this README
2. Review Playwright documentation
3. Check test output and screenshots
4. Review application logs (backend and frontend)

## License

MIT
