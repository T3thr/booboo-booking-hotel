# Data Dictionary - ระบบจองห้องพักโรงแรม

## บทนำ
เอกสารนี้เป็น Data Dictionary ฉบับสมบูรณ์ของระบบจองห้องพักโรงแรม ครอบคลุมทุกตารางในฐานข้อมูล พร้อมคำอธิบายภาษาไทยและภาษาอังกฤษ

---

## 1. ส่วนจัดการแขก (Guest Management)

### 1.1 ตาราง `guests` - สมุดรายชื่อแขก

**วัตถุประสงค์:** เก็บข้อมูลส่วนตัวของผู้เข้าพัก

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `guest_id` | SERIAL | PRIMARY KEY | รหัสผู้เข้าพักอัตโนมัติ | Auto-increment guest ID |
| `first_name` | VARCHAR(100) | NOT NULL | ชื่อจริง | First name |
| `last_name` | VARCHAR(100) | NOT NULL | นามสกุล | Last name |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | อีเมล (ไม่ซ้ำกัน) | Unique email address |
| `phone` | VARCHAR(20) | NULLABLE | เบอร์โทรศัพท์ | Phone number |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Indexes:**
- `idx_guests_email` ON `email`

---

### 1.2 ตาราง `guest_accounts` - บัญชีผู้ใช้

**วัตถุประสงค์:** เก็บข้อมูลการเข้าสู่ระบบของผู้เข้าพัก

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `guest_account_id` | SERIAL | PRIMARY KEY | รหัสบัญชีอัตโนมัติ | Auto-increment account ID |
| `guest_id` | INT | FK → guests.guest_id, UNIQUE | รหัสผู้เข้าพัก (1:1) | Guest ID (one-to-one) |
| `hashed_password` | VARCHAR(255) | NOT NULL | รหัสผ่านที่เข้ารหัส (bcrypt) | Hashed password (bcrypt) |
| `last_login` | TIMESTAMP | NULLABLE | เวลาเข้าสู่ระบบครั้งล่าสุด | Last login timestamp |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างบัญชี | Account creation timestamp |

**Indexes:**
- `idx_guest_accounts_guest_id` ON `guest_id`

---

## 2. ส่วนจัดการห้องพัก (Room Management)

### 2.1 ตาราง `room_types` - ประเภทของห้องพัก

**วัตถุประสงค์:** กำหนดประเภทห้องพัก เช่น Standard, Deluxe, Suite


| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `room_type_id` | SERIAL | PRIMARY KEY | รหัสประเภทห้องอัตโนมัติ | Auto-increment room type ID |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE | ชื่อประเภทห้อง | Room type name |
| `description` | TEXT | NULLABLE | คำอธิบายประเภทห้อง | Room type description |
| `max_occupancy` | INT | NOT NULL, CHECK > 0 | จำนวนผู้เข้าพักสูงสุด | Maximum occupancy |
| `default_allotment` | INT | NOT NULL, DEFAULT 10 | จำนวนห้องเริ่มต้นที่เปิดขาย | Default room allotment |
| `base_price` | DECIMAL(10,2) | NOT NULL, DEFAULT 0.00 | ราคาพื้นฐาน (อ้างอิง) | Base price (reference) |
| `size_sqm` | DECIMAL(8,2) | NULLABLE | ขนาดห้อง (ตารางเมตร) | Room size (square meters) |
| `bed_type` | VARCHAR(50) | NULLABLE | ประเภทเตียง | Bed type |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

---

### 2.2 ตาราง `rooms` - ห้องพัก

**วัตถุประสงค์:** เก็บข้อมูลห้องพักจริงในโรงแรม

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `room_id` | SERIAL | PRIMARY KEY | รหัสห้องอัตโนมัติ | Auto-increment room ID |
| `room_type_id` | INT | FK → room_types.room_type_id | รหัสประเภทห้อง | Room type ID |
| `room_number` | VARCHAR(10) | NOT NULL, UNIQUE | หมายเลขห้อง (เช่น 101, 201) | Room number |
| `floor` | INT | NOT NULL, CHECK > 0 | ชั้น | Floor number |
| `occupancy_status` | VARCHAR(20) | NOT NULL, DEFAULT 'Vacant' | สถานะการเข้าพัก | Occupancy status |
| `housekeeping_status` | VARCHAR(50) | NOT NULL, DEFAULT 'Dirty' | สถานะการทำความสะอาด | Housekeeping status |
| `notes` | TEXT | NULLABLE | หมายเหตุ | Notes |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Enum Values:**
- `occupancy_status`: 'Vacant', 'Occupied'
- `housekeeping_status`: 'Dirty', 'Cleaning', 'Clean', 'Inspected', 'MaintenanceRequired', 'OutOfService'

**Indexes:**
- `idx_rooms_occupancy_status` ON `occupancy_status`
- `idx_rooms_housekeeping_status` ON `housekeeping_status`
- `idx_rooms_status_combined` ON `(occupancy_status, housekeeping_status)`
- `idx_rooms_room_type` ON `room_type_id`
- `idx_rooms_floor` ON `floor`

---

