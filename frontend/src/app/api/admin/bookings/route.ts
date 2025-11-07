import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { Pool } from "pg";

// Create PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/hotel_booking",
});

export async function GET(request: NextRequest) {
  try {
    const session = await auth();

    if (!session) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Check if user is staff (receptionist or manager)
    const userRole = session.user?.role?.toLowerCase();
    if (!["receptionist", "manager", "admin"].includes(userRole || "")) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    // Get query parameters
    const searchParams = request.nextUrl.searchParams;
    const statusFilter = searchParams.get("status");

    // Build SQL query
    let query = `
      SELECT 
        b.booking_id,
        b.guest_id,
        b.total_amount,
        b.status,
        b.created_at,
        b.updated_at,
        b.policy_name,
        b.policy_description,
        g.first_name || ' ' || g.last_name AS guest_name,
        g.email AS guest_email,
        g.phone AS guest_phone,
        json_agg(
          DISTINCT jsonb_build_object(
            'booking_detail_id', bd.booking_detail_id,
            'room_type_id', bd.room_type_id,
            'room_type_name', rt.name,
            'check_in_date', bd.check_in_date,
            'check_out_date', bd.check_out_date,
            'num_guests', bd.num_guests,
            'room_assignment', CASE 
              WHEN ra.room_assignment_id IS NOT NULL THEN
                jsonb_build_object(
                  'room_assignment_id', ra.room_assignment_id,
                  'room_id', ra.room_id,
                  'room_number', r.room_number,
                  'check_in_datetime', ra.check_in_datetime,
                  'check_out_datetime', ra.check_out_datetime,
                  'status', ra.status
                )
              ELSE NULL
            END
          )
        ) FILTER (WHERE bd.booking_detail_id IS NOT NULL) AS booking_details,
        json_agg(
          DISTINCT jsonb_build_object(
            'booking_guest_id', bg.booking_guest_id,
            'first_name', bg.first_name,
            'last_name', bg.last_name,
            'phone', bg.phone,
            'type', bg.type,
            'is_primary', bg.is_primary
          )
        ) FILTER (WHERE bg.booking_guest_id IS NOT NULL) AS booking_guests
      FROM bookings b
      LEFT JOIN guests g ON b.guest_id = g.guest_id
      LEFT JOIN booking_details bd ON b.booking_id = bd.booking_id
      LEFT JOIN room_types rt ON bd.room_type_id = rt.room_type_id
      LEFT JOIN room_assignments ra ON bd.booking_detail_id = ra.booking_detail_id AND ra.status = 'Active'
      LEFT JOIN rooms r ON ra.room_id = r.room_id
      LEFT JOIN booking_guests bg ON bd.booking_detail_id = bg.booking_detail_id
    `;

    const params: any[] = [];
    
    if (statusFilter && statusFilter !== "all") {
      query += ` WHERE b.status = $1`;
      params.push(statusFilter);
    }

    query += `
      GROUP BY b.booking_id, b.guest_id, b.total_amount, b.status, b.created_at, b.updated_at, 
               b.policy_name, b.policy_description, g.first_name, g.last_name, g.email, g.phone
      ORDER BY b.created_at DESC
      LIMIT 100
    `;

    const result = await pool.query(query, params);

    return NextResponse.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error("Error fetching bookings:", error);
    return NextResponse.json(
      {
        error: "Failed to fetch bookings",
        details: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 }
    );
  }
}
