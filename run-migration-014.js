const fs = require('fs');
const path = require('path');

// Simple PostgreSQL client without dependencies
const https = require('https');
const { URL } = require('url');

console.log('============================================');
console.log('Running Migration 014: Role System');
console.log('============================================');
console.log('');

// Read SQL file
const sqlPath = path.join(__dirname, 'database', 'migrations', '014_create_role_system.sql');
const sql = fs.readFileSync(sqlPath, 'utf8');

console.log('✓ SQL file loaded');
console.log('');
console.log('Please run this SQL in Neon Console:');
console.log('https://console.neon.tech');
console.log('');
console.log('Or use one of these methods:');
console.log('1. Copy SQL to Neon SQL Editor');
console.log('2. Use DBeaver / pgAdmin');
console.log('3. Use backend/scripts/run-migration-014.go');
console.log('');
console.log('SQL Content:');
console.log('============================================');
console.log(sql);
console.log('============================================');
console.log('');
console.log('After running, test with:');
console.log('  Guest: anan.test@example.com / password123');
console.log('  Staff: receptionist1@hotel.com / staff123');
console.log('');
