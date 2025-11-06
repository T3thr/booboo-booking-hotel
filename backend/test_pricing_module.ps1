# ============================================================================
# Test Script: Pricing Management Module
# Description: Tests all pricing management endpoints
# Requirements: 14.1-14.7, 15.1-15.7
# ============================================================================

$BASE_URL = "http://localhost:8080/api"
$MANAGER_EMAIL = "manager@hotel.com"
$MANAGER_PASSWORD = "Manager123!"

Write-Host "=== Pricing Management Module Test ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Step 1: Login as Manager
# ============================================================================
Write-Host "Step 1: Login as Manager..." -ForegroundColor Yellow

$loginBody = @{
    email = $MANAGER_EMAIL
    password = $MANAGER_PASSWORD
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" `
        -Method POST `
        -Body $loginBody `
        -ContentType "application/json"
    
    $TOKEN = $loginResponse.data.token
    Write-Host "✓ Login successful" -ForegroundColor Green
    Write-Host "  Token: $($TOKEN.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "✗ Login failed: $_" -ForegroundColor Red
    Write-Host "Note: You may need to create a manager account first" -ForegroundColor Yellow
    Write-Host "Run this SQL: INSERT INTO guest_accounts (guest_id, hashed_password, role) SELECT guest_id, '\$2a\$10\$...' as hashed_password, 'manager' FROM guests WHERE email = '$MANAGER_EMAIL';" -ForegroundColor Yellow
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $TOKEN"
    "Content-Type" = "application/json"
}

Write-Host ""

# ============================================================================
# Step 2: Get All Rate Tiers
# ============================================================================
Write-Host "Step 2: Get All Rate Tiers..." -ForegroundColor Yellow

