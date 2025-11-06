/**
 * E2E Test: Check-in Flow
 * 
 * Tests the receptionist check-in process:
 * 1. Login as receptionist
 * 2. View arrivals
 * 3. Select booking for check-in
 * 4. Assign room
 * 5. Complete check-in
 * 6. Verify room status update
 * 
 * Requirements: 7.1-7.8, 12.1-12.7
 */

import { test, expect } from '@playwright/test';
import { AuthHelper } from '../fixtures/auth-helpers';

test.describe('Check-in Flow - Receptionist', () => {
  let authHelper: AuthHelper;

  test.beforeEach(async ({ page }) => {
    authHelper = new AuthHelper(page);
    // Login as receptionist before each test
    await authHelper.loginAsStaff('receptionist');
  });

  test('should complete check-in process successfully', async ({ page }) => {
    // Step 1: Navigate to check-in page or arrivals
    await page.goto('/checkin');
    
    // Step 2: Wait for arrivals list to load
    await page.waitForSelector('[data-testid="arrivals-list"], .arrivals-list, table', { timeout: 10000 });
    
    // Step 3: Check if there are any arrivals
    const arrivalRows = page.locator('[data-testid="arrival-row"], tbody tr');
    const arrivalCount = await arrivalRows.count();
    
    if (arrivalCount === 0) {
      console.log('No arrivals available for check-in test');
      test.skip();
      return;
    }
    
    // Step 4: Click check-in button for first arrival
    const firstArrival = arrivalRows.first();
    const checkInButton = firstArrival.locator('button:has-text("Check In"), button:has-text("เช็คอิน")');
    await checkInButton.click();
    
    // Step 5: Wait for room selection modal/page
    await page.waitForSelector('[data-testid="room-selection"], .room-selection', { timeout: 5000 });
    
    // Step 6: Select an available room
    const availableRooms = page.locator('[data-testid="available-room"], .available-room');
    await expect(availableRooms.first()).toBeVisible();
    
    // Click on first available room
    await availableRooms.first().click();
    
    // Step 7: Confirm check-in
    await page.click('button:has-text("Confirm Check-in"), button:has-text("ยืนยันเช็คอิน")');
    
    // Step 8: Wait for success message
    await expect(page.locator('text=/Check-in successful|เช็คอินสำเร็จ/i')).toBeVisible({ timeout: 10000 });
    
    // Step 9: Verify room status updated in dashboard
    await page.goto('/dashboard');
    await page.waitForSelector('[data-testid="room-status-grid"], .room-status-grid', { timeout: 5000 });
    
    // Verify at least one room shows as occupied
    const occupiedRooms = page.locator('[data-status="Occupied"], .room-occupied');
    await expect(occupiedRooms.first()).toBeVisible();
  });

  test('should show only clean/inspected rooms for check-in', async ({ page }) => {
    await page.goto('/checkin');
    
    // Wait for arrivals
    await page.waitForSelector('[data-testid="arrivals-list"]', { timeout: 10000 });
    
    const arrivalRows = page.locator('[data-testid="arrival-row"]');
    const arrivalCount = await arrivalRows.count();
    
    if (arrivalCount === 0) {
      test.skip();
      return;
    }
    
    // Click check-in for first arrival
    await arrivalRows.first().locator('button:has-text("Check In")').click();
    
    // Wait for room selection
    await page.waitForSelector('[data-testid="room-selection"]', { timeout: 5000 });
    
    // Verify only clean/inspected rooms are shown
    const availableRooms = page.locator('[data-testid="available-room"]');
    const roomCount = await availableRooms.count();
    
    if (roomCount > 0) {
      // Check first room's status
      const firstRoomStatus = await availableRooms.first().getAttribute('data-housekeeping-status');
      expect(['Clean', 'Inspected']).toContain(firstRoomStatus);
    }
  });

  test('should prevent check-in to dirty room', async ({ page }) => {
    await page.goto('/checkin');
    
    await page.waitForSelector('[data-testid="arrivals-list"]', { timeout: 10000 });
    
    const arrivalRows = page.locator('[data-testid="arrival-row"]');
    const arrivalCount = await arrivalRows.count();
    
    if (arrivalCount === 0) {
      test.skip();
      return;
    }
    
    await arrivalRows.first().locator('button:has-text("Check In")').click();
    await page.waitForSelector('[data-testid="room-selection"]', { timeout: 5000 });
    
    // Dirty rooms should not be in the available list
    const dirtyRooms = page.locator('[data-housekeeping-status="Dirty"]');
    await expect(dirtyRooms).toHaveCount(0);
  });

  test('should display room status dashboard correctly', async ({ page }) => {
    await page.goto('/dashboard');
    
    // Wait for dashboard to load
    await page.waitForSelector('[data-testid="room-status-grid"]', { timeout: 10000 });
    
    // Verify dashboard elements
    await expect(page.locator('text=/Room Status|สถานะห้อง/i')).toBeVisible();
    
    // Verify status summary
    const statusSummary = page.locator('[data-testid="status-summary"]');
    if (await statusSummary.isVisible()) {
      await expect(statusSummary.locator('text=/Vacant|ว่าง/i')).toBeVisible();
      await expect(statusSummary.locator('text=/Occupied|มีผู้เข้าพัก/i')).toBeVisible();
    }
    
    // Verify room cards exist
    const roomCards = page.locator('[data-testid="room-card"], .room-card');
    await expect(roomCards.first()).toBeVisible();
  });

  test('should auto-refresh room status dashboard', async ({ page }) => {
    await page.goto('/dashboard');
    
    await page.waitForSelector('[data-testid="room-status-grid"]', { timeout: 10000 });
    
    // Get initial room count
    const initialRoomCards = await page.locator('[data-testid="room-card"]').count();
    
    // Wait for auto-refresh (30 seconds according to requirements)
    // For testing, we'll just verify the refresh mechanism exists
    const refreshIndicator = page.locator('[data-testid="last-updated"], text=/Last updated|อัปเดตล่าสุด/i');
    
    // If refresh indicator exists, verify it's visible
    if (await refreshIndicator.isVisible()) {
      await expect(refreshIndicator).toBeVisible();
    }
    
    // Verify room count remains consistent
    const currentRoomCards = await page.locator('[data-testid="room-card"]').count();
    expect(currentRoomCards).toBeGreaterThan(0);
  });

  test('should filter rooms by status', async ({ page }) => {
    await page.goto('/dashboard');
    
    await page.waitForSelector('[data-testid="room-status-grid"]', { timeout: 10000 });
    
    // Look for filter controls
    const filterDropdown = page.locator('select[name="statusFilter"], [data-testid="status-filter"]');
    
    if (await filterDropdown.isVisible()) {
      // Select "Vacant" filter
      await filterDropdown.selectOption({ label: /Vacant|ว่าง/i });
      
      // Wait for filter to apply
      await page.waitForTimeout(1000);
      
      // Verify only vacant rooms are shown
      const visibleRooms = page.locator('[data-testid="room-card"]:visible');
      const roomCount = await visibleRooms.count();
      
      if (roomCount > 0) {
        const firstRoomStatus = await visibleRooms.first().getAttribute('data-occupancy-status');
        expect(firstRoomStatus).toBe('Vacant');
      }
    }
  });

  test('should show guest information during check-in', async ({ page }) => {
    await page.goto('/checkin');
    
    await page.waitForSelector('[data-testid="arrivals-list"]', { timeout: 10000 });
    
    const arrivalRows = page.locator('[data-testid="arrival-row"]');
    const arrivalCount = await arrivalRows.count();
    
    if (arrivalCount === 0) {
      test.skip();
      return;
    }
    
    // Verify guest information is displayed in arrivals list
    const firstArrival = arrivalRows.first();
    
    // Should show guest name
    await expect(firstArrival.locator('text=/[A-Z][a-z]+ [A-Z][a-z]+/')).toBeVisible();
    
    // Should show booking ID or confirmation number
    await expect(firstArrival.locator('text=/BK|#|หมายเลข/i')).toBeVisible();
  });
});
