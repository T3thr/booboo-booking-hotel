# 🐳 Docker Complete Guide 2025 - คู่มือฉบับสมบูรณ์

## 📚 สารบัญ

1. [Docker คืออะไร](#docker-คืออะไร)
2. [ติดตั้ง Docker บน Windows](#ติดตั้ง-docker-บน-windows)
3. [Docker Concepts พื้นฐาน](#docker-concepts-พื้นฐาน)
4. [Docker Commands ที่ใช้บ่อย](#docker-commands-ที่ใช้บ่อย)
5. [Docker Compose](#docker-compose)
6. [Best Practices 2025](#best-practices-2025)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Docker คืออะไร

Docker เป็นเครื่องมือที่ช่วยให้เราสามารถ:
- **Package** แอปพลิเคชันพร้อม dependencies ทั้งหมดไว้ใน "Container"
- **Run** แอปพลิเคชันได้เหมือนกันทุกเครื่อง (Dev, Test, Production)
- **Share** environment ได้ง่าย ไม่ต้องติดตั้งซ้ำ

### ทำไมต้องใช้ Docker?

**ปัญหาเดิม:**
```
Dev: "มันทำงานบนเครื่องผมนะ" 🤷‍♂️
Ops: "แต่มันไม่ทำงานบน server" 😤
```

**แก้ด้วย Docker:**
```
Dev: "นี่ Docker image ครับ"
Ops: "รันได้เลย ไม่มีปัญหา" ✅
```

### เปรียบเทียบ: Virtual Machine vs Docker

```
┌─────────────────────────┐  ┌─────────────────────────┐
│   Virtual Machine       │  │      Docker             │
├─────────────────────────┤  ├─────────────────────────┤
│  App A  │  App B        │  │  App A  │  App B        │
│  Bins   │  Bins         │  │  Bins   │  Bins         │
│  Guest OS │ Guest OS    │  │  Docker Engine          │
│  Hypervisor             │  │  Host OS                │
│  Host OS                │  │  Infrastructure         │
│  Infrastructure         │  │                         │
└─────────────────────────┘  └─────────────────────────┘
     ❌ หนัก ช้า                ✅ เบา เร็ว
```

---

## 💻 ติดตั้ง Docker บน Windows

### ขั้นตอนที่ 1: ตรวจสอบความพร้อม

**ต้องการ:**
- Windows 10/11 (64-bit)
- WSL 2 (Windows Subsystem for Linux)
- Virtualization เปิดใน BIOS

**ตรวจสอบ Virtualization:**
```powershell
# เปิด Task Manager (Ctrl + Shift + Esc)
# ไปที่ Performance > CPU
# ดูว่า "Virtualization" เป็น "Enabled" หรือไม่
```

### ขั้นตอนที่ 2: ติดตั้ง WSL 2

```powershell
# เปิด PowerShell แบบ Administrator
wsl --install

# รีสตาร์ทเครื่อง
# หลังรีสตาร์ท ตั้งค่า Ubuntu username/password
```

**ตรวจสอบ WSL:**
```powershell
wsl --list --verbose
# ควรเห็น Ubuntu running
```

### ขั้นตอนที่ 3: ติดตั้ง Docker Desktop

1. **ดาวน์โหลด:**
   - ไปที่: https://www.docker.com/products/docker-desktop/
   - ดาวน์โหลด Docker Desktop for Windows

2. **ติดตั้ง:**
   - รัน installer
   - เลือก "Use WSL 2 instead of Hyper-V"
   - รอให้ติดตั้งเสร็จ
   - รีสตาร์ทเครื่อง

3. **เปิด Docker Desktop:**
   - เปิดโปรแกรม Docker Desktop
   - รอให้ Docker Engine start (ไฟเขียว)
   - ยอมรับ Terms of Service

### ขั้นตอนที่ 4: ตรวจสอบการติดตั้ง

```powershell
# ตรวจสอบ Docker version
docker --version
# Output: Docker version 24.0.7, build...

# ตรวจสอบ Docker Compose version
docker compose version
# Output: Docker Compose version v2.23.0

# ทดสอบรัน container
docker run hello-world
# ถ้าเห็น "Hello from Docker!" แสดงว่าสำเร็จ ✅
```

---

## 🧩 Docker Concepts พื้นฐาน

### 1. Image (แม่แบบ)

Image คือ template สำหรับสร้าง container

```
┌─────────────────┐
│  Docker Image   │  ← แม่แบบ (read-only)
├─────────────────┤
│  - Node.js      │
│  - npm packages │
│  - App code     │
│  - Config       │
└─────────────────┘
```

**ตัวอย่าง:**
```bash
# ดู images ที่มี
docker images

# ดาวน์โหลด image
docker pull postgres:16
docker pull node:20-alpine

# ลบ image
docker rmi postgres:16
```

### 2. Container (ตัวจริง)

Container คือ instance ที่รันจาก image

```
┌─────────────────┐
│  Docker Image   │
└────────┬────────┘
         │ docker run
         ↓
┌─────────────────┐
│   Container 1   │  ← กำลังรันอยู่
├─────────────────┤
│  - Running app  │
│  - Has data     │
│  - Can modify   │
└─────────────────┘
```

**ตัวอย่าง:**
```bash
# รัน container
docker run -d --name my-postgres postgres:16

# ดู containers ที่รันอยู่
docker ps

# ดู containers ทั้งหมด (รวมที่หยุด)
docker ps -a

# หยุด container
docker stop my-postgres

# เริ่ม container
docker start my-postgres

# ลบ container
docker rm my-postgres
```

### 3. Volume (เก็บข้อมูล)

Volume ใช้เก็บข้อมูลถาวร (persistent data)

```
┌─────────────────┐
│   Container     │
│  /var/lib/data  │ ← mount
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Docker Volume  │  ← ข้อมูลไม่หาย
│  my-data        │     แม้ลบ container
└─────────────────┘
```

**ตัวอย่าง:**
```bash
# สร้าง volume
docker volume create my-data

# ดู volumes
docker volume ls

# รัน container พร้อม mount volume
docker run -d \
  --name my-postgres \
  -v my-data:/var/lib/postgresql/data \
  postgres:16

# ลบ volume
docker volume rm my-data
```

### 4. Network (เชื่อมต่อกัน)

Network ให้ containers คุยกันได้

```
┌──────────────────────────────┐
│     Docker Network           │
│  ┌──────────┐  ┌──────────┐ │
│  │ Frontend │←→│ Backend  │ │
│  └──────────┘  └────┬─────┘ │
│                     ↓        │
│                ┌──────────┐  │
│                │ Database │  │
│                └──────────┘  │
└──────────────────────────────┘
```

**ตัวอย่าง:**
```bash
# สร้าง network
docker network create my-network

# ดู networks
docker network ls

# รัน containers ใน network เดียวกัน
docker run -d --name db --network my-network postgres:16
docker run -d --name api --network my-network node:20

# ลบ network
docker network rm my-network
```

---

## 🎮 Docker Commands ที่ใช้บ่อย

### คำสั่งพื้นฐาน

```bash
# ดูข้อมูล Docker
docker info
docker version

# ดู help
docker --help
docker run --help
```

### จัดการ Images

```bash
# ดู images ทั้งหมด
docker images
docker image ls

# ดาวน์โหลด image
docker pull <image-name>:<tag>
docker pull postgres:16
docker pull node:20-alpine

# ลบ image
docker rmi <image-id>
docker rmi postgres:16

# ลบ images ที่ไม่ใช้
docker image prune

# Build image จาก Dockerfile
docker build -t my-app:latest .
docker build -t my-app:v1.0 -f Dockerfile.prod .
```

### จัดการ Containers

```bash
# รัน container
docker run <image>
docker run -d <image>                    # รันแบบ background
docker run -d --name my-app <image>      # ตั้งชื่อ
docker run -d -p 3000:3000 <image>       # map port
docker run -d -e DB_HOST=localhost <image>  # ส่ง env variable

# ดู containers
docker ps                    # ที่รันอยู่
docker ps -a                 # ทั้งหมด
docker ps -q                 # แค่ ID

# จัดการ container
docker start <container>     # เริ่ม
docker stop <container>      # หยุด
docker restart <container>   # รีสตาร์ท
docker pause <container>     # พัก
docker unpause <container>   # เล่นต่อ
docker rm <container>        # ลบ
docker rm -f <container>     # ลบแบบบังคับ

# ดู logs
docker logs <container>
docker logs -f <container>              # ดูแบบ real-time
docker logs --tail 100 <container>      # ดู 100 บรรทัดล่าสุด

# เข้าไปใน container
docker exec -it <container> bash
docker exec -it <container> sh
docker exec <container> ls /app

# ดูข้อมูล container
docker inspect <container>
docker stats <container>                # ดู CPU, Memory usage
docker top <container>                  # ดู processes
```

### จัดการ Volumes

```bash
# สร้าง volume
docker volume create <volume-name>

# ดู volumes
docker volume ls

# ดูข้อมูล volume
docker volume inspect <volume-name>

# ลบ volume
docker volume rm <volume-name>

# ลบ volumes ที่ไม่ใช้
docker volume prune
```

### จัดการ Networks

```bash
# สร้าง network
docker network create <network-name>

# ดู networks
docker network ls

# ดูข้อมูล network
docker network inspect <network-name>

# เชื่อม container เข้า network
docker network connect <network> <container>

# ตัด container ออกจาก network
docker network disconnect <network> <container>

# ลบ network
docker network rm <network-name>
```

### ทำความสะอาด

```bash
# ลบทุกอย่างที่ไม่ใช้
docker system prune

# ลบทุกอย่างรวม volumes
docker system prune -a --volumes

# ดูพื้นที่ที่ใช้
docker system df
```

---

## 🎼 Docker Compose

Docker Compose ใช้จัดการหลาย containers พร้อมกัน

### ทำไมต้องใช้ Docker Compose?

**ไม่ใช้ Compose (ยุ่งยาก):**
```bash
docker network create my-network
docker volume create db-data
docker run -d --name db --network my-network -v db-data:/var/lib/postgresql/data postgres:16
docker run -d --name backend --network my-network -p 8080:8080 my-backend
docker run -d --name frontend --network my-network -p 3000:3000 my-frontend
```

**ใช้ Compose (ง่าย):**
```bash
docker compose up -d
```

### โครงสร้าง docker-compose.yml

```yaml
version: '3.8'

services:
  # Service 1: Database
  postgres:
    image: postgres:16
    container_name: hotel-postgres
    environment:
      POSTGRES_USER: hotel_user
      POSTGRES_PASSWORD: hotel_pass
      POSTGRES_DB: hotel_db
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - hotel-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U hotel_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Service 2: Backend
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    container_name: hotel-backend
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: hotel_user
      DB_PASSWORD: hotel_pass
      DB_NAME: hotel_db
    ports:
      - "8080:8080"
    volumes:
      - ./backend:/app
      - /app/vendor  # exclude vendor folder
    networks:
      - hotel-network
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  # Service 3: Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    container_name: hotel-frontend
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8080/api
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules  # exclude node_modules
      - /app/.next         # exclude .next
    networks:
      - hotel-network
    depends_on:
      - backend
    restart: unless-stopped

# Define volumes
volumes:
  postgres-data:
    driver: local

# Define networks
networks:
  hotel-network:
    driver: bridge
```

### Docker Compose Commands

```bash
# เริ่ม services ทั้งหมด
docker compose up
docker compose up -d              # background mode
docker compose up --build         # build ใหม่ก่อน
docker compose up backend         # เริ่มแค่ service เดียว

# หยุด services
docker compose stop
docker compose stop backend       # หยุดแค่ service เดียว

# หยุดและลบ containers
docker compose down
docker compose down -v            # ลบ volumes ด้วย
docker compose down --rmi all     # ลบ images ด้วย

# ดู status
docker compose ps
docker compose ps -a

# ดู logs
docker compose logs
docker compose logs -f            # real-time
docker compose logs backend       # แค่ service เดียว
docker compose logs -f --tail=100 backend

# รีสตาร์ท services
docker compose restart
docker compose restart backend

# Build images
docker compose build
docker compose build --no-cache   # build ใหม่ทั้งหมด

# เข้าไปใน container
docker compose exec backend bash
docker compose exec postgres psql -U hotel_user -d hotel_db

# รัน command ใน container
docker compose exec backend go test ./...
docker compose exec frontend npm run build

# ดู config
docker compose config             # ดู config ที่ merge แล้ว

# Pull images ใหม่
docker compose pull
```

---

## 🏗️ Dockerfile Best Practices 2025

### Dockerfile สำหรับ Go Backend

```dockerfile
# Multi-stage build
FROM golang:1.21-alpine AS builder

# ติดตั้ง dependencies
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Run
CMD ["./main"]
```

### Dockerfile สำหรับ Next.js Frontend

```dockerfile
# Multi-stage build
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Builder stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build application
RUN npm run build

# Runner stage
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV production

# Copy necessary files
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

### .dockerignore

```
# Git
.git
.gitignore

# Dependencies
node_modules
vendor

# Build outputs
.next
dist
build

# Environment files
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode
.idea
*.swp
*.swo

# Testing
coverage
.nyc_output

# Documentation
*.md
docs/
```

---

## 🎯 Best Practices 2025

### 1. ใช้ Multi-stage Builds

```dockerfile
# ❌ ไม่ดี - image ใหญ่
FROM node:20
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
CMD ["npm", "start"]

# ✅ ดี - image เล็ก
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/main.js"]
```

### 2. ใช้ Alpine Images

```dockerfile
# ❌ ใหญ่ (1GB+)
FROM node:20

# ✅ เล็ก (~100MB)
FROM node:20-alpine
```

### 3. Layer Caching

```dockerfile
# ❌ ไม่ดี - rebuild ทุกครั้ง
COPY . .
RUN npm install

# ✅ ดี - cache dependencies
COPY package*.json ./
RUN npm install
COPY . .
```

### 4. Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

```yaml
# docker-compose.yml
services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 5. Security

```dockerfile
# ใช้ non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
USER nextjs

# Scan vulnerabilities
# docker scan my-image:latest
```

### 6. Environment Variables

```yaml
# ❌ ไม่ดี - hardcode
environment:
  DB_PASSWORD: mypassword123

# ✅ ดี - ใช้ .env file
environment:
  DB_PASSWORD: ${DB_PASSWORD}
```

---

## 🔧 Troubleshooting

### ปัญหา: Docker Desktop ไม่เปิด

```powershell
# ตรวจสอบ WSL
wsl --list --verbose

# รีสตาร์ท WSL
wsl --shutdown
# เปิด Docker Desktop ใหม่

# ตรวจสอบ Hyper-V
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
```

### ปัญหา: Container ไม่ start

```bash
# ดู logs
docker logs <container-name>

# ดูข้อมูลละเอียด
docker inspect <container-name>

# ตรวจสอบ health
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### ปัญหา: Port ถูกใช้แล้ว

```powershell
# ดูว่า port ไหนถูกใช้
netstat -ano | findstr :3000

# Kill process
taskkill /PID <PID> /F
```

### ปัญหา: Volume permission denied

```bash
# ใช้ named volume แทน bind mount
volumes:
  - postgres-data:/var/lib/postgresql/data  # ✅ ดี

# แทนที่
volumes:
  - ./data:/var/lib/postgresql/data  # ❌ อาจมีปัญหา permission
```

### ปัญหา: Build ช้า

```bash
# ใช้ BuildKit (เร็วกว่า)
DOCKER_BUILDKIT=1 docker build .

# หรือตั้งค่าถาวร
export DOCKER_BUILDKIT=1
```

---

## 📝 สรุป Commands สำหรับ Project นี้

### Development

```bash
# เริ่ม project
docker compose up -d

# ดู logs
docker compose logs -f

# หยุด project
docker compose down

# รีสตาร์ท service
docker compose restart backend

# Build ใหม่
docker compose up --build -d
```

### Database

```bash
# เข้า PostgreSQL
docker compose exec postgres psql -U hotel_user -d hotel_db

# Run migration
docker compose exec backend go run cmd/migrate/main.go

# Backup database
docker compose exec postgres pg_dump -U hotel_user hotel_db > backup.sql

# Restore database
docker compose exec -T postgres psql -U hotel_user hotel_db < backup.sql
```

### Debugging

```bash
# เข้าไปใน container
docker compose exec backend sh
docker compose exec frontend sh

# ดู environment variables
docker compose exec backend env

# ดู network
docker network inspect booking-hotel_hotel-network
```

---

## 🎓 เรียนรู้เพิ่มเติม

### Official Documentation
- Docker Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- Best Practices: https://docs.docker.com/develop/dev-best-practices/

### Tutorials
- Docker 101: https://www.docker.com/101-tutorial/
- Play with Docker: https://labs.play-with-docker.com/

### Tools
- Docker Desktop: https://www.docker.com/products/docker-desktop/
- Portainer: https://www.portainer.io/ (GUI for Docker)
- Lazydocker: https://github.com/jesseduffield/lazydocker (TUI)

---

## ✅ Checklist สำหรับ Project

- [ ] ติดตั้ง Docker Desktop
- [ ] ติดตั้ง WSL 2
- [ ] ทดสอบ `docker run hello-world`
- [ ] สร้าง `.env` file
- [ ] รัน `docker compose up -d`
- [ ] ตรวจสอบ containers: `docker compose ps`
- [ ] ทดสอบ API: `curl http://localhost:8080/health`
- [ ] ทดสอบ Frontend: เปิด `http://localhost:3000`
- [ ] ตรวจสอบ Database: `docker compose exec postgres psql -U hotel_user -d hotel_db`

---

**หมายเหตุ:** คู่มือนี้อัพเดทตามมาตรฐาน Docker ปี 2025 ใช้ `docker compose` (ไม่มี dash) แทน `docker-compose` เวอร์ชันเก่า

