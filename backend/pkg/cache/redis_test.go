package cache

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestRedisCache tests Redis cache operations
func TestRedisCache(t *testing.T) {
	// Skip if Redis is not available
	cache, err := NewRedisCache("localhost:6379")
	if err != nil {
		t.Skip("Redis not available, skipping tests")
		return
	}
	defer cache.Close()

	// Clean up before tests
	_ = cache.FlushAll()

	t.Run("Set and Get", func(t *testing.T) {
		type TestData struct {
			Name  string
			Value int
		}

		data := TestData{Name: "test", Value: 123}
		key := "test:data"

		// Set data
		err := cache.Set(key, data, 1*time.Minute)
		require.NoError(t, err)

		// Get data
		var retrieved TestData
		err = cache.Get(key, &retrieved)
		require.NoError(t, err)
		assert.Equal(t, data, retrieved)
	})

	t.Run("Get Non-Existent Key", func(t *testing.T) {
		var data string
		err := cache.Get("non:existent:key", &data)
		assert.Error(t, err)
	})

	t.Run("Delete Key", func(t *testing.T) {
		key := "test:delete"
		err := cache.Set(key, "value", 1*time.Minute)
		require.NoError(t, err)

		// Verify exists
		exists, err := cache.Exists(key)
		require.NoError(t, err)
		assert.True(t, exists)

		// Delete
		err = cache.Delete(key)
		require.NoError(t, err)

		// Verify deleted
		exists, err = cache.Exists(key)
		require.NoError(t, err)
		assert.False(t, exists)
	})

	t.Run("Delete Pattern", func(t *testing.T) {
		// Set multiple keys
		keys := []string{"pattern:test:1", "pattern:test:2", "pattern:test:3"}
		for _, key := range keys {
			err := cache.Set(key, "value", 1*time.Minute)
			require.NoError(t, err)
		}

		// Delete pattern
		err := cache.DeletePattern("pattern:test:*")
		require.NoError(t, err)

		// Verify all deleted
		for _, key := range keys {
			exists, err := cache.Exists(key)
			require.NoError(t, err)
			assert.False(t, exists)
		}
	})

	t.Run("Expiration", func(t *testing.T) {
		key := "test:expiration"
		err := cache.Set(key, "value", 1*time.Second)
		require.NoError(t, err)

		// Should exist immediately
		exists, err := cache.Exists(key)
		require.NoError(t, err)
		assert.True(t, exists)

		// Wait for expiration
		time.Sleep(2 * time.Second)

		// Should not exist after expiration
		exists, err = cache.Exists(key)
		require.NoError(t, err)
		assert.False(t, exists)
	})

	t.Run("Complex Data Structure", func(t *testing.T) {
		type RoomType struct {
			ID          int
			Name        string
			Description string
			Amenities   []string
		}

		room := RoomType{
			ID:          1,
			Name:        "Deluxe Room",
			Description: "A luxurious room",
			Amenities:   []string{"WiFi", "TV", "Mini Bar"},
		}

		key := "test:room:1"
		err := cache.Set(key, room, 1*time.Minute)
		require.NoError(t, err)

		var retrieved RoomType
		err = cache.Get(key, &retrieved)
		require.NoError(t, err)
		assert.Equal(t, room, retrieved)
	})
}

// TestCacheKeys tests cache key generation
func TestCacheKeys(t *testing.T) {
	t.Run("RoomTypesKey", func(t *testing.T) {
		key := RoomTypesKey()
		assert.Equal(t, "room_types:all", key)
	})

	t.Run("RoomTypeKey", func(t *testing.T) {
		key := RoomTypeKey(123)
		assert.Equal(t, "room_type:123", key)
	})

	t.Run("PricingCalendarKey", func(t *testing.T) {
		key := PricingCalendarKey("2024-01-01", "2024-01-31")
		assert.Equal(t, "pricing_calendar:2024-01-01:2024-01-31", key)
	})

	t.Run("RateTiersKey", func(t *testing.T) {
		key := RateTiersKey()
		assert.Equal(t, "rate_tiers:all", key)
	})

	t.Run("RatePricingKey", func(t *testing.T) {
		key := RatePricingKey(1, 2)
		assert.Equal(t, "rate_pricing:1:2", key)
	})

	t.Run("RatePricingMatrixKey", func(t *testing.T) {
		key := RatePricingMatrixKey()
		assert.Equal(t, "rate_pricing:matrix", key)
	})
}
