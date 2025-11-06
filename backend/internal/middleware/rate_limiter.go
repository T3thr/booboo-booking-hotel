package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// RateLimiter implements a simple in-memory rate limiter
// For production, consider using Redis-based rate limiting

type visitor struct {
	lastSeen time.Time
	count    int
}

type RateLimiter struct {
	visitors map[string]*visitor
	mu       sync.RWMutex
	rate     int           // requests per period
	period   time.Duration // time period
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(rate int, period time.Duration) *RateLimiter {
	rl := &RateLimiter{
		visitors: make(map[string]*visitor),
		rate:     rate,
		period:   period,
	}

	// Cleanup old visitors every minute
	go rl.cleanupVisitors()

	return rl
}

// Middleware returns a Gin middleware handler
func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get identifier (IP address or user ID)
		identifier := rl.getIdentifier(c)

		if !rl.allow(identifier) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":   "Rate limit exceeded",
				"message": "Too many requests. Please try again later.",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// getIdentifier returns a unique identifier for rate limiting
func (rl *RateLimiter) getIdentifier(c *gin.Context) string {
	// Try to get user ID from context (if authenticated)
	if userID, exists := c.Get("user_id"); exists {
		return "user:" + string(rune(userID.(int)))
	}

	// Fall back to IP address
	return "ip:" + c.ClientIP()
}

// allow checks if the request should be allowed
func (rl *RateLimiter) allow(identifier string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()

	v, exists := rl.visitors[identifier]
	if !exists {
		rl.visitors[identifier] = &visitor{
			lastSeen: now,
			count:    1,
		}
		return true
	}

	// Reset count if period has passed
	if now.Sub(v.lastSeen) > rl.period {
		v.count = 1
		v.lastSeen = now
		return true
	}

	// Check if limit exceeded
	if v.count >= rl.rate {
		return false
	}

	// Increment count
	v.count++
	v.lastSeen = now
	return true
}

// cleanupVisitors removes old visitors from memory
func (rl *RateLimiter) cleanupVisitors() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()
		now := time.Now()
		for id, v := range rl.visitors {
			if now.Sub(v.lastSeen) > rl.period*2 {
				delete(rl.visitors, id)
			}
		}
		rl.mu.Unlock()
	}
}

// Predefined rate limiters for different endpoint types
var (
	// AuthRateLimiter - 5 requests per minute for auth endpoints
	AuthRateLimiter = NewRateLimiter(5, 1*time.Minute)

	// SearchRateLimiter - 30 requests per minute for search endpoints
	SearchRateLimiter = NewRateLimiter(30, 1*time.Minute)

	// BookingRateLimiter - 10 requests per minute for booking creation
	BookingRateLimiter = NewRateLimiter(10, 1*time.Minute)

	// GeneralRateLimiter - 100 requests per minute for general API
	GeneralRateLimiter = NewRateLimiter(100, 1*time.Minute)
)
