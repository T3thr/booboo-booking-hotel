Write-Host "Testing Go compilation..." -ForegroundColor Green

# Change to backend directory
Set-Location backend

# Try to compile
$result = go build -o main.exe ./cmd/server 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilation successful!" -ForegroundColor Green
    # Clean up
    if (Test-Path "main.exe") {
        Remove-Item "main.exe"
    }
} else {
    Write-Host "❌ Compilation failed:" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
}

# Return to root directory
Set-Location ..