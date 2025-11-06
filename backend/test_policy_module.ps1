# PowerShell script to test Policy & Voucher Management Module
# Usage: .\test_policy_module.ps1

$BASE_URL = "http://localhost:8080/api"
$MANAGER_EMAIL = "manager@hotel.com"
$MANAGER_PASSWORD = "password123"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Policy & Voucher Management Module Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to make HTTP requests
function Invoke-APIRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [string]$Token = $null
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($Token) {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    $params = @{
        Method = $Method
        Uri = "$BASE_URL$Endpoint"
        Headers = $headers
    }
    
    if ($Body) {
        $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
    }
    
    try {
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response: $responseBody" -ForegroundColor Red
        }
        return $null
    }
}

# Step 1: Login as Manager
Write-Host "Step 1: Login as Manager" -ForegroundColor Yellow
$loginBody = @{
    email = $MANAGER_EMAIL
    password = $MANAGER_PASSWORD
}

$loginResponse = Invoke-APIRequest -Method "POST" -Endpoint "/auth/login" -Body $loginBody

if (-not $loginResponse -or -not $loginResponse.success) {
    Write-Host "Failed to login. Please ensure the manager account exists." -ForegroundColor Red
    Write-Host "You can create it by running the seed data script." -ForegroundColor Red
    exit 1
}

$TOKEN = $loginResponse.data.accessToken
Write-Host "✓ Login successful" -ForegroundColor Green
Write-Host ""

# Step 2: Test Cancellation Policies
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Cancellation Policies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get all cancellation policies
Write-Host "Step 2.1: Get all cancellation policies" -ForegroundColor Yellow
$policies = Invoke-APIRequest -Method "GET" -Endpoint "/policies/cancellation" -Token $TOKEN

