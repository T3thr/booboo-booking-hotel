# Script to run PostgreSQL migrations using credentials from backend/.env

Write-Host "Reading database credentials from backend/.env..." -ForegroundColor Cyan

# Parse .env file
$envFile = "backend\.env"
if (-not (Test-Path $envFile)) {
    $envFile = ".env"
}

if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found" -ForegroundColor Red
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
$dbSslMode = $envVars["DB_SSLMODE"]

Write-Host ""
Write-Host "Database Configuration:" -ForegroundColor Yellow
Write-Host "Host: $dbHost"
Write-Host "Port: $dbPort"
Write-Host "User: $dbUser"
Write-Host "Database: $dbName"
Write-Host "SSL Mode: $dbSslMode"
Write-Host ""

# Check if migration file is provided
if ($args.Count -eq 0) {
    Write-Host "Usage: .\run-migration-with-env.ps1 [migration-file.sql]" -ForegroundColor Red
    Write-Host "Example: .\run-migration-with-env.ps1 020_allow_null_guest_id.sql" -ForegroundColor Yellow
    exit 1
}

$migrationFile = $args[0]

# Check if file exists
if (-not (Test-Path $migrationFile)) {
    Write-Host "Error: Migration file '$migrationFile' not found" -ForegroundColor Red
    exit 1
}

Write-Host "Running migration: $migrationFile" -ForegroundColor Cyan
Write-Host ""

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $dbPassword

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
