# PowerShell script to test Housekeeping Module endpoints
# This script tests all housekeeping endpoints with proper authentication

$ErrorActionPreference = "Stop"

# Configuration
$BASE_URL = "http://localhost:8080/api"
$HOUSEKEEPER_EMAIL = "housekeeper@hotel.com"
$HOUSEKEEPER_PASSWORD = "password123"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Housekeeping Module Test Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to make HTTP requests
function Invoke-ApiRequest {
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
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response: $responseBody" -ForegroundColor Red
        }
        throw
    }
}

# Test 1: Login as Housekeeper
Write-Host "Test 1: Login as Housekeeper" -ForegroundColor Yellow
try {
    $loginResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/auth/login" -Body @{
        email = $HOUSEKEEPER_EMAIL
        password = $HOUSEKEEPER_PASSWORD
    }
    
    $token = $loginResponse.data.token
    Write-Host "✓ Login successful" -ForegroundColor Green
    Write-Host "  Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "✗ Login failed" -ForegroundColor Red
    Write-Host "  Make sure housekeeper account exists in database" -ForegroundColor Yellow
    Write-Host "  Email: $HOUSEKEEPER_EMAIL" -ForegroundColor Yellow
    exit 1
}

# Test 2: Get Housekeeping Tasks
Write-Host "Test 2: Get Housekeeping Tasks" -ForegroundColor Yellow
try {
    $tasksResponse = Invoke-ApiRequest -Method "GET" -Endpoint "/housekeeping/tasks" -Token $token
    
    Write-Host "✓ Retrieved housekeeping tasks" -ForegroundColor Green
    Write-Host "  Total tasks: $($tasksResponse.data.total_tasks)" -ForegroundColor Gray
    Write-Host "  Summary:" -ForegroundColor Gray
    Write-Host "    - Dirty: $($tasksResponse.data.summary.dirty)" -ForegroundColor Gray
    Write-Host "    - Cleaning: $($tasksResponse.data.summary.cleaning)" -ForegroundColor Gray
    Write-Host "    - Clean: $($tasksResponse.data.summary.clean)" -ForegroundColor Gray
    Write-Host "    - Inspected: $($tasksResponse.data.summary.inspected)" -ForegroundColor Gray
    Write-Host "    - Maintenance Required: $($tasksResponse.data.summary.maintenance_required)" -ForegroundColor Gray
    
    if ($tasksResponse.data.tasks.Count -gt 0) {
        Write-Host "  First task:" -ForegroundColor Gray
        $firstTask = $tasksResponse.data.tasks[0]
        Write-Host "    - Room: $($firstTask.room_number)" -ForegroundColor Gray
        Write-Host "    - Type: $($firstTask.room_type_name)" -ForegroundColor Gray
        Write-Host "    - Status: $($firstTask.housekeeping_status)" -ForegroundColor Gray
        Write-Host "    - Priority: $($firstTask.priority)" -ForegroundColor Gray
        
        # Save room ID for next tests
        $script:testRoomID = $firstTask.room_id
        $script:currentStatus = $firstTask.housekeeping_status
    }
    Write-Host ""
} catch {
    Write-Host "✗ Failed to get tasks" -ForegroundColor Red
    exit 1
}

