@echo off
echo ========================================
echo Test Complete Booking Flow
echo ========================================
echo.

set TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJlbWFpbCI6ImFuYW4udGVzdEBleGFtcGxlLmNvbSIsInJvbGUiOiJHVUVTVCIsInVzZXJfdHlwZSI6Imd1ZXN0IiwiaXNzIjoiYm9va2luZy1ob3RlbC1hcGkiLCJzdWIiOiJhbmFuLnRlc3RAZXhhbXBsZS5jb20iLCJleHAiOjE3NjI0Mzg3MDcsIm5iZiI6MTc2MjM1MjMwNywiaWF0IjoxNzYyMzUyMzA3fQ.Be1pKTGeTGXS665t2ABUMoUT_DGiGsEW4hdWzWfWDJY

echo Testing create booking...
curl -X POST http://localhost:8080/api/bookings ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -d "{\"details\":[{\"room_type_id\":1,\"rate_plan_id\":1,\"check_in\":\"2025-11-06\",\"check_out\":\"2025-11-07\",\"num_guests\":2,\"guests\":[{\"first_name\":\"John\",\"last_name\":\"Doe\",\"type\":\"Adult\",\"is_primary\":true}]}]}"

echo.
echo.
pause
