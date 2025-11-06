# PowerShell script to test Reporting Module endpoints
# Make sure the backend server is running before executing this script

$BASE_URL = "http://localhost:8080/api"
$MANAGER_TOKEN = ""

Write-Host "=== Hotel Booking System - Reporting Module Test ===" -ForegroundColor Cyan
Write-Host ""

# Function to make API requests
function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [string]$Token = ""
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($Token) {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    try {
        $params = @{
            Method = $Method
            Uri = "$BASE_URL$Endpoint"
            Headers = $headers
        }
        
        if ($Body) {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }
        
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
$loginResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/auth/login" -Body @{
    email = "manager@hotel.com"
    password = "manager123"
}

if ($loginResponse -and $loginResponse.token) {
    $MANAGER_TOKEN = $loginResponse.token
    Write-Host "✓ Manager logged in successfully" -ForegroundColor Green
    Write-Host "Token: $($MANAGER_TOKEN.Substring(0, 20))..." -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to login as manager" -ForegroundColor Red
    Write-Host "Please ensure you have a manager account with email: manager@hotel.com, password: manager123" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Calculate date ranges
$today = Get-Date
$startDate = $today.AddDays(-30).ToString("yyyy-MM-dd")
$endDate = $today.ToString("yyyy-MM-dd")

# Step 2: Get Occupancy Report
Write-Host "Step 2: Get Occupancy Report (Last 30 days)" -ForegroundColor Yellow
$occupancyReport = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/occupancy?start_date=$startDate&end_date=$endDate" -Token $MANAGER_TOKEN

if ($occupancyReport) {
    Write-Host "✓ Occupancy report retrieved successfully" -ForegroundColor Green
    Write-Host "Total records: $($occupancyReport.data.Count)" -ForegroundColor Gray
    if ($occupancyReport.data.Count -gt 0) {
        $sample = $occupancyReport.data[0]
        Write-Host "Sample: Date=$($sample.date), Occupancy Rate=$($sample.occupancy_rate)%" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Failed to get occupancy report" -ForegroundColor Red
}

Write-Host ""

# Step 3: Get Revenue Report
Write-Host "Step 3: Get Revenue Report (Last 30 days)" -ForegroundColor Yellow
$revenueReport = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/revenue?start_date=$startDate&end_date=$endDate" -Token $MANAGER_TOKEN

if ($revenueReport) {
    Write-Host "✓ Revenue report retrieved successfully" -ForegroundColor Green
    Write-Host "Total records: $($revenueReport.data.Count)" -ForegroundColor Gray
    if ($revenueReport.data.Count -gt 0) {
        $sample = $revenueReport.data[0]
        Write-Host "Sample: Date=$($sample.date), Revenue=$($sample.total_revenue), ADR=$($sample.adr)" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Failed to get revenue report" -ForegroundColor Red
}

Write-Host ""

# Step 4: Get Voucher Report
Write-Host "Step 4: Get Voucher Report (Last 30 days)" -ForegroundColor Yellow
$voucherReport = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/vouchers?start_date=$startDate&end_date=$endDate" -Token $MANAGER_TOKEN

if ($voucherReport) {
    Write-Host "✓ Voucher report retrieved successfully" -ForegroundColor Green
    Write-Host "Total vouchers: $($voucherReport.data.Count)" -ForegroundColor Gray
    if ($voucherReport.data.Count -gt 0) {
        $sample = $voucherReport.data[0]
        Write-Host "Sample: Code=$($sample.code), Uses=$($sample.total_uses), Discount=$($sample.total_discount)" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Failed to get voucher report" -ForegroundColor Red
}

Write-Host ""

# Step 5: Get No-Show Report
Write-Host "Step 5: Get No-Show Report (Last 30 days)" -ForegroundColor Yellow
$noShowReport = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/no-shows?start_date=$startDate&end_date=$endDate" -Token $MANAGER_TOKEN

if ($noShowReport) {
    Write-Host "✓ No-show report retrieved successfully" -ForegroundColor Green
    Write-Host "Total no-shows: $($noShowReport.data.Count)" -ForegroundColor Gray
    if ($noShowReport.data.Count -gt 0) {
        $sample = $noShowReport.data[0]
        Write-Host "Sample: Booking ID=$($sample.booking_id), Guest=$($sample.guest_name), Penalty=$($sample.penalty_charged)" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Failed to get no-show report" -ForegroundColor Red
}

Write-Host ""

# Step 6: Get Report Summary
Write-Host "Step 6: Get Report Summary (Last 30 days)" -ForegroundColor Yellow
$summary = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/summary?start_date=$startDate&end_date=$endDate" -Token $MANAGER_TOKEN

if ($summary) {
    Write-Host "✓ Report summary retrieved successfully" -ForegroundColor Green
    Write-Host "Total Revenue: $($summary.total_revenue)" -ForegroundColor Gray
    Write-Host "Total Bookings: $($summary.total_bookings)" -ForegroundColor Gray
    Write-Host "Total Room Nights: $($summary.total_room_nights)" -ForegroundColor Gray
    Write-Host "Average Occupancy: $($summary.avg_occupancy)%" -ForegroundColor Gray
    Write-Host "ADR: $($summary.adr)" -ForegroundColor Gray
    Write-Host "No-Show Count: $($summary.no_show_count)" -ForegroundColor Gray
    Write-Host "No-Show Rate: $($summary.no_show_rate)%" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to get report summary" -ForegroundColor Red
}

Write-Host ""

# Step 7: Get Comparison Report (Year-over-Year)
Write-Host "Step 7: Get Comparison Report (Year-over-Year)" -ForegroundColor Yellow
$comparison = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/comparison?start_date=$startDate&end_date=$endDate" -Token $MANAGER_TOKEN

if ($comparison) {
    Write-Host "✓ Comparison report retrieved successfully" -ForegroundColor Green
    Write-Host "Current Period Revenue: $($comparison.current_period.total_revenue)" -ForegroundColor Gray
    Write-Host "Previous Period Revenue: $($comparison.previous_period.total_revenue)" -ForegroundColor Gray
    Write-Host "Revenue Change: $($comparison.revenue_change_percent)%" -ForegroundColor Gray
    Write-Host "Occupancy Change: $($comparison.occupancy_change_percent)%" -ForegroundColor Gray
    Write-Host "ADR Change: $($comparison.adr_change_percent)%" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to get comparison report" -ForegroundColor Red
}

Write-Host ""

# Step 8: Test Grouped Reports (Weekly)
Write-Host "Step 8: Get Occupancy Report (Grouped by Week)" -ForegroundColor Yellow
$weeklyOccupancy = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/occupancy?start_date=$startDate&end_date=$endDate&group_by=week" -Token $MANAGER_TOKEN

if ($weeklyOccupancy) {
    Write-Host "✓ Weekly occupancy report retrieved successfully" -ForegroundColor Green
    Write-Host "Total weeks: $($weeklyOccupancy.data.Count)" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to get weekly occupancy report" -ForegroundColor Red
}

Write-Host ""

# Step 9: Test CSV Export - Occupancy
Write-Host "Step 9: Export Occupancy Report to CSV" -ForegroundColor Yellow
try {
    $csvUrl = "$BASE_URL/reports/export/occupancy?start_date=$startDate&end_date=$endDate"
    $headers = @{
        "Authorization" = "Bearer $MANAGER_TOKEN"
    }
    
    $csvResponse = Invoke-WebRequest -Uri $csvUrl -Headers $headers -Method GET
    
    if ($csvResponse.StatusCode -eq 200) {
        $csvContent = $csvResponse.Content
        $outputFile = "occupancy_report_$startDate`_$endDate.csv"
        $csvContent | Out-File -FilePath $outputFile -Encoding UTF8
        Write-Host "✓ Occupancy report exported to CSV successfully" -ForegroundColor Green
        Write-Host "File saved: $outputFile" -ForegroundColor Gray
        Write-Host "First 3 lines:" -ForegroundColor Gray
        $csvContent.Split("`n")[0..2] | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
    }
} catch {
    Write-Host "✗ Failed to export occupancy report to CSV" -ForegroundColor Red
}

Write-Host ""

# Step 10: Test CSV Export - Revenue
Write-Host "Step 10: Export Revenue Report to CSV" -ForegroundColor Yellow
try {
    $csvUrl = "$BASE_URL/reports/export/revenue?start_date=$startDate&end_date=$endDate"
    $headers = @{
        "Authorization" = "Bearer $MANAGER_TOKEN"
    }
    
    $csvResponse = Invoke-WebRequest -Uri $csvUrl -Headers $headers -Method GET
    
    if ($csvResponse.StatusCode -eq 200) {
        $csvContent = $csvResponse.Content
        $outputFile = "revenue_report_$startDate`_$endDate.csv"
        $csvContent | Out-File -FilePath $outputFile -Encoding UTF8
        Write-Host "✓ Revenue report exported to CSV successfully" -ForegroundColor Green
        Write-Host "File saved: $outputFile" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to export revenue report to CSV" -ForegroundColor Red
}

Write-Host ""

# Step 11: Test with Room Type Filter
Write-Host "Step 11: Get Revenue Report (Filtered by Room Type)" -ForegroundColor Yellow
$filteredRevenue = Invoke-ApiRequest -Method "GET" -Endpoint "/reports/revenue?start_date=$startDate&end_date=$endDate&room_type_id=1" -Token $MANAGER_TOKEN

if ($filteredRevenue) {
    Write-Host "✓ Filtered revenue report retrieved successfully" -ForegroundColor Green
    Write-Host "Total records: $($filteredRevenue.data.Count)" -ForegroundColor Gray
} else {
    Write-Host "✗ Failed to get filtered revenue report" -ForegroundColor Red
}

Write-Host ""

# Summary
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "All reporting module endpoints have been tested." -ForegroundColor Green
Write-Host ""
Write-Host "Available Endpoints:" -ForegroundColor Yellow
Write-Host "  GET /api/reports/occupancy - Get occupancy statistics" -ForegroundColor Gray
Write-Host "  GET /api/reports/revenue - Get revenue statistics" -ForegroundColor Gray
Write-Host "  GET /api/reports/vouchers - Get voucher usage statistics" -ForegroundColor Gray
Write-Host "  GET /api/reports/no-shows - Get no-show statistics" -ForegroundColor Gray
Write-Host "  GET /api/reports/summary - Get aggregated summary" -ForegroundColor Gray
Write-Host "  GET /api/reports/comparison - Get year-over-year comparison" -ForegroundColor Gray
Write-Host "  GET /api/reports/export/occupancy - Export occupancy to CSV" -ForegroundColor Gray
Write-Host "  GET /api/reports/export/revenue - Export revenue to CSV" -ForegroundColor Gray
Write-Host "  GET /api/reports/export/vouchers - Export vouchers to CSV" -ForegroundColor Gray
Write-Host "  GET /api/reports/export/no-shows - Export no-shows to CSV" -ForegroundColor Gray
Write-Host ""
Write-Host "Query Parameters:" -ForegroundColor Yellow
Write-Host "  start_date (required) - Start date in YYYY-MM-DD format" -ForegroundColor Gray
Write-Host "  end_date (required) - End date in YYYY-MM-DD format" -ForegroundColor Gray
Write-Host "  room_type_id (optional) - Filter by room type" -ForegroundColor Gray
Write-Host "  rate_plan_id (optional) - Filter by rate plan" -ForegroundColor Gray
Write-Host "  group_by (optional) - Group by: day, week, month (default: day)" -ForegroundColor Gray
Write-Host ""
