@echo off
echo Running all migrations...
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database\migrations\006_create_confirm_booking_function.sql
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database\migrations\007_create_cancel_booking_function.sql
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database\migrations\008_create_release_expired_holds_function.sql
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database\migrations\009_create_check_in_function.sql
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database\migrations\010_create_check_out_function.sql
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database\migrations\011_create_move_room_function.sql
docker exec -i hotel-booking-db psql -U postgres -d hotel_booking < database\migrations\012_performance_optimization.sql
echo All migrations completed!
pause
