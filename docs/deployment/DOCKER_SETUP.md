# Docker Setup Guide - ระบบจองโรงแรมและที่พัก

## ภาพรวม

โปรเจกต์นี้ใช้ Docker และ Docker Compose เพื่อจัดการ services ทั้งหมด:
- **PostgreSQL 15** - Database
- **Go Backend** - REST API (พร้อม hot reload ด้วย Air)
- **Next.js Frontend** - Web Application (พร้อม hot reload)

## ข้อกำหนดเบื้องต้น

- Docker Desktop 20.10+ หรือ Docker Engine + Docker Compose
- Git
- 4GB RAM ขั้นต่ำ (แนะนำ 8GB)
- พื้นที่ว่าง 5GB

## การติดตั้ง Docker

### Windows
1. ดาวน์โหลด [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. ติดตั้งและรีสตาร์ทเครื่อง
3. เปิด Docker Desktop และรอจนกว่าจะพร้อมใช้งาน

### macOS
1. ดาวน์โหลด [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
2. ติดตั้งและเปิด Docker Desktop

### Linux
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## โครงสร้าง Docker Files

```
.
├── docker-compose.yml          # Orchestration configuration
├── backend/
│   ├── Dockerfile              # Production build
│   ├── Dockerfile.dev          # Development build (with Air)
│   ├── .air.toml               # Air hot reload config
│   └── .dockerignore
├── frontend/
│   ├── Dockerfile              # Production build
│   ├── Dockerfile.dev          # Development build
│   └── .dockerignore
└── database/
    └── migrations/             # Auto-run on first start
```

## การเริ่มต้นใช้งาน

### 1. Clone Repository
```bash
git clone <repository-url>
cd hotel-booking-system
```

### 2. ตั้งค่า Environment Variables
```bash
cp .env.example .env
```

แก้ไขไฟล์ `.env` ตามต้องการ (สำหรับ development ใช้ค่า default ได้)

### 3. Build และ Start Containers
```bash
# ใช้ Docker Compose
docker-compose up -d

# หรือใช้ Makefile (แนะนำ)
make dev
```

### 4. ตรวจสอบสถานะ
```bash
docker-compose ps

# หรือ
make ps
```

คุณควรเห็น 3 containers ทำงาน:
- `hotel-booking-db` (PostgreSQL)
- `hotel-booking-backend` (Go API)
- `hotel-booking-frontend` (Next.js)

### 5. เข้าถึง Services

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Database**: localhost:5432
  - Database: `hotel_booking`
  - User: `postgres`
  - Password: `postgres123`

## คำสั่งที่ใช้บ่อย

### ใช้ Docker Compose โดยตรง

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db

# Rebuild containers
docker-compose build
docker-compose up -d --build

# Remove everything (including volumes)
docker-compose down -v
```

### ใช้ Makefile (สะดวกกว่า)

```bash
# Show all available commands
make help

# Start development environment
make dev

# View logs
make logs
make logs-backend
make logs-frontend
make logs-db

# Restart services
make restart

# Rebuild everything
make rebuild

# Clean up everything
make clean

# Database operations
make db-shell      # Open PostgreSQL shell
make db-migrate    # Run migrations

# Container shells
make backend-shell
make frontend-shell
```

## Database Migrations

### อัตโนมัติ (First Start)
Migration files ใน `database/migrations/` จะถูกรันอัตโนมัติเมื่อ database container เริ่มครั้งแรก

### Manual Migration
```bash
# Run all migrations
make db-migrate

# Run specific migration
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database/migrations/001_create_guests_tables.sql
```

### เข้าถึง Database Shell
```bash
# ใช้ Makefile
make db-shell

# หรือใช้ Docker โดยตรง
docker exec -it hotel-booking-db psql -U postgres -d hotel_booking
```

## Hot Reload (Development)

### Backend (Go with Air)
- Air จะตรวจจับการเปลี่ยนแปลงไฟล์ `.go` และ rebuild อัตโนมัติ
- ดู logs: `make logs-backend`
- Configuration: `backend/.air.toml`

### Frontend (Next.js)
- Next.js มี hot reload built-in
- การเปลี่ยนแปลงจะสะท้อนทันทีใน browser
- ดู logs: `make logs-frontend`

## Troubleshooting

### Port Already in Use
```bash
# หา process ที่ใช้ port
# Windows
netstat -ano | findstr :3000
netstat -ano | findstr :8080
netstat -ano | findstr :5432

# Linux/Mac
lsof -i :3000
lsof -i :8080
lsof -i :5432

# แก้ไข: เปลี่ยน port ใน docker-compose.yml
```

### Container ไม่ Start
```bash
# ดู logs เพื่อหาสาเหตุ
docker-compose logs backend
docker-compose logs frontend
docker-compose logs db

# Rebuild container
docker-compose build backend
docker-compose up -d backend
```

### Database Connection Failed
```bash
# ตรวจสอบว่า database พร้อมใช้งาน
docker-compose ps db

# ตรวจสอบ health check
docker inspect hotel-booking-db | grep Health

# Restart database
docker-compose restart db
```

### Out of Disk Space
```bash
# ลบ unused images และ containers
docker system prune -a

# ลบ volumes (ระวัง: จะลบข้อมูล database)
docker volume prune
```

### Backend ไม่ rebuild
```bash
# Force rebuild
docker-compose build --no-cache backend
docker-compose up -d backend

# หรือ
make rebuild
```

### Frontend node_modules Issues
```bash
# ลบ node_modules volume และ rebuild
docker-compose down
docker volume rm hotel-booking-system_node_modules
docker-compose build frontend
docker-compose up -d frontend
```

## Production Deployment

### Build Production Images
```bash
# Backend
docker build -f backend/Dockerfile -t hotel-booking-backend:prod ./backend

# Frontend
docker build -f frontend/Dockerfile -t hotel-booking-frontend:prod ./frontend
```

### Production docker-compose
สร้างไฟล์ `docker-compose.prod.yml` สำหรับ production:
- ใช้ production Dockerfiles
- ตั้งค่า environment variables ที่ปลอดภัย
- เพิ่ม reverse proxy (nginx)
- ตั้งค่า SSL/TLS
- เพิ่ม monitoring และ logging

## Performance Tips

### Development
- ใช้ volumes สำหรับ hot reload
- ไม่ต้อง rebuild บ่อยๆ
- ใช้ `.dockerignore` เพื่อลดขนาด context

### Production
- ใช้ multi-stage builds
- Minimize image size
- ใช้ alpine base images
- Enable caching layers

## Security Best Practices

1. **ไม่ commit secrets**: ใช้ `.env` และเพิ่มใน `.gitignore`
2. **เปลี่ยน default passwords**: อย่าใช้ `postgres123` ใน production
3. **ใช้ secrets management**: Docker secrets หรือ external vault
4. **Update images**: ใช้ specific versions แทน `latest`
5. **Scan images**: ใช้ `docker scan` เพื่อหา vulnerabilities

## Monitoring

### View Resource Usage
```bash
# All containers
docker stats

# Specific container
docker stats hotel-booking-backend
```

### Health Checks
```bash
# Database health
curl http://localhost:8080/health

# Check all services
docker-compose ps
```

## Backup & Restore

### Backup Database
```bash
docker exec hotel-booking-db pg_dump -U postgres hotel_booking > backup.sql
```

### Restore Database
```bash
docker exec -i hotel-booking-db psql -U postgres hotel_booking < backup.sql
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Go with Docker](https://docs.docker.com/language/golang/)
- [Next.js with Docker](https://nextjs.org/docs/deployment#docker-image)

## Support

หากพบปัญหา:
1. ตรวจสอบ logs: `make logs`
2. ดู troubleshooting section ด้านบน
3. Restart services: `make restart`
4. Rebuild: `make rebuild`
5. Clean start: `make clean && make dev`

---

**หมายเหตุ**: เอกสารนี้เป็นส่วนหนึ่งของโปรเจกต์ระบบจองโรงแรมและที่พัก
