import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { housekeepingApi } from '@/lib/api';

// Query hooks
export function useHousekeepingTasks() {
  return useQuery({
    queryKey: ['housekeeping', 'tasks'],
    queryFn: () => housekeepingApi.getTasks(),
    refetchInterval: 30000, // Refetch every 30 seconds for real-time updates
  });
}

// Mutation hooks
export function useUpdateRoomStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ roomId, status }: { roomId: number; status: string }) =>
      housekeepingApi.updateRoomStatus(roomId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['housekeeping', 'tasks'] });
      queryClient.invalidateQueries({ queryKey: ['rooms'] });
      queryClient.invalidateQueries({ queryKey: ['roomStatus'] });
    },
  });
}

export function useInspectRoom() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      roomId,
      approved,
      reason,
    }: {
      roomId: number;
      approved: boolean;
      reason?: string;
    }) => housekeepingApi.inspectRoom(roomId, approved, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['housekeeping', 'tasks'] });
      queryClient.invalidateQueries({ queryKey: ['rooms'] });
      queryClient.invalidateQueries({ queryKey: ['roomStatus'] });
    },
  });
}

export function useReportMaintenance() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ roomId, description }: { roomId: number; description: string }) =>
      housekeepingApi.reportMaintenance(roomId, description),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['housekeeping', 'tasks'] });
      queryClient.invalidateQueries({ queryKey: ['rooms'] });
      queryClient.invalidateQueries({ queryKey: ['roomStatus'] });
    },
  });
}
