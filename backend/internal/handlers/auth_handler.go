package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/models"
	"github.com/hotel-booking-system/backend/internal/service"
	"github.com/hotel-booking-system/backend/pkg/utils"
)

// AuthHandler handles authentication HTTP requests
type AuthHandler struct {
	authService *service.AuthService
}

// NewAuthHandler creates a new auth handler
func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// Register handles guest registration (only guests can self-register)
// @Summary Register a new guest
// @Tags auth
// @Accept json
// @Produce json
// @Param request body service.RegisterRequest true "Registration details"
// @Success 201 {object} models.LoginResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Validation Error",
			"message": err.Error(),
		})
		return
	}

	response, err := h.authService.Register(c.Request.Context(), &req)
	if err != nil {
		if err.Error() == "อีเมลนี้ถูกใช้งานแล้ว" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Email Already Exists",
				"message": err.Error(),
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Registration Failed",
			"message": "ไม่สามารถลงทะเบียนได้ กรุณาลองใหม่อีกครั้ง",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    response,
		"message": "ลงทะเบียนสำเร็จ",
	})
}

// Login handles unified login for both guests and staff
// @Summary Login (guests and staff)
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.LoginRequest true "Login credentials"
// @Success 200 {object} models.LoginResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /api/auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Validation Error",
			"message": err.Error(),
		})
		return
	}

	response, err := h.authService.Login(c.Request.Context(), &req)
	if err != nil {
		if err.Error() == "อีเมลหรือรหัสผ่านไม่ถูกต้อง" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Invalid Credentials",
				"message": err.Error(),
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Login Failed",
			"message": "ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่อีกครั้ง",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
		"message": "เข้าสู่ระบบสำเร็จ",
	})
}

// GetMe retrieves the current user's information (works for both guests and staff)
// @Summary Get current user information
// @Tags auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]string
// @Router /api/auth/me [get]
func (h *AuthHandler) GetMe(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Unauthorized",
			"message": "ไม่พบข้อมูลการยืนยันตัวตน",
		})
		return
	}

	userRole, _ := c.Get("user_role")
	userEmail, _ := c.Get("user_email")
	userType, _ := c.Get("user_type")

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":        userID,
			"email":     userEmail,
			"role_code": userRole,
			"user_type": userType,
		},
	})
}

// GetRoles retrieves all available roles (for admin use)
// TODO: Implement GetRoles when AuthService.GetRoles is available
/*
func (h *AuthHandler) GetRoles(c *gin.Context) {
	roles, err := h.authService.GetRoles(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to Get Roles",
			"message": "ไม่สามารถดึงข้อมูลบทบาทได้",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    roles,
	})
}
*/

// CreateStaff creates a new staff member (manager only)
// TODO: Implement CreateStaff when AuthService.CreateStaff is available
/*
func (h *AuthHandler) CreateStaff(c *gin.Context) {
	var req service.CreateStaffRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Validation Error",
			"message": err.Error(),
		})
		return
	}

	staff, err := h.authService.CreateStaff(c.Request.Context(), &req)
	if err != nil {
		if err.Error() == "อีเมลนี้ถูกใช้งานแล้ว" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Email Already Exists",
				"message": err.Error(),
			})
			return
		}
		if err.Error() == "บทบาทไม่ถูกต้อง" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Invalid Role",
				"message": err.Error(),
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Staff Creation Failed",
			"message": "ไม่สามารถสร้างพนักงานได้ กรุณาลองใหม่อีกครั้ง",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    staff,
		"message": "สร้างพนักงานสำเร็จ",
	})
}
*/

// RefreshToken refreshes the JWT token
// @Summary Refresh JWT token
// @Tags auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /api/auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Unauthorized",
			"message": "ไม่พบข้อมูลการยืนยันตัวตน",
		})
		return
	}

	// Extract token
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid Token Format",
			"message": "รูปแบบ token ไม่ถูกต้อง",
		})
		return
	}

	// Get JWT secret from config
	jwtSecret := c.GetString("jwt_secret")
	
	// Validate current token
	claims, err := utils.ValidateToken(parts[1], jwtSecret)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "Invalid Token",
			"message": "Token ไม่ถูกต้องหรือหมดอายุ",
		})
		return
	}

	// Generate new token
	newToken, err := utils.RefreshToken(claims, jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Token Refresh Failed",
			"message": "ไม่สามารถสร้าง token ใหม่ได้",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":      true,
		"access_token": newToken,
		"message":      "รีเฟรช token สำเร็จ",
	})
}
