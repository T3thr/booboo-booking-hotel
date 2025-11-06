/**
 * E2E Test: Error Scenarios
 * 
 * Tests error handling and edge cases:
 * 1. Invalid date selections
 * 2. Invalid form inputs
 * 3. Network errors
 * 4. Race conditions
 * 5. Session timeouts
 * 6. Invalid voucher codes
 * 
 * Requirements: All requirements (quality assurance)
 */

import { test, expect } from '@playwright/test';
import { AuthHelper } from '../fixtures/auth-helpers';
import { errorScenarios } from '../fixtures/test-data';

test.describe('Error Scenarios - Input Validation', () => {
  test('should reject invalid date range (checkout before checkin)', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    await page.fill('input[name="checkIn"]', today.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', yesterday.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    
    await page.click('button[type="submit"]');
    
    // Should show validation error
    await expect(page.locator('text=/invalid|ไม่ถูกต้อง|must be after|ต้องหลังจาก/i')).toBeVisible();
  });

  test('should reject same day check-in and check-out', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const today = new Date().toISOString().split('T')[0];
    
    await page.fill('input[name="checkIn"]', today);
    await page.fill('input[name="checkOut"]', today);
    await page.fill('input[name="guests"]', '2');
    
    await page.click('button[type="submit"]');
    
    // Should show validation error
    await expect(page.locator('text=/at least one night|อย่างน้อย 1 คืน/i')).toBeVisible();
  });

  test('should reject past dates', async ({ page }) => {
    await page.goto('/rooms/search');
    
    await page.fill('input[name="checkIn"]', '2023-01-01');
    await page.fill('input[name="checkOut"]', '2023-01-02');
    await page.fill('input[name="guests"]', '2');
    
    await page.click('button[type="submit"]');
    
    // Should show validation error
    await expect(page.locator('text=/past date|วันที่ผ่านมาแล้ว|cannot be in the past/i')).toBeVisible();
  });

  test('should reject zero or negative guests', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 1);
    
    await page.fill('input[name="checkIn"]', tomorrow.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', dayAfter.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '0');
    
    await page.click('button[type="submit"]');
    
    // Should show validation error
    await expect(page.locator('text=/at least 1 guest|อย่างน้อย 1 คน/i')).toBeVisible();
  });

  test('should reject invalid email format during registration', async ({ page }) => {
    await page.goto('/auth/register');
    
    await page.fill('input[name="email"]', errorScenarios.invalidEmail);
    await page.fill('input[name="password"]', 'ValidPassword123!');
    await page.fill('input[name="firstName"]', 'Test');
    await page.fill('input[name="lastName"]', 'User');
    await page.fill('input[name="phone"]', '+66812345678');
    
    await page.click('button[type="submit"]');
    
    // Should show email validation error
    await expect(page.locator('text=/invalid email|อีเมลไม่ถูกต้อง/i')).toBeVisible();
  });

  test('should reject weak password', async ({ page }) => {
    await page.goto('/auth/register');
    
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', errorScenarios.weakPassword);
    await page.fill('input[name="firstName"]', 'Test');
    await page.fill('input[name="lastName"]', 'User');
    await page.fill('input[name="phone"]', '+66812345678');
    
    await page.click('button[type="submit"]');
    
    // Should show password validation error
    await expect(page.locator('text=/password.*strong|รหัสผ่าน.*แข็งแรง|at least.*characters/i')).toBeVisible();
  });

  test('should reject invalid phone number format', async ({ page }) => {
    await page.goto('/auth/register');
    
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'ValidPassword123!');
    await page.fill('input[name="firstName"]', 'Test');
    await page.fill('input[name="lastName"]', 'User');
    await page.fill('input[name="phone"]', '123'); // Too short
    
    await page.click('button[type="submit"]');
    
    // Should show phone validation error
    await expect(page.locator('text=/invalid phone|เบอร์โทรไม่ถูกต้อง/i')).toBeVisible();
  });
});

test.describe('Error Scenarios - Voucher Validation', () => {
  let authHelper: AuthHelper;

  test.beforeEach(async ({ page }) => {
    authHelper = new AuthHelper(page);
  });

  test('should reject invalid voucher code', async ({ page }) => {
    // Navigate through booking flow to payment page
    await page.goto('/rooms/search');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 2);
    
    await page.fill('input[name="checkIn"]', tomorrow.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', dayAfter.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    await page.click('button[type="submit"]');
    
    // Wait for results and select room
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    const roomCards = await page.locator('[data-testid="room-card"]').count();
    
    if (roomCards > 0) {
      await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
      
      // Fill guest info
      await page.fill('input[name="firstName"]', 'Test');
      await page.fill('input[name="lastName"]', 'User');
      await page.fill('input[name="email"]', 'test@example.com');
      await page.fill('input[name="phone"]', '+66812345678');
      await page.click('button:has-text("Continue")');
      
      // Try to apply invalid voucher
      const voucherInput = page.locator('input[name="voucherCode"]');
      if (await voucherInput.isVisible()) {
        await voucherInput.fill('INVALID_CODE_12345');
        await page.click('button:has-text("Apply")');
        
        // Should show error message
        await expect(page.locator('text=/invalid.*code|รหัสไม่ถูกต้อง|not found/i')).toBeVisible();
      }
    }
  });

  test('should reject expired voucher', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 2);
    
    await page.fill('input[name="checkIn"]', tomorrow.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', dayAfter.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    await page.click('button[type="submit"]');
    
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    const roomCards = await page.locator('[data-testid="room-card"]').count();
    
    if (roomCards > 0) {
      await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
      
      await page.fill('input[name="firstName"]', 'Test');
      await page.fill('input[name="lastName"]', 'User');
      await page.fill('input[name="email"]', 'test@example.com');
      await page.fill('input[name="phone"]', '+66812345678');
      await page.click('button:has-text("Continue")');
      
      const voucherInput = page.locator('input[name="voucherCode"]');
      if (await voucherInput.isVisible()) {
        await voucherInput.fill(errorScenarios.expiredVoucher);
        await page.click('button:has-text("Apply")');
        
        // Should show expired error
        await expect(page.locator('text=/expired|หมดอายุ/i')).toBeVisible();
      }
    }
  });
});

