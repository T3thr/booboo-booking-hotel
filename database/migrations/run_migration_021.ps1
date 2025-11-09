# Run Migration 021: Add Email and Phone to Booking Guests

Write-Host "========================================"
Write-Host "Running Migration 021"
Write-Host "Add Email and Phone to Booking Guests"
Write-Host "========================================"

# Set environment variables from backend .env
$env:PGPASSWORD = "npg_8kHamXSLKg1x"

Write-Host ""
Write-Host "Database: neondb"
Write-Host "Host: ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech:5432"
Write-Host "User: neondb_owner"
Write-Host ""

# Run migration
Write-Host "Running migration..."
psql -h ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech -p 5432 -U neondb_owner -d neondb -f "database/migrations/021_add_email_phone_to_booking_guests.sql"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Migration 021 completed successfully!"
    Write-Host "========================================"
} else {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Migration 021 failed!"
    Write-Host "========================================"
    exit 1
}
