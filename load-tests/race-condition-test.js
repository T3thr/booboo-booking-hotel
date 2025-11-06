import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// Custom metrics
const successfulBookings = new Counter('successful_bookings');
const failedBookings = new Counter('failed_bookings');
const overbookings = new Counter('overbookings');
const bookingDuration = new Trend('booking_duration');

// Test configuration
export const options = {
  scenarios: {
    race_condition_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 20 },  // Ramp up to 20 users
        { duration: '30s', target: 50 },  // Ramp up to 50 users
        { duration: '1m', target: 50 },   // Stay at 50 users
        { duration: '10s', target: 0 },   // Ramp down
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests should be below 2s
    http_req_failed: ['rate<0.1'],     // Less than 10% of requests should fail
    successful_bookings: ['count>0'],   // At least some bookings should succeed
    overbookings: ['count==0'],         // NO overbookings should occur
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';

// Test data - targeting the last available room
const TEST_ROOM_TYPE_ID = 1;
const CHECK_IN_DATE = '2025-12-01';
const CHECK_OUT_DATE = '2025-12-03';

// Login and get token
function login() {
  const loginPayload = JSON.stringify({
    email: `testuser${__VU}@example.com`,
    password: 'password123',
  });

  const loginRes = http.post(`${BASE_URL}/api/auth/login`, loginPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  if (loginRes.status === 200) {
    const body = JSON.parse(loginRes.body);
    return body.accessToken;
  }
  
  // If user doesn't exist, register first
  const registerRes = http.post(`${BASE_URL}/api/auth/register`, JSON.stringify({
    email: `testuser${__VU}@example.com`,
    password: 'password123',
    firstName: `Test${__VU}`,
    lastName: 'User',
    phone: `555000${__VU}`,
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  if (registerRes.status === 201) {
    const loginRetry = http.post(`${BASE_URL}/api/auth/login`, loginPayload, {
      headers: { 'Content-Type': 'application/json' },
    });
    if (loginRetry.status === 200) {
      const body = JSON.parse(loginRetry.body);
      return body.accessToken;
    }
  }

  return null;
}

// Check room availability
function checkAvailability(token) {
  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const res = http.get(
    `${BASE_URL}/api/rooms/search?checkIn=${CHECK_IN_DATE}&checkOut=${CHECK_OUT_DATE}&guests=2`,
    params
  );

  check(res, {
    'availability check successful': (r) => r.status === 200,
  });

  if (res.status === 200) {
    const rooms = JSON.parse(res.body);
    return rooms.length > 0 ? rooms[0] : null;
  }

  return null;
}

// Create booking hold
function createHold(token, roomTypeId) {
  const holdPayload = JSON.stringify({
    roomTypeId: roomTypeId,
    checkInDate: CHECK_IN_DATE,
    checkOutDate: CHECK_OUT_DATE,
    guests: 2,
  });

  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const startTime = Date.now();
  const res = http.post(`${BASE_URL}/api/bookings/hold`, holdPayload, params);
  const duration = Date.now() - startTime;

  bookingDuration.add(duration);

  const holdSuccess = check(res, {
    'hold created': (r) => r.status === 201,
    'hold failed - no rooms': (r) => r.status === 400 || r.status === 409,
  });

  if (res.status === 201) {
    const body = JSON.parse(res.body);
    return body.sessionId || body.holdId;
  }

  return null;
}

// Confirm booking
function confirmBooking(token, holdId) {
  const bookingPayload = JSON.stringify({
    holdId: holdId,
    roomTypeId: TEST_ROOM_TYPE_ID,
    checkInDate: CHECK_IN_DATE,
    checkOutDate: CHECK_OUT_DATE,
    guests: [
      {
        firstName: `Guest${__VU}`,
        lastName: 'Test',
        type: 'Adult',
        isPrimary: true,
      },
    ],
    paymentMethod: 'credit_card',
  });

  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const res = http.post(`${BASE_URL}/api/bookings`, bookingPayload, params);

  const bookingSuccess = check(res, {
    'booking confirmed': (r) => r.status === 201,
    'booking failed': (r) => r.status !== 201,
  });

  if (res.status === 201) {
    successfulBookings.add(1);
    return true;
  } else {
    failedBookings.add(1);
    return false;
  }
}

// Verify no overbooking occurred
function verifyNoOverbooking(token) {
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
    
    // Check if booked_count + tentative_count exceeds allotment
    for (const day of inventory) {
      if (day.bookedCount + day.tentativeCount > day.allotment) {
        console.error(`OVERBOOKING DETECTED on ${day.date}: booked=${day.bookedCount}, tentative=${day.tentativeCount}, allotment=${day.allotment}`);
        overbookings.add(1);
      }
    }
  }
}

export default function () {
  // Login
  const token = login();
  
  if (!token) {
    console.error('Failed to login');
    return;
  }

  sleep(1);

  // Check availability
  const availableRoom = checkAvailability(token);
  
  if (!availableRoom) {
    console.log('No rooms available - expected behavior when fully booked');
    return;
  }

  sleep(0.5);

  // Try to create a hold (this is where race condition can occur)
  const holdId = createHold(token, TEST_ROOM_TYPE_ID);

  if (!holdId) {
    console.log('Hold creation failed - room taken by another user');
    return;
  }

  sleep(1);

  // Confirm booking
  const confirmed = confirmBooking(token, holdId);

  if (confirmed) {
    console.log(`VU ${__VU}: Successfully booked room`);
  }

  sleep(1);

  // Periodically verify no overbooking (only for some VUs to reduce load)
  if (__VU % 10 === 0) {
    verifyNoOverbooking(token);
  }

  sleep(2);
}

export function handleSummary(data) {
  const successCount = data.metrics.successful_bookings?.values?.count || 0;
  const failCount = data.metrics.failed_bookings?.values?.count || 0;
  const overbookCount = data.metrics.overbookings?.values?.count || 0;

  console.log('\n=== RACE CONDITION TEST SUMMARY ===');
  console.log(`Successful Bookings: ${successCount}`);
  console.log(`Failed Bookings: ${failCount}`);
  console.log(`Overbookings Detected: ${overbookCount}`);
  console.log(`Total Booking Attempts: ${successCount + failCount}`);
  
  if (overbookCount === 0) {
    console.log('✅ NO OVERBOOKING DETECTED - System passed race condition test!');
  } else {
    console.log('❌ OVERBOOKING DETECTED - System failed race condition test!');
  }

  return {
    'summary.json': JSON.stringify(data, null, 2),
  };
}
