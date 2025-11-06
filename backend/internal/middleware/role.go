package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// RoleConfig defines role-based access control configuration
type RoleConfig struct {
	AllowedRoles []string
	ErrorMessage string
}

// RequireRole middleware checks if user has required role(s)
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user role from context (set by AuthMiddleware)
		userRole, exists := c.Get("user_role")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "ไม่พบข้อมูลการยืนยันตัวตน",
				"code":    "AUTH_REQUIRED",
			})
			c.Abort()
			return
		}

		role := userRole.(string)
		
		// Check if user has any of the allowed roles
		for _, allowedRole := range allowedRoles {
			if role == allowedRole {
				c.Next()
				return
			}
		}

		// User doesn't have required role
		c.JSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": "คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้",
			"code":    "INSUFFICIENT_PERMISSIONS",
			"required_roles": allowedRoles,
			"user_role": role,
		})
		c.Abort()
	}
}

// RequireGuest middleware - only guests can access
func RequireGuest() gin.HandlerFunc {
	return RequireRole("GUEST")
}

// RequireStaff middleware - any staff can access
func RequireStaff() gin.HandlerFunc {
	return RequireRole("RECEPTIONIST", "HOUSEKEEPER", "MANAGER")
}

// RequireReceptionist middleware - only receptionists and managers
func RequireReceptionist() gin.HandlerFunc {
	return RequireRole("RECEPTIONIST", "MANAGER")
}

// RequireHousekeeper middleware - only housekeepers and managers
func RequireHousekeeper() gin.HandlerFunc {
	return RequireRole("HOUSEKEEPER", "MANAGER")
}

// RequireManager middleware - only managers
func RequireManager() gin.HandlerFunc {
	return RequireRole("MANAGER")
}

// RequireGuestOrStaff middleware - guests or any staff
func RequireGuestOrStaff() gin.HandlerFunc {
	return RequireRole("GUEST", "RECEPTIONIST", "HOUSEKEEPER", "MANAGER")
}

// RoleBasedAccess provides more flexible role checking
func RoleBasedAccess(config RoleConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, exists := c.Get("user_role")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "ไม่พบข้อมูลการยืนยันตัวตน",
				"code":    "AUTH_REQUIRED",
			})
			c.Abort()
			return
		}

		role := userRole.(string)
		
		for _, allowedRole := range config.AllowedRoles {
			if role == allowedRole {
				c.Next()
				return
			}
		}

		errorMessage := config.ErrorMessage
		if errorMessage == "" {
			errorMessage = "คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้"
		}

		c.JSON(http.StatusForbidden, gin.H{
			"error":   "Forbidden",
			"message": errorMessage,
			"code":    "INSUFFICIENT_PERMISSIONS",
			"required_roles": config.AllowedRoles,
			"user_role": role,
		})
		c.Abort()
	}
}

// GetUserRole helper function to get user role from context
func GetUserRole(c *gin.Context) (string, bool) {
	userRole, exists := c.Get("user_role")
	if !exists {
		return "", false
	}
	return userRole.(string), true
}

// GetUserID helper function to get user ID from context
func GetUserID(c *gin.Context) (int, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return 0, false
	}
	return userID.(int), true
}

// GetUserType helper function to get user type from context
func GetUserType(c *gin.Context) (string, bool) {
	userType, exists := c.Get("user_type")
	if !exists {
		return "", false
	}
	return userType.(string), true
}

// IsGuest checks if current user is a guest
func IsGuest(c *gin.Context) bool {
	role, exists := GetUserRole(c)
	return exists && role == "GUEST"
}

// IsStaff checks if current user is staff
func IsStaff(c *gin.Context) bool {
	role, exists := GetUserRole(c)
	if !exists {
		return false
	}
	return role == "RECEPTIONIST" || role == "HOUSEKEEPER" || role == "MANAGER"
}

// IsManager checks if current user is a manager
func IsManager(c *gin.Context) bool {
	role, exists := GetUserRole(c)
	return exists && role == "MANAGER"
}

// HasAnyRole checks if user has any of the specified roles
func HasAnyRole(c *gin.Context, roles ...string) bool {
	userRole, exists := GetUserRole(c)
	if !exists {
		return false
	}
	
	for _, role := range roles {
		if userRole == role {
			return true
		}
	}
	return false
}

// LogRoleAccess logs role-based access attempts (for debugging)
func LogRoleAccess() gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, _ := GetUserRole(c)
		
		// Log access attempt
		if userRole != "" {
			c.Header("X-User-Role", userRole)
			// You can add proper logging here
			// userID, _ := GetUserID(c)
			// path := c.Request.URL.Path
			// method := c.Request.Method
			// log.Printf("Role Access: User %d (%s) accessing %s %s", userID, userRole, method, path)
		}
		
		c.Next()
	}
}

// CORSWithRoles adds CORS headers with role-based considerations
func CORSWithRoles() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		
		// Allow specific origins based on role (if needed)
		allowedOrigins := []string{
			"http://localhost:3000",
			"https://your-domain.com",
			"https://staff.your-domain.com",
			"https://admin.your-domain.com",
		}
		
		for _, allowedOrigin := range allowedOrigins {
			if origin == allowedOrigin {
				c.Header("Access-Control-Allow-Origin", origin)
				break
			}
		}
		
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")
		c.Header("Access-Control-Allow-Credentials", "true")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		
		c.Next()
	}
}

// ValidateResourceOwnership ensures users can only access their own resources
func ValidateResourceOwnership() gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, _ := GetUserRole(c)
		userID, _ := GetUserID(c)
		
		// For guests, they can only access their own bookings
		if userRole == "GUEST" {
			// Extract resource ID from URL (e.g., /bookings/:id)
			resourceID := c.Param("id")
			if resourceID != "" {
				// Here you would check if the booking belongs to the user
				// This is a placeholder - implement actual ownership check
				c.Set("resource_owner_check", true)
				c.Set("resource_id", resourceID)
				c.Set("owner_id", userID)
			}
		}
		
		c.Next()
	}
}

// RoleRouteMap defines which roles can access which route patterns
var RoleRouteMap = map[string][]string{
	"/api/bookings":           {"GUEST", "RECEPTIONIST", "MANAGER"},
	"/api/staff":              {"RECEPTIONIST", "HOUSEKEEPER", "MANAGER"},
	"/api/admin":              {"MANAGER"},
	"/api/housekeeping":       {"HOUSEKEEPER", "MANAGER"},
	"/api/reports":            {"MANAGER"},
	"/api/pricing":            {"MANAGER"},
	"/api/inventory":          {"MANAGER"},
}

// AutoRoleCheck automatically checks roles based on route patterns
func AutoRoleCheck() gin.HandlerFunc {
	return func(c *gin.Context) {
		path := c.Request.URL.Path
		userRole, exists := GetUserRole(c)
		
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authentication required",
			})
			c.Abort()
			return
		}
		
		// Check route patterns
		for routePattern, allowedRoles := range RoleRouteMap {
			if strings.HasPrefix(path, routePattern) {
				for _, allowedRole := range allowedRoles {
					if userRole == allowedRole {
						c.Next()
						return
					}
				}
				
				// Role not allowed for this route
				c.JSON(http.StatusForbidden, gin.H{
					"error":   "Forbidden",
					"message": "คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้",
					"required_roles": allowedRoles,
					"user_role": userRole,
				})
				c.Abort()
				return
			}
		}
		
		c.Next()
	}
}