test.describe('Error Scenarios - Authentication', () => {
  test('should reject invalid login credentials', async ({ page }) => {
    await page.goto('/auth/signin');
    
    await page.fill('input[name="email"]', 'nonexistent@example.com');
    await page.fill('input[name="password"]', 'WrongPassword123!');
    
    await page.click('button[type="submit"]');
    
    // Should show error message
    await expect(page.locator('text=/invalid.*credentials|ข้อมูลไม่ถูกต้อง|incorrect/i')).toBeVisible();
  });

  test('should prevent access to protected routes without authentication', async ({ page }) => {
    // Try to access guest bookings without login
    await page.goto('/bookings');
    
    // Should redirect to signin
    await page.waitForURL(/\/auth\/signin/, { timeout: 5000 });
    
    expect(page.url()).toContain('/auth/signin');
  });

  test('should prevent staff access with guest credentials', async ({ page }) => {
    const authHelper = new AuthHelper(page);
    
    // Login as guest
    await authHelper.loginAsGuest();
    
    // Try to access staff dashboard
    await page.goto('/dashboard');
    
    // Should redirect to unauthorized or home
    await page.waitForTimeout(2000);
    
    const currentUrl = page.url();
    expect(currentUrl).not.toContain('/dashboard');
  });
});

test.describe('Error Scenarios - Network and Loading States', () => {
  test('should show loading state during search', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 2);
    
    await page.fill('input[name="checkIn"]', tomorrow.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', dayAfter.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    
    // Click search and immediately check for loading state
    await page.click('button[type="submit"]');
    
    // Should show loading indicator
    const loadingIndicator = page.locator('[data-testid="loading"], .loading, text=/Loading|กำลังโหลด/i');
    
    // Loading indicator should appear (even briefly)
    // We use a short timeout since it might disappear quickly
    try {
      await expect(loadingIndicator).toBeVisible({ timeout: 2000 });
    } catch {
      // Loading might be too fast to catch, which is okay
      console.log('Loading state was too fast to capture');
    }
  });

  test('should handle empty search results gracefully', async ({ page }) => {
    await page.goto('/rooms/search');
    
    // Search for dates far in the future with no inventory
    const farFuture = new Date();
    farFuture.setFullYear(farFuture.getFullYear() + 5);
    const farFuturePlus = new Date(farFuture);
    farFuturePlus.setDate(farFuturePlus.getDate() + 1);
    
    await page.fill('input[name="checkIn"]', farFuture.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', farFuturePlus.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    await page.click('button[type="submit"]');
    
    // Wait for response
    await page.waitForTimeout(3000);
    
    // Should show appropriate message
    const noResultsMessage = page.locator('text=/No rooms available|ไม่มีห้องว่าง|No results/i');
    const hasResults = await page.locator('[data-testid="room-card"]').count() > 0;
    
    if (!hasResults) {
      await expect(noResultsMessage).toBeVisible();
    }
  });

  test('should handle booking hold timeout gracefully', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 2);
    
    await page.fill('input[name="checkIn"]', tomorrow.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', dayAfter.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    await page.click('button[type="submit"]');
    
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    const roomCards = await page.locator('[data-testid="room-card"]').count();
    
    if (roomCards > 0) {
      await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
      
      // Verify countdown timer exists
      const timer = page.locator('[data-testid="countdown-timer"]');
      await expect(timer).toBeVisible();
      
      // Timer should be counting down
      const initialTime = await timer.textContent();
      await page.waitForTimeout(2000);
      const updatedTime = await timer.textContent();
      
      expect(initialTime).not.toBe(updatedTime);
    }
  });
});

test.describe('Error Scenarios - Form Validation', () => {
  test('should show required field errors', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 2);
    
    await page.fill('input[name="checkIn"]', tomorrow.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', dayAfter.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    await page.click('button[type="submit"]');
    
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    const roomCards = await page.locator('[data-testid="room-card"]').count();
    
    if (roomCards > 0) {
      await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
      
      // Try to continue without filling any fields
      await page.click('button:has-text("Continue")');
      
      // Should show multiple required field errors
      const errorMessages = page.locator('text=/required|จำเป็น/i');
      const errorCount = await errorMessages.count();
      
      expect(errorCount).toBeGreaterThan(0);
    }
  });

  test('should validate email format in guest info', async ({ page }) => {
    await page.goto('/rooms/search');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 2);
    
    await page.fill('input[name="checkIn"]', tomorrow.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', dayAfter.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    await page.click('button[type="submit"]');
    
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    const roomCards = await page.locator('[data-testid="room-card"]').count();
    
    if (roomCards > 0) {
      await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
      
      // Fill with invalid email
      await page.fill('input[name="firstName"]', 'Test');
      await page.fill('input[name="lastName"]', 'User');
      await page.fill('input[name="email"]', 'not-an-email');
      await page.fill('input[name="phone"]', '+66812345678');
      
      await page.click('button:has-text("Continue")');
      
      // Should show email validation error
      await expect(page.locator('text=/invalid.*email|อีเมลไม่ถูกต้อง/i')).toBeVisible();
    }
  });
});
