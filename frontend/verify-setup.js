const fs = require('fs');
const path = require('path');

console.log('🔍 Verifying Next.js Project Setup...\n');

const checks = [
  {
    name: 'package.json exists',
    check: () => fs.existsSync('package.json'),
  },
  {
    name: 'next.config.js exists',
    check: () => fs.existsSync('next.config.ts'),
  },
  {
    name: 'tsconfig.json exists',
    check: () => fs.existsSync('tsconfig.json'),
  },
  {
    name: 'src/app directory exists',
    check: () => fs.existsSync('src/app'),
  },
  {
    name: 'src/components directory exists',
    check: () => fs.existsSync('src/components'),
  },
  {
    name: 'src/lib directory exists',
    check: () => fs.existsSync('src/lib'),
  },
  {
    name: 'src/types directory exists',
    check: () => fs.existsSync('src/types'),
  },
  {
    name: 'src/store directory exists',
    check: () => fs.existsSync('src/store'),
  },
  {
    name: 'NextAuth route exists',
    check: () => fs.existsSync('src/app/api/auth/[...nextauth]/route.ts'),
  },
  {
    name: 'API client exists',
    check: () => fs.existsSync('src/lib/api.ts'),
  },
  {
    name: 'Auth config exists',
    check: () => fs.existsSync('src/lib/auth.ts'),
  },
  {
    name: 'Query client exists',
    check: () => fs.existsSync('src/lib/query-client.ts'),
  },
  {
    name: 'Type definitions exist',
    check: () => fs.existsSync('src/types/index.ts'),
  },
  {
    name: 'Providers component exists',
    check: () => fs.existsSync('src/components/providers.tsx'),
  },
  {
    name: 'UI components exist',
    check: () => {
      return (
        fs.existsSync('src/components/ui/button.tsx') &&
        fs.existsSync('src/components/ui/card.tsx') &&
        fs.existsSync('src/components/ui/input.tsx') &&
        fs.existsSync('src/components/ui/loading.tsx')
      );
    },
  },
  {
    name: 'Zustand stores exist',
    check: () => {
      return (
        fs.existsSync('src/store/useAuthStore.ts') &&
        fs.existsSync('src/store/useBookingStore.ts')
      );
    },
  },
  {
    name: '.env.example exists',
    check: () => fs.existsSync('.env.example'),
  },
  {
    name: 'README.md exists',
    check: () => fs.existsSync('README.md'),
  },
];

let passed = 0;
let failed = 0;

checks.forEach((check) => {
  const result = check.check();
  if (result) {
    console.log(`✅ ${check.name}`);
    passed++;
  } else {
    console.log(`❌ ${check.name}`);
    failed++;
  }
});

console.log(`\n📊 Results: ${passed}/${checks.length} checks passed`);

if (failed === 0) {
  console.log('\n🎉 All checks passed! Setup is complete.');
  console.log('\n📝 Next steps:');
  console.log('   1. Run: npm install');
  console.log('   2. Copy .env.example to .env.local and configure');
  console.log('   3. Run: npm run dev');
  console.log('   4. Open http://localhost:3000');
  process.exit(0);
} else {
  console.log(`\n⚠️  ${failed} check(s) failed. Please review the setup.`);
  process.exit(1);
}
