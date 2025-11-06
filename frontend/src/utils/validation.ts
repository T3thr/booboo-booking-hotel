import { z } from 'zod';

export const loginSchema = z.object({
  username: z.string().min(3, 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร'),
  password: z.string().min(6, 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'),
});

export const registerSchema = z.object({
  first_name: z.string().min(1, 'กรุณากรอกชื่อ'),
  last_name: z.string().min(1, 'กรุณากรอกนามสกุล'),
  email: z.string().email('รูปแบบอีเมลไม่ถูกต้อง'),
  phone: z.string().min(10, 'เบอร์โทรศัพท์ต้องมีอย่างน้อย 10 หลัก'),
  username: z.string().min(3, 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร'),
  password: z.string().min(6, 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'),
});

export const searchSchema = z.object({
  check_in_date: z.string().min(1, 'กรุณาเลือกวันเช็คอิน'),
  check_out_date: z.string().min(1, 'กรุณาเลือกวันเช็คเอาท์'),
  adults: z.number().min(1, 'จำนวนผู้เข้าพักต้องมีอย่างน้อย 1 คน').optional(),
  children: z.number().min(0).optional(),
});
