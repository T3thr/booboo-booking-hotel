# เอกสารออกแบบระบบ - ระบบจองโรงแรมและที่พัก

## ภาพรวม (Overview)

ระบบจองโรงแรมและที่พักนี้ถูกออกแบบเป็น web application แบบ full-stack ที่มุ่งเน้นความปลอดภัย ความถูกต้อง และความสามารถในการทำงานจริง ระบบใช้สถาปัตยกรรมแบบ microservices โดยแยก frontend (Next.js) และ backend (Go) ออกจากกัน พร้อมการบังคับใช้ business rules ผ่าน PostgreSQL functions

### เทคโนโลยีที่เลือกใช้

**Frontend:**
- Next.js 16 (React Framework) - App Router
- TypeScript - type safety
- Tailwind CSS - styling
- React Query (TanStack Query) - data fetching และ caching
- Zustand - state management
- NextAuth.js v5 - authentication (src/app/api/auth/[...nextauth]/)

**Backend:**
- Go 1.21+ (Golang) - RESTful API
- Gin Web Framework - HTTP router
- pgx v5 - PostgreSQL driver
- golang-jwt - JWT handling
- bcrypt - password hashing

**Database:**
- PostgreSQL 15+ - relational database
- PL/pgSQL - stored functions
- pgAdmin - database management

**DevOps:**
- Docker & Docker Compose - containerization
- Air - Go hot reload (development)
- GitHub Actions - CI/CD (optional)

**เหตุผลในการเลือก:**
- Next.js 16 ให้ประสิทธิภาพสูง, SEO-friendly และ Server Components
- Go มีประสิทธิภาพสูง, concurrency ดีเยี่ยม, compile เป็น binary เดียว
- PostgreSQL มีความเสถียรสูง, ACID compliance, รองรับ advanced features
- NextAuth.js v5 ให้ authentication ที่ปลอดภัยและยืดหยุ่น
- Stack นี้เหมาะกับโครงงานและสามารถ scale ได้ดีในอนาคต


### หลักการออกแบบหลัก (Design Principles)

1. **Database-First Integrity:** ใช้ PostgreSQL functions, constraints และ transactions เพื่อบังคับใช้ business rules
2. **Immutable History:** บันทึก snapshot ของนโยบายและราคา ณ เวลาที่จอง
3. **Atomic Operations:** การดำเนินการสำคัญทั้งหมดใช้ transactions (all-or-nothing)
4. **Real-time Synchronization:** สถานะห้องพักสะท้อนความเป็นจริงแบบเรียลไทม์
5. **Fail-Safe Design:** ป้องกัน race conditions และ overbooking ด้วย database constraints
6. **Separation of Concerns:** แยก frontend, backend และ database ชัดเจน

## สถาปัตยกรรมระบบ (Architecture)

### แผนภาพสถาปัตยกรรมระดับสูง

```mermaid
graph TB
    subgraph "Client Layer"
        A[Web Browser]
    end
    
    subgraph "Frontend - Next.js 16"
        B[Guest UI]
        C[Receptionist UI]
        D[Housekeeper UI]
        E[Manager UI]
        F[NextAuth.js]
    end
    
    subgraph "Backend - Go API"
        G[Gin Router]
        H[Auth Handler]
        I[Booking Handler]
        J[Room Handler]
        K[Pricing Handler]
        L[Report Handler]
        M[Middleware]
    end
    
    subgraph "Database - PostgreSQL"
        N[(PostgreSQL)]
        O[Functions]
        P[Triggers]
    end
    
    subgraph "Background Jobs - Go"
        Q[Night Audit]
        R[Hold Cleanup]
    end
    
    A --> B
    A --> C
    A --> D
    A --> E
    B --> F
    C --> F
    D --> F
    E --> F
    F --> H
    B --> I
    C --> I
    C --> J
    D --> J
    E --> K
    E --> L
    H --> M
    I --> M
    J --> M
    K --> M
    L --> M
    M --> O
    O --> N
    P --> N
    Q --> O
    R --> O
```

### โมเดลสถานะห้องพักแบบ 2 แกน

**แกนที่ 1: occupancy_status**
- `Vacant` - ห้องว่าง
- `Occupied` - มีผู้เข้าพัก

**แกนที่ 2: housekeeping_status**
- `Dirty` - รอทำความสะอาด
- `Cleaning` - กำลังทำความสะอาด
- `Clean` - ทำความสะอาดเสร็จ
- `Inspected` - ตรวจสอบแล้ว (พร้อมขายที่สุด)
- `MaintenanceRequired` - ต้องซ่อมบำรุง
- `OutOfService` - ปิดให้บริการ



## โครงสร้างโปรเจกต์ (Project Structure)

