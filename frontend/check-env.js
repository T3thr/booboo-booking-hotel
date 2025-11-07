#!/usr/bin/env node

/**
 * Check Environment Variables
 * ตรวจสอบว่า environment variables ที่จำเป็นถูกตั้งค่าครบถ้วนหรือไม่
 */

const fs = require('fs');
const path = require('path');

// Required environment variables
const REQUIRED_VARS = {
  'NEXTAUTH_URL': {
    description: 'NextAuth URL (ต้องเป็น URL ของ Vercel)',
    example: 'https://booboo-booking.vercel.app',
    required: true,
  },
  'NEXTAUTH_SECRET': {
    description: 'NextAuth Secret (ต้องมีอย่างน้อย 32 ตัวอักษร)',
    example: 'IfXTxsvIgT9p0afnI/8cu5FJSVAU8l5h9TDsupeUbjU=',
    required: true,
    minLength: 32,
  },
  'NEXT_PUBLIC_API_URL': {
    description: 'Backend API URL (สำหรับ client-side)',
    example: 'https://booboo-booking.onrender.com',
    required: true,
  },
  'BACKEND_URL': {
    description: 'Backend URL (สำหรับ server-side)',
    example: 'https://booboo-booking.onrender.com',
    required: true,
  },
  'NODE_ENV': {
    description: 'Node Environment',
    example: 'production',
    required: true,
  },
};

// Optional environment variables
const OPTIONAL_VARS = {
  'NEXT_PUBLIC_DEBUG': {
    description: 'Debug mode',
    example: 'false',
  },
  'NEXT_PUBLIC_LOG_API': {
    description: 'API logging',
    example: 'false',
  },
};

console.log('\n========================================');
console.log('  Environment Variables Checker');
console.log('========================================\n');

// Check if .env.production exists
const envPath = path.join(__dirname, '.env.production');
if (!fs.existsSync(envPath)) {
  console.error('❌ Error: .env.production not found!');
  console.log('\nPlease create .env.production file with required variables.');
  process.exit(1);
}

// Read .env.production
const envContent = fs.readFileSync(envPath, 'utf8');
const envVars = {};

// Parse environment variables
envContent.split('\n').forEach(line => {
  line = line.trim();
  if (line && !line.startsWith('#')) {
    const [key, ...valueParts] = line.split('=');
    if (key && valueParts.length > 0) {
      envVars[key.trim()] = valueParts.join('=').trim();
    }
  }
});

let hasErrors = false;
let hasWarnings = false;

// Check required variables
console.log('📋 Required Variables:\n');
Object.entries(REQUIRED_VARS).forEach(([key, config]) => {
  const value = envVars[key];
  
  if (!value) {
    console.log(`❌ ${key}`);
    console.log(`   Missing! ${config.description}`);
    console.log(`   Example: ${config.example}\n`);
    hasErrors = true;
  } else if (value.includes('your-') || value.includes('placeholder')) {
    console.log(`⚠️  ${key}`);
    console.log(`   Contains placeholder! ${config.description}`);
    console.log(`   Current: ${value}`);
    console.log(`   Example: ${config.example}\n`);
    hasWarnings = true;
  } else if (config.minLength && value.length < config.minLength) {
    console.log(`⚠️  ${key}`);
    console.log(`   Too short! Must be at least ${config.minLength} characters`);
    console.log(`   Current length: ${value.length}\n`);
    hasWarnings = true;
  } else {
    console.log(`✅ ${key}`);
    console.log(`   ${value}\n`);
  }
});

// Check optional variables
console.log('\n📝 Optional Variables:\n');
Object.entries(OPTIONAL_VARS).forEach(([key, config]) => {
  const value = envVars[key];
  
  if (!value) {
    console.log(`ℹ️  ${key}`);
    console.log(`   Not set (optional). ${config.description}`);
    console.log(`   Example: ${config.example}\n`);
  } else {
    console.log(`✅ ${key}`);
    console.log(`   ${value}\n`);
  }
});

// Summary
console.log('\n========================================');
console.log('  Summary');
console.log('========================================\n');

if (hasErrors) {
  console.log('❌ Errors found! Please fix required variables before deploying.\n');
  process.exit(1);
} else if (hasWarnings) {
  console.log('⚠️  Warnings found! Please review before deploying.\n');
  process.exit(0);
} else {
  console.log('✅ All required variables are set correctly!\n');
  console.log('You can now deploy to Vercel.\n');
  process.exit(0);
}
