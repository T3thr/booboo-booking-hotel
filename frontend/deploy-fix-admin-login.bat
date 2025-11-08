@echo off
echo ========================================
echo Deploy Fix: Admin Login Redirect Loop
echo ========================================
echo.

echo [1/3] Checking git status...
git status
echo.

echo [2/3] Adding changes...
git add frontend/src/app/auth/admin/page.tsx
git add frontend/src/middleware.ts
git add แก้ไขปัญหา_Manager_Login.md
git add frontend/deploy-fix-admin-login.bat
echo.

echo [3/3] Committing and pushing...
git commit -m "fix: admin login redirect loop on Vercel - use window.location.href"
git push
echo.

echo ========================================
echo ✅ Deploy Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Wait 2-3 minutes for Vercel to deploy
echo 2. Check Vercel Dashboard for deployment status
echo 3. Test login at: https://your-frontend.vercel.app/auth/admin
echo 4. Login with: manager@hotel.com / manager123
echo.
echo Important: Make sure NEXTAUTH_URL is set correctly in Vercel!
echo.
pause