```
hotel-booking-system/
├── frontend/                    # Next.js 16 Application
│   ├── src/
│   │   ├── app/
│   │   │   ├── api/
│   │   │   │   └── auth/
│   │   │   │       └── [...nextauth]/
│   │   │   │           └── route.ts    # NextAuth configuration
│   │   │   ├── (guest)/                # Guest routes
│   │   │   ├── (staff)/                # Staff routes
│   │   │   ├── (manager)/              # Manager routes
│   │   │   └── layout.tsx
│   │   ├── components/
│   │   ├── lib/
│   │   │   ├── api.ts                  # API client
│   │   │   └── auth.ts                 # Auth utilities
│   │   └── types/
│   ├── public/
│   ├── package.json
│   └── next.config.js
│
├── backend/                     # Go API Server
│   ├── cmd/
│   │   └── server/
│   │       └── main.go                 # Entry point
│   ├── internal/
│   │   ├── handlers/                   # HTTP handlers
│   │   │   ├── auth.go
│   │   │   ├── booking.go
│   │   │   ├── room.go
│   │   │   └── pricing.go
│   │   ├── models/                     # Data models
│   │   ├── repository/                 # Database layer
│   │   ├── service/                    # Business logic
│   │   └── middleware/                 # Middleware
│   ├── pkg/
│   │   ├── database/                   # DB connection
│   │   └── utils/
│   ├── go.mod
│   └── go.sum
│
├── database/                    # PostgreSQL Scripts
│   ├── migrations/
│   │   ├── 001_create_tables.sql
│   │   ├── 002_create_functions.sql
│   │   └── 003_seed_data.sql
│   └── queries/                        # Complex queries
│
├── docker-compose.yml
└── README.md
```

## คอมโพเนนต์และ API (Components and APIs)

### 1. Authentication Module (NextAuth.js + Go)

**NextAuth Configuration (Frontend):**
```typescript
// src/app/api/auth/[...nextauth]/route.ts
import NextAuth from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";

export const authOptions = {
  providers: [
    CredentialsProvider({
      name: "Credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        const res = await fetch(`${process.env.BACKEND_URL}/api/auth/login`, {
          method: "POST",
          body: JSON.stringify(credentials),
          headers: { "Content-Type": "application/json" }
        });
        
        if (res.ok) {
          const user = await res.json();
          return user;
        }
        return null;
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.role = user.role;
        token.accessToken = user.accessToken;
      }
      return token;
    },
    async session({ session, token }) {
      session.user.id = token.id;
      session.user.role = token.role;
      session.accessToken = token.accessToken;
      return session;
    }
  },
  pages: {
    signIn: '/auth/signin',
  }
};

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

**Go Backend Endpoints:**
```
POST /api/auth/register      - ลงทะเบียนผู้ใช้ใหม่
POST /api/auth/login         - เข้าสู่ระบบ (เรียกโดย NextAuth)
GET  /api/auth/me            - ดึงข้อมูลผู้ใช้ปัจจุบัน
POST /api/auth/reset-password - รีเซ็ตรหัสผ่าน
```

**Go Handler Example:**
```go
// internal/handlers/auth.go
package handlers

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
    authService *service.AuthService
}

func (h *AuthHandler) Login(c *gin.Context) {
    var req LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    user, err := h.authService.Authenticate(req.Email, req.Password)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
        return
    }
    
    token, err := h.authService.GenerateToken(user)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{
        "id": user.ID,
        "email": user.Email,
        "role": user.Role,
        "accessToken": token,
    })
}
```



### 2. Room Search & Availability Module

**Go Backend Endpoints:**
```
GET /api/rooms/search         - ค้นหาห้องว่าง
GET /api/rooms/types          - ดึงรายการประเภทห้อง
GET /api/rooms/types/:id      - ดึงรายละเอียดประเภทห้อง
GET /api/rooms/types/:id/pricing - คำนวณราคา
```

**Go Handler:**
```go
// internal/handlers/room.go
func (h *RoomHandler) SearchAvailability(c *gin.Context) {
    checkIn := c.Query("checkIn")
    checkOut := c.Query("checkOut")
    guests, _ := strconv.Atoi(c.Query("guests"))
    
    rooms, err := h.roomService.SearchAvailable(checkIn, checkOut, guests)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, rooms)
}
```

**PostgreSQL Query:**
```sql
-- ค้นหาห้องว่าง
SELECT rt.*, 
       COUNT(DISTINCT ri.date) as available_days,
       SUM(rp.price) as total_price
FROM room_types rt
JOIN room_inventory ri ON rt.room_type_id = ri.room_type_id
JOIN pricing_calendar pc ON ri.date = pc.date
JOIN rate_pricing rp ON rt.room_type_id = rp.room_type_id 
    AND pc.rate_tier_id = rp.rate_tier_id
WHERE ri.date >= $1 AND ri.date < $2
  AND (ri.allotment - ri.booked_count - ri.tentative_count) > 0
  AND rt.max_occupancy >= $3
