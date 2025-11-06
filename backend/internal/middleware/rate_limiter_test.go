package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestRateLimiter(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("allows requests within limit", func(t *testing.T) {
		rl := NewRateLimiter(5, 1*time.Minute)
		router := gin.New()
		router.Use(rl.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "success"})
		})

		// Make 5 requests (should all succeed)
		for i := 0; i < 5; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.1:1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code, "Request %d should succeed", i+1)
		}
	})

	t.Run("blocks requests exceeding limit", func(t *testing.T) {
		rl := NewRateLimiter(5, 1*time.Minute)
		router := gin.New()
		router.Use(rl.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "success"})
		})

		// Make 6 requests (6th should fail)
		for i := 0; i < 6; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.1:1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if i < 5 {
				assert.Equal(t, http.StatusOK, w.Code, "Request %d should succeed", i+1)
			} else {
				assert.Equal(t, http.StatusTooManyRequests, w.Code, "Request %d should be rate limited", i+1)
			}
		}
	})

	t.Run("resets count after period", func(t *testing.T) {
		rl := NewRateLimiter(2, 100*time.Millisecond)
		router := gin.New()
		router.Use(rl.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "success"})
		})

		// Make 2 requests
		for i := 0; i < 2; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.1:1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)
			assert.Equal(t, http.StatusOK, w.Code)
		}

		// 3rd request should fail
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.1:1234"
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusTooManyRequests, w.Code)

		// Wait for period to pass
		time.Sleep(150 * time.Millisecond)

		// Should succeed again
		req = httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.1:1234"
		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)
	})

	t.Run("tracks different IPs separately", func(t *testing.T) {
		rl := NewRateLimiter(2, 1*time.Minute)
		router := gin.New()
		router.Use(rl.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "success"})
		})

		// IP 1: Make 2 requests
		for i := 0; i < 2; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.1:1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)
			assert.Equal(t, http.StatusOK, w.Code)
		}

		// IP 1: 3rd request should fail
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.1:1234"
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusTooManyRequests, w.Code)

		// IP 2: Should still work
		req = httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.2:1234"
		w = httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)
	})

	t.Run("tracks authenticated users by user ID", func(t *testing.T) {
		rl := NewRateLimiter(2, 1*time.Minute)
		router := gin.New()
		router.Use(func(c *gin.Context) {
			// Simulate authenticated user
			c.Set("user_id", 123)
			c.Next()
		})
		router.Use(rl.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "success"})
		})

		// Make 2 requests from same user (different IPs)
		for i := 0; i < 2; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1." + string(rune(i+1)) + ":1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)
			assert.Equal(t, http.StatusOK, w.Code)
		}

		// 3rd request should fail (same user, different IP)
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.99:1234"
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusTooManyRequests, w.Code)
	})
}

func TestPredefinedRateLimiters(t *testing.T) {
	t.Run("AuthRateLimiter has correct limits", func(t *testing.T) {
		assert.Equal(t, 5, AuthRateLimiter.rate)
		assert.Equal(t, 1*time.Minute, AuthRateLimiter.period)
	})

	t.Run("SearchRateLimiter has correct limits", func(t *testing.T) {
		assert.Equal(t, 30, SearchRateLimiter.rate)
		assert.Equal(t, 1*time.Minute, SearchRateLimiter.period)
	})

	t.Run("BookingRateLimiter has correct limits", func(t *testing.T) {
		assert.Equal(t, 10, BookingRateLimiter.rate)
		assert.Equal(t, 1*time.Minute, BookingRateLimiter.period)
	})

	t.Run("GeneralRateLimiter has correct limits", func(t *testing.T) {
		assert.Equal(t, 100, GeneralRateLimiter.rate)
		assert.Equal(t, 1*time.Minute, GeneralRateLimiter.period)
	})
}
