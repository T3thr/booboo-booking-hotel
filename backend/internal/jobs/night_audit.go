package jobs

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/hotel-booking-system/backend/pkg/database"
	"github.com/robfig/cron/v3"
)

// NightAuditJob handles the nightly audit process
type NightAuditJob struct {
	db     *database.DB
	cron   *cron.Cron
	logger *log.Logger
}

// NightAuditResult contains the results of a night audit run
type NightAuditResult struct {
	Timestamp      time.Time
	RoomsUpdated   int
	Success        bool
	ErrorMessage   string
	ExecutionTime  time.Duration
}

// NewNightAuditJob creates a new night audit job instance
func NewNightAuditJob(db *database.DB) *NightAuditJob {
	logger := log.New(log.Writer(), "[NIGHT-AUDIT] ", log.LstdFlags|log.Lshortfile)
	
	return &NightAuditJob{
		db:     db,
		cron:   cron.New(),
		logger: logger,
	}
}

// Start begins the scheduled night audit job
// Runs daily at 02:00 AM
func (j *NightAuditJob) Start() error {
	j.logger.Println("Initializing night audit scheduler...")

	// Schedule: Run at 02:00 AM every day
	// Cron format: minute hour day month weekday
	_, err := j.cron.AddFunc("0 2 * * *", func() {
		j.logger.Println("Starting scheduled night audit...")
		result := j.Run()
		j.logResult(result)
	})

	if err != nil {
		return fmt.Errorf("failed to schedule night audit: %w", err)
	}

	j.cron.Start()
	j.logger.Println("Night audit scheduler started successfully (runs daily at 02:00 AM)")
	
	return nil
}

// Stop gracefully stops the night audit scheduler
func (j *NightAuditJob) Stop() {
	j.logger.Println("Stopping night audit scheduler...")
	ctx := j.cron.Stop()
	<-ctx.Done()
	j.logger.Println("Night audit scheduler stopped")
}

// Run executes the night audit process immediately
// This can be called manually for testing or triggered by the scheduler
func (j *NightAuditJob) Run() NightAuditResult {
	startTime := time.Now()
	result := NightAuditResult{
		Timestamp: startTime,
		Success:   false,
	}

	j.logger.Println("Executing night audit process...")

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Execute the night audit query
	query := `
		UPDATE rooms
		SET housekeeping_status = 'Dirty'
		WHERE occupancy_status = 'Occupied'
		  AND housekeeping_status != 'Dirty'
		RETURNING room_id
	`

	rows, err := j.db.Pool.Query(ctx, query)
	if err != nil {
		result.ErrorMessage = fmt.Sprintf("failed to execute night audit query: %v", err)
		j.logger.Printf("ERROR: %s", result.ErrorMessage)
		result.ExecutionTime = time.Since(startTime)
		return result
	}
	defer rows.Close()

	// Count updated rooms
	roomsUpdated := 0
	var roomIDs []int
	for rows.Next() {
		var roomID int
		if err := rows.Scan(&roomID); err != nil {
			j.logger.Printf("WARNING: Failed to scan room ID: %v", err)
			continue
		}
		roomIDs = append(roomIDs, roomID)
		roomsUpdated++
	}

	if err := rows.Err(); err != nil {
		result.ErrorMessage = fmt.Sprintf("error iterating rows: %v", err)
		j.logger.Printf("ERROR: %s", result.ErrorMessage)
		result.ExecutionTime = time.Since(startTime)
		return result
	}

	result.RoomsUpdated = roomsUpdated
	result.Success = true
	result.ExecutionTime = time.Since(startTime)

	j.logger.Printf("Night audit completed successfully: %d rooms updated in %v", 
		roomsUpdated, result.ExecutionTime)
	
	if roomsUpdated > 0 {
		j.logger.Printf("Updated room IDs: %v", roomIDs)
	}

	return result
}

// RunManual executes the night audit manually and returns the result
// Useful for testing and manual triggers
func (j *NightAuditJob) RunManual() (NightAuditResult, error) {
	j.logger.Println("Manual night audit triggered")
	result := j.Run()
	
	if !result.Success {
		return result, fmt.Errorf("night audit failed: %s", result.ErrorMessage)
	}
	
	return result, nil
}

// logResult logs the night audit result in a structured format
func (j *NightAuditJob) logResult(result NightAuditResult) {
	if result.Success {
		j.logger.Printf("✓ Night Audit Success | Time: %s | Rooms Updated: %d | Duration: %v",
			result.Timestamp.Format("2006-01-02 15:04:05"),
			result.RoomsUpdated,
			result.ExecutionTime)
	} else {
		j.logger.Printf("✗ Night Audit Failed | Time: %s | Error: %s | Duration: %v",
			result.Timestamp.Format("2006-01-02 15:04:05"),
			result.ErrorMessage,
			result.ExecutionTime)
	}
}

// GetNextRunTime returns the next scheduled run time
func (j *NightAuditJob) GetNextRunTime() time.Time {
	entries := j.cron.Entries()
	if len(entries) > 0 {
		return entries[0].Next
	}
	return time.Time{}
}

// IsRunning returns whether the scheduler is running
func (j *NightAuditJob) IsRunning() bool {
	return len(j.cron.Entries()) > 0
}