### 2.3 ตาราง `amenities` - สิ่งอำนวยความสะดวก

**วัตถุประสงค์:** เก็บรายการสิ่งอำนวยความสะดวกต่างๆ

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `amenity_id` | SERIAL | PRIMARY KEY | รหัสสิ่งอำนวยความสะดวกอัตโนมัติ | Auto-increment amenity ID |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE | ชื่อสิ่งอำนวยความสะดวก | Amenity name |
| `description` | TEXT | NULLABLE | คำอธิบาย | Description |
| `icon` | VARCHAR(50) | NULLABLE | ไอคอน | Icon name |
| `category` | VARCHAR(50) | NULLABLE | หมวดหมู่ | Category |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |

---

### 2.4 ตาราง `room_type_amenities` - ตัวเชื่อมสิ่งอำนวยความสะดวก

**วัตถุประสงค์:** เชื่อมโยงประเภทห้องกับสิ่งอำนวยความสะดวก (Many-to-Many)

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `room_type_id` | INT | PK, FK → room_types.room_type_id | รหัสประเภทห้อง | Room type ID |
| `amenity_id` | INT | PK, FK → amenities.amenity_id | รหัสสิ่งอำนวยความสะดวก | Amenity ID |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |

**Composite Primary Key:** (`room_type_id`, `amenity_id`)

**Indexes:**
- `idx_room_type_amenities_room_type` ON `room_type_id`
- `idx_room_type_amenities_amenity` ON `amenity_id`

---

## 3. ส่วนจัดการราคาและสต็อก (Pricing & Inventory)

### 3.1 ตาราง `room_inventory` - สต็อกห้อง

**วัตถุประสงค์:** จัดการจำนวนห้องว่างสำหรับแต่ละวัน


| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `room_type_id` | INT | PK, FK → room_types.room_type_id | รหัสประเภทห้อง | Room type ID |
| `date` | DATE | PK | วันที่ | Date |
| `allotment` | INT | NOT NULL, CHECK >= 0 | จำนวนห้องที่เปิดขาย | Total rooms available for sale |
| `booked_count` | INT | NOT NULL, DEFAULT 0 | จำนวนห้องที่จองแล้ว (Confirmed) | Confirmed bookings count |
| `tentative_count` | INT | NOT NULL, DEFAULT 0 | จำนวนห้องที่กำลังจอง (Hold) | Tentative bookings count |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Composite Primary Key:** (`room_type_id`, `date`)

**Constraints:**
- `CHK_Inventory`: `booked_count + tentative_count <= allotment`

**Indexes:**
- `idx_room_inventory_date` ON `date`
- `idx_room_inventory_room_type` ON `room_type_id`
- `idx_room_inventory_availability` ON `(room_type_id, date)` WHERE available > 0

**หมายเหตุ:** `booked_count` และ `tentative_count` ถูกจัดการโดย Stored Procedures เท่านั้น

---

### 3.2 ตาราง `cancellation_policies` - กฎการยกเลิกห้อง

**วัตถุประสงค์:** กำหนดนโยบายการยกเลิกการจอง

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `policy_id` | SERIAL | PRIMARY KEY | รหัสนโยบายอัตโนมัติ | Auto-increment policy ID |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE | ชื่อนโยบาย | Policy name |
| `description` | TEXT | NOT NULL | คำอธิบายนโยบาย | Policy description |
| `days_before_check_in` | INT | NOT NULL, CHECK >= 0 | จำนวนวันก่อนเช็คอิน | Days before check-in |
| `refund_percentage` | DECIMAL(5,2) | NOT NULL, DEFAULT 0.00 | เปอร์เซ็นต์เงินคืน (0-100) | Refund percentage |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | สถานะใช้งาน | Active status |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**ตัวอย่างนโยบาย:**
- Flexible: ยกเลิกฟรีได้จนถึง 24 ชั่วโมงก่อนเช็คอิน (คืนเงิน 100%)
- Moderate: ยกเลิกฟรีได้จนถึง 7 วันก่อนเช็คอิน (คืนเงิน 50-100%)
- Non-Refundable: ไม่สามารถยกเลิกได้ (คืนเงิน 0%)

---

### 3.3 ตาราง `rate_plans` - แพ็คเกจหรือโปรโมชั่นราคา

**วัตถุประสงค์:** กำหนดแผนราคาต่างๆ เช่น Standard Rate, Non-Refundable Rate

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `rate_plan_id` | SERIAL | PRIMARY KEY | รหัสแผนราคาอัตโนมัติ | Auto-increment rate plan ID |
| `name` | VARCHAR(100) | NOT NULL, UNIQUE | ชื่อแผนราคา | Rate plan name |
| `description` | TEXT | NULLABLE | คำอธิบายแผนราคา | Rate plan description |
| `policy_id` | INT | FK → cancellation_policies.policy_id | รหัสนโยบายการยกเลิก | Cancellation policy ID |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | สถานะใช้งาน | Active status |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

---

### 3.4 ตาราง `rate_tiers` - ระดับราคาตามฤดูกาล

