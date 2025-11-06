package jobs

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/hotel-booking-system/backend/pkg/database"
	"github.com/robfig/cron/v3"
)

// HoldCleanupJob handles the periodic cleanup of expired booking holds
type HoldCleanupJob struct {
	db     *database.DB
	cron   *cron.Cron
	logger *log.Logger
}

// HoldCleanupResult contains the results of a hold cleanup run
type HoldCleanupResult struct {
	Timestamp        time.Time
	HoldsReleased    int
	InventoryUpdated int
	Success          bool
	ErrorMessage     string
	ExecutionTime    time.Duration
}

// NewHoldCleanupJob creates a new hold cleanup job instance
func NewHoldCleanupJob(db *database.DB) *HoldCleanupJob {
	logger := log.New(log.Writer(), "[HOLD-CLEANUP] ", log.LstdFlags|log.Lshortfile)
	
	return &HoldCleanupJob{
		db:     db,
		cron:   cron.New(),
		logger: logger,
	}
}

// Start begins the scheduled hold cleanup job
// Runs every 5 minutes
func (j *HoldCleanupJob) Start() error {
	j.logger.Println("Initializing hold cleanup scheduler...")

	// Schedule: Run every 5 minutes
	// Cron format: minute hour day month weekday
	_, err := j.cron.AddFunc("*/5 * * * *", func() {
		j.logger.Println("Starting scheduled hold cleanup...")
		result := j.Run()
		j.logResult(result)
	})

	if err != nil {
		return fmt.Errorf("failed to schedule hold cleanup: %w", err)
	}

	j.cron.Start()
	j.logger.Println("Hold cleanup scheduler started successfully (runs every 5 minutes)")
	
	return nil
}

// Stop gracefully stops the hold cleanup scheduler
func (j *HoldCleanupJob) Stop() {
	j.logger.Println("Stopping hold cleanup scheduler...")
	ctx := j.cron.Stop()
	<-ctx.Done()
	j.logger.Println("Hold cleanup scheduler stopped")
}

// Run executes the hold cleanup process immediately
// This can be called manually for testing or triggered by the scheduler
func (j *HoldCleanupJob) Run() HoldCleanupResult {
	startTime := time.Now()
	result := HoldCleanupResult{
		Timestamp: startTime,
		Success:   false,
	}

	j.logger.Println("Executing hold cleanup process...")

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Execute the release_expired_holds function
	query := `SELECT * FROM release_expired_holds()`

	var releasedCount int
	var message string

	err := j.db.Pool.QueryRow(ctx, query).Scan(&releasedCount, &message)
	if err != nil {
		result.ErrorMessage = fmt.Sprintf("failed to execute hold cleanup: %v", err)
		j.logger.Printf("ERROR: %s", result.ErrorMessage)
		result.ExecutionTime = time.Since(startTime)
		return result
	}

	// Check if the function returned an error (released_count = -1)
	if releasedCount < 0 {
		result.ErrorMessage = fmt.Sprintf("database function error: %s", message)
		j.logger.Printf("ERROR: %s", result.ErrorMessage)
		result.ExecutionTime = time.Since(startTime)
		return result
	}

	result.HoldsReleased = releasedCount
	result.Success = true
	result.ExecutionTime = time.Since(startTime)

	if releasedCount > 0 {
		j.logger.Printf("Hold cleanup completed successfully: %s (Duration: %v)", 
			message, result.ExecutionTime)
	} else {
		j.logger.Printf("Hold cleanup completed: No expired holds found (Duration: %v)", 
			result.ExecutionTime)
	}

	return result
}

// RunManual executes the hold cleanup manually and returns the result
// Useful for testing and manual triggers
func (j *HoldCleanupJob) RunManual() (HoldCleanupResult, error) {
	j.logger.Println("Manual hold cleanup triggered")
	result := j.Run()
	
	if !result.Success {
		return result, fmt.Errorf("hold cleanup failed: %s", result.ErrorMessage)
	}
	
	return result, nil
}

// logResult logs the hold cleanup result in a structured format
func (j *HoldCleanupJob) logResult(result HoldCleanupResult) {
	if result.Success {
		if result.HoldsReleased > 0 {
			j.logger.Printf("✓ Hold Cleanup Success | Time: %s | Holds Released: %d | Duration: %v",
				result.Timestamp.Format("2006-01-02 15:04:05"),
				result.HoldsReleased,
				result.ExecutionTime)
		} else {
			j.logger.Printf("✓ Hold Cleanup Success | Time: %s | No expired holds | Duration: %v",
				result.Timestamp.Format("2006-01-02 15:04:05"),
				result.ExecutionTime)
		}
	} else {
		j.logger.Printf("✗ Hold Cleanup Failed | Time: %s | Error: %s | Duration: %v",
			result.Timestamp.Format("2006-01-02 15:04:05"),
			result.ErrorMessage,
			result.ExecutionTime)
	}
}

// GetNextRunTime returns the next scheduled run time
func (j *HoldCleanupJob) GetNextRunTime() time.Time {
	entries := j.cron.Entries()
	if len(entries) > 0 {
		return entries[0].Next
	}
	return time.Time{}
}

// IsRunning returns whether the scheduler is running
func (j *HoldCleanupJob) IsRunning() bool {
	return len(j.cron.Entries()) > 0
}

// GetStats returns statistics about the hold cleanup job
func (j *HoldCleanupJob) GetStats() map[string]interface{} {
	return map[string]interface{}{
		"is_running":    j.IsRunning(),
		"next_run_time": j.GetNextRunTime(),
		"schedule":      "Every 5 minutes",
	}
}
