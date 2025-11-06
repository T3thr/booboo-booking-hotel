/**
 * Test Data Fixtures for E2E Tests
 * 
 * Contains reusable test data for different user roles and scenarios
 */

export const testUsers = {
  guest: {
    email: 'test.guest@example.com',
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'Guest',
    phone: '+66812345678',
  },
  receptionist: {
    email: 'receptionist@hotel.com',
    password: 'ReceptionistPass123!',
    role: 'receptionist',
  },
  housekeeper: {
    email: 'housekeeper@hotel.com',
    password: 'HousekeeperPass123!',
    role: 'housekeeper',
  },
  manager: {
    email: 'manager@hotel.com',
    password: 'ManagerPass123!',
    role: 'manager',
  },
};

export const testBooking = {
  checkIn: () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().split('T')[0];
  },
  checkOut: () => {
    const dayAfterTomorrow = new Date();
    dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 3);
    return dayAfterTomorrow.toISOString().split('T')[0];
  },
  guests: 2,
  guestInfo: {
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@example.com',
    phone: '+66898765432',
  },
};

export const testRoomTypes = {
  standard: {
    name: 'Standard Room',
    maxOccupancy: 2,
  },
  deluxe: {
    name: 'Deluxe Room',
    maxOccupancy: 3,
  },
  suite: {
    name: 'Suite',
    maxOccupancy: 4,
  },
};

export const testVoucher = {
  code: 'TEST10',
  discountType: 'Percentage',
  discountValue: 10,
};

export const errorScenarios = {
  invalidDates: {
    checkIn: '2024-01-01',
    checkOut: '2024-01-01', // Same day
  },
  pastDates: {
    checkIn: '2023-01-01',
    checkOut: '2023-01-02',
  },
  invalidEmail: 'not-an-email',
  weakPassword: '123',
  expiredVoucher: 'EXPIRED2023',
};