**วัตถุประสงค์:** กำหนดระดับราคาตามฤดูกาล เช่น Low Season, High Season, Peak Season

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `rate_tier_id` | SERIAL | PRIMARY KEY | รหัสระดับราคาอัตโนมัติ | Auto-increment rate tier ID |
| `name` | VARCHAR(50) | NOT NULL, UNIQUE | ชื่อระดับราคา | Rate tier name |
| `description` | TEXT | NULLABLE | คำอธิบายระดับราคา | Rate tier description |
| `display_order` | INT | NOT NULL, DEFAULT 0 | ลำดับการแสดงผล | Display order |
| `color_code` | VARCHAR(7) | NULLABLE | รหัสสี (HEX) | Color code (HEX) |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | สถานะใช้งาน | Active status |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

---

### 3.5 ตาราง `pricing_calendar` - ปฏิทินฤดูกาล

**วัตถุประสงค์:** กำหนดระดับราคาสำหรับแต่ละวัน

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `date` | DATE | PRIMARY KEY | วันที่ | Date |
| `rate_tier_id` | INT | FK → rate_tiers.rate_tier_id | รหัสระดับราคา | Rate tier ID |
| `notes` | TEXT | NULLABLE | หมายเหตุ (เช่น วันหยุดพิเศษ) | Notes |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Indexes:**
- `idx_pricing_calendar_date` ON `date`
- `idx_pricing_calendar_tier` ON `rate_tier_id`

---

### 3.6 ตาราง `rate_pricing` - ราคาตั้งต้น (เมทริกซ์ราคา)

**วัตถุประสงค์:** กำหนดราคาสำหรับแต่ละแผนราคา x ประเภทห้อง x ระดับราคา


| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `rate_plan_id` | INT | PK, FK → rate_plans.rate_plan_id | รหัสแผนราคา | Rate plan ID |
| `room_type_id` | INT | PK, FK → room_types.room_type_id | รหัสประเภทห้อง | Room type ID |
| `rate_tier_id` | INT | PK, FK → rate_tiers.rate_tier_id | รหัสระดับราคา | Rate tier ID |
| `price` | DECIMAL(10,2) | NOT NULL, CHECK >= 0 | ราคาต่อคืน (บาท) | Price per night |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Composite Primary Key:** (`rate_plan_id`, `room_type_id`, `rate_tier_id`)

**Indexes:**
- `idx_rate_pricing_room_type` ON `room_type_id`
- `idx_rate_pricing_tier` ON `rate_tier_id`

---

### 3.7 ตาราง `vouchers` - คูปองส่วนลด

**วัตถุประสงค์:** จัดการคูปองส่วนลดสำหรับการจอง

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `voucher_id` | SERIAL | PRIMARY KEY | รหัสคูปองอัตโนมัติ | Auto-increment voucher ID |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE | รหัสคูปอง | Voucher code |
| `discount_type` | VARCHAR(20) | NOT NULL | ประเภทส่วนลด | Discount type |
| `discount_value` | DECIMAL(10,2) | NOT NULL, CHECK > 0 | มูลค่าส่วนลด | Discount value |
| `expiry_date` | DATE | NOT NULL | วันหมดอายุ | Expiry date |
| `max_uses` | INT | NOT NULL, DEFAULT 100 | จำนวนครั้งที่ใช้ได้สูงสุด | Maximum uses |
| `current_uses` | INT | NOT NULL, DEFAULT 0 | จำนวนครั้งที่ใช้ไปแล้ว | Current uses |
| `min_booking_amount` | DECIMAL(10,2) | DEFAULT 0.00 | ยอดจองขั้นต่ำ | Minimum booking amount |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | สถานะใช้งาน | Active status |
| `description` | TEXT | NULLABLE | คำอธิบาย | Description |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Enum Values:**
- `discount_type`: 'Percentage', 'FixedAmount'

**Constraints:**
- `CHK_voucher_uses`: `current_uses <= max_uses`

**Indexes:**
- `idx_vouchers_code` ON `code` WHERE `is_active = TRUE`
- `idx_vouchers_expiry` ON `expiry_date` WHERE `is_active = TRUE`

---

### 3.8 ตาราง `booking_holds` - ตะกร้าการจอง

**วัตถุประสงค์:** เก็บการจองชั่วคราว (15 นาที) ระหว่างกรอกข้อมูลและชำระเงิน

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `hold_id` | BIGSERIAL | PRIMARY KEY | รหัส hold อัตโนมัติ | Auto-increment hold ID |
| `session_id` | VARCHAR(255) | NOT NULL | Session ID ของผู้ใช้ | User session ID |
| `guest_account_id` | INT | FK → guest_accounts.guest_account_id | รหัสบัญชีแขก (ถ้ามี) | Guest account ID (optional) |
| `room_type_id` | INT | FK → room_types.room_type_id | รหัสประเภทห้อง | Room type ID |
| `date` | DATE | NOT NULL | วันที่จอง | Booking date |
| `hold_expiry` | DATETIME | NOT NULL | เวลาหมดอายุของ hold | Hold expiry timestamp |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |

