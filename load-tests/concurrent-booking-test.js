import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

// Custom metrics
const bookingAttempts = new Counter('booking_attempts');
const bookingSuccesses = new Counter('booking_successes');
const bookingFailures = new Counter('booking_failures');
const inventoryViolations = new Counter('inventory_violations');
const successRate = new Rate('booking_success_rate');

// Test configuration - Aggressive concurrent booking test
export const options = {
  scenarios: {
    last_room_booking: {
      executor: 'shared-iterations',
      vus: 50,              // 50 users trying simultaneously
      iterations: 50,       // 50 total attempts
      maxDuration: '2m',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    inventory_violations: ['count==0'], // CRITICAL: No inventory violations
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';
const ADMIN_TOKEN = __ENV.ADMIN_TOKEN || '';

// Test targeting a room type with only 1 room available
const TEST_ROOM_TYPE_ID = 2;
const CHECK_IN_DATE = '2025-12-10';
const CHECK_OUT_DATE = '2025-12-12';

function setupTestData() {
  if (!ADMIN_TOKEN) {
    console.log('Warning: ADMIN_TOKEN not provided, skipping test data setup');
    return;
  }

  // Set allotment to 1 for the test room type
  const inventoryPayload = JSON.stringify({
    roomTypeId: TEST_ROOM_TYPE_ID,
    startDate: CHECK_IN_DATE,
    endDate: CHECK_OUT_DATE,
    allotment: 1,
  });

  const params = {
    headers: {
      'Authorization': `Bearer ${ADMIN_TOKEN}`,
      'Content-Type': 'application/json',
    },
  };

  http.put(`${BASE_URL}/api/inventory`, inventoryPayload, params);
}

function login(userId) {
  const email = `concurrent${userId}@test.com`;
  const password = 'test123';

  // Try to register
  const registerPayload = JSON.stringify({
    email: email,
    password: password,
    firstName: `Concurrent${userId}`,
    lastName: 'Tester',
    phone: `555${String(userId).padStart(7, '0')}`,
  });

  http.post(`${BASE_URL}/api/auth/register`, registerPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  // Login
  const loginPayload = JSON.stringify({
    email: email,
    password: password,
  });

  const res = http.post(`${BASE_URL}/api/auth/login`, loginPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  if (res.status === 200) {
    const body = JSON.parse(res.body);
    return body.accessToken;
  }

  return null;
}

function attemptBooking(token, userId) {
  bookingAttempts.add(1);

  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  // Step 1: Create hold
  const holdPayload = JSON.stringify({
    roomTypeId: TEST_ROOM_TYPE_ID,
    checkInDate: CHECK_IN_DATE,
    checkOutDate: CHECK_OUT_DATE,
    guests: 2,
  });

  const holdRes = http.post(`${BASE_URL}/api/bookings/hold`, holdPayload, params);

  if (holdRes.status !== 201) {
    console.log(`User ${userId}: Hold failed (expected when room taken)`);
    bookingFailures.add(1);
    successRate.add(false);
    return false;
  }

  const holdBody = JSON.parse(holdRes.body);
  const holdId = holdBody.sessionId || holdBody.holdId;

  // Small delay to simulate user filling form
  sleep(0.1);

  // Step 2: Confirm booking
  const bookingPayload = JSON.stringify({
    holdId: holdId,
    roomTypeId: TEST_ROOM_TYPE_ID,
    checkInDate: CHECK_IN_DATE,
    checkOutDate: CHECK_OUT_DATE,
    guests: [
      {
        firstName: `User${userId}`,
        lastName: 'Test',
        type: 'Adult',
        isPrimary: true,
      },
    ],
    paymentMethod: 'credit_card',
  });

  const bookingRes = http.post(`${BASE_URL}/api/bookings`, bookingPayload, params);

  const success = check(bookingRes, {
    'booking confirmed': (r) => r.status === 201,
  });

  if (success) {
    console.log(`✅ User ${userId}: Successfully booked the room!`);
    bookingSuccesses.add(1);
    successRate.add(true);
    return true;
  } else {
    console.log(`❌ User ${userId}: Booking failed`);
    bookingFailures.add(1);
    successRate.add(false);
    return false;
  }
}

function verifyInventoryIntegrity(token) {
  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const res = http.get(
    `${BASE_URL}/api/inventory?roomTypeId=${TEST_ROOM_TYPE_ID}&startDate=${CHECK_IN_DATE}&endDate=${CHECK_OUT_DATE}`,
    params
  );

  if (res.status === 200) {
    const inventory = JSON.parse(res.body);
    
    for (const day of inventory) {
      const total = day.bookedCount + day.tentativeCount;
      
      if (total > day.allotment) {
        console.error(`❌ INVENTORY VIOLATION on ${day.date}:`);
        console.error(`   Allotment: ${day.allotment}`);
        console.error(`   Booked: ${day.bookedCount}`);
        console.error(`   Tentative: ${day.tentativeCount}`);
        console.error(`   Total: ${total} (EXCEEDS ALLOTMENT BY ${total - day.allotment})`);
        inventoryViolations.add(1);
      }
    }
  }
}

export function setup() {
  setupTestData();
  sleep(2); // Wait for setup to complete
}

export default function () {
  const userId = __VU;
  
  // Login
  const token = login(userId);
  
  if (!token) {
    console.error(`User ${userId}: Failed to login`);
    return;
  }

  // All users attempt to book at roughly the same time
  const success = attemptBooking(token, userId);

  // Verify inventory integrity after booking attempt
  sleep(1);
  verifyInventoryIntegrity(token);
}

export function teardown(data) {
  console.log('\n=== CONCURRENT BOOKING TEST RESULTS ===');
  console.log('This test simulates 50 users trying to book the LAST available room simultaneously.');
  console.log('Expected: Only 1 booking should succeed, 49 should fail gracefully.');
  console.log('Critical: NO inventory violations should occur.\n');
}

export function handleSummary(data) {
  const attempts = data.metrics.booking_attempts?.values?.count || 0;
  const successes = data.metrics.booking_successes?.values?.count || 0;
  const failures = data.metrics.booking_failures?.values?.count || 0;
  const violations = data.metrics.inventory_violations?.values?.count || 0;

  console.log('\n=== FINAL SUMMARY ===');
  console.log(`Total Booking Attempts: ${attempts}`);
  console.log(`Successful Bookings: ${successes}`);
  console.log(`Failed Bookings: ${failures}`);
  console.log(`Inventory Violations: ${violations}`);
  
  if (violations === 0 && successes <= 1) {
    console.log('\n✅ TEST PASSED: No overbooking, system handled race condition correctly!');
  } else if (violations > 0) {
    console.log('\n❌ TEST FAILED: Inventory violations detected - OVERBOOKING OCCURRED!');
  } else if (successes > 1) {
    console.log('\n⚠️  TEST WARNING: Multiple bookings succeeded for single room!');
  }

  return {
    'concurrent-booking-summary.json': JSON.stringify(data, null, 2),
  };
}
