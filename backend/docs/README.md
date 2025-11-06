# Backend Documentation

> **Go API Documentation Hub**

## 📋 Overview

This directory contains comprehensive documentation for the Go backend API, including module references, testing guides, and API specifications.

## 📁 Documentation Structure

```
backend/docs/
├── README.md                      # This file
├── INDEX.md                       # Complete documentation index
├── TESTING_GUIDE.md               # Testing guidelines
├── API_DOCUMENTATION_SUMMARY.md   # API overview
├── swagger.yaml                   # OpenAPI specification
│
├── modules/                       # Module-specific documentation
│   ├── auth/                      # Authentication module
│   ├── booking/                   # Booking module
│   ├── rooms/                     # Room management
│   ├── pricing/                   # Pricing module
│   ├── inventory/                 # Inventory module
│   ├── policy-voucher/            # Policy & voucher module
│   ├── reporting/                 # Reporting module
│   ├── checkin-checkout/          # Check-in/out module
│   └── housekeeping/              # Housekeeping module
│
├── jobs/                          # Background jobs
│   ├── night-audit/               # Night audit job
│   └── hold-cleanup/              # Hold cleanup job
│
├── security/                      # Security documentation
│   ├── audit.md                   # Security audit
│   └── checklist.md               # Security checklist
│
├── caching/                       # Caching documentation
│   └── redis.md                   # Redis caching guide
│
├── testing/                       # Testing documentation
│   └── unit-tests/                # Unit tests
│
├── examples/                      # API examples
│   ├── auth-examples.md
│   ├── booking-examples.md
│   └── room-examples.md
│
└── swagger-ui/                    # Swagger UI setup
    └── swagger-initializer.js
```

## 🚀 Quick Links

### Getting Started
- [Quick Start Guide](../QUICK_START.md)
- [Architecture Overview](../ARCHITECTURE.md)
- [Project Structure](../PROJECT_STRUCTURE.md)

### API Documentation
- [API Documentation Summary](./API_DOCUMENTATION_SUMMARY.md)
- [Swagger/OpenAPI Spec](./swagger.yaml)
- [API Examples](./examples/)

### Module Documentation
- [Authentication](./modules/auth/)
- [Booking System](./modules/booking/)
- [Room Management](./modules/rooms/)
- [Pricing & Inventory](./modules/pricing/)
- [Reporting](./modules/reporting/)

### Testing
- [Testing Guide](./TESTING_GUIDE.md)
- [Unit Tests](./testing/unit-tests/)
- [Integration Tests](../../database/tests/)

### Security
- [Security Audit](./security/audit.md)
- [Security Checklist](./security/checklist.md)

### Performance
- [Redis Caching](./caching/redis.md)
- [Database Optimization](../../database/docs/performance/)

## 📖 Module References

### Core Modules
- **Authentication:** JWT-based auth, role management
- **Booking:** Hold, confirm, cancel booking operations
- **Rooms:** Search, availability, room management
- **Pricing:** Dynamic pricing, rate tiers, calendar

### Manager Modules
- **Inventory:** Room inventory management
- **Policy & Voucher:** Cancellation policies, vouchers
- **Reporting:** Occupancy, revenue, analytics

### Staff Modules
- **Check-in/out:** Guest check-in and checkout
- **Housekeeping:** Room cleaning, inspection

### Background Jobs
- **Night Audit:** Daily room status updates
- **Hold Cleanup:** Expired booking hold cleanup

## 🔧 Setup & Configuration

### View API Documentation
```bash
# Setup Swagger UI
cd backend/docs
./setup-swagger-ui.sh  # or .bat on Windows

# Open in browser
# http://localhost:8080/swagger/
```

### Run Tests
```bash
cd backend

# Unit tests
go test ./...

# Specific module
go test ./internal/service/...

# With coverage
go test -cover ./...
```

## 📝 Documentation Standards

### Module Documentation Should Include:
1. **Overview:** Purpose and functionality
2. **API Endpoints:** Routes, methods, parameters
3. **Request/Response Examples:** Sample JSON
4. **Error Handling:** Error codes and messages
5. **Testing:** How to test the module
6. **Dependencies:** Related modules and services

### Code Documentation:
- Use GoDoc comments for all exported functions
- Include examples in comments where helpful
- Document complex business logic
- Keep comments up to date with code changes

## 🔗 Related Documentation

- [Frontend Documentation](../../frontend/docs/)
- [Database Documentation](../../database/docs/)
- [API Reference](../../docs/api/README.md)
- [User Guides](../../docs/user-guides/)

## 📞 Need Help?

1. Check [Quick Start Guide](../QUICK_START.md)
2. Review [Architecture](../ARCHITECTURE.md)
3. See [API Examples](./examples/)
4. Check [Testing Guide](./TESTING_GUIDE.md)

---

**Last Updated:** 2025-02-04  
**Backend Version:** 1.0.0  
**Go Version:** 1.21+
