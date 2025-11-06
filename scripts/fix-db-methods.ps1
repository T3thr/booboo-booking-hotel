Write-Host "Fixing database method calls in all repository files..." -ForegroundColor Green

# List of repository files to fix
$files = @(
    "backend/internal/repository/pricing_repository.go",
    "backend/internal/repository/report_repository.go"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        
        # Read content
        $content = Get-Content $file -Raw
        
        # Replace database method calls
        $content = $content -replace 'r\.db\.Query\(', 'r.db.Pool.Query('
        $content = $content -replace 'r\.db\.QueryRow\(', 'r.db.Pool.QueryRow('
        $content = $content -replace 'r\.db\.Exec\(', 'r.db.Pool.Exec('
        
        # Write back
        Set-Content -Path $file -Value $content -NoNewline
        
        Write-Host "✅ Fixed $file" -ForegroundColor Green
    } else {
        Write-Host "⚠️  File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "All repository files have been fixed!" -ForegroundColor Green
Write-Host "Testing compilation..." -ForegroundColor Cyan

Set-Location backend
$result = go build -o main.exe ./cmd/server 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilation successful!" -ForegroundColor Green
    if (Test-Path "main.exe") {
        Remove-Item "main.exe"
    }
} else {
    Write-Host "❌ Compilation failed:" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
}

Set-Location ..