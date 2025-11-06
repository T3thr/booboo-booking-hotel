/**
 * Authentication Helper Functions for E2E Tests
 * 
 * Provides reusable authentication utilities for different user roles
 */

import { Page } from '@playwright/test';
import { testUsers } from './test-data';

export class AuthHelper {
  constructor(private page: Page) {}

  /**
   * Register a new guest user
   */
  async registerGuest(userData = testUsers.guest) {
    await this.page.goto('/auth/register');
    
    await this.page.fill('input[name="email"]', userData.email);
    await this.page.fill('input[name="password"]', userData.password);
    await this.page.fill('input[name="firstName"]', userData.firstName);
    await this.page.fill('input[name="lastName"]', userData.lastName);
    await this.page.fill('input[name="phone"]', userData.phone);
    
    await this.page.click('button[type="submit"]');
    
    // Wait for redirect or success message
    await this.page.waitForURL(/\/(rooms\/search|auth\/signin)/, { timeout: 10000 });
  }

  /**
   * Login as guest
   */
  async loginAsGuest(credentials = testUsers.guest) {
    await this.page.goto('/auth/signin');
    
    await this.page.fill('input[name="email"]', credentials.email);
    await this.page.fill('input[name="password"]', credentials.password);
    
    await this.page.click('button[type="submit"]');
    
    // Wait for successful login
    await this.page.waitForURL(/\/rooms\/search/, { timeout: 10000 });
  }

  /**
   * Login as staff (receptionist, housekeeper, manager)
   */
  async loginAsStaff(role: 'receptionist' | 'housekeeper' | 'manager') {
    const credentials = testUsers[role];
    
    await this.page.goto('/auth/signin');
    
    await this.page.fill('input[name="email"]', credentials.email);
    await this.page.fill('input[name="password"]', credentials.password);
    
    await this.page.click('button[type="submit"]');
    
    // Wait for role-specific dashboard
    const expectedUrls: Record<string, RegExp> = {
      receptionist: /\/dashboard/,
      housekeeper: /\/housekeeping/,
      manager: /\/reports|\/pricing|\/inventory/,
    };
    
    await this.page.waitForURL(expectedUrls[role], { timeout: 10000 });
  }

  /**
   * Logout current user
   */
  async logout() {
    // Look for logout button or link
    const logoutButton = this.page.locator('button:has-text("Logout"), a:has-text("Logout"), button:has-text("ออกจากระบบ"), a:has-text("ออกจากระบบ")').first();
    
    if (await logoutButton.isVisible()) {
      await logoutButton.click();
      await this.page.waitForURL(/\/auth\/signin/, { timeout: 5000 });
    }
  }

  /**
   * Check if user is authenticated
   */
  async isAuthenticated(): Promise<boolean> {
    const currentUrl = this.page.url();
    return !currentUrl.includes('/auth/signin') && !currentUrl.includes('/auth/register');
  }
}
