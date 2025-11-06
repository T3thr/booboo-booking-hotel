import { useQuery } from '@tanstack/react-query';
import { roomApi } from '@/lib/api';
import type { RoomType, RoomSearchResult } from '@/types';

// Search available rooms
export function useRoomSearch(params: {
  check_in_date: string;
  check_out_date: string;
  adults?: number;
  children?: number;
}) {
  return useQuery({
    queryKey: ['rooms', 'search', params],
    queryFn: async () => {
      const response = await roomApi.search(params);
      // Backend returns { success: true, data: { room_types: [...] } }
      // Extract the room_types array from response.data
      if (response.data && response.data.room_types) {
        return response.data.room_types;
      }
      // Fallback for direct room_types in response
      return response.room_types || [];
    },
    enabled: !!params.check_in_date && !!params.check_out_date,
  });
}

// Get all room types
export function useRoomTypes() {
  return useQuery<RoomType[]>({
    queryKey: ['roomTypes'],
    queryFn: () => roomApi.getTypes(),
    staleTime: 5 * 60 * 1000, // 5 minutes - room types don't change often
  });
}

// Get single room type
export function useRoomType(id: number) {
  return useQuery<RoomType>({
    queryKey: ['roomTypes', id],
    queryFn: () => roomApi.getType(id),
    enabled: !!id,
    staleTime: 5 * 60 * 1000,
  });
}

// Get pricing for a room type
export function useRoomPricing(
  id: number,
  params: {
    check_in_date: string;
    check_out_date: string;
    rate_plan_id?: number;
  }
) {
  return useQuery({
    queryKey: ['roomTypes', id, 'pricing', params],
    queryFn: () => roomApi.getPricing(id, params),
    enabled: !!id && !!params.check_in_date && !!params.check_out_date,
  });
}

// Get available rooms for check-in (for receptionist)
export function useRooms(params: { roomTypeId?: number; status?: string }) {
  return useQuery({
    queryKey: ['rooms', params],
    queryFn: async () => {
      if (params.roomTypeId && params.status === 'available') {
        // Import checkinApi dynamically to avoid circular dependency
        const { checkinApi } = await import('@/lib/api');
        return checkinApi.getAvailableRooms(params.roomTypeId);
      }
      return { rooms: [] };
    },
    enabled: !!params.roomTypeId,
    refetchInterval: 30000, // Refetch every 30 seconds
  });
}