**Indexes:**
- `idx_booking_holds_expiry` ON `hold_expiry`
- `idx_booking_holds_session` ON `session_id`
- `idx_booking_holds_guest` ON `guest_account_id`
- `idx_booking_holds_room_date` ON `(room_type_id, date)`

---

## 4. ส่วนจัดการการจอง (Booking Management)

### 4.1 ตาราง `bookings` - ใบเสร็จการจอง

**วัตถุประสงค์:** เก็บข้อมูลการจองหลัก พร้อม snapshot ของนโยบายการยกเลิก

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `booking_id` | SERIAL | PRIMARY KEY | รหัสการจองอัตโนมัติ | Auto-increment booking ID |
| `guest_id` | INT | FK → guests.guest_id | รหัสผู้เข้าพัก | Guest ID |
| `voucher_id` | INT | FK → vouchers.voucher_id | รหัสคูปอง (ถ้ามี) | Voucher ID (optional) |
| `total_amount` | DECIMAL(10,2) | NOT NULL, CHECK >= 0 | ยอดรวมทั้งหมด | Total amount |
| `status` | VARCHAR(50) | NOT NULL, DEFAULT 'PendingPayment' | สถานะการจอง | Booking status |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างการจอง | Booking creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |
| `policy_name` | VARCHAR(100) | NOT NULL | ชื่อนโยบาย (Snapshot) | Policy name (snapshot) |
| `policy_description` | TEXT | NOT NULL | คำอธิบายนโยบาย (Snapshot) | Policy description (snapshot) |

**Enum Values:**
- `status`: 'PendingPayment', 'Confirmed', 'CheckedIn', 'Completed', 'Cancelled', 'NoShow'

**Indexes:**
- `idx_bookings_guest` ON `guest_id`
- `idx_bookings_status` ON `status`
- `idx_bookings_created_at` ON `created_at`
- `idx_bookings_voucher` ON `voucher_id` WHERE `voucher_id IS NOT NULL`

**หมายเหตุ:** `policy_name` และ `policy_description` เป็น snapshot ที่บันทึกไว้ตอนจอง (immutable)

---

### 4.2 ตาราง `booking_details` - รายการในใบเสร็จการจอง

**วัตถุประสงค์:** เก็บรายละเอียดการจองแต่ละห้อง (รองรับการจองหลายห้อง)

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `booking_detail_id` | SERIAL | PRIMARY KEY | รหัสรายละเอียดอัตโนมัติ | Auto-increment detail ID |
| `booking_id` | INT | FK → bookings.booking_id | รหัสการจอง | Booking ID |
| `room_type_id` | INT | FK → room_types.room_type_id | รหัสประเภทห้อง | Room type ID |
| `rate_plan_id` | INT | FK → rate_plans.rate_plan_id | รหัสแผนราคา | Rate plan ID |
| `check_in_date` | DATE | NOT NULL | วันเช็คอิน | Check-in date |
| `check_out_date` | DATE | NOT NULL | วันเช็คเอาท์ | Check-out date |
| `num_guests` | INT | NOT NULL, CHECK > 0 | จำนวนผู้เข้าพัก | Number of guests |

**Constraints:**
- `CHK_DateOrder`: `check_out_date > check_in_date`

**Indexes:**
- `idx_booking_details_booking` ON `booking_id`
- `idx_booking_details_room_type` ON `room_type_id`
- `idx_booking_details_dates` ON `(check_in_date, check_out_date)`

---

## 5. ตารางเพิ่มเติมสำหรับการใช้งานจริง

### 5.1 ตาราง `room_assignments` - การมอบหมายห้องพัก

**วัตถุประสงค์:** ติดตามว่าห้องจริงไหนถูกมอบหมายให้กับการจองไหน (สร้างตอน check-in)


| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `room_assignment_id` | BIGSERIAL | PRIMARY KEY | รหัสการมอบหมายอัตโนมัติ | Auto-increment assignment ID |
| `booking_detail_id` | INT | FK → booking_details.booking_detail_id | รหัสรายละเอียดการจอง | Booking detail ID |
| `room_id` | INT | FK → rooms.room_id | รหัสห้องจริง | Physical room ID |
| `check_in_datetime` | TIMESTAMP | NOT NULL | วันเวลาเช็คอินจริง | Actual check-in timestamp |
| `check_out_datetime` | TIMESTAMP | NULLABLE | วันเวลาเช็คเอาท์จริง | Actual check-out timestamp |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'Active' | สถานะการมอบหมาย | Assignment status |

**Enum Values:**
- `status`: 'Active', 'Moved', 'Completed'

**Constraints:**
- `CHK_checkout_after_checkin`: `check_out_datetime IS NULL OR check_out_datetime > check_in_datetime`

**Indexes:**
- `idx_room_assignments_booking_detail` ON `booking_detail_id`
- `idx_room_assignments_room` ON `room_id`
- `idx_room_assignments_status` ON `status`
- `idx_room_assignments_active` ON `(booking_detail_id, status)` WHERE `status = 'Active'`

**หมายเหตุ:** ตารางนี้รองรับการย้ายห้อง (room move) โดยสร้าง record ใหม่และเปลี่ยนสถานะเดิมเป็น 'Moved'

