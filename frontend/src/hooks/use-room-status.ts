import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';

// Backend response types
export interface RoomStatus {
  room_id: number;
  room_number: string;
  occupancy_status: 'Vacant' | 'Occupied';
  housekeeping_status: 'Dirty' | 'Cleaning' | 'Clean' | 'Inspected' | 'MaintenanceRequired' | 'OutOfService';
  room_type_id: number;
  room_type_name: string;
  guest_name?: string;
  expected_checkout?: string;
}

export interface RoomStatusSummary {
  total_rooms: number;
  vacant_clean: number;
  vacant_inspected: number;
  vacant_dirty: number;
  occupied: number;
  out_of_service: number;
  maintenance_required: number;
}

export interface RoomStatusDashboardResponse {
  rooms: RoomStatus[];
  summary: RoomStatusSummary;
}

// Get all rooms with their current status
export function useRoomStatus() {
  return useQuery<RoomStatusDashboardResponse>({
    queryKey: ['roomStatus'],
    queryFn: async () => {
      const response = await api.get<{ success: boolean; data: RoomStatusDashboardResponse }>('/rooms/status');
      return response.data;
    },
    refetchInterval: 30000, // Auto-refresh every 30 seconds
  });
}

// Get rooms filtered by status
export function useRoomsByStatus(
  occupancyStatus?: string,
  housekeepingStatus?: string
) {
  return useQuery<RoomStatusDashboardResponse>({
    queryKey: ['rooms', 'status', occupancyStatus, housekeepingStatus],
    queryFn: async () => {
      const response = await api.get<{ success: boolean; data: RoomStatusDashboardResponse }>('/rooms/status', {
        params: {
          occupancy_status: occupancyStatus,
          housekeeping_status: housekeepingStatus,
        },
      });
      return response.data;
    },
    refetchInterval: 30000,
  });
}

// Get room status summary
export function useRoomStatusSummary() {
  return useQuery<RoomStatusSummary>({
    queryKey: ['roomStatus', 'summary'],
    queryFn: async () => {
      const response = await api.get<{ success: boolean; data: RoomStatusDashboardResponse }>('/rooms/status');
      return response.data.summary;
    },
    refetchInterval: 30000,
  });
}