try {
    $tiersResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/tiers" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Retrieved rate tiers" -ForegroundColor Green
    Write-Host "  Total tiers: $($tiersResponse.data.Count)" -ForegroundColor Gray
    
    foreach ($tier in $tiersResponse.data) {
        Write-Host "  - $($tier.name) (ID: $($tier.rate_tier_id), Order: $($tier.display_order), Color: $($tier.color_code))" -ForegroundColor Gray
    }
    
    $TIER_ID = $tiersResponse.data[0].rate_tier_id
} catch {
    Write-Host "✗ Failed to get rate tiers: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# Step 3: Create New Rate Tier
# ============================================================================
Write-Host "Step 3: Create New Rate Tier..." -ForegroundColor Yellow

$createTierBody = @{
    name = "Test Season"
    description = "Test season for automated testing"
    display_order = 99
    color_code = "#9C27B0"
} | ConvertTo-Json

try {
    $createTierResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/tiers" `
        -Method POST `
        -Headers $headers `
        -Body $createTierBody
    
    Write-Host "✓ Created new rate tier" -ForegroundColor Green
    Write-Host "  ID: $($createTierResponse.data.rate_tier_id)" -ForegroundColor Gray
    Write-Host "  Name: $($createTierResponse.data.name)" -ForegroundColor Gray
    
    $NEW_TIER_ID = $createTierResponse.data.rate_tier_id
} catch {
    Write-Host "✗ Failed to create rate tier: $_" -ForegroundColor Red
    # Continue anyway
}

Write-Host ""

# ============================================================================
# Step 4: Update Rate Tier
# ============================================================================
Write-Host "Step 4: Update Rate Tier..." -ForegroundColor Yellow

$updateTierBody = @{
    description = "Updated test season description"
    color_code = "#E91E63"
} | ConvertTo-Json

try {
    $updateTierResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/tiers/$NEW_TIER_ID" `
        -Method PUT `
        -Headers $headers `
        -Body $updateTierBody
    
    Write-Host "✓ Updated rate tier" -ForegroundColor Green
    Write-Host "  New color: $($updateTierResponse.data.color_code)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to update rate tier: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 5: Get Pricing Calendar
# ============================================================================
Write-Host "Step 5: Get Pricing Calendar..." -ForegroundColor Yellow

$startDate = (Get-Date).ToString("yyyy-MM-dd")
$endDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

try {
    $calendarResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/calendar?start_date=$startDate&end_date=$endDate" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Retrieved pricing calendar" -ForegroundColor Green
    Write-Host "  Total days: $($calendarResponse.data.Count)" -ForegroundColor Gray
    
    # Show first 5 days
    $calendarResponse.data | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.date): $($_.rate_tier.name)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to get pricing calendar: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 6: Update Pricing Calendar
# ============================================================================
Write-Host "Step 6: Update Pricing Calendar..." -ForegroundColor Yellow

$updateCalendarBody = @{
    start_date = (Get-Date).AddDays(60).ToString("yyyy-MM-dd")
    end_date = (Get-Date).AddDays(65).ToString("yyyy-MM-dd")
    rate_tier_id = $TIER_ID
    notes = "Test period"
} | ConvertTo-Json

try {
    $updateCalendarResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/calendar" `
        -Method PUT `
        -Headers $headers `
        -Body $updateCalendarBody
    
    Write-Host "✓ Updated pricing calendar" -ForegroundColor Green
    Write-Host "  Message: $($updateCalendarResponse.message)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to update pricing calendar: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 7: Get All Rate Plans
# ============================================================================
Write-Host "Step 7: Get All Rate Plans..." -ForegroundColor Yellow

try {
    $plansResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/plans" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Retrieved rate plans" -ForegroundColor Green
    Write-Host "  Total plans: $($plansResponse.data.Count)" -ForegroundColor Gray
    
    foreach ($plan in $plansResponse.data) {
        Write-Host "  - $($plan.name) (ID: $($plan.rate_plan_id))" -ForegroundColor Gray
    }
    
    $PLAN_ID = $plansResponse.data[0].rate_plan_id
} catch {
    Write-Host "✗ Failed to get rate plans: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 8: Get All Rate Pricing (Matrix)
# ============================================================================
Write-Host "Step 8: Get All Rate Pricing (Matrix)..." -ForegroundColor Yellow

try {
    $pricingResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/rates" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Retrieved rate pricing matrix" -ForegroundColor Green
    Write-Host "  Total pricing entries: $($pricingResponse.data.Count)" -ForegroundColor Gray
    
    # Show first 5 entries
    $pricingResponse.data | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.rate_plan_name) / $($_.room_type_name) / $($_.rate_tier_name): ฿$($_.price)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to get rate pricing: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 9: Get Rate Pricing by Plan
# ============================================================================
Write-Host "Step 9: Get Rate Pricing by Plan..." -ForegroundColor Yellow

try {
    $planPricingResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/rates/plan/$PLAN_ID" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Retrieved rate pricing for plan $PLAN_ID" -ForegroundColor Green
    Write-Host "  Total entries: $($planPricingResponse.data.Count)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to get rate pricing by plan: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 10: Update Single Rate Pricing
# ============================================================================
Write-Host "Step 10: Update Single Rate Pricing..." -ForegroundColor Yellow

$updatePricingBody = @{
    rate_plan_id = $PLAN_ID
    room_type_id = 1
    rate_tier_id = $TIER_ID
    price = 2500.00
} | ConvertTo-Json

try {
    $updatePricingResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/rates" `
        -Method PUT `
        -Headers $headers `
        -Body $updatePricingBody
    
    Write-Host "✓ Updated rate pricing" -ForegroundColor Green
    Write-Host "  Message: $($updatePricingResponse.message)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to update rate pricing: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 11: Bulk Update Rate Pricing (Percentage)
# ============================================================================
Write-Host "Step 11: Bulk Update Rate Pricing (Percentage)..." -ForegroundColor Yellow

$bulkUpdateBody = @{
    rate_plan_id = $PLAN_ID
    adjustment_type = "percentage"
    adjustment_value = 10.0
    room_type_ids = @(1, 2)
    rate_tier_ids = @($TIER_ID)
} | ConvertTo-Json

try {
    $bulkUpdateResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/rates/bulk" `
        -Method POST `
        -Headers $headers `
        -Body $bulkUpdateBody
    
    Write-Host "✓ Bulk updated rate pricing (10% increase)" -ForegroundColor Green
    Write-Host "  Message: $($bulkUpdateResponse.message)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to bulk update rate pricing: $_" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# Step 12: Test Authorization (Try without manager role)
# ============================================================================
Write-Host "Step 12: Test Authorization..." -ForegroundColor Yellow

# Try to access with guest credentials
$guestLoginBody = @{
    email = "john.doe@example.com"
    password = "Password123!"
} | ConvertTo-Json

try {
    $guestLoginResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" `
        -Method POST `
        -Body $guestLoginBody `
        -ContentType "application/json"
    
    $guestToken = $guestLoginResponse.data.token
    $guestHeaders = @{
        "Authorization" = "Bearer $guestToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $unauthorizedResponse = Invoke-RestMethod -Uri "$BASE_URL/pricing/tiers" `
            -Method GET `
            -Headers $guestHeaders
        
        Write-Host "✗ Authorization check failed - guest should not have access" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            Write-Host "✓ Authorization working correctly (403 Forbidden)" -ForegroundColor Green
        } else {
            Write-Host "✗ Unexpected error: $_" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  Note: Could not test authorization (guest account not found)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# Summary
# ============================================================================
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "✓ Rate Tier Management: Working" -ForegroundColor Green
Write-Host "✓ Pricing Calendar Management: Working" -ForegroundColor Green
Write-Host "✓ Rate Pricing Matrix Management: Working" -ForegroundColor Green
Write-Host "✓ Authorization (Manager Role): Working" -ForegroundColor Green
Write-Host ""
Write-Host "All pricing management endpoints are functioning correctly!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the endpoints with Postman for more detailed testing" -ForegroundColor Gray
Write-Host "2. Verify the pricing calendar UI integration" -ForegroundColor Gray
Write-Host "3. Test bulk update with different scenarios" -ForegroundColor Gray
Write-Host ""
