# Tailwind CSS 4.0 Migration Script for Windows
# This script helps migrate hardcoded colors to CSS variables

Write-Host "🎨 Tailwind CSS 4.0 Migration Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Function to backup file
function Backup-File {
    param($FilePath)
    
    if (Test-Path $FilePath) {
        $backupPath = "$FilePath.backup"
        Copy-Item $FilePath $backupPath -Force
        Write-Host "✓ Backed up: $FilePath" -ForegroundColor Green
    }
}

# Function to migrate file
function Migrate-File {
    param($FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "⚠ File not found: $FilePath" -ForegroundColor Yellow
        return
    }
    
    Write-Host "→ Migrating: $FilePath" -ForegroundColor Yellow
    
    # Backup first
    Backup-File $FilePath
    
    # Read file content
    $content = Get-Content $FilePath -Raw
    
    # Replace background colors (excluding semantic colors)
    $content = $content -replace 'className="([^"]*)bg-white dark:bg-gray-900([^"]*)"', 'className="$1bg-background$2"'
    $content = $content -replace 'className="([^"]*)bg-gray-50 dark:bg-gray-800([^"]*)"', 'className="$1bg-muted$2"'
    $content = $content -replace 'className="([^"]*)bg-white dark:bg-gray-800([^"]*)"', 'className="$1bg-card$2"'
    $content = $content -replace 'className="([^"]*)bg-gray-100 dark:bg-gray-800([^"]*)"', 'className="$1bg-secondary$2"'
    
    # Replace text colors
    $content = $content -replace 'className="([^"]*)text-gray-900 dark:text-white([^"]*)"', 'className="$1text-foreground$2"'
    $content = $content -replace 'className="([^"]*)text-black dark:text-white([^"]*)"', 'className="$1text-foreground$2"'
    $content = $content -replace 'className="([^"]*)text-gray-600 dark:text-gray-400([^"]*)"', 'className="$1text-muted-foreground$2"'
    $content = $content -replace 'className="([^"]*)text-gray-500 dark:text-gray-400([^"]*)"', 'className="$1text-muted-foreground$2"'
    
    # Replace border colors
    $content = $content -replace 'className="([^"]*)border-gray-200 dark:border-gray-700([^"]*)"', 'className="$1border-border$2"'
    $content = $content -replace 'className="([^"]*)border-gray-300 dark:border-gray-600([^"]*)"', 'className="$1border-border$2"'
    
    # Replace primary colors
    $content = $content -replace 'className="([^"]*)bg-blue-600 hover:bg-blue-700([^"]*)"', 'className="$1bg-primary hover:bg-primary/90$2"'
    $content = $content -replace 'className="([^"]*)text-blue-600([^"]*)"', 'className="$1text-primary$2"'
    
    # Write back to file
    Set-Content $FilePath $content -NoNewline
    
    Write-Host "✓ Migrated: $FilePath" -ForegroundColor Green
}

# Main migration
Write-Host "Starting migration..." -ForegroundColor Cyan
Write-Host ""

# Guest pages
Write-Host "📁 Migrating Guest pages..." -ForegroundColor Cyan
Migrate-File "src\app\(guest)\layout.tsx"
Migrate-File "src\app\(guest)\booking\confirmation\[id]\page.tsx"
Migrate-File "src\app\(guest)\booking\summary\page.tsx"
Migrate-File "src\app\(guest)\booking\guest-info\page.tsx"
Migrate-File "src\app\(guest)\rooms\search\page.tsx"

# Components
Write-Host ""
Write-Host "📁 Migrating Components..." -ForegroundColor Cyan
Migrate-File "src\components\room-card.tsx"
Migrate-File "src\components\room-search-form.tsx"
Migrate-File "src\components\countdown-timer.tsx"
Migrate-File "src\components\ui\loading.tsx"
Migrate-File "src\components\protected-route.tsx"

# Auth pages
Write-Host ""
Write-Host "📁 Migrating Auth pages..." -ForegroundColor Cyan
Migrate-File "src\app\auth\signin\page.tsx"
Migrate-File "src\app\auth\register\page.tsx"
Migrate-File "src\app\auth\error\page.tsx"
Migrate-File "src\app\auth\test\page.tsx"

# Other pages
Write-Host ""
Write-Host "📁 Migrating Other pages..." -ForegroundColor Cyan
Migrate-File "src\app\page.tsx"
Migrate-File "src\app\not-found.tsx"
Migrate-File "src\app\unauthorized\page.tsx"
Migrate-File "src\app\test-api\page.tsx"

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "✓ Migration completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the changes"
Write-Host "2. Test in both light and dark mode"
Write-Host "3. Run: npm run dev"
Write-Host "4. If issues, restore from .backup files"
Write-Host ""
Write-Host "To restore all backups:" -ForegroundColor Yellow
Write-Host '  Get-ChildItem -Recurse -Filter "*.backup" | ForEach-Object { Move-Item $_.FullName ($_.FullName -replace "\.backup$","") -Force }'
