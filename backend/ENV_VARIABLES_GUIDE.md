# 🔐 Environment Variables Guide

Complete reference for all environment variables used in the Go backend.

---

## 📋 Table of Contents

1. [Quick Reference](#quick-reference)
2. [Server Configuration](#server-configuration)
3. [Database Configuration](#database-configuration)
4. [Authentication](#authentication)
5. [CORS Configuration](#cors-configuration)
6. [Redis Cache](#redis-cache)
7. [Rate Limiting](#rate-limiting)
8. [Logging](#logging)
9. [Background Jobs](#background-jobs)
10. [Monitoring](#monitoring)
11. [Email Configuration](#email-configuration)
12. [Error Tracking](#error-tracking)

---

## 🎯 Quick Reference

### Local Development
```bash
cp .env.local.example .env
```

### Production
Add these to Vercel Environment Variables (copy from `.env.production.example`)

---

## 🖥️ Server Configuration

### `PORT`
- **Description**: Server port number
- **Type**: Integer
- **Default**: `8080`
- **Local**: `8080`
- **Production**: `8080`
- **Required**: Yes

```bash
PORT=8080
```

### `GIN_MODE`
- **Description**: Gin framework mode
- **Type**: String
- **Options**: `debug`, `release`, `test`
- **Local**: `debug`
- **Production**: `release`
- **Required**: Yes

```bash
# Local
GIN_MODE=debug

# Production
GIN_MODE=release
```

### `ENVIRONMENT`
- **Description**: Application environment
- **Type**: String
- **Options**: `development`, `production`, `staging`
- **Local**: `development`
- **Production**: `production`
- **Required**: Yes

```bash
# Local
ENVIRONMENT=development

# Production
ENVIRONMENT=production
```

---

## 🗄️ Database Configuration

### Neon PostgreSQL Connection

#### `DB_HOST`
- **Description**: Database host
- **Type**: String
- **Local**: Direct connection endpoint
- **Production**: Pooled connection endpoint (with `-pooler`)
- **Required**: Yes

```bash
# Local (Direct Connection)
DB_HOST=ep-xxx-xxx.region.aws.neon.tech

# Production (Pooled Connection)
DB_HOST=ep-xxx-xxx-pooler.region.aws.neon.tech
```

#### `DB_PORT`
- **Description**: Database port
- **Type**: Integer
- **Default**: `5432`
- **Required**: Yes

```bash
DB_PORT=5432
```

#### `DB_USER`
- **Description**: Database username
- **Type**: String
- **Required**: Yes
- **Get from**: Neon Console → Connection Details

```bash
DB_USER=your_neon_username
```

#### `DB_PASSWORD`
- **Description**: Database password
- **Type**: String
- **Required**: Yes
- **Get from**: Neon Console → Connection Details

```bash
DB_PASSWORD=your_neon_password
```

#### `DB_NAME`
- **Description**: Database name
- **Type**: String
- **Default**: `neondb`
- **Required**: Yes

```bash
DB_NAME=neondb
```

#### `DB_SSLMODE`
- **Description**: SSL mode for database connection
- **Type**: String
- **Options**: `disable`, `require`, `verify-ca`, `verify-full`
- **Local**: `require`
- **Production**: `require`
- **Required**: Yes

```bash
DB_SSLMODE=require
```

#### `DATABASE_URL`
- **Description**: Full database connection string
- **Type**: String
- **Format**: `postgresql://[user]:[password]@[host]/[database]?sslmode=require`
- **Required**: No (if individual DB_* variables are set)

```bash
# Local (Direct Connection)
DATABASE_URL=postgresql://user:pass@ep-xxx.region.aws.neon.tech/neondb?sslmode=require

# Production (Pooled Connection)
DATABASE_URL=postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
```

### Connection Pool Settings

#### `DB_MAX_OPEN_CONNS`
- **Description**: Maximum number of open connections
- **Type**: Integer
- **Local**: `10`
- **Production**: `25`
- **Required**: No

```bash
# Local
DB_MAX_OPEN_CONNS=10

# Production
DB_MAX_OPEN_CONNS=25
```

#### `DB_MAX_IDLE_CONNS`
- **Description**: Maximum number of idle connections
- **Type**: Integer
- **Local**: `5`
- **Production**: `10`
- **Required**: No

```bash
# Local
DB_MAX_IDLE_CONNS=5

# Production
DB_MAX_IDLE_CONNS=10
```

#### `DB_CONN_MAX_LIFETIME`
- **Description**: Maximum lifetime of a connection
- **Type**: Duration
- **Local**: `5m`
- **Production**: `10m`
- **Required**: No

```bash
# Local
DB_CONN_MAX_LIFETIME=5m

# Production
DB_CONN_MAX_LIFETIME=10m
```

---

## 🔐 Authentication

### `JWT_SECRET`
- **Description**: Secret key for JWT token signing
- **Type**: String
- **Minimum Length**: 32 characters
- **Required**: Yes
- **Generate**: `openssl rand -base64 32`

```bash
# Local (can be simple for testing)
JWT_SECRET=local-development-secret-key-change-in-production

# Production (MUST be strong)
JWT_SECRET=your-generated-secret-minimum-32-characters
```

⚠️ **IMPORTANT**: 
- Generate a new secret for production
- Never commit the actual secret to git
- Use at least 32 characters

### `JWT_EXPIRATION`
- **Description**: JWT token expiration time
- **Type**: Duration
- **Default**: `24h`
- **Required**: No

```bash
JWT_EXPIRATION=24h
```

---

## 🌐 CORS Configuration

### `FRONTEND_URL`
- **Description**: Primary frontend URL
- **Type**: String
- **Local**: `http://localhost:3000`
- **Production**: Your Vercel frontend URL
- **Required**: Yes

```bash
# Local
FRONTEND_URL=http://localhost:3000

# Production
FRONTEND_URL=https://your-frontend.vercel.app
```

### `ALLOWED_ORIGINS`
- **Description**: Comma-separated list of allowed origins
- **Type**: String (comma-separated)
- **Local**: All localhost variants
- **Production**: All production domains
- **Required**: Yes

```bash
# Local
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000

# Production
ALLOWED_ORIGINS=https://your-frontend.vercel.app,https://www.your-domain.com
```

---

## 🔴 Redis Cache

### `REDIS_URL`
- **Description**: Redis connection URL
- **Type**: String
- **Format**: `redis://[password]@[host]:[port]/[db]`
- **Required**: No (optional feature)
- **Recommended**: Upstash Redis for production

```bash
# Local (optional)
REDIS_URL=

# Production (Upstash)
REDIS_URL=redis://default:password@us1-xxx.upstash.io:6379
```

**Note**: System works without Redis. Leave empty to disable caching.

---

## 🚦 Rate Limiting

### `RATE_LIMIT_ENABLED`
- **Description**: Enable/disable rate limiting
- **Type**: Boolean
- **Local**: `false`
- **Production**: `true`
- **Required**: No

```bash
# Local
RATE_LIMIT_ENABLED=false

# Production
RATE_LIMIT_ENABLED=true
```

### `RATE_LIMIT_REQUESTS`
- **Description**: Maximum requests per window
- **Type**: Integer
- **Local**: `1000`
- **Production**: `1000`
- **Required**: No

```bash
RATE_LIMIT_REQUESTS=1000
```

### `RATE_LIMIT_WINDOW`
- **Description**: Time window for rate limiting
- **Type**: Duration
- **Default**: `1m`
- **Required**: No

```bash
RATE_LIMIT_WINDOW=1m
```

---

## 📝 Logging

### `LOG_LEVEL`
- **Description**: Logging level
- **Type**: String
- **Options**: `debug`, `info`, `warn`, `error`
- **Local**: `debug`
- **Production**: `warn`
- **Required**: No

```bash
# Local (verbose)
LOG_LEVEL=debug

# Production (minimal)
LOG_LEVEL=warn
```

### `LOG_FORMAT`
- **Description**: Log output format
- **Type**: String
- **Options**: `text`, `json`
- **Local**: `text`
- **Production**: `json`
- **Required**: No

```bash
# Local (human-readable)
LOG_FORMAT=text

# Production (structured)
LOG_FORMAT=json
```

---

## ⏰ Background Jobs

### Night Audit Job

#### `NIGHT_AUDIT_ENABLED`
- **Description**: Enable/disable night audit job
- **Type**: Boolean
- **Local**: `false` (recommended)
- **Production**: `true`
- **Required**: No

```bash
# Local
NIGHT_AUDIT_ENABLED=false

# Production
NIGHT_AUDIT_ENABLED=true
```

#### `NIGHT_AUDIT_TIME`
- **Description**: Time to run night audit (24-hour format)
- **Type**: String (HH:MM)
- **Default**: `00:00`
- **Required**: No

```bash
NIGHT_AUDIT_TIME=00:00
```

### Hold Cleanup Job

#### `HOLD_CLEANUP_ENABLED`
- **Description**: Enable/disable hold cleanup job
- **Type**: Boolean
- **Local**: `true`
- **Production**: `true`
- **Required**: No

```bash
HOLD_CLEANUP_ENABLED=true
```

#### `HOLD_CLEANUP_INTERVAL`
- **Description**: How often to run cleanup
- **Type**: Duration
- **Default**: `5m`
- **Required**: No

```bash
HOLD_CLEANUP_INTERVAL=5m
```

#### `HOLD_TIMEOUT`
- **Description**: How long before holds expire
- **Type**: Duration
- **Default**: `15m`
- **Required**: No

```bash
HOLD_TIMEOUT=15m
```

---

## 📊 Monitoring

### `ENABLE_METRICS`
- **Description**: Enable/disable metrics collection
- **Type**: Boolean
- **Local**: `false`
- **Production**: `true`
- **Required**: No

```bash
# Local
ENABLE_METRICS=false

# Production
ENABLE_METRICS=true
```

### `HEALTH_CHECK_PATH`
- **Description**: Health check endpoint path
- **Type**: String
- **Default**: `/health`
- **Required**: No

```bash
HEALTH_CHECK_PATH=/health
```

---

## 📧 Email Configuration

### `SMTP_HOST`
- **Description**: SMTP server host
- **Type**: String
- **Required**: No (optional feature)

```bash
SMTP_HOST=smtp.gmail.com
```

### `SMTP_PORT`
- **Description**: SMTP server port
- **Type**: Integer
- **Default**: `587`
- **Required**: No

```bash
SMTP_PORT=587
```

### `SMTP_USER`
- **Description**: SMTP username
- **Type**: String
- **Required**: No

```bash
SMTP_USER=your-email@gmail.com
```

### `SMTP_PASSWORD`
- **Description**: SMTP password or app password
- **Type**: String
- **Required**: No

```bash
SMTP_PASSWORD=your-app-password
```

### `SMTP_FROM`
- **Description**: Default sender email
- **Type**: String
- **Required**: No

```bash
SMTP_FROM=noreply@yourdomain.com
```

### `SMTP_TLS`
- **Description**: Enable TLS for SMTP
- **Type**: Boolean
- **Default**: `true`
- **Required**: No

```bash
SMTP_TLS=true
```

---

## 🐛 Error Tracking

### `SENTRY_DSN`
- **Description**: Sentry DSN for error tracking
- **Type**: String
- **Required**: No (optional feature)
- **Get from**: Sentry.io project settings

```bash
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
```

### `SENTRY_ENVIRONMENT`
- **Description**: Environment name for Sentry
- **Type**: String
- **Local**: `development`
- **Production**: `production`
- **Required**: No

```bash
# Local
SENTRY_ENVIRONMENT=development

# Production
SENTRY_ENVIRONMENT=production
```

---

## 📝 Complete Examples

### Local Development (`.env`)

```bash
# Server
PORT=8080
GIN_MODE=debug
ENVIRONMENT=development

# Database (Neon Direct Connection)
DB_HOST=ep-xxx-xxx.region.aws.neon.tech
DB_PORT=5432
DB_USER=your_neon_username
DB_PASSWORD=your_neon_password
DB_NAME=neondb
DB_SSLMODE=require
DATABASE_URL=postgresql://user:pass@ep-xxx.region.aws.neon.tech/neondb?sslmode=require

# JWT
JWT_SECRET=local-development-secret-key-change-in-production
JWT_EXPIRATION=24h

# CORS
FRONTEND_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001

# Redis (optional)
REDIS_URL=

# Rate Limiting (disabled)
RATE_LIMIT_ENABLED=false

# Logging (verbose)
LOG_LEVEL=debug
LOG_FORMAT=text

# Jobs (disabled for local)
NIGHT_AUDIT_ENABLED=false
HOLD_CLEANUP_ENABLED=true
```

### Production (Vercel Environment Variables)

```bash
# Server
PORT=8080
GIN_MODE=release
ENVIRONMENT=production

# Database (Neon Pooled Connection)
DB_HOST=ep-xxx-xxx-pooler.region.aws.neon.tech
DB_PORT=5432
DB_USER=your_neon_username
DB_PASSWORD=your_neon_password
DB_NAME=neondb
DB_SSLMODE=require
DATABASE_URL=postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=10

# JWT (STRONG SECRET!)
JWT_SECRET=your-generated-secret-minimum-32-characters
JWT_EXPIRATION=24h

# CORS (YOUR DOMAIN!)
FRONTEND_URL=https://your-frontend.vercel.app
ALLOWED_ORIGINS=https://your-frontend.vercel.app

# Redis (Upstash)
REDIS_URL=redis://default:password@upstash.io:6379

# Rate Limiting (enabled)
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=1000

# Logging (minimal)
LOG_LEVEL=warn
LOG_FORMAT=json

# Jobs (enabled)
NIGHT_AUDIT_ENABLED=true
HOLD_CLEANUP_ENABLED=true
```

---

## ✅ Validation Checklist

Before deploying, verify:

- [ ] All required variables are set
- [ ] JWT_SECRET is at least 32 characters
- [ ] Database connection string is correct
- [ ] Using **pooled** connection for production
- [ ] FRONTEND_URL matches your actual domain
- [ ] ALLOWED_ORIGINS includes all frontend URLs
- [ ] GIN_MODE is `release` for production
- [ ] LOG_LEVEL is `warn` or `error` for production
- [ ] Sensitive values are not committed to git

---

## 🔒 Security Best Practices

1. **Never commit `.env` files** - They're in `.gitignore`
2. **Use strong JWT secrets** - Minimum 32 characters
3. **Rotate secrets regularly** - Especially after team changes
4. **Use environment-specific secrets** - Different for local/production
5. **Enable rate limiting** - Protect against abuse
6. **Use HTTPS in production** - Always
7. **Restrict CORS origins** - Only allow your domains
8. **Use pooled connections** - For better performance and security

---

## 📚 Additional Resources

- [Neon PostgreSQL Docs](https://neon.tech/docs)
- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)
- [Gin Framework Configuration](https://gin-gonic.com/docs/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

**Need help? Check [PRODUCTION_SETUP_GUIDE.md](./PRODUCTION_SETUP_GUIDE.md) for detailed instructions.**
