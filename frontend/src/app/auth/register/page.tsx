'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useSession } from 'next-auth/react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { getRoleHomePage } from '@/utils/role-redirect';
import { toast } from 'sonner';

export default function RegisterPage() {
  const router = useRouter();
  const { data: session, status } = useSession();
  
  // Redirect if already logged in
  useEffect(() => {
    if (status === 'authenticated' && session?.user) {
      const redirectUrl = getRoleHomePage(session.user.role || 'GUEST');
      router.replace(redirectUrl);
    }
  }, [status, session, router]);

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
  });
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validation
    if (formData.password !== formData.confirmPassword) {
      const errorMsg = 'รหัสผ่านไม่ตรงกัน';
      setError(errorMsg);
      toast.error(errorMsg);
      return;
    }

    if (formData.password.length < 8) {
      const errorMsg = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
      setError(errorMsg);
      toast.error(errorMsg);
      return;
    }

    if (!formData.phone || formData.phone.length < 10) {
      const errorMsg = 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง (อย่างน้อย 10 หลัก)';
      setError(errorMsg);
      toast.error(errorMsg);
      return;
    }

    setIsLoading(true);
    toast.loading('กำลังลงทะเบียน...', { id: 'register' });

    try {
      const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';
      const res = await fetch(`${backendUrl}/api/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          first_name: formData.firstName,
          last_name: formData.lastName,
          email: formData.email,
          phone: formData.phone,
          password: formData.password,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.message || data.error || 'ลงทะเบียนไม่สำเร็จ');
      }

      // Registration successful
      console.log('[Register] Success:', data);
      toast.success('ลงทะเบียนสำเร็จ! กำลังนำคุณไปยังหน้าเข้าสู่ระบบ...', { id: 'register', duration: 3000 });
      
      // Wait a bit for user to see success message
      await new Promise(resolve => setTimeout(resolve, 1500));
      router.push('/auth/signin?registered=true');
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'เกิดข้อผิดพลาดในการลงทะเบียน';
      console.error('[Register] Error:', errorMsg);
      setError(errorMsg);
      toast.error(errorMsg, { id: 'register' });
    } finally {
      setIsLoading(false);
    }
  };

  // Show loading while checking session
  if (status === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="animate-pulse text-muted-foreground">กำลังตรวจสอบ...</div>
      </div>
    );
  }

  // Don't render form if already authenticated
  if (status === 'authenticated') {
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background py-12 px-4 sm:px-6 lg:px-8">
      <Card className="max-w-md w-full space-y-8 p-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-foreground">
            ลงทะเบียน
          </h2>
          <p className="mt-2 text-center text-sm text-muted-foreground">
            สร้างบัญชีใหม่สำหรับการจองโรงแรม
          </p>
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && (
            <div className="rounded-md bg-destructive/10 border border-destructive/20 p-4">
              <div className="flex">
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-destructive">
                    {error}
                  </h3>
                </div>
              </div>
            </div>
          )}

          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="firstName" className="block text-sm font-medium text-foreground mb-1">
                  ชื่อ
                </label>
                <Input
                  id="firstName"
                  name="firstName"
                  type="text"
                  required
                  value={formData.firstName}
                  onChange={handleChange}
                  placeholder="สมชาย"
                  disabled={isLoading}
                />
              </div>

              <div>
                <label htmlFor="lastName" className="block text-sm font-medium text-foreground mb-1">
                  นามสกุล
                </label>
                <Input
                  id="lastName"
                  name="lastName"
                  type="text"
                  required
                  value={formData.lastName}
                  onChange={handleChange}
                  placeholder="ใจดี"
                  disabled={isLoading}
                />
              </div>
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-foreground mb-1">
                อีเมล
              </label>
              <Input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={formData.email}
                onChange={handleChange}
                placeholder="example@email.com"
                disabled={isLoading}
              />
            </div>

            <div>
              <label htmlFor="phone" className="block text-sm font-medium text-foreground mb-1">
                เบอร์โทรศัพท์
              </label>
              <Input
                id="phone"
                name="phone"
                type="tel"
                value={formData.phone}
                onChange={handleChange}
                placeholder="0812345678 (10 หลัก)"
                disabled={isLoading}
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-foreground mb-1">
                รหัสผ่าน
              </label>
              <Input
                id="password"
                name="password"
                type="password"
                autoComplete="new-password"
                required
                value={formData.password}
                onChange={handleChange}
                placeholder="อย่างน้อย 8 ตัวอักษร"
                disabled={isLoading}
              />
            </div>

            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-foreground mb-1">
                ยืนยันรหัสผ่าน
              </label>
              <Input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                autoComplete="new-password"
                required
                value={formData.confirmPassword}
                onChange={handleChange}
                placeholder="กรอกรหัสผ่านอีกครั้ง"
                disabled={isLoading}
              />
            </div>
          </div>

          <div>
            <Button
              type="submit"
              className="w-full"
              disabled={isLoading}
            >
              {isLoading ? 'กำลังลงทะเบียน...' : 'ลงทะเบียน'}
            </Button>
          </div>

          <div className="text-center">
            <p className="text-sm text-muted-foreground">
              มีบัญชีอยู่แล้ว?{' '}
              <a href="/auth/signin" className="font-medium text-primary hover:text-primary/80">
                เข้าสู่ระบบ
              </a>
            </p>
          </div>
        </form>
      </Card>
    </div>
  );
}
