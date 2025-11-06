-- Quick fix: Add phone column to booking_guests table
ALTER TABLE booking_guests 
ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Verify
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'booking_guests' 
AND column_name = 'phone';
