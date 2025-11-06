# Task 44: Redis Caching - Quick Start Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Install Redis Client (1 minute)

**Windows:**
```bash
cd backend
install_redis.bat
```

**Linux/Mac:**
```bash
cd backend
chmod +x install_redis.sh
./install_redis.sh
```

### Step 2: Start Redis (1 minute)

```bash
# Start Redis with Docker Compose
docker-compose up -d redis

# Verify Redis is running
docker exec hotel-booking-redis redis-cli ping
# Expected output: PONG
```

### Step 3: Configure Environment (30 seconds)

The `.env` file should already have:
```bash
REDIS_URL=localhost:6379
```

For Docker deployment, it's already configured as `redis:6379` in docker-compose.yml.

### Step 4: Start Backend (1 minute)

```bash
cd backend
go run cmd/server/main.go
```

Look for this log message:
```
Redis cache connection established
```

### Step 5: Test Caching (2 minutes)

**Test 1: Cache Miss (First Request)**
```bash
curl http://localhost:8080/api/rooms/types
```

**Test 2: Cache Hit (Second Request - Should be faster)**
```bash
curl http://localhost:8080/api/rooms/types
```

**Verify Cache:**
```bash
# Check if data is cached
docker exec hotel-booking-redis redis-cli GET room_types:all

# View all cache keys
docker exec hotel-booking-redis redis-cli KEYS "*"
```

---

## ✅ Verification

Run the test script:

**Windows:**
```bash
cd backend
./test_redis_caching.ps1
```

**Linux/Mac:**
```bash
cd backend
chmod +x test_redis_caching.sh
./test_redis_caching.sh
```

Expected output:
- ✓ Redis is responding
- ✓ Cache unit tests passed
- ✓ Performance improvement visible

---

## 📊 Monitor Cache Performance

### View Cache Keys
```bash
docker exec hotel-booking-redis redis-cli KEYS "*"
```

### Monitor Real-time
```bash
docker exec -it hotel-booking-redis redis-cli MONITOR
```

### Check Statistics
```bash
docker exec hotel-booking-redis redis-cli INFO stats
```

Look for:
- `keyspace_hits` - Number of successful cache lookups
- `keyspace_misses` - Number of cache misses
- Hit rate = hits / (hits + misses)

### Check Memory Usage
```bash
docker exec hotel-booking-redis redis-cli INFO memory
```

---

## 🎯 What's Cached

| Data | Cache Key | TTL | Why |
|------|-----------|-----|-----|
| All Room Types | `room_types:all` | 24h | Rarely changes, frequently accessed |
| Specific Room Type | `room_type:{id}` | 24h | Rarely changes, frequently accessed |
| Pricing Calendar | `pricing_calendar:{start}:{end}` | 6h | Changes occasionally |
| Rate Tiers | `rate_tiers:all` | 24h | Rarely changes |

---

## 🔧 Common Commands

### Clear All Cache
```bash
docker exec hotel-booking-redis redis-cli FLUSHALL
```

### Clear Specific Key
```bash
docker exec hotel-booking-redis redis-cli DEL room_types:all
```

### Check if Key Exists
```bash
docker exec hotel-booking-redis redis-cli EXISTS room_types:all
```

### Check TTL (Time To Live)
```bash
docker exec hotel-booking-redis redis-cli TTL room_types:all
```

### Get Key Value
```bash
docker exec hotel-booking-redis redis-cli GET room_types:all
```

---

## 🐛 Troubleshooting

### Redis Not Starting
```bash
# Check logs
docker logs hotel-booking-redis

# Restart Redis
docker-compose restart redis
```

### Backend Can't Connect to Redis
```bash
# Check REDIS_URL in .env
cat backend/.env | grep REDIS_URL

# Test connection
docker exec hotel-booking-redis redis-cli ping
```

### Cache Not Working
```bash
# Check if Redis is running
docker ps | grep redis

# Check backend logs for Redis connection message
# Should see: "Redis cache connection established"

# Verify cache keys exist
docker exec hotel-booking-redis redis-cli KEYS "*"
```

---

## 📈 Performance Comparison

### Before Caching
```bash
# Clear cache
docker exec hotel-booking-redis redis-cli FLUSHALL

# Make request and measure time
time curl http://localhost:8080/api/rooms/types
```

### After Caching
```bash
# Make same request again (cache hit)
time curl http://localhost:8080/api/rooms/types
```

Expected: 50-95% faster response time

---

## 🎓 Next Steps

1. **Read Full Guide**: `TASK_44_REDIS_CACHING_GUIDE.md`
2. **Run Verification**: `TASK_44_VERIFICATION_CHECKLIST.md`
3. **Review Implementation**: `TASK_44_COMPLETION_SUMMARY.md`

---

## 💡 Tips

- Cache is optional - system works without it
- Monitor cache hit rate to ensure effectiveness
- Adjust TTL values based on your data change frequency
- Use `MONITOR` command to debug cache behavior
- Clear cache after major data updates

---

## 🎉 Success!

If you see:
- ✅ Redis responding to PING
- ✅ Backend logs "Redis cache connection established"
- ✅ Cache keys visible in Redis
- ✅ Faster response times on second request

**You're all set!** Redis caching is working correctly.

---

## 📞 Need Help?

Check these files:
- `TASK_44_REDIS_CACHING_GUIDE.md` - Detailed implementation guide
- `TASK_44_VERIFICATION_CHECKLIST.md` - Complete testing procedures
- `TASK_44_COMPLETION_SUMMARY.md` - Implementation summary

Or run the test script:
```bash
cd backend
./test_redis_caching.ps1  # Windows
./test_redis_caching.sh   # Linux/Mac
```