GROUP BY rt.room_type_id
HAVING COUNT(DISTINCT ri.date) = ($2::date - $1::date);
```

### 3. Booking Management Module

**Go Backend Endpoints:**
```
POST /api/bookings/hold       - สร้าง booking hold
POST /api/bookings            - สร้างการจอง
POST /api/bookings/:id/confirm - ยืนยันการจอง
POST /api/bookings/:id/cancel  - ยกเลิกการจอง
GET  /api/bookings            - ดึงรายการการจอง
GET  /api/bookings/:id        - ดึงรายละเอียดการจอง
```

**PostgreSQL Function - Create Booking Hold:**
```sql
CREATE OR REPLACE FUNCTION create_booking_hold(
    p_session_id VARCHAR(255),
    p_guest_account_id INT,
    p_room_type_id INT,
    p_check_in DATE,
    p_check_out DATE
) RETURNS TABLE(
    hold_id BIGINT,
    success BOOLEAN,
    message TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_date DATE;
    v_available INT;
    v_hold_id BIGINT;
BEGIN
    -- ตรวจสอบห้องว่างสำหรับทุกวัน
    v_date := p_check_in;
    WHILE v_date < p_check_out LOOP
        SELECT (allotment - booked_count - tentative_count) INTO v_available
        FROM room_inventory
        WHERE room_type_id = p_room_type_id AND date = v_date
        FOR UPDATE; -- Lock row
        
        IF v_available IS NULL OR v_available <= 0 THEN
            RETURN QUERY SELECT NULL::BIGINT, FALSE, 'ห้องไม่ว่างสำหรับวันที่เลือก'::TEXT;
            RETURN;
        END IF;
        
        -- อัปเดต tentative_count
        UPDATE room_inventory
        SET tentative_count = tentative_count + 1
        WHERE room_type_id = p_room_type_id AND date = v_date;
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
    
    -- สร้าง hold records
    v_date := p_check_in;
    WHILE v_date < p_check_out LOOP
        INSERT INTO booking_holds (
            session_id, guest_account_id, room_type_id, date, hold_expiry
        ) VALUES (
            p_session_id, p_guest_account_id, p_room_type_id, v_date,
            NOW() + INTERVAL '15 minutes'
        ) RETURNING hold_id INTO v_hold_id;
        
        v_date := v_date + INTERVAL '1 day';
    END LOOP;
    
    RETURN QUERY SELECT v_hold_id, TRUE, 'สร้าง hold สำเร็จ'::TEXT;
END;
$$;
```

**PostgreSQL Function - Confirm Booking:**
```sql
CREATE OR REPLACE FUNCTION confirm_booking(
    p_booking_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(50);
    v_detail RECORD;
    v_date DATE;
BEGIN
    -- ตรวจสอบสถานะ
    SELECT status INTO v_status FROM bookings WHERE booking_id = p_booking_id;
    
    IF v_status != 'PendingPayment' THEN
        RETURN QUERY SELECT FALSE, 'การจองนี้ไม่สามารถยืนยันได้'::TEXT;
        RETURN;
    END IF;
    
    -- อัปเดตสถานะการจอง
    UPDATE bookings
    SET status = 'Confirmed', updated_at = NOW()
    WHERE booking_id = p_booking_id;
    
    -- อัปเดต inventory สำหรับแต่ละ booking detail
    FOR v_detail IN 
        SELECT room_type_id, check_in_date, check_out_date
        FROM booking_details
        WHERE booking_id = p_booking_id
    LOOP
        v_date := v_detail.check_in_date;
        WHILE v_date < v_detail.check_out_date LOOP
            UPDATE room_inventory
            SET booked_count = booked_count + 1,
                tentative_count = GREATEST(tentative_count - 1, 0)
            WHERE room_type_id = v_detail.room_type_id AND date = v_date;
            
            v_date := v_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
    
    -- ลบ holds
    DELETE FROM booking_holds
    WHERE guest_account_id = (SELECT guest_id FROM bookings WHERE booking_id = p_booking_id);
    
    RETURN QUERY SELECT TRUE, 'ยืนยันการจองสำเร็จ'::TEXT;
END;
$$;
```



### 4. Check-in/Check-out Module

**Go Backend Endpoints:**
```
POST /api/checkin             - ทำการ check-in
POST /api/checkin/move-room   - ย้ายห้อง
POST /api/checkout            - ทำการ check-out
POST /api/bookings/:id/no-show - ทำเครื่องหมาย no-show
GET  /api/checkin/arrivals    - รายการแขกที่จะมาถึง
GET  /api/checkout/departures - รายการแขกที่จะเช็คเอาท์
```

**PostgreSQL Function - Check-in:**
```sql
CREATE OR REPLACE FUNCTION check_in(
    p_booking_detail_id INT,
    p_room_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_occupancy VARCHAR(20);
    v_housekeeping VARCHAR(50);
    v_booking_id INT;
BEGIN
    -- ตรวจสอบสถานะห้อง
    SELECT occupancy_status, housekeeping_status
    INTO v_occupancy, v_housekeeping
    FROM rooms
    WHERE room_id = p_room_id
    FOR UPDATE;
    
    IF v_occupancy != 'Vacant' THEN
        RETURN QUERY SELECT FALSE, 'ห้องนี้ไม่ว่าง'::TEXT;
        RETURN;
    END IF;
    
    IF v_housekeeping NOT IN ('Clean', 'Inspected') THEN
        RETURN QUERY SELECT FALSE, 'ห้องยังไม่พร้อมสำหรับ check-in'::TEXT;
        RETURN;
    END IF;
    
    -- อัปเดตสถานะการจอง
    SELECT booking_id INTO v_booking_id
    FROM booking_details
    WHERE booking_detail_id = p_booking_detail_id;
    
    UPDATE bookings
    SET status = 'CheckedIn', updated_at = NOW()
    WHERE booking_id = v_booking_id;
    
    -- สร้าง room assignment
    INSERT INTO room_assignments (
        booking_detail_id, room_id, check_in_datetime, status
    ) VALUES (
        p_booking_detail_id, p_room_id, NOW(), 'Active'
    );
    
    -- อัปเดตสถานะห้อง
    UPDATE rooms
    SET occupancy_status = 'Occupied'
    WHERE room_id = p_room_id;
    
    RETURN QUERY SELECT TRUE, 'Check-in สำเร็จ'::TEXT;
END;
$$;
```

**PostgreSQL Function - Move Room:**
```sql
CREATE OR REPLACE FUNCTION move_room(
    p_assignment_id BIGINT,
    p_new_room_id INT
) RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_old_room_id INT;
    v_booking_detail_id INT;
BEGIN
    -- หาห้องเก่า
    SELECT room_id, booking_detail_id
    INTO v_old_room_id, v_booking_detail_id
    FROM room_assignments
    WHERE room_assignment_id = p_assignment_id AND status = 'Active';
    
    IF v_old_room_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'ไม่พบ assignment ที่ active'::TEXT;
        RETURN;
    END IF;
    
    -- ปิด assignment เก่า
    UPDATE room_assignments
    SET check_out_datetime = NOW(), status = 'Moved'
    WHERE room_assignment_id = p_assignment_id;
    
    -- สร้าง assignment ใหม่
    INSERT INTO room_assignments (
        booking_detail_id, room_id, check_in_datetime, status
    ) VALUES (
        v_booking_detail_id, p_new_room_id, NOW(), 'Active'
    );
    
    -- อัปเดตห้องเก่า
    UPDATE rooms
    SET occupancy_status = 'Vacant', housekeeping_status = 'Dirty'
    WHERE room_id = v_old_room_id;
    
    -- อัปเดตห้องใหม่
    UPDATE rooms
    SET occupancy_status = 'Occupied'
    WHERE room_id = p_new_room_id;
    
    RETURN QUERY SELECT TRUE, 'ย้ายห้องสำเร็จ'::TEXT;
END;
$$;
```

### 5. Housekeeping Module

**Go Backend Endpoints:**
```
GET /api/housekeeping/tasks           - รายการงานทำความสะอาด
PUT /api/housekeeping/rooms/:id/status - อัปเดตสถานะห้อง
POST /api/housekeeping/rooms/:id/inspect - ตรวจสอบห้อง
POST /api/housekeeping/rooms/:id/maintenance - รายงานปัญหา
```

**Go Handler:**
```go
func (h *HousekeepingHandler) UpdateRoomStatus(c *gin.Context) {
    roomID, _ := strconv.Atoi(c.Param("id"))
    
    var req struct {
        Status string `json:"status" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    // Validate status transition
    validStatuses := []string{"Dirty", "Cleaning", "Clean", "Inspected", 
                              "MaintenanceRequired", "OutOfService"}
    if !contains(validStatuses, req.Status) {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status"})
        return
    }
    
    err := h.housekeepingService.UpdateRoomStatus(roomID, req.Status)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{"message": "อัปเดตสถานะสำเร็จ"})
}
```



### 6. Pricing & Inventory Management Module

**Go Backend Endpoints:**
```
# Rate Tiers
GET  /api/pricing/tiers       - ดึงรายการ rate tiers
POST /api/pricing/tiers       - สร้าง rate tier
PUT  /api/pricing/tiers/:id   - อัปเดต rate tier

# Pricing Calendar
GET /api/pricing/calendar     - ดึง pricing calendar
PUT /api/pricing/calendar     - อัปเดต tier สำหรับช่วงวันที่

# Rate Pricing
GET /api/pricing/rates        - ดึงเมทริกซ์ราคา
PUT /api/pricing/rates        - อัปเดตราคา

# Inventory
GET /api/inventory            - ดึงข้อมูล inventory
PUT /api/inventory            - อัปเดต allotment
```

### 7. Reporting Module

**Go Backend Endpoints:**
```
GET /api/reports/occupancy    - รายงานการเข้าพัก
GET /api/reports/revenue      - รายงานรายได้
GET /api/reports/vouchers     - รายงานคูปอง
GET /api/reports/export       - ส่งออกรายงาน
```

## โมเดลข้อมูล (Data Models)

### PostgreSQL Schema (ตารางหลัก)

```sql
-- Guests & Authentication
CREATE TABLE guests (
    guest_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE guest_accounts (
    guest_account_id SERIAL PRIMARY KEY,
    guest_id INT UNIQUE NOT NULL REFERENCES guests(guest_id),
    hashed_password VARCHAR(255) NOT NULL,
    last_login TIMESTAMP
);

-- Room Management
CREATE TABLE room_types (
    room_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    max_occupancy INT NOT NULL,
    default_allotment INT NOT NULL DEFAULT 10
);

CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id),
    room_number VARCHAR(10) UNIQUE NOT NULL,
    occupancy_status VARCHAR(20) NOT NULL DEFAULT 'Vacant' 
        CHECK (occupancy_status IN ('Vacant', 'Occupied')),
    housekeeping_status VARCHAR(50) NOT NULL DEFAULT 'Dirty'
        CHECK (housekeeping_status IN ('Dirty', 'Cleaning', 'Clean', 
               'Inspected', 'MaintenanceRequired', 'OutOfService'))
);

CREATE TABLE amenities (
    amenity_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE room_type_amenities (
    room_type_id INT REFERENCES room_types(room_type_id),
    amenity_id INT REFERENCES amenities(amenity_id),
    PRIMARY KEY (room_type_id, amenity_id)
);

-- Pricing & Inventory
CREATE TABLE room_inventory (
    room_type_id INT REFERENCES room_types(room_type_id),
    date DATE,
    allotment INT NOT NULL,
    booked_count INT NOT NULL DEFAULT 0,
    tentative_count INT NOT NULL DEFAULT 0,
    PRIMARY KEY (room_type_id, date),
    CONSTRAINT chk_inventory CHECK (booked_count + tentative_count <= allotment)
);

CREATE TABLE cancellation_policies (
    policy_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    days_before_check_in INT,
    refund_percentage DECIMAL(5, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE rate_plans (
    rate_plan_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    policy_id INT NOT NULL REFERENCES cancellation_policies(policy_id)
);

CREATE TABLE rate_tiers (
    rate_tier_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE pricing_calendar (
    date DATE PRIMARY KEY,
    rate_tier_id INT NOT NULL REFERENCES rate_tiers(rate_tier_id)
);

CREATE TABLE rate_pricing (
    rate_plan_id INT REFERENCES rate_plans(rate_plan_id),
    room_type_id INT REFERENCES room_types(room_type_id),
    rate_tier_id INT REFERENCES rate_tiers(rate_tier_id),
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    PRIMARY KEY (rate_plan_id, room_type_id, rate_tier_id)
);

CREATE TABLE vouchers (
    voucher_id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('Percentage', 'FixedAmount')),
    discount_value DECIMAL(10, 2) NOT NULL,
    expiry_date DATE NOT NULL,
    max_uses INT NOT NULL DEFAULT 100,
    current_uses INT NOT NULL DEFAULT 0
);

CREATE TABLE booking_holds (
    hold_id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    guest_account_id INT REFERENCES guest_accounts(guest_account_id),
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id),
    date DATE NOT NULL,
    hold_expiry TIMESTAMP NOT NULL
);

CREATE INDEX idx_holds_expiry ON booking_holds(hold_expiry);
CREATE INDEX idx_holds_session ON booking_holds(session_id);

-- Bookings
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    guest_id INT NOT NULL REFERENCES guests(guest_id),
    voucher_id INT REFERENCES vouchers(voucher_id),
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PendingPayment'
        CHECK (status IN ('PendingPayment', 'Confirmed', 'CheckedIn', 
               'Completed', 'Cancelled', 'NoShow')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    policy_name VARCHAR(100) NOT NULL,
    policy_description TEXT NOT NULL
);

CREATE TABLE booking_details (
    booking_detail_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(booking_id),
    room_type_id INT NOT NULL REFERENCES room_types(room_type_id),
    rate_plan_id INT NOT NULL REFERENCES rate_plans(rate_plan_id),
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    num_guests INT NOT NULL,
    CONSTRAINT chk_date_order CHECK (check_out_date > check_in_date)
);

CREATE TABLE room_assignments (
    room_assignment_id BIGSERIAL PRIMARY KEY,
    booking_detail_id INT NOT NULL REFERENCES booking_details(booking_detail_id),
    room_id INT NOT NULL REFERENCES rooms(room_id),
    check_in_datetime TIMESTAMP NOT NULL,
    check_out_datetime TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (status IN ('Active', 'Moved', 'Completed'))
);

CREATE TABLE booking_guests (
    booking_guest_id BIGSERIAL PRIMARY KEY,
    booking_detail_id INT NOT NULL REFERENCES booking_details(booking_detail_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    type VARCHAR(10) NOT NULL DEFAULT 'Adult' CHECK (type IN ('Adult', 'Child')),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE booking_nightly_log (
    booking_nightly_log_id SERIAL PRIMARY KEY,
    booking_detail_id INT NOT NULL REFERENCES booking_details(booking_detail_id),
    date DATE NOT NULL,
    quoted_price DECIMAL(10, 2) NOT NULL
);

-- Indexes
CREATE INDEX idx_bookings_guest ON bookings(guest_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_inventory_date ON room_inventory(date);
CREATE INDEX idx_rooms_status ON rooms(occupancy_status, housekeeping_status);
```



## Background Jobs (Go Cron)

### Night Audit Job

```go
// cmd/jobs/night_audit.go
package main

import (
    "log"
    "time"
    "github.com/robfig/cron/v3"
)

func RunNightAudit(db *sql.DB) {
    c := cron.New()
    
    // ทุกวันเวลา 02:00 น.
    c.AddFunc("0 2 * * *", func() {
        log.Println("Running night audit...")
        
        _, err := db.Exec(`
            UPDATE rooms
            SET housekeeping_status = 'Dirty'
            WHERE occupancy_status = 'Occupied'
        `)
        
        if err != nil {
            log.Printf("Night audit failed: %v", err)
            // ส่งอีเมลแจ้งเตือน
        } else {
            log.Println("Night audit completed successfully")
        }
    })
    
    c.Start()
}
```

### Hold Cleanup Job

```go
// cmd/jobs/hold_cleanup.go
func RunHoldCleanup(db *sql.DB) {
    c := cron.New()
    
    // ทุก 5 นาที
    c.AddFunc("*/5 * * * *", func() {
        _, err := db.Exec(`
            SELECT release_expired_holds()
        `)
        
        if err != nil {
            log.Printf("Hold cleanup failed: %v", err)
        }
    })
    
    c.Start()
}
```

**PostgreSQL Function:**
```sql
CREATE OR REPLACE FUNCTION release_expired_holds()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    -- คืนสต็อก
    UPDATE room_inventory ri
    SET tentative_count = tentative_count - 1
    FROM (
        SELECT room_type_id, date
        FROM booking_holds
        WHERE hold_expiry < NOW()
        GROUP BY room_type_id, date
    ) expired
    WHERE ri.room_type_id = expired.room_type_id 
      AND ri.date = expired.date
      AND ri.tentative_count > 0;
    
    -- ลบ holds
    DELETE FROM booking_holds
    WHERE hold_expiry < NOW();
END;
$$;
```

## Security Implementation

### JWT Authentication (Go)

```go
// pkg/auth/jwt.go
package auth

import (
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type Claims struct {
    UserID int    `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

func GenerateToken(userID int, email, role string) (string, error) {
    claims := Claims{
        UserID: userID,
        Email:  email,
        Role:   role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
        },
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(os.Getenv("JWT_SECRET")))
}

func ValidateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        return []byte(os.Getenv("JWT_SECRET")), nil
    })
    
    if err != nil {
        return nil, err
    }
    
    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
        return claims, nil
    }
    
    return nil, errors.New("invalid token")
}
```

### Middleware (Go)

```go
// internal/middleware/auth.go
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "No authorization header"})
            c.Abort()
            return
        }
        
        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        claims, err := auth.ValidateToken(tokenString)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            c.Abort()
            return
        }
        
        c.Set("user_id", claims.UserID)
        c.Set("user_role", claims.Role)
        c.Next()
    }
}

