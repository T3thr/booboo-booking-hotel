import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { Room } from '@/types';

// Get all rooms with their current status
export function useRoomStatus() {
  return useQuery<Room[]>({
    queryKey: ['roomStatus'],
    queryFn: () => api.get('/rooms/status'),
    refetchInterval: 30000, // Auto-refresh every 30 seconds
  });
}

// Get rooms filtered by status
export function useRoomsByStatus(
  occupancyStatus?: string,
  housekeepingStatus?: string
) {
  return useQuery<Room[]>({
    queryKey: ['rooms', 'status', occupancyStatus, housekeepingStatus],
    queryFn: () =>
      api.get('/rooms/status', {
        params: {
          occupancy_status: occupancyStatus,
          housekeeping_status: housekeepingStatus,
        },
      }),
    refetchInterval: 30000,
  });
}

// Get room status summary
export function useRoomStatusSummary() {
  return useQuery({
    queryKey: ['roomStatus', 'summary'],
    queryFn: () => api.get('/rooms/status/summary'),
    refetchInterval: 30000,
  });
}
