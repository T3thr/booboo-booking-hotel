#!/bin/bash

# Tailwind CSS 4.0 Migration Script
# This script helps migrate hardcoded colors to CSS variables

echo "🎨 Tailwind CSS 4.0 Migration Script"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to backup file
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup"
        echo -e "${GREEN}✓${NC} Backed up: $file"
    fi
}

# Function to migrate file
migrate_file() {
    local file=$1
    echo -e "${YELLOW}→${NC} Migrating: $file"
    
    # Backup first
    backup_file "$file"
    
    # Replace background colors (excluding semantic colors)
    sed -i.tmp 's/className="\([^"]*\)bg-white dark:bg-gray-900\([^"]*\)"/className="\1bg-background\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)bg-gray-50 dark:bg-gray-800\([^"]*\)"/className="\1bg-muted\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)bg-white dark:bg-gray-800\([^"]*\)"/className="\1bg-card\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)bg-gray-100 dark:bg-gray-800\([^"]*\)"/className="\1bg-secondary\2"/g' "$file"
    
    # Replace text colors
    sed -i.tmp 's/className="\([^"]*\)text-gray-900 dark:text-white\([^"]*\)"/className="\1text-foreground\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)text-black dark:text-white\([^"]*\)"/className="\1text-foreground\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)text-gray-600 dark:text-gray-400\([^"]*\)"/className="\1text-muted-foreground\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)text-gray-500 dark:text-gray-400\([^"]*\)"/className="\1text-muted-foreground\2"/g' "$file"
    
    # Replace border colors
    sed -i.tmp 's/className="\([^"]*\)border-gray-200 dark:border-gray-700\([^"]*\)"/className="\1border-border\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)border-gray-300 dark:border-gray-600\([^"]*\)"/className="\1border-border\2"/g' "$file"
    
    # Replace primary colors
    sed -i.tmp 's/className="\([^"]*\)bg-blue-600 hover:bg-blue-700\([^"]*\)"/className="\1bg-primary hover:bg-primary\/90\2"/g' "$file"
    sed -i.tmp 's/className="\([^"]*\)text-blue-600\([^"]*\)"/className="\1text-primary\2"/g' "$file"
    
    # Clean up temp files
    rm -f "$file.tmp"
    
    echo -e "${GREEN}✓${NC} Migrated: $file"
}

# Main migration
echo "Starting migration..."
echo ""

# Guest pages
echo "📁 Migrating Guest pages..."
migrate_file "src/app/(guest)/layout.tsx"
migrate_file "src/app/(guest)/booking/confirmation/[id]/page.tsx"
migrate_file "src/app/(guest)/booking/summary/page.tsx"
migrate_file "src/app/(guest)/booking/guest-info/page.tsx"
migrate_file "src/app/(guest)/rooms/search/page.tsx"

# Components
echo ""
echo "📁 Migrating Components..."
migrate_file "src/components/room-card.tsx"
migrate_file "src/components/room-search-form.tsx"
migrate_file "src/components/countdown-timer.tsx"
migrate_file "src/components/ui/loading.tsx"
migrate_file "src/components/protected-route.tsx"

# Auth pages
echo ""
echo "📁 Migrating Auth pages..."
migrate_file "src/app/auth/signin/page.tsx"
migrate_file "src/app/auth/register/page.tsx"
migrate_file "src/app/auth/error/page.tsx"
migrate_file "src/app/auth/test/page.tsx"

# Other pages
echo ""
echo "📁 Migrating Other pages..."
migrate_file "src/app/page.tsx"
migrate_file "src/app/not-found.tsx"
migrate_file "src/app/unauthorized/page.tsx"
migrate_file "src/app/test-api/page.tsx"

echo ""
echo "===================================="
echo -e "${GREEN}✓ Migration completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the changes"
echo "2. Test in both light and dark mode"
echo "3. Run: npm run dev"
echo "4. If issues, restore from .backup files"
echo ""
echo "To restore all backups:"
echo "  find src -name '*.backup' -exec bash -c 'mv \"\$0\" \"\${0%.backup}\"' {} \;"
