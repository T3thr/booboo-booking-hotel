@echo off
echo ========================================
echo 🔒 SSL Certificate Setup
echo ========================================
echo.

echo สร้าง SSL directory...
if not exist nginx\ssl mkdir nginx\ssl

echo.
echo สร้าง Self-Signed Certificate สำหรับ Development...
echo (สำหรับ Production ใช้ Let's Encrypt หรือ Certificate จริง)
echo.

cd nginx\ssl

echo สร้าง Private Key...
openssl genrsa -out key.pem 2048

echo สร้าง Certificate...
openssl req -new -x509 -key key.pem -out cert.pem -days 365 -subj "/C=TH/ST=Bangkok/L=Bangkok/O=Hotel Booking/CN=localhost"

echo.
echo ✅ SSL Certificate สร้างเสร็จ!
echo.
echo 📁 Files:
echo   - nginx/ssl/key.pem (Private Key)
echo   - nginx/ssl/cert.pem (Certificate)
echo.
echo ⚠️  สำหรับ Production:
echo   1. ใช้ Let's Encrypt: certbot --nginx
echo   2. หรือใช้ Certificate จาก CA
echo.

cd ..\..
pause