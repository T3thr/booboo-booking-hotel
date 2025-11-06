package jobs

import (
	"database/sql"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewHoldCleanupJob(t *testing.T) {
	db, _, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	assert.NotNil(t, job)
	assert.NotNil(t, job.db)
	assert.NotNil(t, job.cron)
	assert.NotNil(t, job.logger)
}

func TestHoldCleanupJob_Start(t *testing.T) {
	db, _, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	err = job.Start()
	assert.NoError(t, err)
	assert.True(t, job.IsRunning())

	// Verify next run time is set
	nextRun := job.GetNextRunTime()
	assert.False(t, nextRun.IsZero())
	assert.True(t, nextRun.After(time.Now()))

	job.Stop()
}

func TestHoldCleanupJob_Stop(t *testing.T) {
	db, _, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	err = job.Start()
	require.NoError(t, err)
	assert.True(t, job.IsRunning())

	job.Stop()
	
	// After stop, should have no entries
	assert.False(t, job.IsRunning())
}

func TestHoldCleanupJob_Run_Success_WithExpiredHolds(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Mock successful cleanup with expired holds
	rows := sqlmock.NewRows([]string{"released_count", "message"}).
		AddRow(5, "ปล่อย 5 holds ที่หมดอายุ และอัปเดต 3 inventory records")

	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnRows(rows)

	result := job.Run()

	assert.True(t, result.Success)
	assert.Equal(t, 5, result.HoldsReleased)
	assert.Empty(t, result.ErrorMessage)
	assert.Greater(t, result.ExecutionTime, time.Duration(0))
	assert.False(t, result.Timestamp.IsZero())

	err = mock.ExpectationsWereMet()
	assert.NoError(t, err)
}

func TestHoldCleanupJob_Run_Success_NoExpiredHolds(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Mock successful cleanup with no expired holds
	rows := sqlmock.NewRows([]string{"released_count", "message"}).
		AddRow(0, "ไม่มี holds ที่หมดอายุ")

	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnRows(rows)

	result := job.Run()

	assert.True(t, result.Success)
	assert.Equal(t, 0, result.HoldsReleased)
	assert.Empty(t, result.ErrorMessage)
	assert.Greater(t, result.ExecutionTime, time.Duration(0))

	err = mock.ExpectationsWereMet()
	assert.NoError(t, err)
}

func TestHoldCleanupJob_Run_DatabaseError(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Mock database error
	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnError(sql.ErrConnDone)

	result := job.Run()

	assert.False(t, result.Success)
	assert.Equal(t, 0, result.HoldsReleased)
	assert.Contains(t, result.ErrorMessage, "failed to execute hold cleanup")
	assert.Greater(t, result.ExecutionTime, time.Duration(0))

	err = mock.ExpectationsWereMet()
	assert.NoError(t, err)
}

func TestHoldCleanupJob_Run_FunctionError(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Mock function returning error (released_count = -1)
	rows := sqlmock.NewRows([]string{"released_count", "message"}).
		AddRow(-1, "เกิดข้อผิดพลาด: some database error")

	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnRows(rows)

	result := job.Run()

	assert.False(t, result.Success)
	assert.Equal(t, 0, result.HoldsReleased)
	assert.Contains(t, result.ErrorMessage, "database function error")
	assert.Greater(t, result.ExecutionTime, time.Duration(0))

	err = mock.ExpectationsWereMet()
	assert.NoError(t, err)
}

func TestHoldCleanupJob_RunManual_Success(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Mock successful cleanup
	rows := sqlmock.NewRows([]string{"released_count", "message"}).
		AddRow(3, "ปล่อย 3 holds ที่หมดอายุ และอัปเดต 2 inventory records")

	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnRows(rows)

	result, err := job.RunManual()

	assert.NoError(t, err)
	assert.True(t, result.Success)
	assert.Equal(t, 3, result.HoldsReleased)

	err = mock.ExpectationsWereMet()
	assert.NoError(t, err)
}

func TestHoldCleanupJob_RunManual_Failure(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Mock database error
	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnError(sql.ErrConnDone)

	result, err := job.RunManual()

	assert.Error(t, err)
	assert.False(t, result.Success)
	assert.Contains(t, err.Error(), "hold cleanup failed")

	err = mock.ExpectationsWereMet()
	assert.NoError(t, err)
}

func TestHoldCleanupJob_GetStats(t *testing.T) {
	db, _, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Before starting
	stats := job.GetStats()
	assert.False(t, stats["is_running"].(bool))
	assert.Equal(t, "Every 5 minutes", stats["schedule"])

	// After starting
	err = job.Start()
	require.NoError(t, err)

	stats = job.GetStats()
	assert.True(t, stats["is_running"].(bool))
	assert.NotNil(t, stats["next_run_time"])

	job.Stop()
}

func TestHoldCleanupJob_IsRunning(t *testing.T) {
	db, _, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Initially not running
	assert.False(t, job.IsRunning())

	// After start
	err = job.Start()
	require.NoError(t, err)
	assert.True(t, job.IsRunning())

	// After stop
	job.Stop()
	assert.False(t, job.IsRunning())
}

func TestHoldCleanupJob_GetNextRunTime(t *testing.T) {
	db, _, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// Before starting, should return zero time
	nextRun := job.GetNextRunTime()
	assert.True(t, nextRun.IsZero())

	// After starting, should return valid time
	err = job.Start()
	require.NoError(t, err)

	nextRun = job.GetNextRunTime()
	assert.False(t, nextRun.IsZero())
	assert.True(t, nextRun.After(time.Now()))

	// Next run should be within 5 minutes
	assert.True(t, nextRun.Before(time.Now().Add(6*time.Minute)))

	job.Stop()
}

func TestHoldCleanupJob_MultipleRuns(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	job := NewHoldCleanupJob(db)

	// First run - with expired holds
	rows1 := sqlmock.NewRows([]string{"released_count", "message"}).
		AddRow(5, "ปล่อย 5 holds ที่หมดอายุ และอัปเดต 3 inventory records")
	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnRows(rows1)

	result1 := job.Run()
	assert.True(t, result1.Success)
	assert.Equal(t, 5, result1.HoldsReleased)

	// Second run - no expired holds
	rows2 := sqlmock.NewRows([]string{"released_count", "message"}).
		AddRow(0, "ไม่มี holds ที่หมดอายุ")
	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnRows(rows2)

	result2 := job.Run()
	assert.True(t, result2.Success)
	assert.Equal(t, 0, result2.HoldsReleased)

	// Third run - with expired holds again
	rows3 := sqlmock.NewRows([]string{"released_count", "message"}).
		AddRow(2, "ปล่อย 2 holds ที่หมดอายุ และอัปเดต 1 inventory records")
	mock.ExpectQuery(`SELECT \* FROM release_expired_holds\(\)`).
		WillReturnRows(rows3)

	result3 := job.Run()
	assert.True(t, result3.Success)
	assert.Equal(t, 2, result3.HoldsReleased)

	err = mock.ExpectationsWereMet()
	assert.NoError(t, err)
}