---

### 5.2 ตาราง `booking_guests` - ข้อมูลผู้เข้าพักในการจอง

**วัตถุประสงค์:** เก็บข้อมูลผู้เข้าพักทุกคนในการจอง (ไม่ใช่แค่ผู้จอง)

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `booking_guest_id` | BIGSERIAL | PRIMARY KEY | รหัสผู้เข้าพักอัตโนมัติ | Auto-increment guest ID |
| `booking_detail_id` | INT | FK → booking_details.booking_detail_id | รหัสรายละเอียดการจอง | Booking detail ID |
| `first_name` | VARCHAR(100) | NOT NULL | ชื่อจริง | First name |
| `last_name` | VARCHAR(100) | NULLABLE | นามสกุล | Last name |
| `type` | VARCHAR(10) | NOT NULL, DEFAULT 'Adult' | ประเภทผู้เข้าพัก | Guest type |
| `is_primary` | BOOLEAN | NOT NULL, DEFAULT FALSE | เป็นผู้เข้าพักหลักหรือไม่ | Is primary guest |

**Enum Values:**
- `type`: 'Adult', 'Child'

**Indexes:**
- `idx_booking_guests_booking_detail` ON `booking_detail_id`
- `idx_booking_guests_primary` ON `(booking_detail_id, is_primary)` WHERE `is_primary = TRUE`

---

### 5.3 ตาราง `booking_nightly_log` - บันทึกราคารายคืน

**วัตถุประสงค์:** บันทึกราคาที่เสนอให้สำหรับแต่ละคืน (immutable snapshot)

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `booking_nightly_log_id` | SERIAL | PRIMARY KEY | รหัสบันทึกอัตโนมัติ | Auto-increment log ID |
| `booking_detail_id` | INT | FK → booking_details.booking_detail_id | รหัสรายละเอียดการจอง | Booking detail ID |
| `date` | DATE | NOT NULL | วันที่ | Date |
| `quoted_price` | DECIMAL(10,2) | NOT NULL, CHECK >= 0 | ราคาที่เสนอ (ตอนจอง) | Quoted price (at booking time) |

**Constraints:**
- `UQ_booking_nightly_log`: UNIQUE (`booking_detail_id`, `date`)

**Indexes:**
- `idx_booking_nightly_log_booking_detail` ON `booking_detail_id`
- `idx_booking_nightly_log_date` ON `date`

**หมายเหตุ:** ตารางนี้ป้องกันไม่ให้ราคาเปลี่ยนแปลงหลังจากจองแล้ว (price protection)

---

## 6. ส่วนจัดการพนักงานและสิทธิ์การเข้าถึง (Staff & Role Management)

### 6.1 ตาราง `roles` - บทบาทผู้ใช้งาน

**วัตถุประสงค์:** กำหนดบทบาทของผู้ใช้งานในระบบ (Guest, Receptionist, Housekeeper, Manager)

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `role_id` | SERIAL | PRIMARY KEY | รหัสบทบาทอัตโนมัติ | Auto-increment role ID |
| `role_name` | VARCHAR(50) | NOT NULL, UNIQUE | ชื่อบทบาท | Role name |
| `role_code` | VARCHAR(20) | NOT NULL, UNIQUE | รหัสบทบาท | Role code |
| `description` | TEXT | NULLABLE | คำอธิบายบทบาท | Role description |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |

**ตัวอย่างบทบาท:**
- Guest (GUEST): ผู้เข้าพัก - สามารถจองห้องและดูประวัติการจองของตนเอง
- Receptionist (RECEPTIONIST): พนักงานต้อนรับ - จัดการการจอง เช็คอิน/เช็คเอาท์
- Housekeeper (HOUSEKEEPER): แม่บ้าน - จัดการการทำความสะอาดและสถานะห้อง
- Manager (MANAGER): ผู้จัดการ - เข้าถึงทุกฟังก์ชันและดูรายงาน

---

### 6.2 ตาราง `staff` - พนักงาน

**วัตถุประสงค์:** เก็บข้อมูลพนักงานโรงแรม

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `staff_id` | SERIAL | PRIMARY KEY | รหัสพนักงานอัตโนมัติ | Auto-increment staff ID |
| `first_name` | VARCHAR(100) | NOT NULL | ชื่อจริง | First name |
| `last_name` | VARCHAR(100) | NOT NULL | นามสกุล | Last name |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | อีเมล (ไม่ซ้ำกัน) | Unique email address |
| `phone` | VARCHAR(20) | NULLABLE | เบอร์โทรศัพท์ | Phone number |
| `role_id` | INT | FK → roles.role_id | รหัสบทบาท | Role ID |
| `is_active` | BOOLEAN | DEFAULT TRUE | สถานะใช้งาน | Active status |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Indexes:**
- `idx_staff_email` ON `email`
- `idx_staff_role_id` ON `role_id`

---

### 6.3 ตาราง `staff_accounts` - บัญชีพนักงาน

