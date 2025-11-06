/**
 * NextAuth.js Setup Verification Script
 * 
 * This script checks if all NextAuth files are in place and properly configured.
 */

const fs = require('fs');
const path = require('path');

const checks = [];

function checkFile(filePath, description) {
  const fullPath = path.join(__dirname, filePath);
  const exists = fs.existsSync(fullPath);
  checks.push({
    name: description,
    status: exists ? '✓' : '✗',
    passed: exists,
    path: filePath
  });
  return exists;
}

function checkEnvVar(varName, description) {
  const envPath = path.join(__dirname, '.env.local');
  if (!fs.existsSync(envPath)) {
    checks.push({
      name: description,
      status: '✗',
      passed: false,
      path: '.env.local (file not found)'
    });
    return false;
  }

  const content = fs.readFileSync(envPath, 'utf8');
  const hasVar = content.includes(varName) && !content.includes(`# ${varName}`);
  checks.push({
    name: description,
    status: hasVar ? '✓' : '✗',
    passed: hasVar,
    path: `.env.local (${varName})`
  });
  return hasVar;
}

console.log('\n🔍 NextAuth.js Setup Verification\n');
console.log('='.repeat(60));

// Check core files
console.log('\n📁 Core Files:');
checkFile('src/lib/auth.ts', 'NextAuth configuration');
checkFile('src/app/api/auth/[...nextauth]/route.ts', 'NextAuth API route');

// Check auth pages
console.log('\n📄 Auth Pages:');
checkFile('src/app/auth/signin/page.tsx', 'Sign-in page');
checkFile('src/app/auth/register/page.tsx', 'Register page');
checkFile('src/app/auth/error/page.tsx', 'Error page');
checkFile('src/app/auth/test/page.tsx', 'Test page');

// Check components
console.log('\n🧩 Components:');
checkFile('src/components/providers.tsx', 'Providers (SessionProvider)');
checkFile('src/components/protected-route.tsx', 'Protected route component');

// Check environment variables
console.log('\n🔐 Environment Variables:');
checkEnvVar('NEXTAUTH_URL', 'NEXTAUTH_URL');
checkEnvVar('NEXTAUTH_SECRET', 'NEXTAUTH_SECRET');
checkEnvVar('BACKEND_URL', 'BACKEND_URL');
checkEnvVar('NEXT_PUBLIC_API_URL', 'NEXT_PUBLIC_API_URL');

// Check documentation
console.log('\n📚 Documentation:');
checkFile('NEXTAUTH_SETUP.md', 'NextAuth setup documentation');

// Summary
console.log('\n' + '='.repeat(60));
console.log('\n📊 Summary:\n');

const passed = checks.filter(c => c.passed).length;
const total = checks.length;
const percentage = Math.round((passed / total) * 100);

checks.forEach(check => {
  console.log(`${check.status} ${check.name}`);
  if (!check.passed) {
    console.log(`   └─ Missing: ${check.path}`);
  }
});

console.log('\n' + '='.repeat(60));
console.log(`\n${passed}/${total} checks passed (${percentage}%)\n`);

if (passed === total) {
  console.log('✅ All checks passed! NextAuth.js is properly configured.\n');
  console.log('Next steps:');
  console.log('1. Start the backend: cd backend && make run');
  console.log('2. Start the frontend: npm run dev');
  console.log('3. Visit http://localhost:3000/auth/test to test authentication');
  console.log('4. Try signing in with test credentials\n');
} else {
  console.log('❌ Some checks failed. Please review the missing files above.\n');
  process.exit(1);
}
