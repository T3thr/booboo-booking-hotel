package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestCORS(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name                  string
		allowedOrigins        []string
		requestOrigin         string
		requestMethod         string
		expectedStatus        int
		expectCORSHeaders     bool
		expectedAllowedOrigin string
	}{
		{
			name:                  "Allowed origin - exact match",
			allowedOrigins:        []string{"http://localhost:3000"},
			requestOrigin:         "http://localhost:3000",
			requestMethod:         "GET",
			expectedStatus:        http.StatusOK,
			expectCORSHeaders:     true,
			expectedAllowedOrigin: "http://localhost:3000",
		},
		{
			name:                  "Allowed origin - wildcard",
			allowedOrigins:        []string{"*"},
			requestOrigin:         "http://example.com",
			requestMethod:         "GET",
			expectedStatus:        http.StatusOK,
			expectCORSHeaders:     true,
			expectedAllowedOrigin: "http://example.com",
		},
		{
			name:              "Not allowed origin",
			allowedOrigins:    []string{"http://localhost:3000"},
			requestOrigin:     "http://evil.com",
			requestMethod:     "GET",
			expectedStatus:    http.StatusOK,
			expectCORSHeaders: false,
		},
		{
			name:                  "Multiple allowed origins - first match",
			allowedOrigins:        []string{"http://localhost:3000", "http://localhost:4000"},
			requestOrigin:         "http://localhost:3000",
			requestMethod:         "GET",
			expectedStatus:        http.StatusOK,
			expectCORSHeaders:     true,
			expectedAllowedOrigin: "http://localhost:3000",
		},
		{
			name:                  "Multiple allowed origins - second match",
			allowedOrigins:        []string{"http://localhost:3000", "http://localhost:4000"},
			requestOrigin:         "http://localhost:4000",
			requestMethod:         "GET",
			expectedStatus:        http.StatusOK,
			expectCORSHeaders:     true,
			expectedAllowedOrigin: "http://localhost:4000",
		},
		{
			name:                  "OPTIONS preflight request",
			allowedOrigins:        []string{"http://localhost:3000"},
			requestOrigin:         "http://localhost:3000",
			requestMethod:         "OPTIONS",
			expectedStatus:        http.StatusNoContent,
			expectCORSHeaders:     true,
			expectedAllowedOrigin: "http://localhost:3000",
		},
		{
			name:                  "No origin header - use first allowed",
			allowedOrigins:        []string{"http://localhost:3000"},
			requestOrigin:         "",
			requestMethod:         "GET",
			expectedStatus:        http.StatusOK,
			expectCORSHeaders:     true,
			expectedAllowedOrigin: "http://localhost:3000",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			w := httptest.NewRecorder()
			c, r := gin.CreateTestContext(w)

			// Apply CORS middleware
			r.Use(CORS(tt.allowedOrigins))
			r.GET("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"success": true})
			})
			r.OPTIONS("/test", func(c *gin.Context) {
				c.Status(http.StatusNoContent)
			})

			// Create request
			req, _ := http.NewRequest(tt.requestMethod, "/test", nil)
			if tt.requestOrigin != "" {
				req.Header.Set("Origin", tt.requestOrigin)
			}

			// Execute
			r.ServeHTTP(w, req)

			// Assert status
			assert.Equal(t, tt.expectedStatus, w.Code)

			// Assert CORS headers
			if tt.expectCORSHeaders {
				assert.Equal(t, tt.expectedAllowedOrigin, w.Header().Get("Access-Control-Allow-Origin"))
				assert.Equal(t, "true", w.Header().Get("Access-Control-Allow-Credentials"))
				assert.NotEmpty(t, w.Header().Get("Access-Control-Allow-Headers"))
				assert.NotEmpty(t, w.Header().Get("Access-Control-Allow-Methods"))
			} else {
				assert.Empty(t, w.Header().Get("Access-Control-Allow-Origin"))
			}
		})
	}
}

func TestCORS_AllowedMethods(t *testing.T) {
	gin.SetMode(gin.TestMode)

	methods := []string{"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"}

	for _, method := range methods {
		t.Run("Method: "+method, func(t *testing.T) {
			// Setup
			w := httptest.NewRecorder()
			c, r := gin.CreateTestContext(w)

			// Apply CORS middleware
			r.Use(CORS([]string{"http://localhost:3000"}))
			
			// Register handlers for all methods
			r.GET("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"method": "GET"})
			})
			r.POST("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"method": "POST"})
			})
			r.PUT("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"method": "PUT"})
			})
			r.DELETE("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"method": "DELETE"})
			})
			r.PATCH("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"method": "PATCH"})
			})
			r.OPTIONS("/test", func(c *gin.Context) {
				c.Status(http.StatusNoContent)
			})

			// Create request
			req, _ := http.NewRequest(method, "/test", nil)
			req.Header.Set("Origin", "http://localhost:3000")

			// Execute
			r.ServeHTTP(w, req)

			// Assert CORS headers are present
			assert.Equal(t, "http://localhost:3000", w.Header().Get("Access-Control-Allow-Origin"))
			
			// Check that allowed methods include the current method
			allowedMethods := w.Header().Get("Access-Control-Allow-Methods")
			assert.Contains(t, allowedMethods, method)
		})
	}
}

func TestCORS_AllowedHeaders(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup
	w := httptest.NewRecorder()
	c, r := gin.CreateTestContext(w)

	// Apply CORS middleware
	r.Use(CORS([]string{"http://localhost:3000"}))
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"success": true})
	})

	// Create request
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Origin", "http://localhost:3000")

	// Execute
	r.ServeHTTP(w, req)

	// Assert allowed headers
	allowedHeaders := w.Header().Get("Access-Control-Allow-Headers")
	assert.Contains(t, allowedHeaders, "Content-Type")
	assert.Contains(t, allowedHeaders, "Authorization")
	assert.Contains(t, allowedHeaders, "X-Requested-With")
}

func TestCORS_EmptyAllowedOrigins(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup
	w := httptest.NewRecorder()
	c, r := gin.CreateTestContext(w)

	// Apply CORS middleware with empty origins
	r.Use(CORS([]string{}))
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"success": true})
	})

	// Create request
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Origin", "http://localhost:3000")

	// Execute
	r.ServeHTTP(w, req)

	// Assert no CORS headers
	assert.Empty(t, w.Header().Get("Access-Control-Allow-Origin"))
}