**วัตถุประสงค์:** เก็บข้อมูลการเข้าสู่ระบบของพนักงาน

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `staff_account_id` | SERIAL | PRIMARY KEY | รหัสบัญชีอัตโนมัติ | Auto-increment account ID |
| `staff_id` | INT | FK → staff.staff_id, UNIQUE | รหัสพนักงาน (1:1) | Staff ID (one-to-one) |
| `hashed_password` | VARCHAR(255) | NOT NULL | รหัสผ่านที่เข้ารหัส (bcrypt) | Hashed password (bcrypt) |
| `last_login` | TIMESTAMP | NULLABLE | เวลาเข้าสู่ระบบครั้งล่าสุด | Last login timestamp |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างบัญชี | Account creation timestamp |

**Indexes:**
- `idx_staff_accounts_staff_id` ON `staff_id`

---

### 6.4 View: `v_all_users` - มุมมองผู้ใช้งานทั้งหมด

**วัตถุประสงค์:** รวมข้อมูลผู้ใช้งานทั้งแขกและพนักงานไว้ในมุมมองเดียว (สำหรับ Authentication)

**Columns:**
- `user_type`: 'guest' หรือ 'staff'
- `user_id`: รหัสผู้ใช้
- `first_name`, `last_name`, `email`, `phone`
- `role_code`: รหัสบทบาท (GUEST, RECEPTIONIST, HOUSEKEEPER, MANAGER)
- `role_name`: ชื่อบทบาท
- `hashed_password`: รหัสผ่านที่เข้ารหัส
- `last_login`: เวลาเข้าสู่ระบบครั้งล่าสุด
- `created_at`: วันที่สร้างบัญชี

---

## 7. ส่วนจัดการการชำระเงิน (Payment Management)

### 7.1 ตาราง `payment_proofs` - หลักฐานการชำระเงิน

**วัตถุประสงค์:** เก็บหลักฐานการชำระเงินสำหรับการตรวจสอบ (Mockup Payment System)

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `payment_proof_id` | SERIAL | PRIMARY KEY | รหัสหลักฐานอัตโนมัติ | Auto-increment proof ID |
| `booking_id` | INT | FK → bookings.booking_id | รหัสการจอง | Booking ID |
| `payment_method` | VARCHAR(50) | NOT NULL | วิธีการชำระเงิน | Payment method |
| `amount` | DECIMAL(10,2) | NOT NULL, CHECK > 0 | จำนวนเงิน | Amount |
| `proof_url` | TEXT | NOT NULL | URL ของหลักฐาน | Proof URL |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'pending' | สถานะการตรวจสอบ | Verification status |
| `verified_by` | INT | FK → staff.staff_id | ผู้ตรวจสอบ | Verified by staff |
| `verified_at` | TIMESTAMP | NULLABLE | เวลาที่ตรวจสอบ | Verification timestamp |
| `rejection_reason` | TEXT | NULLABLE | เหตุผลที่ปฏิเสธ | Rejection reason |
| `notes` | TEXT | NULLABLE | หมายเหตุ | Notes |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | วันที่สร้างข้อมูล | Record creation timestamp |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | วันที่แก้ไขล่าสุด | Last update timestamp |

**Enum Values:**
- `payment_method`: 'bank_transfer', 'qr_code', 'credit_card', 'cash'
- `status`: 'pending', 'approved', 'rejected'

**Indexes:**
- `idx_payment_proofs_booking_id` ON `booking_id`
- `idx_payment_proofs_status` ON `status`
- `idx_payment_proofs_created_at` ON `created_at`

**Functions:**
- `approve_payment(payment_proof_id, staff_id, notes)`: อนุมัติการชำระเงิน
- `reject_payment(payment_proof_id, staff_id, rejection_reason)`: ปฏิเสธการชำระเงิน

**Views:**
- `pending_payment_verifications`: หลักฐานการชำระเงินที่รอตรวจสอบ
- `payment_verification_history`: ประวัติการตรวจสอบการชำระเงิน

---

### 7.2 เพิ่มฟิลด์ `payment_status` ในตาราง `bookings`

**วัตถุประสงค์:** ติดตามสถานะการชำระเงินของการจอง

| Column Name | Data Type | Constraints | Description (TH) | Description (EN) |
|------------|-----------|-------------|------------------|------------------|
| `payment_status` | VARCHAR(20) | DEFAULT 'pending' | สถานะการชำระเงิน | Payment status |

**Enum Values:**
- `payment_status`: 'pending', 'paid', 'refunded', 'failed'

**Index:**
- `idx_bookings_payment_status` ON `payment_status`

---

## สรุปจำนวนตาราง

| หมวดหมู่ | จำนวนตาราง | รายชื่อตาราง |
|---------|------------|-------------|
| **Guest Management** | 2 | guests, guest_accounts |
| **Room Management** | 4 | room_types, rooms, amenities, room_type_amenities |
| **Pricing & Inventory** | 8 | room_inventory, cancellation_policies, rate_plans, rate_tiers, pricing_calendar, rate_pricing, vouchers, booking_holds |
| **Booking Management** | 5 | bookings, booking_details, room_assignments, booking_guests, booking_nightly_log |
| **Staff & Role Management** | 3 | roles, staff, staff_accounts |
| **Payment Management** | 1 | payment_proofs |
| **รวมทั้งหมด** | **23 ตาราง** | |
| **Views** | 3 | v_all_users, pending_payment_verifications, payment_verification_history |

