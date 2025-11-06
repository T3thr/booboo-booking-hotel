#!/usr/bin/env node

/**
 * E2E Test Setup Verification Script
 * 
 * This script verifies that the E2E test environment is properly configured
 * and ready to run tests.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const COLORS = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

function log(message, color = COLORS.reset) {
  console.log(`${color}${message}${COLORS.reset}`);
}

function checkMark() {
  return `${COLORS.green}✓${COLORS.reset}`;
}

function crossMark() {
  return `${COLORS.red}✗${COLORS.reset}`;
}

function warningMark() {
  return `${COLORS.yellow}⚠${COLORS.reset}`;
}

async function checkUrl(url, name) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname,
      method: 'GET',
      timeout: 5000,
    };

    const req = http.request(options, (res) => {
      if (res.statusCode >= 200 && res.statusCode < 500) {
        log(`  ${checkMark()} ${name} is running at ${url}`, COLORS.green);
        resolve(true);
      } else {
        log(`  ${crossMark()} ${name} returned status ${res.statusCode}`, COLORS.red);
        resolve(false);
      }
    });

    req.on('error', () => {
      log(`  ${crossMark()} ${name} is not accessible at ${url}`, COLORS.red);
      resolve(false);
    });

    req.on('timeout', () => {
      log(`  ${crossMark()} ${name} request timed out`, COLORS.red);
      req.destroy();
      resolve(false);
    });

    req.end();
  });
}

function checkFile(filePath, name) {
  if (fs.existsSync(filePath)) {
    log(`  ${checkMark()} ${name} exists`, COLORS.green);
    return true;
  } else {
    log(`  ${crossMark()} ${name} not found`, COLORS.red);
    return false;
  }
}

function checkDirectory(dirPath, name) {
  if (fs.existsSync(dirPath) && fs.statSync(dirPath).isDirectory()) {
    log(`  ${checkMark()} ${name} directory exists`, COLORS.green);
    return true;
  } else {
    log(`  ${crossMark()} ${name} directory not found`, COLORS.red);
    return false;
  }
}

async function main() {
  log('\n========================================', COLORS.blue);
  log('E2E Test Setup Verification', COLORS.blue);
  log('========================================\n', COLORS.blue);

  let allChecksPass = true;

  // Check Node.js version
  log('Checking Node.js version...', COLORS.blue);
  const nodeVersion = process.version;
  const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
  if (majorVersion >= 18) {
    log(`  ${checkMark()} Node.js ${nodeVersion} (>= 18 required)`, COLORS.green);
  } else {
    log(`  ${crossMark()} Node.js ${nodeVersion} (>= 18 required)`, COLORS.red);
    allChecksPass = false;
  }
  console.log();

  // Check dependencies
  log('Checking dependencies...', COLORS.blue);
  const hasNodeModules = checkDirectory('node_modules', 'node_modules');
  const hasPlaywright = checkDirectory('node_modules/@playwright', 'Playwright');
  if (!hasNodeModules || !hasPlaywright) {
    log(`  ${warningMark()} Run: npm install`, COLORS.yellow);
    allChecksPass = false;
  }
  console.log();

  // Check Playwright browsers
  log('Checking Playwright browsers...', COLORS.blue);
  const hasPlaywrightCache = checkDirectory(
    path.join(require('os').homedir(), '.cache/ms-playwright'),
    'Playwright browsers'
  ) || checkDirectory(
    'node_modules/.playwright',
    'Playwright browsers (local)'
  );
  if (!hasPlaywrightCache) {
    log(`  ${warningMark()} Run: npx playwright install chromium`, COLORS.yellow);
  }
  console.log();

  // Check test files
  log('Checking test files...', COLORS.blue);
  checkFile('tests/01-booking-flow.spec.ts', 'Booking flow tests');
  checkFile('tests/02-checkin-flow.spec.ts', 'Check-in flow tests');
  checkFile('tests/03-cancellation-flow.spec.ts', 'Cancellation flow tests');
  checkFile('tests/04-error-scenarios.spec.ts', 'Error scenarios tests');
  console.log();

  // Check configuration files
  log('Checking configuration files...', COLORS.blue);
  checkFile('playwright.config.ts', 'Playwright config');
  checkFile('package.json', 'package.json');
  console.log();

  // Check helper files
  log('Checking helper files...', COLORS.blue);
  checkFile('fixtures/test-data.ts', 'Test data');
  checkFile('fixtures/auth-helpers.ts', 'Auth helpers');
  console.log();

  // Check services
  log('Checking services...', COLORS.blue);
  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:8080';

  const frontendRunning = await checkUrl(frontendUrl, 'Frontend');
  const backendRunning = await checkUrl(backendUrl + '/api/health', 'Backend API');

  if (!frontendRunning) {
    log(`  ${warningMark()} Start frontend: cd frontend && npm run dev`, COLORS.yellow);
    allChecksPass = false;
  }
  if (!backendRunning) {
    log(`  ${warningMark()} Start backend: cd backend && go run cmd/server/main.go`, COLORS.yellow);
    allChecksPass = false;
  }
  console.log();

  // Summary
  log('========================================', COLORS.blue);
  if (allChecksPass && frontendRunning && backendRunning) {
    log('✅ All checks passed! Ready to run tests.', COLORS.green);
    log('\nRun tests with: npm test', COLORS.blue);
  } else {
    log('⚠️  Some checks failed. Please fix the issues above.', COLORS.yellow);
    log('\nSetup instructions:', COLORS.blue);
    log('  1. Install dependencies: npm install', COLORS.reset);
    log('  2. Install browsers: npx playwright install chromium', COLORS.reset);
    log('  3. Start backend: cd backend && go run cmd/server/main.go', COLORS.reset);
    log('  4. Start frontend: cd frontend && npm run dev', COLORS.reset);
    log('  5. Run tests: npm test', COLORS.reset);
  }
  log('========================================\n', COLORS.blue);

  process.exit(allChecksPass && frontendRunning && backendRunning ? 0 : 1);
}

main().catch((error) => {
  console.error('Error running verification:', error);
  process.exit(1);
});
