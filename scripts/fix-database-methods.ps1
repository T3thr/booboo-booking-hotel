Write-Host "Fixing database method calls..." -ForegroundColor Green

# Get all repository files
$repoFiles = Get-ChildItem -Path "backend/internal/repository/*.go" -File

foreach ($file in $repoFiles) {
    Write-Host "Processing $($file.Name)..." -ForegroundColor Yellow
    
    # Read file content
    $content = Get-Content $file.FullName -Raw
    
    # Replace database method calls
    $content = $content -replace 'r\.db\.Query\(', 'r.db.Pool.Query('
    $content = $content -replace 'r\.db\.QueryRow\(', 'r.db.Pool.QueryRow('
    $content = $content -replace 'r\.db\.Exec\(', 'r.db.Pool.Exec('
    
    # Write back to file
    Set-Content -Path $file.FullName -Value $content -NoNewline
    
    Write-Host "✅ Fixed $($file.Name)" -ForegroundColor Green
}

Write-Host "All repository files have been fixed!" -ForegroundColor Green