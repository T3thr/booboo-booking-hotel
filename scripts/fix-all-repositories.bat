@echo off
echo Fixing all repository database method calls...

echo Fixing pricing_repository.go...
powershell -Command "(Get-Content 'backend/internal/repository/pricing_repository.go') -replace 'r\.db\.Query\(', 'r.db.Pool.Query(' -replace 'r\.db\.QueryRow\(', 'r.db.Pool.QueryRow(' -replace 'r\.db\.Exec\(', 'r.db.Pool.Exec(' | Set-Content 'backend/internal/repository/pricing_repository.go'"

echo Fixing report_repository.go...
powershell -Command "(Get-Content 'backend/internal/repository/report_repository.go') -replace 'r\.db\.Query\(', 'r.db.Pool.Query(' -replace 'r\.db\.QueryRow\(', 'r.db.Pool.QueryRow(' -replace 'r\.db\.Exec\(', 'r.db.Pool.Exec(' | Set-Content 'backend/internal/repository/report_repository.go'"

echo All repository files have been fixed!
echo Testing compilation...
cd backend
go build -o main.exe ./cmd/server
if %ERRORLEVEL% EQU 0 (
    echo ✅ Compilation successful!
    del main.exe
) else (
    echo ❌ Compilation failed
)
cd ..
pause