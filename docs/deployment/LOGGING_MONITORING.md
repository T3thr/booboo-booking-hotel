# Logging and Monitoring Guide

This document describes the logging and monitoring setup for the Hotel Booking System in production.

## Table of Contents

1. [Logging Architecture](#logging-architecture)
2. [Log Locations](#log-locations)
3. [Log Formats](#log-formats)
4. [Monitoring Stack](#monitoring-stack)
5. [Metrics](#metrics)
6. [Alerts](#alerts)
7. [Log Analysis](#log-analysis)

## Logging Architecture

The system uses a structured logging approach with JSON format for easy parsing and analysis.

### Logging Levels

- **DEBUG**: Detailed information for debugging (development only)
- **INFO**: General informational messages
- **WARN**: Warning messages for potentially harmful situations
- **ERROR**: Error events that might still allow the application to continue
- **FATAL**: Severe errors that cause the application to abort

### Log Rotation

All logs are automatically rotated using Docker's JSON file logging driver:
- Maximum file size: 10MB (backend/frontend) or 5MB (other services)
- Maximum files: 3-5 files
- Older logs are automatically deleted

## Log Locations

### Backend Logs

```
logs/backend/
├── app.log          # Application logs
├── error.log        # Error logs
└── access.log       # API access logs
```

### Frontend Logs

```
logs/frontend/
├── app.log          # Next.js application logs
└── error.log        # Frontend errors
```

### Database Logs

```
logs/postgres/
├── postgresql.log   # PostgreSQL logs
└── queries.log      # Slow query logs
```

### Nginx Logs

```
logs/nginx/
├── access.log       # HTTP access logs
└── error.log        # Nginx errors
```

### Redis Logs

```
logs/redis/
└── redis.log        # Redis server logs
```

## Log Formats

### Backend (Go) Log Format

```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "info",
  "service": "backend",
  "message": "Request processed successfully",
  "request_id": "abc123",
  "method": "POST",
  "path": "/api/bookings",
  "status": 200,
  "duration_ms": 45,
  "user_id": 123,
  "ip": "192.168.1.1"
}
```

### Nginx Access Log Format

```
192.168.1.1 - - [15/Jan/2024:10:30:45 +0000] "POST /api/bookings HTTP/1.1" 200 1234 
"https://yourdomain.com" "Mozilla/5.0..." rt=0.045 uct="0.001" uht="0.002" urt="0.042"
```

### Database Log Format

```
2024-01-15 10:30:45 UTC [123]: [1-1] user=hotel_admin,db=hotel_booking 
LOG: duration: 12.345 ms statement: SELECT * FROM bookings WHERE guest_id = $1
```

## Monitoring Stack

### Components

1. **Prometheus**: Metrics collection and storage
2. **Grafana**: Visualization and dashboards
3. **Docker Logs**: Container log aggregation

### Access Points

- **Prometheus**: http://your-server:9091
- **Grafana**: http://your-server:3001

## Metrics

### Backend Metrics

The backend exposes metrics at `/metrics` endpoint (port 9090):

#### HTTP Metrics

```
# Request count by endpoint and status
http_requests_total{method="POST", endpoint="/api/bookings", status="200"} 1234

# Request duration histogram
http_request_duration_seconds_bucket{endpoint="/api/bookings", le="0.1"} 950
http_request_duration_seconds_bucket{endpoint="/api/bookings", le="0.5"} 1200
http_request_duration_seconds_bucket{endpoint="/api/bookings", le="1.0"} 1230

# Active requests
http_requests_in_flight{endpoint="/api/bookings"} 5
```

#### Database Metrics

```
# Database connection pool
db_connections_open 10
db_connections_idle 5
db_connections_in_use 5

# Query duration
db_query_duration_seconds{query="select_bookings"} 0.045

# Query errors
db_query_errors_total{query="select_bookings"} 2
```

#### Business Metrics

```
# Bookings
bookings_created_total 1234
bookings_confirmed_total 1100
bookings_cancelled_total 50

# Revenue
revenue_total_usd 125000.00

# Occupancy
rooms_occupied 45
rooms_available 55
occupancy_rate 0.45
```

### System Metrics

```
# CPU usage
node_cpu_seconds_total

# Memory usage
node_memory_MemAvailable_bytes
node_memory_MemTotal_bytes

# Disk usage
node_filesystem_avail_bytes
node_filesystem_size_bytes
```

## Alerts

### Critical Alerts

#### High Error Rate

```yaml
alert: HighErrorRate
expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
for: 5m
labels:
  severity: critical
annotations:
  summary: "High error rate detected"
  description: "Error rate is {{ $value }} errors/sec"
```

#### Database Down

```yaml
alert: DatabaseDown
expr: up{job="postgres"} == 0
for: 1m
labels:
  severity: critical
annotations:
  summary: "Database is down"
  description: "PostgreSQL database is not responding"
```

#### High Response Time

```yaml
alert: HighResponseTime
expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
for: 10m
labels:
  severity: warning
annotations:
  summary: "High API response time"
  description: "95th percentile response time is {{ $value }}s"
```

### Warning Alerts

#### High Memory Usage

```yaml
alert: HighMemoryUsage
expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.85
for: 10m
labels:
  severity: warning
annotations:
  summary: "High memory usage"
  description: "Memory usage is {{ $value | humanizePercentage }}"
```

#### Disk Space Low

```yaml
alert: DiskSpaceLow
expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.15
for: 10m
labels:
  severity: warning
annotations:
  summary: "Low disk space"
  description: "Only {{ $value | humanizePercentage }} disk space remaining"
```

## Log Analysis

### Viewing Logs

#### Real-time Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend

# Last 100 lines
docker-compose -f docker-compose.prod.yml logs --tail=100 backend
```

#### Search Logs

```bash
# Search for errors
docker-compose -f docker-compose.prod.yml logs backend | grep ERROR

# Search for specific request ID
docker-compose -f docker-compose.prod.yml logs backend | grep "request_id=abc123"

# Search in log files
grep "ERROR" logs/backend/app.log

# Search with context
grep -C 5 "ERROR" logs/backend/app.log
```

### Common Log Queries

#### Find Failed Bookings

```bash
grep "booking.*failed" logs/backend/app.log | jq '.'
```

#### Find Slow Queries

```bash
grep "duration.*ms" logs/postgres/postgresql.log | awk '$10 > 1000'
```

#### Find 5xx Errors

```bash
grep " 5[0-9][0-9] " logs/nginx/access.log
```

#### Count Requests by Endpoint

```bash
awk '{print $7}' logs/nginx/access.log | sort | uniq -c | sort -rn
```

### Log Aggregation (Optional)

For production environments with multiple servers, consider:

#### ELK Stack (Elasticsearch, Logstash, Kibana)

```yaml
# Add to docker-compose.prod.yml
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
  environment:
    - discovery.type=single-node
  volumes:
    - elasticsearch-data:/usr/share/elasticsearch/data

logstash:
  image: docker.elastic.co/logstash/logstash:8.11.0
  volumes:
    - ./logstash/pipeline:/usr/share/logstash/pipeline
    - ./logs:/logs:ro

kibana:
  image: docker.elastic.co/kibana/kibana:8.11.0
  ports:
    - "5601:5601"
  depends_on:
    - elasticsearch
```

#### Loki + Promtail (Lightweight Alternative)

```yaml
loki:
  image: grafana/loki:latest
  ports:
    - "3100:3100"
  volumes:
    - loki-data:/loki

promtail:
  image: grafana/promtail:latest
  volumes:
    - ./logs:/logs:ro
    - ./promtail-config.yml:/etc/promtail/config.yml
  command: -config.file=/etc/promtail/config.yml
```

## Monitoring Best Practices

### 1. Set Up Dashboards

Create Grafana dashboards for:
- System overview (CPU, memory, disk)
- Application metrics (requests, errors, latency)
- Business metrics (bookings, revenue, occupancy)
- Database performance

### 2. Configure Alerts

Set up alerts for:
- Service downtime
- High error rates
- Performance degradation
- Resource exhaustion
- Security events

### 3. Regular Review

- Review logs daily for errors
- Check metrics weekly for trends
- Analyze performance monthly
- Update alert thresholds as needed

### 4. Retention Policy

- Keep detailed logs for 7 days
- Keep aggregated metrics for 30 days
- Archive important logs for 1 year
- Delete old logs automatically

## Troubleshooting with Logs

### Application Crashes

```bash
# Check for panic/fatal errors
docker-compose -f docker-compose.prod.yml logs backend | grep -i "fatal\|panic"

# Check exit codes
docker-compose -f docker-compose.prod.yml ps
```

### Performance Issues

```bash
# Find slow requests
docker-compose -f docker-compose.prod.yml logs backend | jq 'select(.duration_ms > 1000)'

# Check database slow queries
grep "duration:" logs/postgres/postgresql.log | awk '$10 > 1000'
```

### Authentication Issues

```bash
# Check auth failures
docker-compose -f docker-compose.prod.yml logs backend | grep "auth.*failed"

# Check JWT errors
docker-compose -f docker-compose.prod.yml logs backend | grep "jwt\|token"
```

### Database Issues

```bash
# Check connection errors
docker-compose -f docker-compose.prod.yml logs backend | grep "database.*error"

# Check deadlocks
grep "deadlock" logs/postgres/postgresql.log
```

## Security Monitoring

### Failed Login Attempts

```bash
# Monitor failed logins
docker-compose -f docker-compose.prod.yml logs backend | grep "login.*failed" | wc -l

# Check for brute force attempts
docker-compose -f docker-compose.prod.yml logs backend | grep "login.*failed" | awk '{print $NF}' | sort | uniq -c | sort -rn
```

### Suspicious Activity

```bash
# Check for SQL injection attempts
grep -i "select\|union\|drop\|insert" logs/nginx/access.log

# Check for XSS attempts
grep -i "script\|javascript:" logs/nginx/access.log
```

## Performance Monitoring

### Response Time Analysis

```bash
# Average response time
awk '{sum+=$NF; count++} END {print sum/count}' logs/nginx/access.log

# 95th percentile
awk '{print $NF}' logs/nginx/access.log | sort -n | awk 'BEGIN{c=0} {a[c]=$1; c++} END{print a[int(c*0.95)]}'
```

### Request Rate

```bash
# Requests per minute
awk '{print $4}' logs/nginx/access.log | cut -d: -f1-2 | uniq -c
```

## Conclusion

Proper logging and monitoring are essential for:
- Detecting and diagnosing issues quickly
- Understanding system behavior
- Optimizing performance
- Ensuring security
- Meeting SLAs

Regular review and analysis of logs and metrics will help maintain a healthy production system.
