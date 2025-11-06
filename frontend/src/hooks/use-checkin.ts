import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { checkinApi } from '@/lib/api';

// Query hooks
export function useArrivals(date?: string) {
  return useQuery({
    queryKey: ['arrivals', date],
    queryFn: () => checkinApi.getArrivals(date),
    refetchInterval: 30000, // Refetch every 30 seconds
  });
}

export function useDepartures(date?: string) {
  return useQuery({
    queryKey: ['departures', date],
    queryFn: () => checkinApi.getDepartures(date),
    refetchInterval: 30000,
  });
}

// Mutation hooks
export function useCheckIn() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { booking_detail_id: number; room_id: number }) =>
      checkinApi.checkIn(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      queryClient.invalidateQueries({ queryKey: ['arrivals'] });
      queryClient.invalidateQueries({ queryKey: ['rooms'] });
      queryClient.invalidateQueries({ queryKey: ['roomStatus'] });
    },
  });
}

export function useCheckOut() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (bookingId: number) => checkinApi.checkOut(bookingId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      queryClient.invalidateQueries({ queryKey: ['departures'] });
      queryClient.invalidateQueries({ queryKey: ['rooms'] });
      queryClient.invalidateQueries({ queryKey: ['roomStatus'] });
    },
  });
}

export function useMoveRoom() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { assignment_id: number; new_room_id: number; reason?: string }) =>
      checkinApi.moveRoom(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      queryClient.invalidateQueries({ queryKey: ['rooms'] });
      queryClient.invalidateQueries({ queryKey: ['roomStatus'] });
    },
  });
}

export function useNoShow() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (bookingId: number) => checkinApi.noShow(bookingId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      queryClient.invalidateQueries({ queryKey: ['arrivals'] });
    },
  });
}
