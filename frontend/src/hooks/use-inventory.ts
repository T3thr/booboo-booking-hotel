import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { inventoryApi } from '@/lib/api';
import type { RoomInventory } from '@/types';

// Query hooks
export function useInventory(params?: {
  room_type_id?: number;
  start_date?: string;
  end_date?: string;
}) {
  return useQuery({
    queryKey: ['inventory', params],
    queryFn: async () => {
      try {
        console.log('[useInventory] Fetching with params:', params);
        const response = await inventoryApi.get(params);
        console.log('[useInventory] Raw response:', JSON.stringify(response));
        
        // Handle different response formats
        if (Array.isArray(response)) {
          console.log('[useInventory] Response is array, length:', response.length);
          return response;
        }
        if (response?.data && Array.isArray(response.data)) {
          console.log('[useInventory] Response.data is array, length:', response.data.length);
          return response.data;
        }
        
        // Check if response is empty object or has no data
        if (!response || Object.keys(response).length === 0) {
          console.warn('[useInventory] Empty response - no inventory data in database');
          return [];
        }
        
        console.error('[useInventory] Unexpected response format:', response);
        return [];
      } catch (error) {
        console.error('[useInventory] Error:', error);
        return [];
      }
    },
    retry: false,
  });
}

// Mutation hooks
export function useUpdateInventory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: {
      room_type_id: number;
      date: string;
      allotment: number;
    }[]) => inventoryApi.update(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
    },
  });
}