func RequireRole(roles ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        userRole, exists := c.Get("user_role")
        if !exists {
            c.JSON(http.StatusForbidden, gin.H{"error": "No role found"})
            c.Abort()
            return
        }
        
        for _, role := range roles {
            if userRole == role {
                c.Next()
                return
            }
        }
        
        c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient permissions"})
        c.Abort()
    }
}
```

### CORS Configuration (Go)

```go
// cmd/server/main.go
import "github.com/gin-contrib/cors"

func main() {
    r := gin.Default()
    
    // CORS
    r.Use(cors.New(cors.Config{
        AllowOrigins:     []string{os.Getenv("FRONTEND_URL")},
        AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
        MaxAge:           12 * time.Hour,
    }))
    
    // Routes
    api := r.Group("/api")
    {
        auth := api.Group("/auth")
        {
            auth.POST("/register", authHandler.Register)
            auth.POST("/login", authHandler.Login)
        }
        
        // Protected routes
        protected := api.Group("")
        protected.Use(middleware.AuthMiddleware())
        {
            protected.GET("/bookings", bookingHandler.GetBookings)
            protected.POST("/bookings", bookingHandler.CreateBooking)
        }
        
        // Manager only routes
        manager := api.Group("/pricing")
        manager.Use(middleware.AuthMiddleware(), middleware.RequireRole("manager"))
        {
            manager.GET("/rates", pricingHandler.GetRates)
            manager.PUT("/rates", pricingHandler.UpdateRates)
        }
    }
    
    r.Run(":8080")
}
```



## Frontend Implementation (Next.js 16)

### API Client

```typescript
// src/lib/api.ts
import { getSession } from "next-auth/react";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080";

