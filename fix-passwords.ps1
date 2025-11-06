Write-Host "=== Fixing Password Hashes ===" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$env:DATABASE_URL = "postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"

go run backend/scripts/fix-passwords.go

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "Password hashes fixed successfully!" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now login with:"
    Write-Host "  Email: anan.test@example.com"
    Write-Host "  Password: password123"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Failed to fix passwords." -ForegroundColor Red
    Write-Host ""
}
