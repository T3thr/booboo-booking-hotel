# Production Verification Checklist

## Pre-Deployment Checklist

- [x] Code changes committed
- [x] No TypeScript/Go compilation errors
- [x] Backend models updated (ArrivalInfo)
- [x] Backend repository updated (GetArrivals query)
- [x] Backend config updated (CORS origins parsing)

## Deployment Checklist

### Backend (Render.com)

- [ ] Code pushed to GitHub main branch
- [ ] Render auto-deploy triggered
- [ ] Environment variables configured:
  - [ ] `ALLOWED_ORIGINS` includes Vercel URL
  - [ ] `DATABASE_URL` is correct
  - [ ] `JWT_SECRET` is set
  - [ ] `PORT=8080`
  - [ ] `GIN_MODE=release`
- [ ] Deployment completed successfully
- [ ] Logs show "Starting server on 0.0.0.0:8080"

### Frontend (Vercel)

- [ ] Frontend already deployed
- [ ] Environment variables correct:
  - [ ] `NEXT_PUBLIC_API_URL=https://booboo-booking.onrender.com`
  - [ ] `BACKEND_URL=https://booboo-booking.onrender.com`
  - [ ] `NEXTAUTH_URL=https://booboo-booking.vercel.app`
  - [ ] `NEXTAUTH_SECRET` is set

## Post-Deployment Testing

### 1. Health Check

- [ ] Backend health: https://booboo-booking.onrender.com/health
  - Expected: `{"status":"ok","message":"Hotel Booking System API is running"}`

- [ ] Frontend loads: https://booboo-booking.vercel.app
  - Expected: Homepage loads without errors

### 2. CORS Testing

- [ ] Open browser console at https://booboo-booking.vercel.app
- [ ] No CORS errors in console
- [ ] Test with curl:
  ```bash
  curl -X OPTIONS https://booboo-booking.onrender.com/api/rooms/status \
    -H "Origin: https://booboo-booking.vercel.app" \
    -H "Access-Control-Request-Method: GET" \
    -v
  ```
- [ ] Response includes `Access-Control-Allow-Origin: https://booboo-booking.vercel.app`

### 3. Authentication Testing

- [ ] Login page loads: https://booboo-booking.vercel.app/auth/admin
- [ ] Can login with manager credentials:
  - Email: `manager@hotel.com`
  - Password: `Manager123!`
- [ ] Redirects to dashboard after login
- [ ] JWT token stored in session

### 4. Room Status Testing (Reception Page)

- [ ] Navigate to: https://booboo-booking.vercel.app/admin/reception
- [ ] Page loads without errors
- [ ] Room status tab shows:
  - [ ] Summary cards with room counts
  - [ ] Grid of room cards with colors
  - [ ] Room numbers visible
  - [ ] Room types visible
  - [ ] Status indicators correct
- [ ] Auto-refresh works (check after 30 seconds)
- [ ] Manual refresh button works
- [ ] Filter buttons work
- [ ] Search box works

### 5. Check-in Testing

- [ ] Navigate to: https://booboo-booking.vercel.app/admin/checkin
- [ ] Page loads without errors
- [ ] Date selector works
- [ ] Arrivals list shows:
  - [ ] Guest names
  - [ ] Room types
  - [ ] Check-in/out dates
  - [ ] Number of guests
  - [ ] Payment status badges
- [ ] Click on an arrival shows:
  - [ ] Guest details card
  - [ ] Payment proof section (if available)
  - [ ] Room selection grid
  - [ ] Check-in button

### 6. Check-in Workflow Testing

If test data exists:

- [ ] Select today's date
- [ ] Click on an arrival with "approved" payment
- [ ] Room selection grid appears
- [ ] Select a room
- [ ] Click "Check-in" button
- [ ] Success message appears
- [ ] Arrival marked as checked in
- [ ] Room number displayed

### 7. API Response Testing

Test arrivals API directly:

