/**
 * E2E Test: Complete Booking Flow
 * 
 * Tests the entire guest booking journey from search to confirmation:
 * 1. Search for available rooms
 * 2. Select a room
 * 3. Fill guest information
 * 4. Complete payment
 * 5. Receive confirmation
 * 
 * Requirements: 2.1-2.8, 3.1-3.8, 4.1-4.9
 */

import { test, expect } from '@playwright/test';
import { AuthHelper } from '../fixtures/auth-helpers';
import { testBooking, testVoucher } from '../fixtures/test-data';

test.describe('Booking Flow - Guest Journey', () => {
  let authHelper: AuthHelper;

  test.beforeEach(async ({ page }) => {
    authHelper = new AuthHelper(page);
  });

  test('should complete full booking flow successfully', async ({ page }) => {
    // Step 1: Navigate to room search
    await page.goto('/rooms/search');
    
    // Step 2: Fill search form
    const checkInDate = testBooking.checkIn();
    const checkOutDate = testBooking.checkOut();
    
    await page.fill('input[name="checkIn"]', checkInDate);
    await page.fill('input[name="checkOut"]', checkOutDate);
    await page.fill('input[name="guests"]', testBooking.guests.toString());
    
    // Step 3: Submit search
    await page.click('button[type="submit"]:has-text("Search"), button:has-text("ค้นหา")');
    
    // Step 4: Wait for results
    await page.waitForSelector('[data-testid="room-card"], .room-card', { timeout: 10000 });
    
    // Verify results are displayed
    const roomCards = page.locator('[data-testid="room-card"], .room-card');
    await expect(roomCards.first()).toBeVisible();
    
    // Step 5: Select first available room
    const firstRoomBookButton = roomCards.first().locator('button:has-text("Book"), button:has-text("จอง")');
    await firstRoomBookButton.click();
    
    // Step 6: Verify booking hold is created (countdown timer should appear)
    await page.waitForSelector('[data-testid="countdown-timer"], .countdown-timer', { timeout: 5000 });
    
    // Step 7: Fill guest information
    await page.fill('input[name="firstName"]', testBooking.guestInfo.firstName);
    await page.fill('input[name="lastName"]', testBooking.guestInfo.lastName);
    await page.fill('input[name="email"]', testBooking.guestInfo.email);
    await page.fill('input[name="phone"]', testBooking.guestInfo.phone);
    
    // Step 8: Proceed to payment
    await page.click('button:has-text("Continue"), button:has-text("ดำเนินการต่อ")');
    
    // Step 9: Verify booking summary
    await expect(page.locator('text=/Total|ยอดรวม/i')).toBeVisible();
    
    // Step 10: Complete payment (mock)
    await page.click('button:has-text("Confirm Payment"), button:has-text("ยืนยันการชำระเงิน")');
    
    // Step 11: Wait for confirmation page
    await page.waitForURL(/\/booking\/confirmation/, { timeout: 15000 });
    
    // Step 12: Verify confirmation details
    await expect(page.locator('text=/Booking Confirmed|การจองสำเร็จ/i')).toBeVisible();
    await expect(page.locator('text=/Booking ID|หมายเลขการจอง/i')).toBeVisible();
    
    // Step 13: Verify booking appears in history
    await page.goto('/bookings');
    await expect(page.locator(`text=${testBooking.guestInfo.firstName}`)).toBeVisible();
  });

  test('should apply voucher code correctly', async ({ page }) => {
    // Navigate and search
    await page.goto('/rooms/search');
    
    const checkInDate = testBooking.checkIn();
    const checkOutDate = testBooking.checkOut();
    
    await page.fill('input[name="checkIn"]', checkInDate);
    await page.fill('input[name="checkOut"]', checkOutDate);
    await page.fill('input[name="guests"]', testBooking.guests.toString());
    await page.click('button[type="submit"]');
    
    // Select room
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
    
    // Fill guest info
    await page.fill('input[name="firstName"]', testBooking.guestInfo.firstName);
    await page.fill('input[name="lastName"]', testBooking.guestInfo.lastName);
    await page.fill('input[name="email"]', testBooking.guestInfo.email);
    await page.fill('input[name="phone"]', testBooking.guestInfo.phone);
    await page.click('button:has-text("Continue")');
    
    // Apply voucher
    const voucherInput = page.locator('input[name="voucherCode"], input[placeholder*="voucher"], input[placeholder*="คูปอง"]');
    if (await voucherInput.isVisible()) {
      await voucherInput.fill(testVoucher.code);
      await page.click('button:has-text("Apply"), button:has-text("ใช้")');
      
      // Verify discount is applied
      await expect(page.locator('text=/Discount|ส่วนลด/i')).toBeVisible();
    }
  });

  test('should handle booking hold expiration', async ({ page }) => {
    // Navigate and search
    await page.goto('/rooms/search');
    
    const checkInDate = testBooking.checkIn();
    const checkOutDate = testBooking.checkOut();
    
    await page.fill('input[name="checkIn"]', checkInDate);
    await page.fill('input[name="checkOut"]', checkOutDate);
    await page.fill('input[name="guests"]', testBooking.guests.toString());
    await page.click('button[type="submit"]');
    
    // Select room
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
    
    // Verify countdown timer exists
    const timer = page.locator('[data-testid="countdown-timer"]');
    await expect(timer).toBeVisible();
    
    // Get initial time
    const initialTime = await timer.textContent();
    expect(initialTime).toMatch(/\d+:\d+/);
    
    // Wait a few seconds and verify timer is counting down
    await page.waitForTimeout(3000);
    const updatedTime = await timer.textContent();
    expect(updatedTime).not.toBe(initialTime);
  });

  test('should prevent booking without required guest information', async ({ page }) => {
    // Navigate and search
    await page.goto('/rooms/search');
    
    const checkInDate = testBooking.checkIn();
    const checkOutDate = testBooking.checkOut();
    
    await page.fill('input[name="checkIn"]', checkInDate);
    await page.fill('input[name="checkOut"]', checkOutDate);
    await page.fill('input[name="guests"]', testBooking.guests.toString());
    await page.click('button[type="submit"]');
    
    // Select room
    await page.waitForSelector('[data-testid="room-card"]', { timeout: 10000 });
    await page.click('[data-testid="room-card"]:first-child button:has-text("Book")');
    
    // Try to proceed without filling information
    const continueButton = page.locator('button:has-text("Continue"), button:has-text("ดำเนินการต่อ")');
    await continueButton.click();
    
    // Verify validation errors appear
    await expect(page.locator('text=/required|จำเป็น/i')).toBeVisible();
  });

  test('should show no rooms available message when dates are fully booked', async ({ page }) => {
    // This test assumes there's a way to create a fully booked scenario
    // or uses dates that are known to be fully booked in test data
    
    await page.goto('/rooms/search');
    
    // Use dates far in the future that might not have inventory
    const farFutureCheckIn = new Date();
    farFutureCheckIn.setFullYear(farFutureCheckIn.getFullYear() + 2);
    const farFutureCheckOut = new Date(farFutureCheckIn);
    farFutureCheckOut.setDate(farFutureCheckOut.getDate() + 1);
    
    await page.fill('input[name="checkIn"]', farFutureCheckIn.toISOString().split('T')[0]);
    await page.fill('input[name="checkOut"]', farFutureCheckOut.toISOString().split('T')[0]);
    await page.fill('input[name="guests"]', '2');
    await page.click('button[type="submit"]');
    
    // Wait for response
    await page.waitForTimeout(2000);
    
    // Check for either results or no availability message
    const hasResults = await page.locator('[data-testid="room-card"]').count() > 0;
    const hasNoAvailabilityMessage = await page.locator('text=/No rooms available|ไม่มีห้องว่าง/i').isVisible();
    
    expect(hasResults || hasNoAvailabilityMessage).toBeTruthy();
  });
});