---

## ความแตกต่างจาก Data Dictionary เดิม

### ✅ ตารางที่ตรงกับ Data Dictionary ของคุณ (16 ตาราง):
1. guests
2. guest_accounts
3. room_types
4. rooms
5. amenities
6. room_type_amenities
7. room_inventory
8. cancellation_policies
9. rate_plans
10. rate_tiers
11. pricing_calendar
12. rate_pricing
13. vouchers
14. booking_holds
15. bookings
16. booking_details

### 🆕 ตารางเพิ่มเติมที่จำเป็นสำหรับระบบจริง (7 ตาราง):

**Booking Management (3 ตาราง):**
1. **room_assignments** - ติดตามการมอบหมายห้องจริง และรองรับการย้ายห้อง
2. **booking_guests** - เก็บข้อมูลผู้เข้าพักทุกคนในการจอง (ไม่ใช่แค่ผู้จอง)
3. **booking_nightly_log** - บันทึกราคารายคืน (price protection)

**Staff & Role Management (3 ตาราง):**
4. **roles** - กำหนดบทบาทผู้ใช้งาน (Guest, Receptionist, Housekeeper, Manager)
5. **staff** - ข้อมูลพนักงานโรงแรม
6. **staff_accounts** - บัญชีเข้าสู่ระบบของพนักงาน

**Payment Management (1 ตาราง):**
7. **payment_proofs** - หลักฐานการชำระเงินสำหรับการตรวจสอบ (Mockup Payment System)

### 📝 ฟิลด์เพิ่มเติมที่มีในระบบจริง:
- `is_active` - สำหรับ soft delete และการจัดการสถานะ
- `created_at`, `updated_at` - สำหรับ audit trail
- `display_order`, `color_code` - สำหรับ UI/UX
- `icon`, `category` - สำหรับการจัดกลุ่มและแสดงผล
- `floor`, `notes` - สำหรับข้อมูลเพิ่มเติม

---

## คำแนะนำสำหรับการนำเสนอ

เมื่อนำเสนอให้ลูกค้า แนะนำให้:

1. **เริ่มจากตารางหลัก 16 ตาราง** ที่ตรงกับ Data Dictionary ที่คุณออกแบบไว้

2. **อธิบายตารางเพิ่มเติม 7 ตาราง** ว่าทำไมจำเป็นสำหรับระบบจริง:
   
   **Booking Management (3 ตาราง):**
   - `room_assignments`: รองรับการย้ายห้อง และติดตามว่าแขกพักห้องไหนจริงๆ
   - `booking_guests`: เก็บข้อมูลผู้เข้าพักทุกคน (เช่น ครอบครัว 4 คน)
   - `booking_nightly_log`: ป้องกันราคาเปลี่ยนแปลงหลังจอง
   
   **Staff & Role Management (3 ตาราง):**
   - `roles`: กำหนดบทบาทผู้ใช้งาน 4 ระดับ (Guest, Receptionist, Housekeeper, Manager)
   - `staff`: เก็บข้อมูลพนักงานโรงแรม
   - `staff_accounts`: บัญชีเข้าสู่ระบบของพนักงาน
   
   **Payment Management (1 ตาราง):**
   - `payment_proofs`: ระบบตรวจสอบหลักฐานการชำระเงิน (Mockup Payment)

3. **เน้นฟีเจอร์สำคัญ**:
   - **Policy Snapshot** (immutable): บันทึกนโยบายการยกเลิกตอนจอง
   - **Price Protection**: ป้องกันราคาเปลี่ยนแปลงหลังจอง
   - **Room Move Support**: รองรับการย้ายห้องพร้อม audit trail
   - **Multi-room Booking**: จองหลายห้องในใบเสร็จเดียว
   - **Role-Based Access Control**: ควบคุมสิทธิ์การเข้าถึง 4 ระดับ
   - **Payment Verification**: ระบบตรวจสอบการชำระเงินโดยพนักงาน
   - **Complete Audit Trail**: ติดตามการเปลี่ยนแปลงทุกอย่าง

4. **แสดง Entity Relationship**:
   - แขก (Guests) → การจอง (Bookings) → รายละเอียดการจอง (Booking Details)
   - ห้องพัก (Rooms) ← มอบหมาย (Room Assignments) ← รายละเอียดการจอง
   - พนักงาน (Staff) → บทบาท (Roles) → สิทธิ์การเข้าถึง
   - การจอง → หลักฐานการชำระเงิน (Payment Proofs) → ตรวจสอบโดยพนักงาน

---

## ไฟล์ที่เกี่ยวข้อง

- Migration Files: `database/migrations/001-004_*.sql`
- Verification Scripts: `database/migrations/verify_*.sql`
- Test Scripts: `database/migrations/test_*.sql`

---

**เอกสารนี้สร้างโดย:** Theerapat Pooraya
**วันที่:** 5 พฤศจิกายน 2025  
**เวอร์ชัน:** 1.0 - Complete Data Dictionary



