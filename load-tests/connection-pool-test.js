import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend, Rate } from 'k6/metrics';

// Custom metrics
const dbConnectionErrors = new Counter('db_connection_errors');
const timeoutErrors = new Counter('timeout_errors');
const responseTime = new Trend('response_time');
const errorRate = new Rate('error_rate');

// Test configuration - Stress test for database connection pool
export const options = {
  scenarios: {
    connection_pool_stress: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 200,
      stages: [
        { duration: '30s', target: 50 },   // Ramp to 50 req/s
        { duration: '1m', target: 100 },   // Ramp to 100 req/s
        { duration: '30s', target: 150 },  // Ramp to 150 req/s
        { duration: '1m', target: 150 },   // Hold at 150 req/s
        { duration: '30s', target: 0 },    // Ramp down
      ],
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<5000', 'p(99)<10000'],
    http_req_failed: ['rate<0.05'], // Less than 5% failure rate
    db_connection_errors: ['count<10'], // Very few connection errors
    error_rate: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';

// Various endpoints to test connection pool under different loads
const ENDPOINTS = [
  { method: 'GET', path: '/api/rooms/types', weight: 30 },
  { method: 'GET', path: '/api/rooms/search?checkIn=2025-12-01&checkOut=2025-12-03&guests=2', weight: 25 },
  { method: 'GET', path: '/api/inventory?roomTypeId=1&startDate=2025-12-01&endDate=2025-12-31', weight: 20 },
  { method: 'GET', path: '/api/pricing/calendar?startDate=2025-12-01&endDate=2025-12-31', weight: 15 },
  { method: 'GET', path: '/api/bookings', weight: 10 },
];

function selectEndpoint() {
  const random = Math.random() * 100;
  let cumulative = 0;
  
  for (const endpoint of ENDPOINTS) {
    cumulative += endpoint.weight;
    if (random <= cumulative) {
      return endpoint;
    }
  }
  
  return ENDPOINTS[0];
}

function login() {
  const userId = Math.floor(Math.random() * 1000);
  const email = `pooltest${userId}@test.com`;
  const password = 'test123';

  // Register if needed
  http.post(`${BASE_URL}/api/auth/register`, JSON.stringify({
    email: email,
    password: password,
    firstName: `Pool${userId}`,
    lastName: 'Test',
    phone: `555${String(userId).padStart(7, '0')}`,
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  // Login
  const res = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: email,
    password: password,
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  if (res.status === 200) {
    const body = JSON.parse(res.body);
    return body.accessToken;
  }

  return null;
}

export default function () {
  const token = login();
  
  if (!token) {
    errorRate.add(true);
    return;
  }

  const endpoint = selectEndpoint();
  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    timeout: '30s',
  };

  const startTime = Date.now();
  let res;

  if (endpoint.method === 'GET') {
    res = http.get(`${BASE_URL}${endpoint.path}`, params);
  } else if (endpoint.method === 'POST') {
    res = http.post(`${BASE_URL}${endpoint.path}`, '{}', params);
  }

  const duration = Date.now() - startTime;
  responseTime.add(duration);

  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'no timeout': (r) => r.status !== 0,
    'no server error': (r) => r.status < 500,
  });

  if (!success) {
    errorRate.add(true);
    
    if (res.status === 0) {
      timeoutErrors.add(1);
      console.log(`Timeout on ${endpoint.path}`);
    } else if (res.status >= 500) {
      // Check if it's a database connection error
      const body = res.body || '';
      if (body.includes('connection') || body.includes('pool') || body.includes('database')) {
        dbConnectionErrors.add(1);
        console.error(`DB Connection Error on ${endpoint.path}: ${res.status}`);
      }
    }
  } else {
    errorRate.add(false);
  }

  sleep(0.1); // Small delay between requests
}

export function handleSummary(data) {
  const totalRequests = data.metrics.http_reqs?.values?.count || 0;
  const failedRequests = data.metrics.http_req_failed?.values?.count || 0;
  const dbErrors = data.metrics.db_connection_errors?.values?.count || 0;
  const timeouts = data.metrics.timeout_errors?.values?.count || 0;
  const p95 = data.metrics.http_req_duration?.values['p(95)'] || 0;
  const p99 = data.metrics.http_req_duration?.values['p(99)'] || 0;

  console.log('\n=== CONNECTION POOL TEST SUMMARY ===');
  console.log(`Total Requests: ${totalRequests}`);
  console.log(`Failed Requests: ${failedRequests} (${((failedRequests/totalRequests)*100).toFixed(2)}%)`);
  console.log(`DB Connection Errors: ${dbErrors}`);
  console.log(`Timeout Errors: ${timeouts}`);
  console.log(`Response Time P95: ${p95.toFixed(2)}ms`);
  console.log(`Response Time P99: ${p99.toFixed(2)}ms`);
  
  if (dbErrors === 0 && timeouts < 10) {
    console.log('\n✅ CONNECTION POOL TEST PASSED: System handled high load without connection issues!');
  } else if (dbErrors > 0) {
    console.log('\n❌ CONNECTION POOL TEST FAILED: Database connection errors detected!');
    console.log('   Recommendation: Increase database connection pool size');
  } else if (timeouts > 10) {
    console.log('\n⚠️  CONNECTION POOL TEST WARNING: High number of timeouts detected!');
    console.log('   Recommendation: Review query performance and connection pool configuration');
  }

  return {
    'connection-pool-summary.json': JSON.stringify(data, null, 2),
  };
}