export async function apiClient(endpoint: string, options: RequestInit = {}) {
  const session = await getSession();
  
  const headers = {
    "Content-Type": "application/json",
    ...options.headers,
  };
  
  if (session?.accessToken) {
    headers["Authorization"] = `Bearer ${session.accessToken}`;
  }
  
  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers,
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || "API request failed");
  }
  
  return response.json();
}

// API functions
export const api = {
  // Rooms
  searchRooms: (params: SearchParams) => 
    apiClient(`/api/rooms/search?${new URLSearchParams(params)}`),
  
  getRoomTypes: () => 
    apiClient("/api/rooms/types"),
  
  // Bookings
  createBookingHold: (data: HoldData) =>
    apiClient("/api/bookings/hold", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  
  createBooking: (data: BookingData) =>
    apiClient("/api/bookings", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  
  confirmBooking: (bookingId: number) =>
    apiClient(`/api/bookings/${bookingId}/confirm`, {
      method: "POST",
    }),
  
  getBookings: () =>
    apiClient("/api/bookings"),
  
  // Check-in/out
  checkIn: (data: CheckInData) =>
    apiClient("/api/checkin", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  
  checkOut: (bookingId: number) =>
    apiClient("/api/checkout", {
      method: "POST",
      body: JSON.stringify({ booking_id: bookingId }),
    }),
};
```

### React Query Hooks

```typescript
// src/hooks/useBookings.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";

export function useBookings() {
  return useQuery({
    queryKey: ["bookings"],
    queryFn: api.getBookings,
  });
}

export function useCreateBooking() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: api.createBooking,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useConfirmBooking() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (bookingId: number) => api.confirmBooking(bookingId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}
```

### Protected Route Component

```typescript
// src/components/ProtectedRoute.tsx
"use client";

import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export function ProtectedRoute({ 
  children, 
  requiredRole 
}: { 
  children: React.ReactNode;
  requiredRole?: string;
}) {
  const { data: session, status } = useSession();
  const router = useRouter();
  
  useEffect(() => {
    if (status === "loading") return;
    
    if (!session) {
      router.push("/auth/signin");
      return;
    }
    
    if (requiredRole && session.user.role !== requiredRole) {
      router.push("/unauthorized");
    }
  }, [session, status, requiredRole, router]);
  
  if (status === "loading") {
    return <div>Loading...</div>;
  }
  
  if (!session || (requiredRole && session.user.role !== requiredRole)) {
    return null;
  }
  
  return <>{children}</>;
}
```

## Docker Configuration

### docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: hotel_booking
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgres://postgres:postgres@postgres:5432/hotel_booking?sslmode=disable
      JWT_SECRET: your-secret-key-change-in-production
      PORT: 8080
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./backend:/app
    command: air # Hot reload for development

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8080
      NEXTAUTH_URL: http://localhost:3000
      NEXTAUTH_SECRET: your-nextauth-secret
      BACKEND_URL: http://backend:8080
    ports:
      - "3000:3000"
    depends_on:
      - backend
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next

volumes:
  postgres_data:
```

### Backend Dockerfile

```dockerfile
# backend/Dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/server

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
```

### Frontend Dockerfile (Development)

```dockerfile
# frontend/Dockerfile.dev
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
```



## Testing Strategy

### Backend Testing (Go)

```go
// internal/handlers/booking_test.go
package handlers_test

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
)

func TestCreateBooking(t *testing.T) {
    // Setup
    gin.SetMode(gin.TestMode)
    router := setupTestRouter()
    
    // Test data
    booking := map[string]interface{}{
        "guest_id": 1,
        "room_type_id": 1,
        "check_in": "2025-02-01",
        "check_out": "2025-02-03",
    }
    
    body, _ := json.Marshal(booking)
    req, _ := http.NewRequest("POST", "/api/bookings", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+testToken)
    
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    // Assertions
    assert.Equal(t, http.StatusCreated, w.Code)
    
    var response map[string]interface{}
    json.Unmarshal(w.Body.Bytes(), &response)
    assert.NotNil(t, response["booking_id"])
}
```

### Frontend Testing (Jest + React Testing Library)

```typescript
// src/components/BookingForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BookingForm } from './BookingForm';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

describe('BookingForm', () => {
  it('should submit booking successfully', async () => {
    const queryClient = new QueryClient();
    
    render(
      <QueryClientProvider client={queryClient}>
        <BookingForm />
      </QueryClientProvider>
    );
    
    // Fill form
    fireEvent.change(screen.getByLabelText('Check-in'), {
      target: { value: '2025-02-01' }
    });
    fireEvent.change(screen.getByLabelText('Check-out'), {
      target: { value: '2025-02-03' }
    });
    
    // Submit
    fireEvent.click(screen.getByText('จองเลย'));
    
    // Wait for success message
    await waitFor(() => {
      expect(screen.getByText('จองสำเร็จ')).toBeInTheDocument();
    });
  });
});
```

### E2E Testing (Playwright)

```typescript
// tests/e2e/booking-flow.spec.ts
import { test, expect } from '@playwright/test';

test('complete booking flow', async ({ page }) => {
  // 1. ค้นหาห้อง
  await page.goto('http://localhost:3000');
  await page.fill('[name="checkIn"]', '2025-02-01');
  await page.fill('[name="checkOut"]', '2025-02-03');
  await page.click('button:has-text("ค้นหา")');
  
  // 2. เลือกห้อง
  await page.waitForSelector('.room-card');
  await page.click('.room-card:first-child button:has-text("จองเลย")');
  
  // 3. กรอกข้อมูล
  await page.fill('[name="firstName"]', 'John');
  await page.fill('[name="lastName"]', 'Doe');
  await page.fill('[name="email"]', 'john@example.com');
  
  // 4. ชำระเงิน (mock)
  await page.click('button:has-text("ชำระเงิน")');
  
  // 5. ตรวจสอบการยืนยัน
  await expect(page.locator('.booking-confirmation')).toBeVisible();
  const bookingNumber = await page.locator('.booking-number').textContent();
  expect(bookingNumber).toMatch(/^BK\d+$/);
});
```

## Performance Optimization

### Database Optimization

```sql
-- Indexes สำหรับ performance
CREATE INDEX CONCURRENTLY idx_bookings_guest_status 
ON bookings(guest_id, status);

CREATE INDEX CONCURRENTLY idx_inventory_lookup 
ON room_inventory(room_type_id, date) 
WHERE (allotment - booked_count - tentative_count) > 0;

CREATE INDEX CONCURRENTLY idx_pricing_lookup 
ON rate_pricing(rate_plan_id, room_type_id, rate_tier_id);

-- Materialized view สำหรับ dashboard
CREATE MATERIALIZED VIEW room_status_summary AS
SELECT 
    occupancy_status,
    housekeeping_status,
    COUNT(*) as count
FROM rooms
GROUP BY occupancy_status, housekeeping_status;

CREATE UNIQUE INDEX ON room_status_summary(occupancy_status, housekeeping_status);

-- Refresh ทุก 30 วินาที
REFRESH MATERIALIZED VIEW CONCURRENTLY room_status_summary;
```

### Caching Strategy (Redis - Optional)

```go
// pkg/cache/redis.go
package cache

import (
    "context"
    "encoding/json"
    "time"
    "github.com/redis/go-redis/v9"
)

type Cache struct {
    client *redis.Client
}

func NewCache() *Cache {
    client := redis.NewClient(&redis.Options{
        Addr: os.Getenv("REDIS_URL"),
    })
    
    return &Cache{client: client}
}

func (c *Cache) Get(ctx context.Context, key string, dest interface{}) error {
    val, err := c.client.Get(ctx, key).Result()
    if err != nil {
        return err
    }
    
    return json.Unmarshal([]byte(val), dest)
}

func (c *Cache) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
    data, err := json.Marshal(value)
    if err != nil {
        return err
    }
    
    return c.client.Set(ctx, key, data, ttl).Err()
}

// Usage in handler
func (h *RoomHandler) GetRoomTypes(c *gin.Context) {
    ctx := c.Request.Context()
    cacheKey := "room_types"
    
    // Try cache first
    var roomTypes []RoomType
    err := h.cache.Get(ctx, cacheKey, &roomTypes)
    if err == nil {
        c.JSON(http.StatusOK, roomTypes)
        return
    }
    
    // Cache miss - query database
    roomTypes, err = h.roomService.GetAllRoomTypes()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    // Cache for 1 hour
    h.cache.Set(ctx, cacheKey, roomTypes, time.Hour)
    
    c.JSON(http.StatusOK, roomTypes)
}
```

## Deployment & DevOps

### Environment Variables

```bash
# .env.example

# Database
DATABASE_URL=postgres://user:password@localhost:5432/hotel_booking?sslmode=disable

# Backend
JWT_SECRET=your-jwt-secret-change-in-production
PORT=8080
GIN_MODE=release

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-nextauth-secret
BACKEND_URL=http://backend:8080

# Optional - Redis
REDIS_URL=localhost:6379

# Email (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Production Deployment Steps

1. **Build Backend:**
```bash
cd backend
go build -o hotel-api ./cmd/server
```

2. **Build Frontend:**
```bash
cd frontend
npm run build
npm run start
```

3. **Database Migration:**
```bash
psql -U postgres -d hotel_booking -f database/migrations/001_create_tables.sql
psql -U postgres -d hotel_booking -f database/migrations/002_create_functions.sql
psql -U postgres -d hotel_booking -f database/migrations/003_seed_data.sql
```

4. **Run with Docker Compose:**
```bash
docker-compose up -d
```

## สรุปและข้อแนะนำ

### จุดเด่นของการออกแบบนี้

1. **Separation of Concerns:** แยก frontend, backend และ database ชัดเจน
2. **Type Safety:** ใช้ TypeScript และ Go ที่มี strong typing
3. **Performance:** Go มี concurrency ดี, PostgreSQL มี advanced features
4. **Security:** NextAuth.js + JWT + bcrypt + prepared statements
5. **Scalability:** สามารถ scale แต่ละส่วนแยกกันได้
6. **Developer Experience:** Hot reload, type checking, good tooling

### ลำดับการพัฒนาที่แนะนำ

1. **Phase 1: Database & Backend Core**
   - สร้าง PostgreSQL schema
   - สร้าง PostgreSQL functions
   - สร้าง Go API สำหรับ authentication
   - สร้าง Go API สำหรับ room search

2. **Phase 2: Booking Flow**
   - สร้าง booking hold logic
   - สร้าง booking confirmation
   - สร้าง payment integration (mock)
   - ทดสอบ race conditions

3. **Phase 3: Frontend Guest**
   - สร้าง NextAuth configuration
   - สร้างหน้าค้นหาห้อง
   - สร้างหน้าจอง
   - สร้างหน้าประวัติการจอง

4. **Phase 4: Staff Features**
   - สร้าง check-in/check-out
   - สร้าง room status dashboard
   - สร้าง housekeeping interface

5. **Phase 5: Manager Features**
   - สร้าง pricing management
   - สร้าง inventory management
   - สร้าง reports

6. **Phase 6: Testing & Optimization**
   - เขียน unit tests
   - เขียน integration tests
   - เขียน E2E tests
   - Optimize queries
   - Add caching

### ข้อควรระวัง

1. **Database Transactions:** ต้องใช้ transactions สำหรับ operations ที่สำคัญ
2. **Error Handling:** ต้อง handle errors อย่างถูกต้องทั้ง Go และ TypeScript
3. **CORS:** ต้อง configure CORS ให้ถูกต้องระหว่าง frontend และ backend
4. **Environment Variables:** ต้องไม่ commit secrets ลง git
5. **Database Migrations:** ต้องมี version control สำหรับ schema changes

