$response = Invoke-RestMethod -Uri "http://localhost:8080/api/rooms/search?checkIn=2025-11-06&checkOut=2025-11-08&guests=2"
Write-Host "=== API Response ===" -ForegroundColor Green
$response | ConvertTo-Json -Depth 10
Write-Host "`n=== Room Types ===" -ForegroundColor Yellow
foreach ($room in $response.data.room_types) {
    Write-Host "`nRoom: $($room.name)" -ForegroundColor Cyan
    Write-Host "  - available_rooms: $($room.available_rooms)"
    Write-Host "  - max_occupancy: $($room.max_occupancy)"
    Write-Host "  - total_price: $($room.total_price)"
}