if ($policies -and $policies.success) {
    Write-Host "✓ Retrieved $($policies.data.Count) cancellation policies" -ForegroundColor Green
    $policies.data | ForEach-Object {
        Write-Host "  - $($_.name): $($_.refund_percentage)% refund if cancelled $($_.days_before_check_in) days before check-in" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Failed to retrieve cancellation policies" -ForegroundColor Red
}
Write-Host ""

# Create a new cancellation policy
Write-Host "Step 2.2: Create a new cancellation policy" -ForegroundColor Yellow
$newPolicy = @{
    name = "Test Flexible Policy"
    description = "Full refund if cancelled 7 days before check-in"
    days_before_check_in = 7
    refund_percentage = 100
}

$createdPolicy = Invoke-APIRequest -Method "POST" -Endpoint "/policies/cancellation" -Body $newPolicy -Token $TOKEN

if ($createdPolicy -and $createdPolicy.success) {
    Write-Host "✓ Created cancellation policy: $($createdPolicy.data.name)" -ForegroundColor Green
    $POLICY_ID = $createdPolicy.data.policy_id
} else {
    Write-Host "✗ Failed to create cancellation policy" -ForegroundColor Red
}
Write-Host ""

# Get policy by ID
if ($POLICY_ID) {
    Write-Host "Step 2.3: Get cancellation policy by ID" -ForegroundColor Yellow
    $policy = Invoke-APIRequest -Method "GET" -Endpoint "/policies/cancellation/$POLICY_ID" -Token $TOKEN
    
    if ($policy -and $policy.success) {
        Write-Host "✓ Retrieved policy: $($policy.data.name)" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to retrieve policy" -ForegroundColor Red
    }
    Write-Host ""
}

# Update cancellation policy
if ($POLICY_ID) {
    Write-Host "Step 2.4: Update cancellation policy" -ForegroundColor Yellow
    $updatePolicy = @{
        refund_percentage = 90
        description = "90% refund if cancelled 7 days before check-in"
    }
    
    $updatedPolicy = Invoke-APIRequest -Method "PUT" -Endpoint "/policies/cancellation/$POLICY_ID" -Body $updatePolicy -Token $TOKEN
    
    if ($updatedPolicy -and $updatedPolicy.success) {
        Write-Host "✓ Updated policy: $($updatedPolicy.data.name)" -ForegroundColor Green
        Write-Host "  New refund percentage: $($updatedPolicy.data.refund_percentage)%" -ForegroundColor Gray
    } else {
        Write-Host "✗ Failed to update policy" -ForegroundColor Red
    }
    Write-Host ""
}

# Step 3: Test Vouchers
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Vouchers" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get all vouchers
Write-Host "Step 3.1: Get all vouchers" -ForegroundColor Yellow
$vouchers = Invoke-APIRequest -Method "GET" -Endpoint "/vouchers" -Token $TOKEN

if ($vouchers -and $vouchers.success) {
    Write-Host "✓ Retrieved $($vouchers.data.Count) vouchers" -ForegroundColor Green
    $vouchers.data | ForEach-Object {
        Write-Host "  - $($_.code): $($_.discount_value)$(if ($_.discount_type -eq 'Percentage') { '%' } else { ' THB' }) off (Uses: $($_.current_uses)/$($_.max_uses))" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Failed to retrieve vouchers" -ForegroundColor Red
}
Write-Host ""

# Create a new voucher
Write-Host "Step 3.2: Create a new voucher" -ForegroundColor Yellow
$futureDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
$newVoucher = @{
    code = "TESTCODE2024"
    discount_type = "Percentage"
    discount_value = 20
    expiry_date = $futureDate
    max_uses = 100
}

$createdVoucher = Invoke-APIRequest -Method "POST" -Endpoint "/vouchers" -Body $newVoucher -Token $TOKEN

if ($createdVoucher -and $createdVoucher.success) {
    Write-Host "✓ Created voucher: $($createdVoucher.data.code)" -ForegroundColor Green
    $VOUCHER_ID = $createdVoucher.data.voucher_id
} else {
    Write-Host "✗ Failed to create voucher" -ForegroundColor Red
}
Write-Host ""

# Get voucher by ID
if ($VOUCHER_ID) {
    Write-Host "Step 3.3: Get voucher by ID" -ForegroundColor Yellow
    $voucher = Invoke-APIRequest -Method "GET" -Endpoint "/vouchers/$VOUCHER_ID" -Token $TOKEN
    
    if ($voucher -and $voucher.success) {
        Write-Host "✓ Retrieved voucher: $($voucher.data.code)" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to retrieve voucher" -ForegroundColor Red
    }
    Write-Host ""
}

# Validate voucher (public endpoint)
Write-Host "Step 3.4: Validate voucher (public endpoint)" -ForegroundColor Yellow
$validateRequest = @{
    code = "TESTCODE2024"
    total_amount = 5000
}

$validation = Invoke-APIRequest -Method "POST" -Endpoint "/vouchers/validate" -Body $validateRequest

if ($validation -and $validation.success) {
    $result = $validation.data
    if ($result.valid) {
        Write-Host "✓ Voucher is valid" -ForegroundColor Green
        Write-Host "  Discount Type: $($result.discount_type)" -ForegroundColor Gray
        Write-Host "  Discount Value: $($result.discount_value)" -ForegroundColor Gray
        Write-Host "  Discount Amount: $($result.discount_amount) THB" -ForegroundColor Gray
        Write-Host "  Final Amount: $($result.final_amount) THB" -ForegroundColor Gray
    } else {
        Write-Host "✗ Voucher is invalid: $($result.message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Failed to validate voucher" -ForegroundColor Red
}
Write-Host ""

# Update voucher
if ($VOUCHER_ID) {
    Write-Host "Step 3.5: Update voucher" -ForegroundColor Yellow
    $updateVoucher = @{
        discount_value = 25
        max_uses = 150
    }
    
    $updatedVoucher = Invoke-APIRequest -Method "PUT" -Endpoint "/vouchers/$VOUCHER_ID" -Body $updateVoucher -Token $TOKEN
    
    if ($updatedVoucher -and $updatedVoucher.success) {
        Write-Host "✓ Updated voucher: $($updatedVoucher.data.code)" -ForegroundColor Green
        Write-Host "  New discount value: $($updatedVoucher.data.discount_value)%" -ForegroundColor Gray
        Write-Host "  New max uses: $($updatedVoucher.data.max_uses)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Failed to update voucher" -ForegroundColor Red
    }
    Write-Host ""
}

# Test validation with invalid voucher
Write-Host "Step 3.6: Test validation with invalid voucher code" -ForegroundColor Yellow
$invalidValidation = @{
    code = "INVALIDCODE"
    total_amount = 5000
}

$invalidResult = Invoke-APIRequest -Method "POST" -Endpoint "/vouchers/validate" -Body $invalidValidation

if ($invalidResult -and $invalidResult.success) {
    $result = $invalidResult.data
    if (-not $result.valid) {
        Write-Host "✓ Correctly identified invalid voucher: $($result.message)" -ForegroundColor Green
    } else {
        Write-Host "✗ Should have rejected invalid voucher" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Failed to validate voucher" -ForegroundColor Red
}
Write-Host ""

# Test validation with expired voucher
Write-Host "Step 3.7: Create and test expired voucher" -ForegroundColor Yellow
$pastDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$expiredVoucher = @{
    code = "EXPIRED2024"
    discount_type = "FixedAmount"
    discount_value = 500
    expiry_date = $pastDate
    max_uses = 10
}

$createdExpired = Invoke-APIRequest -Method "POST" -Endpoint "/vouchers" -Body $expiredVoucher -Token $TOKEN

if ($createdExpired -and $createdExpired.success) {
    Write-Host "✓ Created expired voucher for testing" -ForegroundColor Green
    
    $expiredValidation = @{
        code = "EXPIRED2024"
        total_amount = 5000
    }
    
    $expiredResult = Invoke-APIRequest -Method "POST" -Endpoint "/vouchers/validate" -Body $expiredValidation
    
    if ($expiredResult -and $expiredResult.success) {
        $result = $expiredResult.data
        if (-not $result.valid -and $result.message -like "*expired*") {
            Write-Host "✓ Correctly identified expired voucher: $($result.message)" -ForegroundColor Green
        } else {
            Write-Host "✗ Should have rejected expired voucher" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Note: Could not create expired voucher (validation may prevent past dates)" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Cleanup
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Delete test voucher
if ($VOUCHER_ID) {
    Write-Host "Step 4.1: Delete test voucher" -ForegroundColor Yellow
    $deleteVoucher = Invoke-APIRequest -Method "DELETE" -Endpoint "/vouchers/$VOUCHER_ID" -Token $TOKEN
    
    if ($deleteVoucher -and $deleteVoucher.success) {
        Write-Host "✓ Deleted test voucher" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to delete voucher" -ForegroundColor Red
    }
    Write-Host ""
}

# Delete test policy
if ($POLICY_ID) {
    Write-Host "Step 4.2: Delete test cancellation policy" -ForegroundColor Yellow
    $deletePolicy = Invoke-APIRequest -Method "DELETE" -Endpoint "/policies/cancellation/$POLICY_ID" -Token $TOKEN
    
    if ($deletePolicy -and $deletePolicy.success) {
        Write-Host "✓ Deleted test policy" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to delete policy" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
