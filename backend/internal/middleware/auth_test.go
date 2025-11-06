package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/hotel-booking-system/backend/pkg/utils"
	"github.com/stretchr/testify/assert"
)

func TestAuthMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	jwtSecret := "test-secret-key"

	tests := []struct {
		name           string
		setupAuth      func() string
		expectedStatus int
		expectedError  string
	}{
		{
			name: "Valid token",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "test@example.com", "guest", jwtSecret)
				return "Bearer " + token
			},
			expectedStatus: http.StatusOK,
		},
		{
			name: "No authorization header",
			setupAuth: func() string {
				return ""
			},
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "No authorization header provided",
		},
		{
			name: "Invalid header format - missing Bearer",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "test@example.com", "guest", jwtSecret)
				return token
			},
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "Invalid authorization header format",
		},
		{
			name: "Invalid header format - wrong prefix",
			setupAuth: func() string {
				token, _ := utils.GenerateToken(1, "test@example.com", "guest", jwtSecret)
				return "Basic " + token
			},
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "Invalid authorization header format",
		},
		{
			name: "Invalid token",
			setupAuth: func() string {
				return "Bearer invalid.token.here"
			},
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "Invalid or expired token",
		},
		{
			name: "Expired token",
			setupAuth: func() string {
				// Create an expired token
				claims := &utils.Claims{
					UserID: 1,
					Email:  "test@example.com",
					Role:   "guest",
					RegisteredClaims: jwt.RegisteredClaims{
						ExpiresAt: jwt.NewNumericDate(time.Now().Add(-1 * time.Hour)),
						IssuedAt:  jwt.NewNumericDate(time.Now().Add(-2 * time.Hour)),
					},
				}
				token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
				tokenString, _ := token.SignedString([]byte(jwtSecret))
				return "Bearer " + tokenString
			},
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "Invalid or expired token",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			w := httptest.NewRecorder()
			c, r := gin.CreateTestContext(w)

			// Apply middleware
			r.Use(AuthMiddleware(jwtSecret))
			r.GET("/test", func(c *gin.Context) {
				userID, _ := c.Get("user_id")
				userEmail, _ := c.Get("user_email")
				userRole, _ := c.Get("user_role")
				c.JSON(http.StatusOK, gin.H{
					"user_id":    userID,
					"user_email": userEmail,
					"user_role":  userRole,
				})
			})

			// Create request
			req, _ := http.NewRequest("GET", "/test", nil)
			authHeader := tt.setupAuth()
			if authHeader != "" {
				req.Header.Set("Authorization", authHeader)
			}

			// Execute
			r.ServeHTTP(w, req)

			// Assert
			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedStatus == http.StatusOK {
				// Verify context values were set
				assert.Contains(t, w.Body.String(), "user_id")
				assert.Contains(t, w.Body.String(), "user_email")
				assert.Contains(t, w.Body.String(), "user_role")
			} else if tt.expectedError != "" {
				assert.Contains(t, w.Body.String(), tt.expectedError)
			}
		})
	}
}

func TestAuthMiddleware_ContextValues(t *testing.T) {
	gin.SetMode(gin.TestMode)
	jwtSecret := "test-secret-key"

	// Setup
	w := httptest.NewRecorder()
	c, r := gin.CreateTestContext(w)

	// Apply middleware
	r.Use(AuthMiddleware(jwtSecret))
	r.GET("/test", func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		assert.True(t, exists)
		assert.Equal(t, 123, userID)

		userEmail, exists := c.Get("user_email")
		assert.True(t, exists)
		assert.Equal(t, "test@example.com", userEmail)

		userRole, exists := c.Get("user_role")
		assert.True(t, exists)
		assert.Equal(t, "guest", userRole)

		c.JSON(http.StatusOK, gin.H{"success": true})
	})

	// Create request with valid token
	token, _ := utils.GenerateToken(123, "test@example.com", "guest", jwtSecret)
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)

	// Execute
	r.ServeHTTP(w, req)

	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRequireRole(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		userRole       string
		requiredRoles  []string
		roleExists     bool
		expectedStatus int
		expectedError  string
	}{
		{
			name:           "User has required role - single role",
			userRole:       "manager",
			requiredRoles:  []string{"manager"},
			roleExists:     true,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "User has one of multiple required roles",
			userRole:       "receptionist",
			requiredRoles:  []string{"manager", "receptionist", "housekeeper"},
			roleExists:     true,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "User does not have required role",
			userRole:       "guest",
			requiredRoles:  []string{"manager", "receptionist"},
			roleExists:     true,
			expectedStatus: http.StatusForbidden,
			expectedError:  "Insufficient permissions",
		},
		{
			name:           "No role in context",
			userRole:       "",
			requiredRoles:  []string{"manager"},
			roleExists:     false,
			expectedStatus: http.StatusForbidden,
			expectedError:  "No role found in token",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			w := httptest.NewRecorder()
			c, r := gin.CreateTestContext(w)

			// Apply middleware
			r.Use(func(c *gin.Context) {
				if tt.roleExists {
					c.Set("user_role", tt.userRole)
				}
				c.Next()
			})
			r.Use(RequireRole(tt.requiredRoles...))
			r.GET("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"success": true})
			})

			// Create request
			req, _ := http.NewRequest("GET", "/test", nil)

			// Execute
			r.ServeHTTP(w, req)

			// Assert
			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedError != "" {
				assert.Contains(t, w.Body.String(), tt.expectedError)
			}
		})
	}
}

func TestRequireRole_MultipleRoles(t *testing.T) {
	gin.SetMode(gin.TestMode)

	roles := []string{"guest", "receptionist", "housekeeper", "manager"}

	for _, userRole := range roles {
		t.Run("User with role: "+userRole, func(t *testing.T) {
			// Setup
			w := httptest.NewRecorder()
			c, r := gin.CreateTestContext(w)

			// Apply middleware - require manager or receptionist
			r.Use(func(c *gin.Context) {
				c.Set("user_role", userRole)
				c.Next()
			})
			r.Use(RequireRole("manager", "receptionist"))
			r.GET("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"success": true})
			})

			// Create request
			req, _ := http.NewRequest("GET", "/test", nil)

			// Execute
			r.ServeHTTP(w, req)

			// Assert
			if userRole == "manager" || userRole == "receptionist" {
				assert.Equal(t, http.StatusOK, w.Code)
			} else {
				assert.Equal(t, http.StatusForbidden, w.Code)
			}
		})
	}
}

func TestRequireRole_InvalidRoleType(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup
	w := httptest.NewRecorder()
	c, r := gin.CreateTestContext(w)

	// Apply middleware with invalid role type
	r.Use(func(c *gin.Context) {
		c.Set("user_role", 123) // Set as int instead of string
		c.Next()
	})
	r.Use(RequireRole("manager"))
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"success": true})
	})

	// Create request
	req, _ := http.NewRequest("GET", "/test", nil)

	// Execute
	r.ServeHTTP(w, req)

	// Assert
	assert.Equal(t, http.StatusForbidden, w.Code)
	assert.Contains(t, w.Body.String(), "Invalid role format")
}
