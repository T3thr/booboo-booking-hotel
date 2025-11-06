# Script to run migration 020 using credentials from backend/.env

Write-Host "Reading database credentials from backend/.env..." -ForegroundColor Cyan

# Parse .env file
$envFile = "..\..\backend\.env"

# If running from project root, adjust path
if (-not (Test-Path $envFile)) {
    $envFile = "backend\.env"
}

if (-not (Test-Path $envFile)) {
    Write-Host "Error: backend/.env file not found" -ForegroundColor Red
    Write-Host "Tried: ..\..\backend\.env and backend\.env" -ForegroundColor Red
    exit 1
}

# Read and parse .env file
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    # Skip comments and empty lines
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Length -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            $envVars[$key] = $value
        }
    }
}

# Extract database credentials
$dbHost = $envVars["DB_HOST"]
$dbPort = $envVars["DB_PORT"]
$dbUser = $envVars["DB_USER"]
$dbPassword = $envVars["DB_PASSWORD"]
$dbName = $envVars["DB_NAME"]

Write-Host ""
Write-Host "Database Configuration:" -ForegroundColor Yellow
Write-Host "Host: $dbHost"
Write-Host "Port: $dbPort"
Write-Host "User: $dbUser"
Write-Host "Database: $dbName"
Write-Host ""

Write-Host "Running migration: 020_allow_null_guest_id.sql" -ForegroundColor Cyan
Write-Host ""

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $dbPassword

# Determine migration file path
$migrationFile = "020_allow_null_guest_id.sql"
if (-not (Test-Path $migrationFile)) {
    $migrationFile = "database\migrations\020_allow_null_guest_id.sql"
}

# Run psql
& psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f $migrationFile

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Migration completed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Migration failed with error code: $LASTEXITCODE" -ForegroundColor Red
}

# Clear password from environment
$env:PGPASSWORD = $null

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