```bash
# Get JWT token first by logging in
TOKEN="your_jwt_token_here"

# Test arrivals endpoint
curl "https://booboo-booking.onrender.com/api/checkin/arrivals?date=2025-01-15" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Origin: https://booboo-booking.vercel.app"
```

- [ ] Response status: 200
- [ ] Response includes:
  - [ ] `arrivals` array
  - [ ] `count` field
- [ ] Each arrival has:
  - [ ] `booking_id`
  - [ ] `booking_detail_id`
  - [ ] `guest_name`
  - [ ] `room_type_name`
  - [ ] `room_type_id` ✨ NEW
  - [ ] `check_in_date`
  - [ ] `check_out_date`
  - [ ] `num_guests`
  - [ ] `status`
  - [ ] `payment_status` ✨ NEW
  - [ ] `payment_proof_url` ✨ NEW (if exists)
  - [ ] `payment_proof_id` ✨ NEW (if exists)

### 8. Database Verification

Connect to database:
```bash
psql "postgresql://neondb_owner:npg_8kHamXSLKg1x@ep-jolly-dream-a1f9usld-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
```

- [ ] Check bookings exist:
  ```sql
  SELECT COUNT(*) FROM bookings WHERE status IN ('Confirmed', 'CheckedIn');
  ```
  Expected: > 0

- [ ] Check payment_proofs table exists:
  ```sql
  \dt payment_proofs
  ```
  Expected: Table found

- [ ] Check arrivals query works:
  ```sql
  SELECT 
      b.booking_id,
      bd.booking_detail_id,
      CONCAT(g.first_name, ' ', g.last_name) as guest_name,
      rt.name as room_type_name,
      bd.room_type_id,
      COALESCE(pp.status, 'none') as payment_status
  FROM bookings b
  JOIN guests g ON b.guest_id = g.guest_id
  JOIN booking_details bd ON b.booking_id = bd.booking_id
  JOIN room_types rt ON bd.room_type_id = rt.room_type_id
  LEFT JOIN payment_proofs pp ON b.booking_id = pp.booking_id
  WHERE b.status IN ('Confirmed', 'CheckedIn')
  LIMIT 5;
  ```
  Expected: Returns rows with all fields

### 9. Error Handling Testing

- [ ] Try accessing admin pages without login
  - Expected: Redirect to login page
- [ ] Try invalid date in check-in page
  - Expected: Shows "no arrivals" message
- [ ] Try check-in without selecting room
  - Expected: Error toast message
- [ ] Try check-in with unapproved payment
  - Expected: Error message about payment approval

### 10. Performance Testing

- [ ] Room status page loads in < 3 seconds
- [ ] Check-in page loads in < 3 seconds
- [ ] API responses in < 1 second
- [ ] No memory leaks (check browser task manager)
- [ ] No console warnings or errors

## Rollback Plan

If issues occur:

1. **Immediate**: Revert environment variables on Render
   - Remove Vercel URL from ALLOWED_ORIGINS temporarily
   - Use only localhost for testing

2. **Code Rollback**:
   ```bash
   git revert HEAD
   git push origin main
   ```

3. **Database Rollback** (if needed):
   - No schema changes were made
   - No rollback needed for this fix

## Success Criteria

All of the following must be true:

- ✅ No CORS errors in browser console
- ✅ Room status page displays all rooms
- ✅ Check-in page displays arrivals list
- ✅ Arrivals include payment proof information
- ✅ Can select rooms and perform check-in
- ✅ All API calls return status 200
- ✅ No errors in Render logs
- ✅ No errors in Vercel logs

## Sign-off

- [ ] Tested by: _______________
- [ ] Date: _______________
- [ ] All tests passed: Yes / No
- [ ] Issues found: _______________
- [ ] Production approved: Yes / No

## Notes

Add any observations or issues here:

---

**Last Updated**: 2025-01-08
**Version**: 1.0
**Related Docs**: 
- PRODUCTION_FIX_COMPLETE.md
- แก้ไข_Production_สำเร็จ.md
- CORS_PRODUCTION_FIX.md
- CHECKIN_DATA_FIX.md
