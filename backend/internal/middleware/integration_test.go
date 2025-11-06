package middleware

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/pkg/utils"
	"github.com/stretchr/testify/assert"
)

// TestProtectedRoutes tests the complete authentication flow with protected routes
func TestProtectedRoutes(t *testing.T) {
	gin.SetMode(gin.TestMode)
	jwtSecret := "test-secret-key"

	tests := []struct {
		name           string
		setupAuth      func() string
		requiredRoles  []string
		userRole       string
		expectedStatus int
		shouldPass     bool
	}{
		{
			name: "Guest accessing guest route",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "guest@example.com", "guest", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"guest"},
			userRole:       "guest",
			expectedStatus: http.StatusOK,
			shouldPass:     true,
		},
		{
			name: "Receptionist accessing receptionist route",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(2, "receptionist@example.com", "receptionist", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"receptionist"},
			userRole:       "receptionist",
			expectedStatus: http.StatusOK,
			shouldPass:     true,
		},
		{
			name: "Manager accessing manager route",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(3, "manager@example.com", "manager", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"manager"},
			userRole:       "manager",
			expectedStatus: http.StatusOK,
			shouldPass:     true,
		},
		{
			name: "Housekeeper accessing housekeeper route",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(4, "housekeeper@example.com", "housekeeper", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"housekeeper"},
			userRole:       "housekeeper",
			expectedStatus: http.StatusOK,
			shouldPass:     true,
		},
		{
			name: "Guest trying to access manager route",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "guest@example.com", "guest", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"manager"},
			userRole:       "guest",
			expectedStatus: http.StatusForbidden,
			shouldPass:     false,
		},
		{
			name: "Receptionist accessing multi-role route (receptionist or manager)",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(2, "receptionist@example.com", "receptionist", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"receptionist", "manager"},
			userRole:       "receptionist",
			expectedStatus: http.StatusOK,
			shouldPass:     true,
		},
		{
			name: "Manager accessing multi-role route (receptionist or manager)",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(3, "manager@example.com", "manager", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"receptionist", "manager"},
			userRole:       "manager",
			expectedStatus: http.StatusOK,
			shouldPass:     true,
		},
		{
			name: "Guest trying to access multi-role route (receptionist or manager)",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "guest@example.com", "guest", jwtSecret)
				return "Bearer " + token
			},
			requiredRoles:  []string{"receptionist", "manager"},
			userRole:       "guest",
			expectedStatus: http.StatusForbidden,
			shouldPass:     false,
		},
		{
			name: "No token provided",
			setupAuth: func() string {
				return ""
			},
			requiredRoles:  []string{"guest"},
			userRole:       "",
			expectedStatus: http.StatusUnauthorized,
			shouldPass:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup router
			r := gin.New()
			r.Use(AuthMiddleware(jwtSecret))
			r.Use(RequireRole(tt.requiredRoles...))
			r.GET("/protected", func(c *gin.Context) {
				userID, _ := c.Get("user_id")
				userEmail, _ := c.Get("user_email")
				userRole, _ := c.Get("user_role")
				c.JSON(http.StatusOK, gin.H{
					"success":    true,
					"user_id":    userID,
					"user_email": userEmail,
					"user_role":  userRole,
				})
			})

			// Create request
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("GET", "/protected", nil)
			authHeader := tt.setupAuth()
			if authHeader != "" {
				req.Header.Set("Authorization", authHeader)
			}

			// Execute
			r.ServeHTTP(w, req)

			// Assert
			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.shouldPass {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				assert.True(t, response["success"].(bool))
				assert.Equal(t, tt.userRole, response["user_role"])
			}
		})
	}
}

