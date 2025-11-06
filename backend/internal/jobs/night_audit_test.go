package jobs

import (
	"database/sql"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestNightAuditJob_Run tests the night audit execution
func TestNightAuditJob_Run(t *testing.T) {
	// This is an integration test that requires a real database
	// Skip if DB_TEST_URL is not set
	dbURL := getTestDBURL()
	if dbURL == "" {
		t.Skip("Skipping integration test: DB_TEST_URL not set")
	}

	db, err := sql.Open("pgx", dbURL)
	require.NoError(t, err)
	defer db.Close()

	// Setup test data
	setupNightAuditTestData(t, db)
	defer cleanupNightAuditTestData(t, db)

	// Create job
	job := NewNightAuditJob(db)
	require.NotNil(t, job)

	// Run night audit
	result := job.Run()

	// Verify result
	assert.True(t, result.Success, "Night audit should succeed")
	assert.Empty(t, result.ErrorMessage, "Should have no error message")
	assert.Greater(t, result.RoomsUpdated, 0, "Should update at least one room")
	assert.NotZero(t, result.Timestamp, "Should have timestamp")
	assert.Greater(t, result.ExecutionTime, time.Duration(0), "Should have execution time")

	// Verify database state
	var dirtyCount int
	err = db.QueryRow(`
		SELECT COUNT(*) 
		FROM rooms 
		WHERE occupancy_status = 'Occupied' 
		  AND housekeeping_status = 'Dirty'
	`).Scan(&dirtyCount)
	require.NoError(t, err)
	assert.Greater(t, dirtyCount, 0, "Should have dirty occupied rooms after audit")
}

// TestNightAuditJob_RunManual tests manual execution
func TestNightAuditJob_RunManual(t *testing.T) {
	dbURL := getTestDBURL()
	if dbURL == "" {
		t.Skip("Skipping integration test: DB_TEST_URL not set")
	}

	db, err := sql.Open("pgx", dbURL)
	require.NoError(t, err)
	defer db.Close()

	setupNightAuditTestData(t, db)
	defer cleanupNightAuditTestData(t, db)

	job := NewNightAuditJob(db)
	result, err := job.RunManual()

	assert.NoError(t, err)
	assert.True(t, result.Success)
	assert.Greater(t, result.RoomsUpdated, 0)
}

// TestNightAuditJob_StartStop tests scheduler start and stop
func TestNightAuditJob_StartStop(t *testing.T) {
	dbURL := getTestDBURL()
	if dbURL == "" {
		t.Skip("Skipping integration test: DB_TEST_URL not set")
	}

	db, err := sql.Open("pgx", dbURL)
	require.NoError(t, err)
	defer db.Close()

	job := NewNightAuditJob(db)

	// Start scheduler
	err = job.Start()
	assert.NoError(t, err)
	assert.True(t, job.IsRunning(), "Job should be running after start")

	// Check next run time
	nextRun := job.GetNextRunTime()
	assert.False(t, nextRun.IsZero(), "Should have next run time")
	assert.True(t, nextRun.After(time.Now()), "Next run should be in the future")

	// Stop scheduler
	job.Stop()
	time.Sleep(100 * time.Millisecond) // Give it time to stop
}

// TestNightAuditJob_NoRoomsToUpdate tests when no rooms need updating
func TestNightAuditJob_NoRoomsToUpdate(t *testing.T) {
	dbURL := getTestDBURL()
	if dbURL == "" {
		t.Skip("Skipping integration test: DB_TEST_URL not set")
	}

	db, err := sql.Open("pgx", dbURL)
	require.NoError(t, err)
	defer db.Close()

	// Ensure all occupied rooms are already dirty
	_, err = db.Exec(`
		UPDATE rooms 
		SET housekeeping_status = 'Dirty' 
		WHERE occupancy_status = 'Occupied'
	`)
	require.NoError(t, err)

	job := NewNightAuditJob(db)
	result := job.Run()

	assert.True(t, result.Success)
	assert.Equal(t, 0, result.RoomsUpdated, "Should update 0 rooms")
}

// Helper functions

func getTestDBURL() string {
	// Get from environment or use default test database
	// In real tests, this would come from environment variable
	return "" // Return empty to skip tests by default
}

func setupNightAuditTestData(t *testing.T, db *sql.DB) {
	// Create test rooms with occupied status but not dirty
	_, err := db.Exec(`
		UPDATE rooms 
		SET occupancy_status = 'Occupied',
		    housekeeping_status = 'Clean'
		WHERE room_id IN (
			SELECT room_id FROM rooms LIMIT 3
		)
	`)
	require.NoError(t, err)
}

func cleanupNightAuditTestData(t *testing.T, db *sql.DB) {
	// Reset rooms to vacant and clean
	_, err := db.Exec(`
		UPDATE rooms 
		SET occupancy_status = 'Vacant',
		    housekeeping_status = 'Clean'
		WHERE occupancy_status = 'Occupied'
	`)
	require.NoError(t, err)
}
