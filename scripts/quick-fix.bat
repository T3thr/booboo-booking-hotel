@echo off
echo Quick fixing database method calls...

echo Fixing pricing_repository.go...
powershell -Command "$content = Get-Content 'backend/internal/repository/pricing_repository.go' -Raw; $content = $content -replace 'r\.db\.Query\(', 'r.db.Pool.Query(' -replace 'r\.db\.QueryRow\(', 'r.db.Pool.QueryRow(' -replace 'r\.db\.Exec\(', 'r.db.Pool.Exec('; Set-Content 'backend/internal/repository/pricing_repository.go' -Value $content -NoNewline"

echo Fixing report_repository.go...
powershell -Command "$content = Get-Content 'backend/internal/repository/report_repository.go' -Raw; $content = $content -replace 'r\.db\.Query\(', 'r.db.Pool.Query(' -replace 'r\.db\.QueryRow\(', 'r.db.Pool.QueryRow(' -replace 'r\.db\.Exec\(', 'r.db.Pool.Exec('; Set-Content 'backend/internal/repository/report_repository.go' -Value $content -NoNewline"

echo Done! Now testing compilation...
cd backend
docker build -t test-backend .
cd ..
pause