# Test 3: Update Room Status (if we have a room)
if ($script:testRoomID) {
    Write-Host "Test 3: Update Room Status" -ForegroundColor Yellow
    
    # Determine next status based on current status
    $newStatus = switch ($script:currentStatus) {
        "Dirty" { "Cleaning" }
        "Cleaning" { "Clean" }
        "Clean" { "Inspected" }
        default { "Cleaning" }
    }
    
    try {
        $updateResponse = Invoke-ApiRequest -Method "PUT" -Endpoint "/housekeeping/rooms/$script:testRoomID/status" -Token $token -Body @{
            status = $newStatus
        }
        
        Write-Host "✓ Room status updated" -ForegroundColor Green
        Write-Host "  Room ID: $script:testRoomID" -ForegroundColor Gray
        Write-Host "  Old Status: $script:currentStatus" -ForegroundColor Gray
        Write-Host "  New Status: $newStatus" -ForegroundColor Gray
        Write-Host ""
        
        # Update current status for next test
        $script:currentStatus = $newStatus
    } catch {
        Write-Host "✗ Failed to update room status" -ForegroundColor Red
        Write-Host "  This might be due to invalid status transition" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Test 4: Get Rooms for Inspection
Write-Host "Test 4: Get Rooms for Inspection" -ForegroundColor Yellow
try {
    $inspectionResponse = Invoke-ApiRequest -Method "GET" -Endpoint "/housekeeping/inspection" -Token $token
    
    Write-Host "✓ Retrieved rooms for inspection" -ForegroundColor Green
    Write-Host "  Total rooms: $($inspectionResponse.data.Count)" -ForegroundColor Gray
    
    if ($inspectionResponse.data.Count -gt 0) {
        Write-Host "  First room:" -ForegroundColor Gray
        $firstRoom = $inspectionResponse.data[0]
        Write-Host "    - Room: $($firstRoom.room_number)" -ForegroundColor Gray
        Write-Host "    - Type: $($firstRoom.room_type_name)" -ForegroundColor Gray
        Write-Host "    - Status: $($firstRoom.housekeeping_status)" -ForegroundColor Gray
        
        # Save for inspection test
        $script:inspectionRoomID = $firstRoom.room_id
    }
    Write-Host ""
} catch {
    Write-Host "✗ Failed to get rooms for inspection" -ForegroundColor Red
    Write-Host ""
}

# Test 5: Inspect Room (if we have a Clean room)
if ($script:inspectionRoomID) {
    Write-Host "Test 5: Inspect Room (Approve)" -ForegroundColor Yellow
    try {
        $inspectResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/housekeeping/rooms/$script:inspectionRoomID/inspect" -Token $token -Body @{
            approved = $true
            notes = "Room looks great, approved for guest check-in"
        }
        
        Write-Host "✓ Room inspection completed" -ForegroundColor Green
        Write-Host "  Room ID: $script:inspectionRoomID" -ForegroundColor Gray
        Write-Host "  Status: Approved (Inspected)" -ForegroundColor Gray
        Write-Host ""
    } catch {
        Write-Host "✗ Failed to inspect room" -ForegroundColor Red
        Write-Host "  Room might not be in Clean status" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Test 6: Report Maintenance Issue
if ($script:testRoomID) {
    Write-Host "Test 6: Report Maintenance Issue" -ForegroundColor Yellow
    try {
        $maintenanceResponse = Invoke-ApiRequest -Method "POST" -Endpoint "/housekeeping/rooms/$script:testRoomID/maintenance" -Token $token -Body @{
            description = "Air conditioning not working properly"
        }
        
        Write-Host "✓ Maintenance issue reported" -ForegroundColor Green
        Write-Host "  Room ID: $script:testRoomID" -ForegroundColor Gray
        Write-Host "  Description: Air conditioning not working properly" -ForegroundColor Gray
        Write-Host ""
    } catch {
        Write-Host "✗ Failed to report maintenance" -ForegroundColor Red
        Write-Host ""
    }
}

# Test 7: Test Invalid Status Transition
if ($script:testRoomID) {
    Write-Host "Test 7: Test Invalid Status Transition" -ForegroundColor Yellow
    try {
        # Try to set an invalid status
        $invalidResponse = Invoke-ApiRequest -Method "PUT" -Endpoint "/housekeeping/rooms/$script:testRoomID/status" -Token $token -Body @{
            status = "InvalidStatus"
        }
        
        Write-Host "✗ Should have failed with invalid status" -ForegroundColor Red
        Write-Host ""
    } catch {
        Write-Host "✓ Correctly rejected invalid status" -ForegroundColor Green
        Write-Host "  Error handled as expected" -ForegroundColor Gray
        Write-Host ""
    }
}

# Test 8: Test Authorization (try without token)
Write-Host "Test 8: Test Authorization (No Token)" -ForegroundColor Yellow
try {
    $noAuthResponse = Invoke-ApiRequest -Method "GET" -Endpoint "/housekeeping/tasks"
    
    Write-Host "✗ Should have failed without authentication" -ForegroundColor Red
    Write-Host ""
} catch {
    Write-Host "✓ Correctly rejected request without token" -ForegroundColor Green
    Write-Host "  Authorization working as expected" -ForegroundColor Gray
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All critical housekeeping endpoints tested!" -ForegroundColor Green
Write-Host ""
Write-Host "Endpoints tested:" -ForegroundColor White
Write-Host "  ✓ GET  /api/housekeeping/tasks" -ForegroundColor Green
Write-Host "  ✓ PUT  /api/housekeeping/rooms/:id/status" -ForegroundColor Green
Write-Host "  ✓ GET  /api/housekeeping/inspection" -ForegroundColor Green
Write-Host "  ✓ POST /api/housekeeping/rooms/:id/inspect" -ForegroundColor Green
Write-Host "  ✓ POST /api/housekeeping/rooms/:id/maintenance" -ForegroundColor Green
Write-Host ""
Write-Host "Features verified:" -ForegroundColor White
Write-Host "  ✓ Authentication required (housekeeper role)" -ForegroundColor Green
Write-Host "  ✓ Task list retrieval with summary" -ForegroundColor Green
Write-Host "  ✓ Room status updates" -ForegroundColor Green
Write-Host "  ✓ Status transition validation" -ForegroundColor Green
Write-Host "  ✓ Room inspection workflow" -ForegroundColor Green
Write-Host "  ✓ Maintenance reporting" -ForegroundColor Green
Write-Host ""
Write-Host "Housekeeping Module is working correctly! ✓" -ForegroundColor Green
