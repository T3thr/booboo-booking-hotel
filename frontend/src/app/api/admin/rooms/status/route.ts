import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";

const BACKEND_URL = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080";

export async function GET(request: NextRequest) {
  try {
    const session = await auth();

    if (!session) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Check if user is staff (receptionist or housekeeper)
    const userRole = session.user?.role?.toLowerCase();
    if (!["receptionist", "housekeeper", "manager", "admin"].includes(userRole || "")) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    // Fetch room status from backend
    const response = await fetch(`${BACKEND_URL}/api/rooms/status`, {
      headers: {
        Authorization: `Bearer ${session.accessToken}`,
      },
      cache: 'no-store',
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Backend error:", errorText);
      throw new Error(`Backend returned ${response.status}`);
    }

    const data = await response.json();

    // Calculate summary
    const rooms = data.data || [];
    const summary = {
      total: rooms.length,
      available: rooms.filter((r: any) => r.occupancy_status === "Vacant" && r.housekeeping_status === "Inspected").length,
      occupied: rooms.filter((r: any) => r.occupancy_status === "Occupied").length,
      maintenance: rooms.filter((r: any) => r.housekeeping_status === "MaintenanceRequired").length,
      clean: rooms.filter((r: any) => r.housekeeping_status === "Clean" || r.housekeeping_status === "Inspected").length,
      dirty: rooms.filter((r: any) => r.housekeeping_status === "Dirty").length,
      cleaning: rooms.filter((r: any) => r.housekeeping_status === "Cleaning").length,
    };

    return NextResponse.json({
      success: true,
      data: {
        rooms,
        summary,
      },
    });
  } catch (error) {
    console.error("Error fetching room status:", error);
    return NextResponse.json(
      {
        error: "Failed to fetch room status",
        details: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 }
    );
  }
}