---

## สรุปฟีเจอร์หลักของระบบ

### 1. Guest Management (การจัดการแขก)
- ระบบสมาชิกสำหรับแขก
- Authentication ด้วย bcrypt
- ประวัติการจองของแขก

### 2. Room Management (การจัดการห้องพัก)
- จัดการประเภทห้อง 3 แบบ (Standard, Deluxe, Suite)
- ติดตามสถานะห้อง (Vacant/Occupied)
- ติดตามสถานะการทำความสะอาด (6 สถานะ)
- สิ่งอำนวยความสะดวก (Amenities) แบบ Many-to-Many

### 3. Pricing & Inventory (ราคาและสต็อก)
- ระบบราคาแบบ Dynamic (Rate Tiers)
- ปฏิทินราคาตามฤดูกาล
- นโยบายการยกเลิก 3 แบบ
- คูปองส่วนลด
- ระบบ Hold ห้อง 15 นาที
- จัดการสต็อกห้องรายวัน

### 4. Booking Management (การจัดการการจอง)
- จองหลายห้องในใบเสร็จเดียว
- Policy Snapshot (ป้องกันการเปลี่ยนแปลง)
- Price Protection (ราคาไม่เปลี่ยนหลังจอง)
- ติดตามสถานะการจอง 6 สถานะ
- รองรับการย้ายห้อง
- เก็บข้อมูลผู้เข้าพักทุกคน

### 5. Staff & Role Management (พนักงานและสิทธิ์)
- 4 บทบาท: Guest, Receptionist, Housekeeper, Manager
- Role-Based Access Control (RBAC)
- Unified Authentication View
- ติดตามการเข้าสู่ระบบ

### 6. Payment Management (การชำระเงิน)
- อัพโหลดหลักฐานการชำระเงิน
- ระบบตรวจสอบโดยพนักงาน
- 4 วิธีการชำระเงิน
- ติดตามสถานะการชำระเงิน

---

## Database Statistics

| Metric | Value |
|--------|-------|
| **Total Tables** | 23 ตาราง |
| **Total Views** | 3 views |
| **Total Functions** | 10+ stored procedures |
| **Total Indexes** | 50+ indexes |
| **Foreign Keys** | 30+ relationships |
| **Check Constraints** | 40+ validations |

---

## Performance Optimizations

1. **Indexes**: 50+ indexes สำหรับ query ที่ใช้บ่อย
2. **Composite Indexes**: สำหรับ multi-column queries
3. **Partial Indexes**: สำหรับ filtered queries
4. **Triggers**: Auto-update `updated_at` timestamps
5. **Views**: Pre-joined data สำหรับ common queries
6. **Constraints**: Data integrity ที่ database level

---

## Security Features

1. **Password Hashing**: bcrypt cost 10
2. **Role-Based Access**: 4 ระดับสิทธิ์
3. **Audit Trail**: `created_at`, `updated_at` ทุกตาราง
4. **Soft Delete**: `is_active` flags
5. **Immutable Data**: Policy และ Price snapshots
6. **Foreign Key Constraints**: Data integrity

---

## ER Diagram Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    HOTEL BOOKING SYSTEM                          │
│                    Database Schema v2.0                          │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   GUESTS     │────────▶│   BOOKINGS   │────────▶│BOOKING_DETAILS│
│  (แขก)       │  1:N    │  (การจอง)    │  1:N    │(รายละเอียด)  │
└──────────────┘         └──────────────┘         └──────────────┘
       │                        │                         │
       │                        │                         │
       ▼                        ▼                         ▼
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│GUEST_ACCOUNTS│         │PAYMENT_PROOFS│         │ROOM_ASSIGNMENTS│
│(บัญชีแขก)    │         │(หลักฐานชำระ) │         │(มอบหมายห้อง)  │
└──────────────┘         └──────────────┘         └──────────────┘
                                │                         │
                                │                         │
                                ▼                         ▼
                         ┌──────────────┐         ┌──────────────┐
                         │    STAFF     │         │    ROOMS     │
                         │  (พนักงาน)   │         │  (ห้องพัก)   │
                         └──────────────┘         └──────────────┘
                                │                         │
                                │                         │
                                ▼                         ▼
                         ┌──────────────┐         ┌──────────────┐
                         │    ROLES     │         │  ROOM_TYPES  │
                         │  (บทบาท)     │         │(ประเภทห้อง)  │
                         └──────────────┘         └──────────────┘
                                                          │
                                                          │
                                                          ▼
                                                   ┌──────────────┐
                                                   │RATE_PRICING  │
                                                   │(เมทริกซ์ราคา)│
                                                   └──────────────┘
```

---

**เอกสารนี้สร้างโดย:** Theerapat Pooraya  
**วันที่:** 5 พฤศจิกายน 2025  
**เวอร์ชัน:** 2.0 - Complete Data Dictionary (Updated with Staff & Payment Management)  
**Migration Files:** 001-016  
**Total Entities:** 23 Tables + 3 Views + 10+ Functions  
**Database:** PostgreSQL 14+  
**Project:** Hotel Booking System - Complete Implementation
