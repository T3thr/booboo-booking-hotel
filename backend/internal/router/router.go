package router

import (
	"github.com/gin-gonic/gin"
	"github.com/hotel-booking-system/backend/internal/handlers"
	"github.com/hotel-booking-system/backend/internal/jobs"
	"github.com/hotel-booking-system/backend/internal/middleware"
	"github.com/hotel-booking-system/backend/internal/repository"
	"github.com/hotel-booking-system/backend/internal/service"
	"github.com/hotel-booking-system/backend/pkg/cache"
	"github.com/hotel-booking-system/backend/pkg/config"
	"github.com/hotel-booking-system/backend/pkg/database"
)

// Setup creates and configures the Gin router
func Setup(cfg *config.Config, db *database.DB, redisCache *cache.RedisCache, nightAudit *jobs.NightAuditJob, holdCleanup *jobs.HoldCleanupJob) *gin.Engine {
	// Set Gin mode
	gin.SetMode(cfg.Server.GinMode)

	// Create router
	r := gin.New()

	// Apply global middleware
	r.Use(middleware.Recovery())
	r.Use(middleware.Logger())
	r.Use(middleware.SecurityHeaders())
	r.Use(middleware.CORS(cfg.Server.CORS.AllowOrigins))
	r.Use(middleware.GeneralRateLimiter.Middleware())

	// Initialize repositories
	authRepo := repository.NewAuthRepository(db)
	roomRepo := repository.NewRoomRepository(db)
	bookingRepo := repository.NewBookingRepository(db)
	housekeepingRepo := repository.NewHousekeepingRepository(db)
	pricingRepo := repository.NewPricingRepository(db)
	inventoryRepo := repository.NewInventoryRepository(db)
	policyRepo := repository.NewPolicyRepository(db)
	reportRepo := repository.NewReportRepository(db.Pool)

	// Initialize services
	authService := service.NewAuthService(authRepo, cfg.JWT.Secret)
	roomService := service.NewRoomService(roomRepo, redisCache)
	bookingService := service.NewBookingService(bookingRepo, roomRepo)
	housekeepingService := service.NewHousekeepingService(housekeepingRepo)
	pricingService := service.NewPricingService(pricingRepo, redisCache)
	inventoryService := service.NewInventoryService(inventoryRepo, roomRepo)
	policyService := service.NewPolicyService(policyRepo)
	reportService := service.NewReportService(reportRepo)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService)
	roomHandler := handlers.NewRoomHandler(roomService)
	bookingHandler := handlers.NewBookingHandler(bookingService)
	checkInHandler := handlers.NewCheckInHandler(bookingService)
	housekeepingHandler := handlers.NewHousekeepingHandler(housekeepingService)
	pricingHandler := handlers.NewPricingHandler(pricingService)
	inventoryHandler := handlers.NewInventoryHandler(inventoryService)
	policyHandler := handlers.NewPolicyHandler(policyService)
	reportHandler := handlers.NewReportHandler(reportService)
	nightAuditHandler := handlers.NewNightAuditHandler(nightAudit)
	holdCleanupHandler := handlers.NewHoldCleanupHandler(holdCleanup)

	// Serve API documentation
	r.Static("/docs", "./backend/docs/swagger-ui")
	r.StaticFile("/swagger.yaml", "./backend/docs/swagger.yaml")

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"message": "Hotel Booking System API is running",
		})
	})

	// Database health check endpoint
	r.GET("/health/db", func(c *gin.Context) {
		if err := db.Ping(c.Request.Context()); err != nil {
			c.JSON(500, gin.H{
				"status": "error",
				"error":  "Database connection failed",
			})
			return
		}

		stats := db.Stats()
		c.JSON(200, gin.H{
			"status":             "ok",
			"total_conns":        stats.TotalConns(),
			"idle_conns":         stats.IdleConns(),
			"acquired_conns":     stats.AcquiredConns(),
			"constructing_conns": stats.ConstructingConns(),
		})
	})

	// API routes
	api := r.Group("/api")
	{
		// Version endpoint
		api.GET("/", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"message": "Hotel Booking System API",
				"version": "1.0.0",
			})
		})

		// Auth routes (with stricter rate limiting)
		auth := api.Group("/auth")
		auth.Use(middleware.AuthRateLimiter.Middleware())
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)

			// Protected routes
			// TODO: Uncomment when GetProfile and UpdateProfile are implemented
			/*
			protected := auth.Group("")
			protected.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
			{
				protected.GET("/me", authHandler.GetProfile)
				protected.PUT("/profile", authHandler.UpdateProfile)
			}
			*/
		}

		// Room routes (with search rate limiting)
		rooms := api.Group("/rooms")
		rooms.Use(middleware.SearchRateLimiter.Middleware())
		{
			rooms.GET("/search", roomHandler.SearchRooms)
			rooms.GET("/types", roomHandler.GetAllRoomTypes)
			rooms.GET("/types/:id", roomHandler.GetRoomTypeByID)
			rooms.GET("/types/:id/pricing", roomHandler.GetRoomTypePricing)

			// Protected endpoint for receptionist + manager
			protected := rooms.Group("")
			protected.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
			protected.Use(middleware.RequireReceptionist()) // RECEPTIONIST or MANAGER
			{
				protected.GET("/status", roomHandler.GetRoomStatusDashboard)
			}
		}

		// Booking routes (with booking rate limiting)
		bookings := api.Group("/bookings")
		bookings.Use(middleware.BookingRateLimiter.Middleware())
		{
			// Public endpoints - can use without authentication
			bookings.POST("/hold", bookingHandler.CreateBookingHold)
			bookings.GET("/search", bookingHandler.SearchBookingsByPhone)
			
			// Optional auth endpoints - work with or without authentication
			optionalAuth := bookings.Group("")
			optionalAuth.Use(middleware.OptionalAuth(cfg.JWT.Secret))
			{
				optionalAuth.POST("/", bookingHandler.CreateBooking)
				optionalAuth.POST("/:id/confirm", bookingHandler.ConfirmBooking)
			}

			// Protected endpoints - require authentication
			protected := bookings.Group("")
			protected.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
			{
				protected.GET("/", bookingHandler.GetBookings)
				protected.GET("/:id", bookingHandler.GetBookingByID)
				protected.POST("/:id/cancel", bookingHandler.CancelBooking)
				protected.POST("/sync", bookingHandler.SyncBookings)

				// Receptionist + Manager endpoints
				receptionist := protected.Group("")
				receptionist.Use(middleware.RequireReceptionist()) // RECEPTIONIST or MANAGER
				{
					receptionist.POST("/:id/no-show", checkInHandler.MarkNoShow)
				}
			}
		}

		// Check-in/Check-out routes (Receptionist + Manager)
		checkin := api.Group("/checkin")
		checkin.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		checkin.Use(middleware.RequireReceptionist()) // RECEPTIONIST or MANAGER
		{
			checkin.POST("/", checkInHandler.CheckIn)
			checkin.POST("/move-room", checkInHandler.MoveRoom)
			checkin.GET("/arrivals", checkInHandler.GetArrivals)
			checkin.GET("/available-rooms/:roomTypeId", checkInHandler.GetAvailableRooms)
		}

		// Check-out routes (Receptionist + Manager)
		checkout := api.Group("/checkout")
		checkout.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		checkout.Use(middleware.RequireReceptionist()) // RECEPTIONIST or MANAGER
		{
			checkout.POST("/", checkInHandler.CheckOut)
			checkout.GET("/departures", checkInHandler.GetDepartures)
		}

		// Housekeeping routes (Housekeeper + Manager)
		housekeeping := api.Group("/housekeeping")
		housekeeping.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		housekeeping.Use(middleware.RequireHousekeeper()) // HOUSEKEEPER or MANAGER
		{
			housekeeping.GET("/tasks", housekeepingHandler.GetTasks)
			housekeeping.PUT("/rooms/:id/status", housekeepingHandler.UpdateRoomStatus)
			housekeeping.POST("/rooms/:id/inspect", housekeepingHandler.InspectRoom)
			housekeeping.GET("/inspection", housekeepingHandler.GetRoomsForInspection)
			housekeeping.POST("/rooms/:id/maintenance", housekeepingHandler.ReportMaintenance)
		}

		// Pricing Management routes (Manager only)
		pricing := api.Group("/pricing")
		pricing.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		pricing.Use(middleware.RequireManager()) // MANAGER only
		{
			// Rate Tiers
			pricing.GET("/tiers", pricingHandler.GetAllRateTiers)
			pricing.GET("/tiers/:id", pricingHandler.GetRateTierByID)
			pricing.POST("/tiers", pricingHandler.CreateRateTier)
			pricing.PUT("/tiers/:id", pricingHandler.UpdateRateTier)

			// Pricing Calendar
			pricing.GET("/calendar", pricingHandler.GetPricingCalendar)
			pricing.PUT("/calendar", pricingHandler.UpdatePricingCalendar)

			// Rate Pricing (Matrix)
			pricing.GET("/rates", pricingHandler.GetAllRatePricing)
			pricing.GET("/rates/plan/:planId", pricingHandler.GetRatePricingByPlan)
			pricing.PUT("/rates", pricingHandler.UpdateRatePricing)
			pricing.POST("/rates/bulk", pricingHandler.BulkUpdateRatePricing)

			// Rate Plans
			pricing.GET("/plans", pricingHandler.GetAllRatePlans)
		}

		// Inventory Management routes (Manager only)
		inventory := api.Group("/inventory")
		inventory.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		inventory.Use(middleware.RequireManager()) // MANAGER only
		{
			inventory.GET("", inventoryHandler.GetInventory)
			inventory.GET("/:roomTypeId/:date", inventoryHandler.GetInventoryByDate)
			inventory.PUT("", inventoryHandler.UpdateInventory)
			inventory.POST("/bulk", inventoryHandler.BulkUpdateInventory)
		}

		// Cancellation Policy Management routes (Manager only)
		policies := api.Group("/policies")
		policies.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		policies.Use(middleware.RequireManager()) // MANAGER only
		{
			policies.GET("/cancellation", policyHandler.GetAllCancellationPolicies)
			policies.GET("/cancellation/:id", policyHandler.GetCancellationPolicyByID)
			policies.POST("/cancellation", policyHandler.CreateCancellationPolicy)
			policies.PUT("/cancellation/:id", policyHandler.UpdateCancellationPolicy)
			policies.DELETE("/cancellation/:id", policyHandler.DeleteCancellationPolicy)
		}

		// Voucher Management routes
		vouchers := api.Group("/vouchers")
		{
			// Public endpoint for voucher validation
			vouchers.POST("/validate", policyHandler.ValidateVoucher)

			// Manager-only endpoints
			protected := vouchers.Group("")
			protected.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
			protected.Use(middleware.RequireManager()) // MANAGER only
			{
				protected.GET("", policyHandler.GetAllVouchers)
				protected.GET("/:id", policyHandler.GetVoucherByID)
				protected.POST("", policyHandler.CreateVoucher)
				protected.PUT("/:id", policyHandler.UpdateVoucher)
				protected.DELETE("/:id", policyHandler.DeleteVoucher)
			}
		}

		// Reporting routes (Manager only)
		reports := api.Group("/reports")
		reports.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		reports.Use(middleware.RequireManager()) // MANAGER only
		{
			// Report endpoints
			reports.GET("/occupancy", reportHandler.GetOccupancyReport)
			reports.GET("/revenue", reportHandler.GetRevenueReport)
			reports.GET("/vouchers", reportHandler.GetVoucherReport)
			reports.GET("/no-shows", reportHandler.GetNoShowReport)
			reports.GET("/summary", reportHandler.GetReportSummary)
			reports.GET("/comparison", reportHandler.GetComparisonReport)

			// Export endpoints
			reports.GET("/export/occupancy", reportHandler.ExportOccupancyReport)
			reports.GET("/export/revenue", reportHandler.ExportRevenueReport)
			reports.GET("/export/vouchers", reportHandler.ExportVoucherReport)
			reports.GET("/export/no-shows", reportHandler.ExportNoShowReport)
		}

		// Admin routes (Manager only)
		admin := api.Group("/admin")
		admin.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		admin.Use(middleware.RequireManager()) // MANAGER only
		{
			// Night Audit endpoints
			admin.POST("/night-audit/trigger", nightAuditHandler.TriggerManual)
			admin.GET("/night-audit/status", nightAuditHandler.GetStatus)

			// Hold Cleanup endpoints
			admin.POST("/hold-cleanup/trigger", holdCleanupHandler.TriggerManual)
			admin.GET("/hold-cleanup/status", holdCleanupHandler.GetStatus)
		}
	}

	return r
}