// TestMiddlewareChain tests the complete middleware chain (CORS + Auth + Role)
func TestMiddlewareChain(t *testing.T) {
	gin.SetMode(gin.TestMode)
	jwtSecret := "test-secret-key"

	// Setup router with all middleware
	r := gin.New()
	r.Use(CORS([]string{"http://localhost:3000"}))
	r.Use(AuthMiddleware(jwtSecret))
	r.Use(RequireRole("manager"))
	r.POST("/api/manager/action", func(c *gin.Context) {
		var body map[string]interface{}
		c.BindJSON(&body)
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Action completed",
			"data":    body,
		})
	})

	// Test successful request
	t.Run("Successful request with all middleware", func(t *testing.T) {
		token, _ := utils.GenerateToken(1, "manager@example.com", "manager", jwtSecret)
		
		requestBody := map[string]interface{}{
			"action": "update_pricing",
			"value":  100,
		}
		bodyBytes, _ := json.Marshal(requestBody)

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/manager/action", bytes.NewBuffer(bodyBytes))
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Origin", "http://localhost:3000")
		req.Header.Set("Content-Type", "application/json")

		r.ServeHTTP(w, req)

		// Assert status
		assert.Equal(t, http.StatusOK, w.Code)

		// Assert CORS headers
		assert.Equal(t, "http://localhost:3000", w.Header().Get("Access-Control-Allow-Origin"))

		// Assert response
		var response map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.True(t, response["success"].(bool))
	})

	// Test failed request - wrong role
	t.Run("Failed request - insufficient permissions", func(t *testing.T) {
		token, _ := utils.GenerateToken(1, "guest@example.com", "guest", jwtSecret)

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("POST", "/api/manager/action", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Origin", "http://localhost:3000")

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusForbidden, w.Code)
	})

	// Test OPTIONS preflight
	t.Run("OPTIONS preflight request", func(t *testing.T) {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("OPTIONS", "/api/manager/action", nil)
		req.Header.Set("Origin", "http://localhost:3000")

		r.ServeHTTP(w, req)

		// OPTIONS should be handled by CORS middleware before auth
		assert.Equal(t, http.StatusNoContent, w.Code)
		assert.Equal(t, "http://localhost:3000", w.Header().Get("Access-Control-Allow-Origin"))
	})
}

// TestPublicAndProtectedRoutes tests a mix of public and protected routes
func TestPublicAndProtectedRoutes(t *testing.T) {
	gin.SetMode(gin.TestMode)
	jwtSecret := "test-secret-key"

	// Setup router
	r := gin.New()
	r.Use(CORS([]string{"*"}))

	// Public routes
	r.GET("/public", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "public"})
	})

	// Protected routes
	protected := r.Group("/protected")
	protected.Use(AuthMiddleware(jwtSecret))
	{
		protected.GET("/profile", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "profile"})
		})

		// Manager only
		manager := protected.Group("/manager")
		manager.Use(RequireRole("manager"))
		{
			manager.GET("/dashboard", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "manager dashboard"})
			})
		}
	}

	tests := []struct {
		name           string
		path           string
		setupAuth      func() string
		expectedStatus int
	}{
		{
			name:           "Public route without auth",
			path:           "/public",
			setupAuth:      func() string { return "" },
			expectedStatus: http.StatusOK,
		},
		{
			name: "Protected route with valid auth",
			path: "/protected/profile",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "user@example.com", "guest", jwtSecret)
				return "Bearer " + token
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "Protected route without auth",
			path:           "/protected/profile",
			setupAuth:      func() string { return "" },
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name: "Manager route with manager auth",
			path: "/protected/manager/dashboard",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "manager@example.com", "manager", jwtSecret)
				return "Bearer " + token
			},
			expectedStatus: http.StatusOK,
		},
		{
			name: "Manager route with guest auth",
			path: "/protected/manager/dashboard",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "guest@example.com", "guest", jwtSecret)
				return "Bearer " + token
			},
			expectedStatus: http.StatusForbidden,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("GET", tt.path, nil)
			authHeader := tt.setupAuth()
			if authHeader != "" {
				req.Header.Set("Authorization", authHeader)
			}

			r.ServeHTTP(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code)
		})
	}
}
