/**
 * E2E Test: Cancellation Flow
 * 
 * Tests the booking cancellation process:
 * 1. View booking history
 * 2. Select booking to cancel
 * 3. Review cancellation policy
 * 4. Confirm cancellation
 * 5. Verify refund calculation
 * 6. Verify booking status update
 * 
 * Requirements: 6.1-6.9
 */

import { test, expect } from '@playwright/test';
import { AuthHelper } from '../fixtures/auth-helpers';
import { testBooking } from '../fixtures/test-data';

test.describe('Cancellation Flow - Guest', () => {
  let authHelper: AuthHelper;

  test.beforeEach(async ({ page }) => {
    authHelper = new AuthHelper(page);
  });

  test('should display cancellation policy before cancelling', async ({ page }) => {
    // This test assumes there's at least one confirmed booking
    // In a real scenario, you'd create a booking first
    
    await authHelper.loginAsGuest();
    
    // Navigate to bookings
    await page.goto('/bookings');
    
    // Wait for bookings list
    await page.waitForSelector('[data-testid="booking-list"], .booking-list', { timeout: 10000 });
    
    // Check if there are any bookings
    const bookingCards = page.locator('[data-testid="booking-card"], .booking-card');
    const bookingCount = await bookingCards.count();
    
    if (bookingCount === 0) {
      console.log('No bookings available for cancellation test');
      test.skip();
      return;
    }
    
    // Find a confirmed booking
    const confirmedBooking = bookingCards.filter({ hasText: /Confirmed|ยืนยันแล้ว/i }).first();
    
    if (!(await confirmedBooking.isVisible())) {
      test.skip();
      return;
    }
    
    // Click on booking to view details
    await confirmedBooking.click();
    
    // Look for cancel button
    const cancelButton = page.locator('button:has-text("Cancel Booking"), button:has-text("ยกเลิกการจอง")');
    
    if (await cancelButton.isVisible()) {
      await cancelButton.click();
      
      // Verify cancellation policy is displayed
      await expect(page.locator('text=/Cancellation Policy|นโยบายการยกเลิก/i')).toBeVisible();
      await expect(page.locator('text=/Refund|เงินคืน/i')).toBeVisible();
    }
  });

  test('should calculate refund amount correctly', async ({ page }) => {
    await authHelper.loginAsGuest();
    await page.goto('/bookings');
    
    await page.waitForSelector('[data-testid="booking-list"]', { timeout: 10000 });
    
    const bookingCards = page.locator('[data-testid="booking-card"]');
    const bookingCount = await bookingCards.count();
    
    if (bookingCount === 0) {
      test.skip();
      return;
    }
    
    const confirmedBooking = bookingCards.filter({ hasText: /Confirmed/i }).first();
    
    if (!(await confirmedBooking.isVisible())) {
      test.skip();
      return;
    }
    
    // Get original booking amount
    const amountText = await confirmedBooking.locator('text=/Total|ยอดรวม/i').textContent();
    const originalAmount = parseFloat(amountText?.replace(/[^0-9.]/g, '') || '0');
    
    await confirmedBooking.click();
    
    const cancelButton = page.locator('button:has-text("Cancel Booking")');
    
    if (await cancelButton.isVisible()) {
      await cancelButton.click();
      
      // Wait for refund calculation
      await page.waitForSelector('text=/Refund Amount|จำนวนเงินคืน/i', { timeout: 5000 });
      
      // Verify refund amount is displayed
      const refundText = await page.locator('text=/Refund Amount|จำนวนเงินคืน/i').textContent();
      expect(refundText).toBeTruthy();
      
      // Refund should be <= original amount
      const refundAmount = parseFloat(refundText?.replace(/[^0-9.]/g, '') || '0');
      expect(refundAmount).toBeLessThanOrEqual(originalAmount);
    }
  });

  test('should complete cancellation successfully', async ({ page }) => {
    await authHelper.loginAsGuest();
    await page.goto('/bookings');
    
    await page.waitForSelector('[data-testid="booking-list"]', { timeout: 10000 });
    
    const bookingCards = page.locator('[data-testid="booking-card"]');
    const bookingCount = await bookingCards.count();
    
    if (bookingCount === 0) {
      test.skip();
      return;
    }
    
    const confirmedBooking = bookingCards.filter({ hasText: /Confirmed/i }).first();
    
    if (!(await confirmedBooking.isVisible())) {
      test.skip();
      return;
    }
    
    // Get booking ID for verification
    const bookingIdText = await confirmedBooking.locator('text=/BK|#/').textContent();
    
    await confirmedBooking.click();
    
    const cancelButton = page.locator('button:has-text("Cancel Booking")');
    
    if (await cancelButton.isVisible()) {
      await cancelButton.click();
      
      // Confirm cancellation in modal
      const confirmButton = page.locator('button:has-text("Confirm Cancellation"), button:has-text("ยืนยันการยกเลิก")');
      await confirmButton.click();
      
      // Wait for success message
      await expect(page.locator('text=/Cancellation successful|ยกเลิกสำเร็จ/i')).toBeVisible({ timeout: 10000 });
      
      // Navigate back to bookings
      await page.goto('/bookings');
      
      // Verify booking status is updated to Cancelled
      const cancelledBooking = page.locator(`text=${bookingIdText}`).locator('..').locator('text=/Cancelled|ยกเลิกแล้ว/i');
      await expect(cancelledBooking).toBeVisible();
    }
  });

  test('should prevent cancellation of checked-in booking', async ({ page }) => {
    await authHelper.loginAsGuest();
    await page.goto('/bookings');
    
    await page.waitForSelector('[data-testid="booking-list"]', { timeout: 10000 });
    
    // Look for checked-in booking
    const checkedInBooking = page.locator('[data-testid="booking-card"]').filter({ hasText: /Checked In|เช็คอินแล้ว/i }).first();
    
    if (await checkedInBooking.isVisible()) {
      await checkedInBooking.click();
      
      // Cancel button should not be visible or should be disabled
      const cancelButton = page.locator('button:has-text("Cancel Booking")');
      
      if (await cancelButton.isVisible()) {
        await expect(cancelButton).toBeDisabled();
      } else {
        // Button should not exist
        await expect(cancelButton).not.toBeVisible();
      }
    }
  });

  test('should show confirmation dialog before cancelling', async ({ page }) => {
    await authHelper.loginAsGuest();
    await page.goto('/bookings');
    
    await page.waitForSelector('[data-testid="booking-list"]', { timeout: 10000 });
    
    const bookingCards = page.locator('[data-testid="booking-card"]');
    const bookingCount = await bookingCards.count();
    
    if (bookingCount === 0) {
      test.skip();
      return;
    }
    
    const confirmedBooking = bookingCards.filter({ hasText: /Confirmed/i }).first();
    
    if (!(await confirmedBooking.isVisible())) {
      test.skip();
      return;
    }
    
    await confirmedBooking.click();
    
    const cancelButton = page.locator('button:has-text("Cancel Booking")');
    
    if (await cancelButton.isVisible()) {
      await cancelButton.click();
      
      // Verify confirmation dialog appears
      await expect(page.locator('text=/Are you sure|คุณแน่ใจหรือไม่/i')).toBeVisible();
      
      // Verify both confirm and cancel options are available
      await expect(page.locator('button:has-text("Confirm"), button:has-text("ยืนยัน")')).toBeVisible();
      await expect(page.locator('button:has-text("Cancel"), button:has-text("ยกเลิก"), button:has-text("กลับ")')).toBeVisible();
    }
  });

  test('should allow user to abort cancellation', async ({ page }) => {
    await authHelper.loginAsGuest();
    await page.goto('/bookings');
    
    await page.waitForSelector('[data-testid="booking-list"]', { timeout: 10000 });
    
    const bookingCards = page.locator('[data-testid="booking-card"]');
    const bookingCount = await bookingCards.count();
    
    if (bookingCount === 0) {
      test.skip();
      return;
    }
    
    const confirmedBooking = bookingCards.filter({ hasText: /Confirmed/i }).first();
    
    if (!(await confirmedBooking.isVisible())) {
      test.skip();
      return;
    }
    
    await confirmedBooking.click();
    
    const cancelButton = page.locator('button:has-text("Cancel Booking")');
    
    if (await cancelButton.isVisible()) {
      await cancelButton.click();
      
      // Click cancel/back button in confirmation dialog
      const abortButton = page.locator('button:has-text("Cancel"):not(:has-text("Booking")), button:has-text("กลับ"), button:has-text("ยกเลิก"):not(:has-text("การจอง"))').first();
      await abortButton.click();
      
      // Verify we're still on booking details page
      await expect(page.locator('text=/Booking Details|รายละเอียดการจอง/i')).toBeVisible();
      
      // Booking should still be confirmed
      await expect(page.locator('text=/Confirmed|ยืนยันแล้ว/i')).toBeVisible();
    }
  });

  test('should display cancellation history', async ({ page }) => {
    await authHelper.loginAsGuest();
    await page.goto('/bookings');
    
    await page.waitForSelector('[data-testid="booking-list"]', { timeout: 10000 });
    
    // Look for cancelled bookings
    const cancelledBookings = page.locator('[data-testid="booking-card"]').filter({ hasText: /Cancelled|ยกเลิกแล้ว/i });
    const cancelledCount = await cancelledBookings.count();
    
    if (cancelledCount > 0) {
      // Click on first cancelled booking
      await cancelledBookings.first().click();
      
      // Verify cancellation details are shown
      await expect(page.locator('text=/Cancelled|ยกเลิกแล้ว/i')).toBeVisible();
      await expect(page.locator('text=/Refund|เงินคืน/i')).toBeVisible();
    }
  });
});
